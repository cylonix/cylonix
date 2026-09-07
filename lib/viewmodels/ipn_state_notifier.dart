// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:collection';
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/exception.dart';
import '../models/ipn.dart';
import '../services/ipn.dart';
import '../services/mdm.dart';
import '../services/system_tray_service.dart';
import '../utils/distribution.dart';
import '../utils/logger.dart';
import '../utils/utils.dart';
import '../providers/ipn.dart';
import '../providers/settings.dart';
import 'state_notifier.dart';

class IpnStateNotifier extends StateNotifier<AsyncValue<IpnState>> {
  final Ref ref;
  final IpnService _ipnService;
  final MDMSettingsService _mdmSettings;
  final _notificationQueue = Queue<IpnNotification>();
  StreamSubscription<IpnNotification>? _notificationSubscription;
  bool _isProcessingNotification = false;
  bool _initializingAlwaysUseDerp = false;
  bool _initializingLocalDiscoveryRelay = false;
  bool _initializingL2RelayCapture = false;
  bool _initializingL2RelayVerboseDebug = false;
  bool _isTailchatInitialized = false;
  bool _isAlwaysUseDerpInitialized = false;
  bool _isLocalDiscoveryRelayInitialized = false;
  bool _isL2RelayCaptureInitialized = false;
  bool _isL2RelayVerboseDebugInitialized = false;
  bool _checkedFilesWaiting = false;
  String? urlBrowsed;
  bool loginSent = false;
  bool _reauthRequested = false;
  String? _reauthOrigNodeKey;

  var peerCategorizer = PeerCategorizer();
  static final _logger = Logger(tag: "IpnStateNotifier");

  IpnStateNotifier(this._ipnService, this._mdmSettings, this.ref)
      : super(const AsyncValue.loading()) {
    _logger.d("IpnStateNotifier initialized to loading state");
    if (isApple() && !IpnService.isDirectDistribution) {
      ref.listen(vpnPermissionStateProvider, (previous, next) {
        if (next && previous != true) {
          _logger.d("VPN permission granted=$next, initializing engine");
          _initialize();
        } else {
          _logger.d(
            "VPN permission state didn't change or denied "
            "(next=$next previous=$previous), not initializing engine",
          );
        }
      });
    } else {
      _logger.d("Not an Apple platform or direct distribution, initializing engine");
      _initialize();
    }
  }

  MDMSettingsService get mdmSettings => _mdmSettings;

  Future<void> _initialize() async {
    _logger.d("Initializing IpnStateNotifier. Set ipn state to connecting");
    state = const AsyncValue.data(IpnState(vpnState: VpnState.connecting));

    try {
      if (Platform.isWindows || Platform.isMacOS) {
        SystemTrayService.setCallbacks(
          onConnect: () async {
            _logger.d("System tray connect clicked");
            await startVpn();
          },
          onDisconnect: () async {
            _logger.d("System tray disconnect clicked");
            await stopVpn();
          },
        );
      }
      _notificationSubscription?.cancel();
      _notificationSubscription =
          _ipnService.notificationStream.listen((notification) {
        _notificationQueue.add(notification);
        _processNextNotification();
      });
      await _ipnService.initializeEngine(_onError);
      unawaited(_logAppBuildInfo());
      await _syncStateFromBackendStatus();
    } catch (error, stack) {
      _onError(error, stack);
    }
  }

  /// Ships one line with the app version and install source to the daemon
  /// log (and hence the uploaded log stream) so support can tell from a
  /// log what build a user is running, and reports the same build string
  /// to the daemon for Hostinfo.App so the control server sees it too.
  /// Sent after the engine is up so both paths to the daemon exist.
  Future<void> _logAppBuildInfo() async {
    final PackageInfo info;
    try {
      info = await PackageInfo.fromPlatform();
    } catch (e) {
      _logger.w("Failed to read package info for build log: $e");
      return;
    }
    _logger.i(appVersionLogLine(info));
    try {
      await _ipnService.setAppInfo(appHostinfoValue(info));
    } catch (e) {
      _logger.w("Failed to report app info to daemon: $e");
    }
  }

  Timer? _stateResyncTimer;
  int _stateNotifySeq = 0;

  /// Schedules a forced backend-status resync shortly after a notification
  /// lands the UI in a disconnected-family state. On iOS the app process is
  /// routinely evicted while the network extension keeps running; on
  /// relaunch the bridge replays the queued notification backlog, and a
  /// minutes-old State transition from that history (e.g. a transient
  /// needsLogin) can drive the UI to "disconnected" while the tunnel is
  /// actually up — and nothing else ever corrects it (observed 2026-08-23,
  /// UI stuck disconnected with the NE healthy). Stale notifications are
  /// history, not truth: after the burst settles, ask the backend what
  /// state it is really in. For a genuine disconnect the status call just
  /// confirms the current state and changes nothing.
  void _scheduleStateResync() {
    _stateResyncTimer?.cancel();
    _stateResyncTimer = Timer(const Duration(seconds: 2), () {
      _syncStateFromBackendStatus(force: true);
    });
  }

  Future<void> _syncStateFromBackendStatus({bool force = false}) async {
    // Cold-start sync: don't pass fast:true. The 500ms fast-path timeout
    // races libtailscale's runBackend cold start (lb.Start holds b.mu while
    // the LocalAPI status handler waits for it); using the regular 5s
    // timeout lets the call succeed once the backend reaches its first
    // steady state. If we still time out, retry a few times with
    // exponential backoff before giving up — the notification stream will
    // eventually deliver state transitions, but a successful status read
    // here lets the UI move past the "connecting" placeholder immediately.
    const maxAttempts = 4;
    var delayMs = 500;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final seqAtFetch = _stateNotifySeq;
        final status = await _ipnService.status(light: true);
        final backendState = BackendState.fromString(status.backendState);
        final currentState = state.valueOrNull ?? const IpnState();
        // force mode (stale-replay recovery): apply the fetched state
        // whenever it disagrees with the UI, unless a fresh state-bearing
        // notification arrived while the fetch was in flight — that newer
        // transition wins over our snapshot.
        final shouldSync = force
            ? (backendState != currentState.backendState &&
                _stateNotifySeq == seqAtFetch)
            : (currentState.backendState == BackendState.noState ||
                currentState.vpnState == VpnState.connecting);

        if (!shouldSync) {
          return;
        }

        final shouldClearSessionData =
            backendState.index <= BackendState.needsLogin.index;
        state = AsyncValue.data(
          currentState.copyWith(
            backendState: backendState,
            vpnState: _vpnStateForBackendState(backendState),
            isMeshMode: !status.tun,
            loggedInUser:
                shouldClearSessionData ? null : currentState.loggedInUser,
            selfNode: shouldClearSessionData ? null : currentState.selfNode,
            netmap: shouldClearSessionData ? null : currentState.netmap,
            currentProfile:
                shouldClearSessionData ? null : currentState.currentProfile,
          ),
        );
        return;
      } catch (error) {
        if (attempt == maxAttempts) {
          _logger.w(
              "Failed to sync backend status after $maxAttempts attempts: $error");
          return;
        }
        _logger.d(
            "Sync backend status attempt $attempt/$maxAttempts failed ($error); retrying in ${delayMs}ms");
        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs = (delayMs * 2).clamp(500, 4000);
      }
    }
  }

  void _onError(Object error, StackTrace stack) {
    _logger.e("Error in IpnStateNotifier: $error, stackTrace: $stack");
    var e = error;
    if (Platform.isLinux) {
      if (error
          .toString()
          .contains("OS Error: No such file or directory, errno = 2")) {
        e = Exception("Cylonix backend initialization failed. "
            "Please ensure the Cylonixd service is running.");
      }
    }
    state = AsyncValue.error(e, stack);
  }

  Future<void> _processNextNotification() async {
    if (_isProcessingNotification || _notificationQueue.isEmpty) {
      return;
    }

    _isProcessingNotification = true;
    try {
      while (_notificationQueue.isNotEmpty) {
        final notification = _notificationQueue.removeFirst();
        await _handleIpnNotification(notification);
        if (state.valueOrNull?.backendState != BackendState.noState) {
          if (!_isAlwaysUseDerpInitialized) {
            _logger.d("Initializing always use DERP");
            _initAlwaysUseDerp();
          }
          if (!_isLocalDiscoveryRelayInitialized) {
            _logger.d("Initializing local discovery relay");
            _initLocalDiscoveryRelay();
          }
          if (!_isL2RelayCaptureInitialized) {
            _logger.d("Initializing l2 relay capture");
            _initL2RelayCapture();
          }
          if (!_isL2RelayVerboseDebugInitialized) {
            _logger.d("Initializing l2 relay verbose debug");
            _initL2RelayVerboseDebug();
          }
          if (!_isTailchatInitialized && !_initializingTailchat) {
            _logger.d("Initializing tailchat");
            _initTailchat();
          }
        }
      }
    } finally {
      _isProcessingNotification = false;
    }
  }

  Future<void> _handleIpnNotification(IpnNotification notification) async {
    if (notification.state != null || notification.browseToURL != null) {
      _logger.d(
        "Received notification state=${notification.state} "
        "url=${notification.browseToURL}",
      );
    }
    List<LoginProfile>? loginProfiles;
    var currentProfile = state.valueOrNull?.currentProfile;
    if (notification.netMap != null) {
      peerCategorizer.regenerateGroupedPeers(notification.netMap!);
      currentProfile = await getCurrentProfile();
    }
    final currentState = state.valueOrNull;
    var backendState = currentState?.backendState ?? BackendState.noState;
    var netmap = notification.netMap ?? currentState?.netmap;
    var loggedInUser = peerCategorizer.me ?? currentState?.loggedInUser;

    final ns = notification.state;
    if (ns != null) {
      _stateNotifySeq++;
      backendState = BackendState.fromInt(ns);
      _logger.d(
        "\n\n\n********** NEW STATE -> ${backendState.name} ***********\n\n\n",
      );
      if (backendState != BackendState.noState) {
        loginProfiles = await getProfiles();
        if (backendState.index <= BackendState.needsLogin.index) {
          _logger.d(
            "\n\n\n***************** Not Logged In *******************\n\n\n",
          );
          loggedInUser = null;
          netmap = null;
          peerCategorizer = PeerCategorizer();
          currentProfile = null;
          // This may be a stale transition replayed from the notification
          // backlog after an app relaunch; verify against the live backend
          // before letting "disconnected" stand (see _scheduleStateResync).
          _scheduleStateResync();
        }
      }
      if (ns > BackendState.needsLogin.value) {
        // Past needsLogin: the post-login progress bridge (if any) is over,
        // and so is any add-account flow (its login completed, or the
        // backend is back on a logged-in profile).
        _setLoginFinishing(false);
        _clearAddAccount("backend past needsLogin");
        if (urlBrowsed != null) {
          if (isMobile()) {
            // Mobile platform with URL browsed and state changed to past
            // needsLogin. Close the in-app web view.
            _logger.d("Closing in-app web view. State -> $backendState");
            closeInAppWebView();
            if (Platform.isAndroid) {
              // On Android we have to rely on the native side to
              // close the custom tab.
              _ipnService.loginComplete();
            }
          }
        }
      }
    }
    // Login finished: the auth session is established even though the backend
    // may still be fetching the first netmap before it leaves needsLogin and
    // reaches running. Close the in-app login view now so the user returns to
    // the app immediately and watches the native connecting state instead of
    // a browser page waiting out the transitions. This covers both new login
    // and reauth; the needsLogin-crossing close above stays as a fallback for
    // flows that never emit LoginFinished (e.g. machine auth approval).
    if (notification.loginFinished != null &&
        urlBrowsed != null &&
        isMobile()) {
      _logger.d("Closing in-app web view: login finished.");
      closeInAppWebView();
      if (Platform.isAndroid) {
        _ipnService.loginComplete();
      }
      urlBrowsed = null;
      // The backend stays in needsLogin until the first netmap arrives; mark
      // login as finishing so the UI shows progress instead of flashing the
      // login page underneath the dismissed browser.
      _setLoginFinishing(true);
    }

    final vpnState = _determineVpnState(notification);
    if (state.valueOrNull?.vpnState != vpnState) {
      _logger.d("\n\n******** VPN state -> $vpnState **********\n\n");
    }

    // If local backend sends another URL to us. Clear the browsed URL
    // even if they match since backend wants to try again.
    if ((notification.browseToURL ?? "") != "") {
      _logger.d("Received browseToURL: ${notification.browseToURL}, "
          "clearing urlBrowsed");
      urlBrowsed = null;
      // A new login URL supersedes any post-login progress bridge: drop back
      // to the login page so it can (re)launch the URL.
      _setLoginFinishing(false);
    }

    // Track an in-progress explicit re-authentication. When the device key has
    // not yet expired, the backend renews the node key seamlessly: it stays in
    // the running state and never drops to needsLogin. We keep the login URL
    // (instead of discarding it below) and route the UI to the login page so it
    // auto-launches the URL like a normal login. Completion is detected by the
    // node key changing or a LoginFinished event, mirroring upstream
    // `tailscale up --force-reauth`.
    if (_reauthRequested) {
      final newNodeKey =
          (notification.netMap ?? currentState?.netmap)?.selfNode.key;
      final keyChanged = newNodeKey != null &&
          newNodeKey.isNotEmpty &&
          _reauthOrigNodeKey != null &&
          newNodeKey != _reauthOrigNodeKey;
      if (notification.loginFinished != null || keyChanged) {
        _logger.d("Reauth: completed (loginFinished="
            "${notification.loginFinished != null}, keyChanged=$keyChanged)");
        _setReauthInProgress(false);
        // Completion detected by the node key changing without a
        // LoginFinished event: the unified loginFinished close above never
        // ran, so close the relaunched in-app view here. (When LoginFinished
        // did fire, urlBrowsed is already null and this is a no-op.)
        if (isMobile() && urlBrowsed != null) {
          _logger.d("Closing in-app web view after reauth completion.");
          closeInAppWebView();
          if (Platform.isAndroid) {
            _ipnService.loginComplete();
          }
        }
        urlBrowsed = null;
      }
    }

    // Determine browseToURL
    var browseToURL = notification.browseToURL ?? currentState?.browseToURL;
    if (backendState.value > BackendState.needsLogin.index) {
      // A login URL is normally only relevant at/below needsLogin. During an
      // explicit re-auth of a not-yet-expired key the backend stays running, so
      // keep the URL until login finishes — this lets the login page show and
      // auto-launch the URL exactly like a normal login.
      if (!_reauthRequested) {
        browseToURL = null;
        loginSent = false;
      }
    }

    var health = notification.health;
    if (isMobile() || Platform.isMacOS) {
      final warnings = health?.warnings;
      if (warnings != null) {
        final filteredWarnings = Map<String, UnhealthyState?>.from(warnings);
        // Remove specific warnings that are not relevant for mobile or macOS
        // which has the backend bundled in the app.
        filteredWarnings.removeWhere((key, warning) =>
            warning?.warnableCode == "update-available" ||
            warning?.warnableCode == "is-using-unstable-version");
        health = HealthState(warnings: filteredWarnings);
      }
    }

    List<AwaitingFile>? awaitingFiles;
    var errMessage = notification.errMessage ?? currentState?.errMessage;
    // For Apple App Store builds, we rely on the notification from native side
    // to update the files waiting and move them, so we don't fetch it here.
    // For direct distribution on macOS, we use the HTTP API like non-Apple
    // platforms since there is no network extension to relay notifications.
    if (!isApple() || IpnService.isDirectDistribution) {
      if (notification.filesWaiting != null) {
        if (isApple()) {}
        try {
          awaitingFiles = await getWaitingFiles(throwOnError: true);
        } catch (e) {
          _logger.e("Failed to get waiting files: $e");
          if (errMessage != null) {
            errMessage += "\nFailed to get waiting files: $e";
          } else {
            errMessage = "Failed to get waiting files: $e";
          }
        }
        _checkedFilesWaiting = true;
      } else if (!_checkedFilesWaiting &&
          backendState == BackendState.running) {
        // Quick check for awaiting files once when backend is running.
        awaitingFiles = await getWaitingFiles(
          timeoutMilliseconds: 1000,
          ignoreErrors: true,
        );
        // If there is no file waiting, we don't need to check again.
        // Otherwise keep checking until we received a notification with
        // filesWaiting. This is to handle the case when the app starts
        // and backend does not send filesWaiting notification soon enough.
        if (awaitingFiles == null || awaitingFiles.isEmpty) {
          _checkedFilesWaiting = true;
        }
      }
    } else if (notification.filesWaiting != null) {
      final filesWaitingMap = notification.filesWaiting!;
      final dir = filesWaitingMap['Dir'] as String? ?? '';
      final files =
          (filesWaitingMap['Files'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(
                (file) => AwaitingFile(
                  id: file['ID'] as String?,
                  name: file['Name'] as String? ?? '',
                  size: (file['Size'] as num?)?.toInt() ?? 0,
                  path: dir.isEmpty
                      ? null
                      : p.join(dir, file['Name'] as String? ?? ''),
                ),
              )
              .where((file) => file.name.isNotEmpty)
              .toList();
      awaitingFiles = files;
      _checkedFilesWaiting = true;
    }

    // Create new state or update existing one
    final newState = currentState?.copyWith(
          backendState: backendState,
          netmap: netmap,
          prefs: notification.prefs ?? currentState.prefs,
          vpnState: vpnState,
          health: health ?? currentState.health,
          loggedInUser: loggedInUser,
          currentProfile: currentProfile,
          selfNode: peerCategorizer.selfNode ?? currentState.selfNode,
          browseToURL: browseToURL,
          errMessage: errMessage,
          outgoingFiles: notification.outgoingFiles,
          filesWaiting: awaitingFiles,
          loginProfiles: ((loginProfiles ?? []).isNotEmpty
                  ? loginProfiles
                  : currentState.loginProfiles) ??
              [],
        ) ??
        IpnState(
          backendState: backendState,
          netmap: netmap,
          prefs: notification.prefs,
          vpnState: vpnState,
          health: notification.health,
          loggedInUser: loggedInUser,
          currentProfile: currentProfile,
          selfNode: peerCategorizer.selfNode,
          browseToURL: browseToURL,
          errMessage: errMessage,
          loginProfiles: loginProfiles ?? [],
          outgoingFiles: notification.outgoingFiles,
          filesWaiting: awaitingFiles,
        );

    if (newState.loggedInUser != null) {
      //_logger.d(
      //  "\n\n\n********* loginUser -> ${newState.loggedInUser} *********\n\n\n",
      //);
    }

    state = AsyncValue.data(newState);
    final relayEnabled =
        newState.selfNode?.capMap?.containsKey('can-relay-l2-discovery') ??
            false;
    ref.read(localDiscoveryRelayProvider.notifier).setState(relayEnabled);

    // For windows, update the system tray status.
    updateSystemTrayStatus();
  }

  void updateSystemTrayStatus() {
    if (!Platform.isWindows && !Platform.isMacOS) {
      return;
    }
    final vpnState = state.valueOrNull?.vpnState ?? VpnState.disconnected;
    final displayName = state.valueOrNull?.loggedInUser?.displayName ?? '';
    final deviceName = state.valueOrNull?.selfNode?.name ?? '';
    final avatarUrl = state.valueOrNull?.loggedInUser?.profilePicURL;
    final email = state.valueOrNull?.loggedInUser?.loginName;

    var isConnected = false;
    var tooltip = 'Cylonix - Disconnected';
    switch (vpnState) {
      case VpnState.connected:
        isConnected = true;
        tooltip = 'Cylonix - Connected';
        break;
      case VpnState.connecting:
        isConnected = false;
        tooltip = 'Cylonix - Connecting...';
        break;
      case VpnState.disconnecting:
        isConnected = false;
        tooltip = 'Cylonix - Disconnecting...';
        break;
      case VpnState.disconnected:
        isConnected = false;
        tooltip = 'Cylonix - Disconnected. Click to connect.';
        break;
      case VpnState.error:
        isConnected = false;
        tooltip = 'Cylonix - Error';
        break;
    }
    SystemTrayService.setConnectionState(
      isConnected: isConnected,
      tooltip: tooltip,
      displayName: displayName,
      deviceName: deviceName,
      avatarUrl: avatarUrl,
      email: email,
    );
  }

  VpnState _determineVpnState(IpnNotification notification) {
    final backendState = BackendState.fromInt(notification.state ?? -1);
    if (backendState == BackendState.noState) {
      return state.valueOrNull?.vpnState ?? VpnState.disconnected;
    }
    return _vpnStateForBackendState(backendState);
  }

  VpnState _vpnStateForBackendState(BackendState backendState) {
    switch (backendState) {
      case BackendState.noState:
        return state.valueOrNull?.vpnState ?? VpnState.disconnected;
      case BackendState.needsLogin:
      case BackendState.needsMachineAuth:
      case BackendState.stopped:
        return VpnState.disconnected;
      case BackendState.running:
        return VpnState.connected;
      case BackendState.starting:
        return VpnState.connecting;
      case BackendState.stopping:
        return VpnState.disconnecting;
      case BackendState.inUseOtherUser:
        return VpnState.error;
    }
  }

  Future<void> reset() async {
    loginSent = false;
    urlBrowsed = null;
    state = const AsyncValue.data(IpnState());
    ref.read(localDiscoveryRelayProvider.notifier).setState(false);
    _logger.d("Resetting and re-initialize IpnStateNotifier");
    await start();
  }

  Future<void> start() async {
    _isTailchatInitialized = false;
    _isAlwaysUseDerpInitialized = false;
    _isLocalDiscoveryRelayInitialized = false;
    _isL2RelayCaptureInitialized = false;
    ref.read(localDiscoveryRelayProvider.notifier).setState(false);
    await _initialize();
  }

  Future<void> toggleVpn() async {
    // Set loading state immediately
    final savedState = state.valueOrNull;
    _logger.d("Toggling VPN. Set ipn state to connecting or disconnecting");

    try {
      _logger.d("Toggling VPN");
      if (savedState == null) {
        throw Exception("Cannot toggle VPN: state is null");
      }

      if (savedState.vpnState == VpnState.connected) {
        _logger.d("Stopping VPN");
        state = AsyncValue.data(
          savedState.copyWith(
            vpnState: VpnState.disconnecting,
          ),
        );

        await _ipnService.stopVpn();
      } else {
        _logger.d("Starting VPN");
        state = AsyncValue.data(
          savedState.copyWith(
            vpnState: VpnState.connecting,
          ),
        );

        await _ipnService.startVpn();
      }
    } catch (error, stack) {
      _logger.e("Failed to toggle VPN: $error, stackTrace: $stack");
      state = AsyncValue.error(error, stack);
      // Let the error propagate up to be handled by the error UI
      rethrow;
    }
  }

  Future<void> startVpn() async {
    _logger.d("Starting VPN. Set ipn state to connecting");
    state = AsyncValue.data(
      (state.valueOrNull ?? const IpnState()).copyWith(
        vpnState: VpnState.connecting,
      ),
    );
    try {
      await _ipnService.startVpn();
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> stopVpn() async {
    _logger.d("Stopping VPN. Set ipn state to disconnecting");
    state = AsyncValue.data(
      (state.valueOrNull ?? const IpnState()).copyWith(
        vpnState: VpnState.disconnecting,
      ),
    );
    try {
      await _ipnService.stopVpn();
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<List<dynamic>> getLogs() async {
    _logger.d("Getting logs");
    return await _ipnService.getLogs();
  }

  Future<void> login({
    String? authKey,
    String? controlURL,
    bool reauth = false,
  }) async {
    _logger.d(
      "\n\n***Logging in with authKey: $authKey, controlURL: $controlURL, "
      "reauth: $reauth. Set ipn state to connecting***\n\n",
    );
    if (!reauth) _abandonReauth("a new login supersedes it");
    final previousState = state.valueOrNull ?? const IpnState();
    state = AsyncValue.data(
      previousState.copyWith(
        vpnState: VpnState.connecting,
      ),
    );
    try {
      await _ipnService.login(
        authKey: authKey,
        controlURL: controlURL,
        reauth: reauth,
      );
      loginSent = true;
    } catch (error, stack) {
      _logger.e("login() caught error: $error");
      // Restore previous state instead of AsyncValue.error so derived
      // providers keep their values and the UI doesn't flash to a
      // disconnected/reconnect view.
      state = AsyncValue.data(previousState);
      rethrow;
    }
  }

  /// Re-authenticate the current profile.
  ///
  /// Performs an interactive login, which forces control to rotate a new node
  /// key and return a fresh login URL. The request is remembered so the
  /// notification handler opens that URL in the browser even when the backend
  /// stays in the running state (seamless key renewal for a not-yet-expired
  /// key). Mirrors `tailscale up --force-reauth`.
  Future<void> reauthenticate() async {
    if (_reauthRequested) {
      _logger.d("Reauth already in progress, ignoring duplicate request");
      return;
    }
    // Remember the current node key so we can detect when control rotates it,
    // which marks the re-authentication as complete (the backend may stay
    // running the whole time when the key has not yet expired).
    _reauthOrigNodeKey = state.valueOrNull?.netmap?.selfNode.key;
    // Mark reauth in progress so the UI drops to the login page.
    _setReauthInProgress(true);
    try {
      // No controlURL: reauth reuses the daemon's current (own) controller.
      await login(reauth: true);
    } catch (e) {
      _setReauthInProgress(false);
      rethrow;
    }
  }

  /// Drop the app-side re-authentication bookkeeping: the in-progress flag,
  /// the pending login URL and the "login sent" marker, so the login page
  /// cannot re-launch the URL. Used when the user abandons the re-auth and
  /// when another flow (new login, add account, profile switch, logout)
  /// supersedes it.
  void _abandonReauth(String reason) {
    if (!_reauthRequested) return;
    _logger.d("Reauth: abandoned ($reason)");
    _setReauthInProgress(false);
    loginSent = false;
    clearBrowseToURL();
  }

  /// Abandon an in-progress explicit re-authentication and return to the
  /// main view, leaving the node on its current key until that expires.
  ///
  /// Only meaningful while the key has not expired: the backend then stayed
  /// running throughout the re-auth. The interactive login it started is
  /// still pending in the daemon, though, and keeps the "You are logged out"
  /// health warning raised until it completes. Re-issuing `start` with the
  /// current prefs replaces the control client, which logs back in with the
  /// existing (still valid) node key: the pending login and the warning go
  /// away, and the key is unchanged because a rotated key is only persisted
  /// once an interactive login completes. The expiry notice on the home
  /// screen remains as the way to try again later.
  Future<void> cancelReauthentication() async {
    if (!_reauthRequested) return;
    _abandonReauth("cancelled by the user; keeping the current node key");
    try {
      await _ipnService.start();
    } catch (e) {
      _logger.e("Reauth cancel: failed to restart the backend: $e");
    }
  }

  Timer? _loginFinishingTimer;

  // Marks the post-login progress bridge (LoginFinished seen, backend not yet
  // past needsLogin). A safety timeout clears it so the UI can never wedge on
  // the spinner if the backend stalls before the first netmap.
  void _setLoginFinishing(bool value) {
    _loginFinishingTimer?.cancel();
    _loginFinishingTimer = null;
    if (ref.read(loginFinishingProvider) != value) {
      ref.read(loginFinishingProvider.notifier).state = value;
    }
    if (value) {
      _loginFinishingTimer = Timer(const Duration(seconds: 30), () {
        ref.read(loginFinishingProvider.notifier).state = false;
      });
    }
  }

  void _setReauthInProgress(bool value) {
    _reauthRequested = value;
    if (!value) {
      _reauthOrigNodeKey = null;
    }
    ref.read(reauthInProgressProvider.notifier).state = value;
  }

  Future<void> logout() async {
    _abandonReauth("logging out");
    _clearAddAccount("logging out");
    await _ipnService.logout();
  }

  void clearBrowseToURL() {
    _logger.d("Clearing browseToURL");
    urlBrowsed = null;
    state = AsyncValue.data(
      (state.valueOrNull ?? const IpnState()).copyWith(browseToURL: null),
    );
  }

  void clearErrorMessage() {
    _logger.d("Clearing error message");
    state = AsyncValue.data(
      (state.valueOrNull ?? const IpnState()).copyWith(errMessage: null),
    );
  }

  Future<List<LoginProfile>?> getProfiles() async {
    try {
      return await _ipnService.getProfiles();
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      return null;
    }
  }

  Future<LoginProfile?>? _profileFetch;

  Future<LoginProfile?> getCurrentProfile() {
    // Coalesce concurrent callers: a replayed notification backlog after an
    // app relaunch otherwise fans out into one current_profile round-trip
    // per queued netmap notification (297 calls in one 4.5-minute iOS log).
    return _profileFetch ??= _fetchCurrentProfile().whenComplete(() {
      _profileFetch = null;
    });
  }

  Future<LoginProfile?> _fetchCurrentProfile() async {
    try {
      return await _ipnService.currentProfile();
    } catch (error) {
      // A failed profile read must not poison the whole IpnState (it used
      // to set AsyncValue.error, blanking the UI to the error/disconnected
      // view even though the tunnel was fine). Keep the last known profile.
      _logger.w("Failed to fetch current profile: $error");
      return state.valueOrNull?.currentProfile;
    }
  }

  Future<void> addProfile(String? controlURL) async {
    _abandonReauth("adding an account");
    // Remember the profile being left only when it was selected and logged
    // in: that is the state "Cancel Add Account" can take the user back to.
    final before = state.valueOrNull ?? const IpnState();
    final from = before.currentProfile;
    final fromLoggedIn = from != null &&
        !from.isEmpty &&
        before.backendState.value > BackendState.needsLogin.value;
    try {
      await _ipnService.addProfile();
    } catch (error, stack) {
      _logger.e("Failed to add profile: $error, stackTrace: $stack");
      rethrow;
    }
    _logger.d("Added profile, entering needsLogin state"
        "${fromLoggedIn ? ' (cancel returns to ${from.name})' : ''}");
    ref.read(addAccountFromProfileProvider.notifier).state =
        fromLoggedIn ? from : null;
    final currentState = state.valueOrNull ?? const IpnState();
    state = AsyncValue.data(
      currentState.copyWith(
        backendState: BackendState.needsLogin,
        browseToURL: null,
      ),
    );
  }

  void _clearAddAccount(String reason) {
    if (ref.read(addAccountFromProfileProvider) == null) return;
    _logger.d("Add account: flow ended ($reason)");
    ref.read(addAccountFromProfileProvider.notifier).state = null;
  }

  /// Abandon an "Add Account" that has not logged in yet and switch the
  /// backend back to the profile that was selected and logged in before it
  /// started. The new profile was never saved (the daemon only persists a
  /// profile once its login completes), so switching away simply discards
  /// it. No-op when Add Account was not started from a logged-in profile.
  Future<void> cancelAddAccount() async {
    final from = ref.read(addAccountFromProfileProvider);
    if (from == null) return;
    _logger.d("Add account: cancelled; switching back to ${from.name}");
    _clearAddAccount("cancelled by the user");
    loginSent = false;
    clearBrowseToURL();
    await switchProfile(from.id);
  }

  Future<void> deleteProfile(String profileID) async {
    try {
      await _ipnService.deleteProfile(profileID);
    } catch (error, stack) {
      _logger.e("Failed to delete profile: $error, stackTrace: $stack");
      rethrow;
    }
    final profiles = await getProfiles();
    state = AsyncValue.data(
      (state.valueOrNull ?? const IpnState()).copyWith(
        loginProfiles: profiles ?? [],
      ),
    );
  }

  Future<void> switchProfile(String id) async {
    _abandonReauth("switching profile");
    _clearAddAccount("switching profile");
    try {
      _logger.d("Switching profile with id: $id. Set ipn state to connecting");
      state = AsyncValue.data(
        const IpnState().copyWith(
          vpnState: VpnState.connecting,
        ),
      );
      await _ipnService.switchProfile(id);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> stopPing() async {
    try {
      await _ipnService.stopPing();
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> startTailchat() async {
    try {
      _logger.d("Starting tailchat");
      await _ipnService.startTailchat();
      ref.read(tailchatServiceStateProvider.notifier).state = true;
    } catch (error, stack) {
      _logger.e("Failed to start tailchat: $error, stackTrace: $stack");
      rethrow;
    }
  }

  Future<void> stopTailchat() async {
    try {
      _logger.d("Stopping tailchat");
      await _ipnService.stopTailchat();
      ref.read(tailchatServiceStateProvider.notifier).state = false;
    } catch (error, stack) {
      _logger.e("Failed to stop tailchat: $error, stackTrace: $stack");
      rethrow;
    }
  }

  Future<void> setAlwaysUseDerp(bool on) async {
    try {
      _logger.d("Setting always use DERP to: $on");
      await _ipnService.setAlwaysUseDerp(on);
    } catch (error, stack) {
      _logger.e("Failed to set always use DERP: $error, stackTrace: $stack");
      rethrow;
    }
  }

  Future<void> setLocalDiscoveryRelay(bool on) async {
    try {
      _logger.d("Setting local discovery relay to: $on");
      await _ipnService.setLocalDiscoveryRelay(on);
    } catch (error, stack) {
      _logger.e(
        "Failed to set local discovery relay: $error, stackTrace: $stack",
      );
      rethrow;
    }
  }

  Future<void> setL2RelayCapture(bool on) async {
    try {
      _logger.d("Setting l2 relay capture to: $on");
      await _ipnService.setL2RelayCapture(on);
    } catch (error, stack) {
      _logger.e("Failed to set l2 relay capture: $error, stackTrace: $stack");
      rethrow;
    }
  }

  Future<void> setL2RelayVerboseDebug(bool on) async {
    try {
      _logger.d("Setting l2 relay verbose debug to: $on");
      await _ipnService.setL2RelayVerboseDebug(on);
    } catch (error, stack) {
      _logger.e(
        "Failed to set l2 relay verbose debug: $error, stackTrace: $stack",
      );
      rethrow;
    }
  }

  Future<bool> requestLocalNetworkPermission() async {
    return _ipnService.requestLocalNetworkPermission();
  }

  Future<void> setUserDialUseRoutes(bool on) async {
    try {
      _logger.d("Setting user dial use routes to: $on");
      await _ipnService.setUserDialUseRoutes(on);
      final savedState = state.valueOrNull;
      if (savedState == null) {
        throw "invalid ipn state";
      }
      final netmap = savedState.netmap;
      final selfNode = netmap?.selfNode;
      if (netmap == null || selfNode == null) {
        return;
      }
      Map<String, dynamic>? capMap;
      final originalCapMap = netmap.selfNode.capMap;

      if (on) {
        capMap = {
          ...?(originalCapMap),
          'user-dial-routes': "",
        };
      } else {
        if (originalCapMap != null) {
          capMap = Map<String, dynamic>.from(originalCapMap);
          capMap.remove('user-dial-routes');
        }
      }
      state = AsyncValue.data(
        savedState.copyWith(
          netmap: netmap.copyWith(
            selfNode: selfNode.copyWith(
              capMap: capMap,
            ),
          ),
        ),
      );
    } catch (error, stack) {
      _logger
          .e("Failed to set user dial use routes: $error, stackTrace: $stack");
      rethrow;
    }
  }

  Future<void> setSendDNSToExitNodeInTunnel(bool on) async {
    try {
      _logger.d("Setting 'send dns to exit node in tunnel' to: $on");
      await _ipnService.setSendDNSToExitNodeInTunnel(on);
    } catch (error) {
      _logger.e("Failed to set 'send dns to exit node in tunnel': $error");
      rethrow;
    }
  }

  Future<DNSQueryResponse> queryDNS(String name, {String? type}) async {
    try {
      _logger.d("Querying DNS for name: $name, type: $type");
      return await _ipnService.queryDNS(name, type: type);
    } catch (error) {
      _logger.e("Failed to query DNS': $error");
      rethrow;
    }
  }

  Future<void> sendPeerFiles({
    required String peerID,
    required List<OutgoingFile> files,
  }) async {
    try {
      _logger.d("Sending files to peer: $peerID");
      await _ipnService.sendPeerFiles(peerID, files);
    } catch (error, stack) {
      _logger.e("Failed to send files to peer: $error, stackTrace: $stack");
      rethrow;
    }
  }

  void setConnecting() {
    _logger.d("Setting state to connecting");
    state = AsyncValue.data(
      (state.valueOrNull ?? const IpnState()).copyWith(
        vpnState: VpnState.connecting,
      ),
    );
  }

  bool _initializingTailchat = false;
  Future<void> _initTailchat() async {
    if (_initializingTailchat) return;
    _initializingTailchat = true;
    try {
      _logger.d("Initializing tailchat state");
      // Wait for SharedPreferences to be ready
      final autoStartPref = ref.read(sharedPreferencesProvider);
      if (autoStartPref.isLoading) {
        _logger.d("SharedPreferences not ready, defer tailchat initialization");
        await Future.delayed(const Duration(milliseconds: 100));
        _initializingTailchat = false;
        _initTailchat(); // Retry initialization
        return;
      }

      _logger.d("SharedPreferences ready, checking tailchat state");
      final isRunning = await _ipnService.isTailchatRunning();
      ref.read(tailchatServiceStateProvider.notifier).setState(isRunning);

      final autoStart = ref.read(tailchatAutoStartProvider);
      _logger.d("Tailchat auto start: $autoStart isRunning: $isRunning");
      if (autoStart && !isRunning) {
        await startTailchat();
      }
      _isTailchatInitialized = true;
    } catch (e) {
      _logger.e("Failed to initialize tailchat state: $e");
      // TODO: add a tailchat state to handle the error
    } finally {
      _initializingTailchat = false;
    }
  }

  Future<void> _initAlwaysUseDerp() async {
    if (_initializingAlwaysUseDerp) return;
    _initializingAlwaysUseDerp = true;
    try {
      _logger.d("Initializing alwaysUserDerp state");
      // Wait for SharedPreferences to be ready
      final prefs = ref.read(sharedPreferencesProvider);
      if (prefs.isLoading) {
        _logger.d(
          "SharedPreferences not ready, defer alwaysUserDerp initialization",
        );
        await Future.delayed(const Duration(milliseconds: 100));
        _initializingAlwaysUseDerp = false;
        _initAlwaysUseDerp(); // Retry initialization
        return;
      }

      final alwaysUserDerp = ref.read(alwaysUseDerpProvider);
      _logger.d("Always user DERP: $alwaysUserDerp");
      final isSet = await _ipnService.getAlwaysUseDerp();
      if (alwaysUserDerp && !isSet) {
        await setAlwaysUseDerp(true);
      }
      _isAlwaysUseDerpInitialized = true;
    } catch (e) {
      _logger.e("Failed to initialize alwaysUserDerp state: $e");
      // TODO: add a derp state to handle the error
    } finally {
      _initializingAlwaysUseDerp = false;
    }
  }

  Future<void> _initLocalDiscoveryRelay() async {
    if (_initializingLocalDiscoveryRelay) return;
    _initializingLocalDiscoveryRelay = true;
    try {
      _logger.d("Initializing local discovery relay state");
      final isSet = await _ipnService.getLocalDiscoveryRelay();
      ref.read(localDiscoveryRelayProvider.notifier).setState(isSet);
      _isLocalDiscoveryRelayInitialized = true;
    } catch (e) {
      _logger.e("Failed to initialize local discovery relay state: $e");
    } finally {
      _initializingLocalDiscoveryRelay = false;
    }
  }

  Future<void> _initL2RelayCapture() async {
    if (_initializingL2RelayCapture) return;
    _initializingL2RelayCapture = true;
    try {
      _logger.d("Initializing l2 relay capture state");
      final prefs = ref.read(sharedPreferencesProvider);
      if (prefs.isLoading) {
        _logger.d(
          "SharedPreferences not ready, defer l2 relay capture initialization",
        );
        await Future.delayed(const Duration(milliseconds: 100));
        _initializingL2RelayCapture = false;
        _initL2RelayCapture();
        return;
      }

      final captureEnabled = ref.read(l2RelayCaptureProvider);
      _logger.d("L2 relay capture: $captureEnabled");
      final isSet = await _ipnService.getL2RelayCapture();
      if (captureEnabled && !isSet) {
        await setL2RelayCapture(true);
      }
      _isL2RelayCaptureInitialized = true;
    } catch (e) {
      _logger.e("Failed to initialize l2 relay capture state: $e");
    } finally {
      _initializingL2RelayCapture = false;
    }
  }

  Future<void> _initL2RelayVerboseDebug() async {
    if (_initializingL2RelayVerboseDebug) return;
    _initializingL2RelayVerboseDebug = true;
    try {
      _logger.d("Initializing l2 relay verbose debug state");
      final prefs = ref.read(sharedPreferencesProvider);
      if (prefs.isLoading) {
        _logger.d(
          "SharedPreferences not ready, defer l2 relay verbose debug initialization",
        );
        await Future.delayed(const Duration(milliseconds: 100));
        _initializingL2RelayVerboseDebug = false;
        _initL2RelayVerboseDebug();
        return;
      }

      final verboseDebugEnabled = ref.read(l2RelayVerboseDebugProvider);
      _logger.d("L2 relay verbose debug: ");
      final isSet = await _ipnService.getL2RelayVerboseDebug();
      if (verboseDebugEnabled != isSet) {
        await setL2RelayVerboseDebug(verboseDebugEnabled);
      }
      _isL2RelayVerboseDebugInitialized = true;
    } catch (e) {
      _logger.e("Failed to initialize l2 relay verbose debug state: ");
    } finally {
      _initializingL2RelayVerboseDebug = false;
    }
  }

  Future<bool?> startWebAuth(String url) async {
    _logger.d("Starting web auth with URL: $url");
    try {
      if (Platform.isMacOS) {
        // On macOS, we use the native side to handle web auth
        _logger.d("Launching web auth on macOS");
        await _ipnService.startWebAuth(url, () {
          _logger.d("Web auth started on macOS");
          urlBrowsed = url;
          _logger.d("Set urlBrowsed and browseToURL to $url in callback");
          state = AsyncValue.data(
            (state.valueOrNull ?? const IpnState()).copyWith(
              browseToURL: url,
            ),
          );
        });
        return true;
      }
      _logger.d("Launching to URL $url");
      // iOS: open in the in-app web view (SFSafariViewController) so the app
      // can dismiss it with closeInAppWebView() once login completes — same
      // auto-return the Android custom-tab path already does. Android keeps
      // the platform default (Chrome Custom Tab), which it closes natively via
      // loginComplete().
      final launched = await launchUrl(
        Uri.parse(url),
        mode: Platform.isIOS
            ? LaunchMode.inAppWebView
            : LaunchMode.platformDefault,
      );
      if (!launched) {
        throw Exception("Failed to launch login URL at '$url'");
      }
      urlBrowsed = url;
      _logger.d("Set urlBrowsed and browseToURL to $url");
      state = AsyncValue.data(
        (state.valueOrNull ?? const IpnState()).copyWith(
          browseToURL: url,
        ),
      );
    } on WebAuthCanceledException {
      _logger.d("User canceled web auth");
      urlBrowsed = null;
      _logger.d("Set urlBrowsed null due to cancellation");
      state = AsyncValue.data(
        (state.valueOrNull ?? const IpnState()).copyWith(
          browseToURL: url,
        ),
      );
      // Don't treat user cancellation as an error
    } catch (error, stack) {
      _logger.e("Failed to start web auth: $error, stackTrace: $stack");
      state = AsyncValue.error(error, stack);
    }
    return null;
  }

  Future<http.Response?> signinWithApple(String url) async {
    _logger.d("Signing in with Apple using URL: $url");
    try {
      final resp = await _ipnService.signinWithApple(url);
      urlBrowsed = url;
      _logger.d("Set urlBrowsed and browseToURL to $url");
      state = AsyncValue.data(
        (state.valueOrNull ?? const IpnState()).copyWith(
          browseToURL: url,
        ),
      );
      _logger.d("Changed ipn state to include browseToURL for Apple sign-in");
      return resp;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        _logger.d("User canceled Apple sign-in");
        // Don't treat user cancellation as an error
        return null;
      }
      _logger.e("Failed to sign in with Apple: $e");
      state = AsyncValue.error(e, StackTrace.current);
    } catch (error, stack) {
      _logger.e("Failed to sign in with Apple: $error, stackTrace: $stack");
      state = AsyncValue.error(error, stack);
    }
    return null;
  }

  Future<void> confirmDeviceConnection(
      http.Response resp, String sessionID) async {
    _logger.d("Confirming device connection with state: $sessionID");
    try {
      await _ipnService.confirmDeviceConnection(resp, sessionID);
    } catch (error, stack) {
      _logger
          .e("Failed to confirm device connection: $error, stackTrace: $stack");
      state = AsyncValue.error(error, stack);
    }
  }

  Future<IpnPrefs> editPrefs(
    MaskedPrefs prefs, {
    int timeOutMilliseconds = 10000,
  }) async {
    _logger.d("Editing preferences: $prefs");
    try {
      final current = await _ipnService.editPrefs(
        prefs,
        timeOutMilliseconds: timeOutMilliseconds,
      );
      state = AsyncValue.data(
        (state.valueOrNull ?? const IpnState()).copyWith(prefs: current),
      );
      return current;
    } catch (error, stack) {
      _logger.e("Failed to edit preferences: $error, stackTrace: $stack");
      state = AsyncValue.error(error, stack);
      throw Exception("Failed to edit preferences: $error");
    }
  }

  Future<List<AwaitingFile>?> getWaitingFiles({
    int timeoutMilliseconds = 5000,
    bool ignoreErrors = false,
    bool throwOnError = false,
  }) async {
    try {
      return await _ipnService.getWaitingFiles(
        timeoutMilliseconds: timeoutMilliseconds,
      );
    } catch (error, stack) {
      if (ignoreErrors) {
        return null;
      }
      if (throwOnError) {
        rethrow;
      }
      _logger.e("Failed to get awaiting files: $error, stackTrace: $stack");
      state = AsyncData(
        state.valueOrNull?.copyWith(
              errMessage: "Failed to get awaiting files: $error",
            ) ??
            IpnState(errMessage: "Failed to get awaiting files: $error"),
      );
      return null;
    }
  }

  Future<void> saveFile(String file, String path) async {
    await _ipnService.saveFile(file, path);
  }

  Future<String> getFilePath(String file) async {
    return await _ipnService.getFilePath(file);
  }

  Future<void> deleteFile(String file) async {
    try {
      await _ipnService.deleteFile(file);
      state = AsyncValue.data(
        (state.valueOrNull ?? const IpnState()).copyWith(
          filesWaiting: state.valueOrNull?.filesWaiting
              ?.where((f) => f.name != file)
              .toList(),
        ),
      );
    } catch (e) {
      _logger.e("Failed to delete file: $file, error: $e");
      rethrow;
    }
  }

  Future<void> setRunAsExitNode(bool isOn) async {
    _logger.d("Setting run as exit node: $isOn");
    final on = isOn ? "on" : "off";
    try {
      final prefs =
          await _ipnService.setRunningExitNode(state.valueOrNull?.prefs, isOn);
      _logger.d(
        "Run as exit node set to $on. New prefs: $prefs",
        sendToIpn: false,
      );
      state = AsyncValue.data(
        (state.valueOrNull ?? const IpnState()).copyWith(prefs: prefs),
      );
    } catch (error, stack) {
      final msg = "Failed to set run as exit node $on: $error";
      _logger.e(msg);
      state = AsyncValue.error(error, stack);
      throw Exception(msg);
    }
  }

  Future<void> toggleCorpDNS() async {
    _logger.d("Toggling Cylonix DNS");
    try {
      final prefs = await _ipnService.editPrefs(
        MaskedPrefs(
          corpDNS: !(state.valueOrNull?.prefs?.corpDNS ?? false),
          corpDNSSet: true,
        ),
      );
      _logger.d(
        "Cylonix DNS toggled. New prefs: $prefs",
        sendToIpn: false,
      );
      state = AsyncValue.data(
        (state.valueOrNull ?? const IpnState()).copyWith(prefs: prefs),
      );
    } catch (error, stack) {
      final msg = "Failed to toggle Cylonix DNS: $error";
      _logger.e(msg);
      state = AsyncValue.error(error, stack);
      throw Exception(msg);
    }
  }

  Future<void> excludeAppFromVPN(String packageName, bool isOn) async {
    await _ipnService.excludeAppFromVPN(packageName, isOn);
  }

  Future<bool> getAutoStartEnabled() async {
    return await _ipnService.getAutoStartEnabled();
  }

  Future<void> setAutoStartEnabled(bool isOn) async {
    await _ipnService.setAutoStartEnabled(isOn);
  }
}
