import 'dart:collection';
import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/ipn.dart';
import '../services/ipn.dart';
import '../services/mdm.dart';
import '../utils/logger.dart';
import '../utils/utils.dart';
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
  bool _isTailchatInitialized = false;
  bool _isAlwaysUseDerpInitialized = false;
  String? urlBrowsed;

  var peerCategorizer = PeerCategorizer();
  static final _logger = Logger(tag: "IpnStateNotifier");

  IpnStateNotifier(this._ipnService, this._mdmSettings, this.ref)
      : super(const AsyncValue.loading()) {
    _logger.d("IpnStateNotifier initialized to loading state");
    if (isApple()) {
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
      _logger.d("Not an Apple platform, initializing engine");
      _initialize();
    }
  }

  MDMSettingsService get mdmSettings => _mdmSettings;

  Future<void> _initialize() async {
    if (!mounted) return;
    _logger.d("Initializing IpnStateNotifier. Set ipn state to connecting");
    state = const AsyncValue.data(IpnState(vpnState: VpnState.connecting));

    try {
      _notificationSubscription?.cancel();
      _notificationSubscription =
          _ipnService.notificationStream.listen((notification) {
        _notificationQueue.add(notification);
        _processNextNotification();
      });
      await _ipnService.initializeEngine();

      if (!mounted) return;
    } catch (error, stack) {
      _logger.e("Failed to initialize engine: $error, stackTrace: $stack");
      if (!mounted) return;
      state = AsyncValue.error(error, stack);
    }
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
    _logger.d(
      "Received notification state=${notification.state} "
      "url=${notification.browseToURL}",
    );
    List<LoginProfile>? loginProfiles;
    var currentProfile = state.valueOrNull?.currentProfile;
    if (notification.netMap != null) {
      peerCategorizer.regenerateGroupedPeers(notification.netMap!);
      _logger.d("me=${peerCategorizer.me} node=${peerCategorizer.selfNode}");
      currentProfile = await getCurrentProfile();
    }
    final currentState = state.valueOrNull;
    var backendState = currentState?.backendState ?? BackendState.noState;
    var netmap = notification.netMap ?? currentState?.netmap;
    var loggedInUser = peerCategorizer.me ?? currentState?.loggedInUser;

    final ns = notification.state;
    if (ns != null) {
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
        }
      }
      if (ns > BackendState.needsLogin.value) {
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
    final vpnState = _determineVpnState(notification);
    if (state.valueOrNull?.vpnState != vpnState) {
      _logger.d("\n\n******** VPN state -> $vpnState **********\n\n");
    }

    print("browseToURL=${notification.browseToURL} "
        "currentState.browseToURL=${currentState?.browseToURL}");
    // Determine browseToURL
    var browseToURL = notification.browseToURL ?? currentState?.browseToURL;
    if (backendState.value > BackendState.needsLogin.index) {
      browseToURL = null;
    }

    var health = notification.health;
    if (isMobile() || Platform.isMacOS) {
      final warnings = health?.warnings;
      if (warnings != null) {
        final filteredWarnings = Map<String, UnhealthyState?>.from(warnings);
        filteredWarnings.removeWhere(
            (key, warning) => warning?.warnableCode == "update-available");
        health = HealthState(warnings: filteredWarnings);
      }
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
          outgoingFiles:
              notification.outgoingFiles ?? currentState.outgoingFiles,
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
          loginProfiles: loginProfiles ?? [],
          outgoingFiles: notification.outgoingFiles,
        );

    if (newState.loggedInUser != null) {
      //_logger.d(
      //  "\n\n\n********* loginUser -> ${newState.loggedInUser} *********\n\n\n",
      //);
    }

    state = AsyncValue.data(newState);
  }

  VpnState _determineVpnState(IpnNotification notification) {
    final backendState = BackendState.fromInt(notification.state ?? -1);
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
    state = const AsyncValue.data(IpnState());
    _logger.d("Resetting and re-initialize IpnStateNotifier");
    await start();
  }

  Future<void> start() async {
    _isTailchatInitialized = false;
    _isAlwaysUseDerpInitialized = false;
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

  Future<void> setControlURL(String url) async {
    state = AsyncValue.data(
      state.valueOrNull?.copyWith(browseToURL: null) ?? const IpnState(),
    );
    await _ipnService.setControlURL(url);
  }

  Future<void> login({String? authKey, String? controlURL}) async {
    _logger.d(
      "\n\n***Logging in with authKey: $authKey, controlURL: $controlURL. "
      "Set ipn state to connecting***\n\n",
    );
    state = AsyncValue.data(
      (state.valueOrNull ?? const IpnState()).copyWith(
        vpnState: VpnState.connecting,
      ),
    );
    try {
      await _ipnService.login(authKey: authKey, controlURL: controlURL);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> logout() async {
    await _ipnService.logout();
  }

  void clearBrowseToURL() {
    _logger.d("Clearing browseToURL");
    state = AsyncValue.data(
      (state.valueOrNull ?? const IpnState()).copyWith(browseToURL: null),
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

  Future<LoginProfile?> getCurrentProfile() async {
    try {
      return await _ipnService.currentProfile();
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      return null;
    }
  }

  Future<void> addProfile(String? controlURL) async {
    try {
      _logger.d(
        "Adding profile with controlURL: $controlURL. "
        "Set ipn state to connecting",
      );
      state = AsyncValue.data(
        const IpnState().copyWith(
          vpnState: VpnState.connecting,
        ),
      );
      await _ipnService.addProfile();
      await _ipnService.login(controlURL: controlURL);
      await _ipnService.startVpn();
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> switchProfile(String id) async {
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

  Future<void> startWebAuth(String url) async {
    _logger.d("Starting web auth with URL: $url");
    try {
      if (Platform.isMacOS) {
        // On macOS, we use the native side to handle web auth
        _logger.d("Launching web auth on macOS");
        await _ipnService.startWebAuth(url);
        urlBrowsed = url;
        return;
      }
      _logger.d("Launching to URL $url");
      final launched = await launchUrl(
        Uri.parse(url),
      );
      if (!launched) {
        throw Exception("Failed to launch login URL at '$url'");
      }
      urlBrowsed = url;
    } catch (error, stack) {
      _logger.e("Failed to start web auth: $error, stackTrace: $stack");
      state = AsyncValue.error(error, stack);
    }
  }

  Future<http.Response?> signinWithApple(String url) async {
    _logger.d("Signing in with Apple using URL: $url");
    try {
      final resp = await _ipnService.signinWithApple(url);
      urlBrowsed = url;
      return resp;
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
}
