// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/backend_notify_event.dart';
import '../models/exception.dart';
import '../models/ipn.dart';
import '../models/log_file.dart';
import '../models/peer_messaging.dart';
import '../utils/logger.dart';
import '../utils/utils.dart';
import 'named_pipe_socket.dart';

class IpnService {
  static const _capRelayL2Discovery = 'can-relay-l2-discovery';
  static const _capInjectL2Discovery = 'can-inject-l2-discovery';
  static bool _initialized = false;
  static const _channel = MethodChannel('io.cylonix.sase/wg');
  static final _logger = Logger(tag: "IpnService");
  static final eventBus = EventBus();
  static final _commandCompleters =
      <String, Completer>{}; // key is command uuid
  static final _notificationController =
      StreamController<IpnNotification>.broadcast();
  static final _peerMessagingController =
      StreamController<PeerMessagingEvent>.broadcast();
  static final _pendingPeerMessagingEvents = <PeerMessagingEvent>[];

  StreamSubscription<BackendNotifyEvent>? _startEngineBackendNotifySub;
  static Timer? _tunnelInactiveDebounceTimer;
  static const _tunnelInactiveDebounce = Duration(milliseconds: 1000);
  static const _peerMessagingTransportErrorGrace = Duration(seconds: 30);
  static String? _lastReceivedTunnelStatus;
  static DateTime? _lastPeerMessagingTransportErrorAt;
  static const _localBaseURL = "http://local-tailscaled.sock/localapi/v0";
  static const _localApiHost = "local-tailscaled.sock";
  static const _localApiPrefix = "/localapi/v0";
  static HttpClient? _notificationClient;
  static HttpClient? _logClient;

  IpnService() {
    _init();
  }

  void dispose() {
    _notificationController.close();
  }

  void _init() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    eventBus.on<BackendNotifyEvent>().listen((onData) {
      //_logger.d("Received notification");
      final n = onData.notification;
      _notificationController.add(n);
    });

    _initMethodChannel();
    eventBus.on<TunnelStatusEvent>().listen((onData) {
      _logger.d("Received tunnel status ${onData.status}");
      // If tunnel status changed to inactive we may not receive a notification
      // from the backend as it is being disposed for network extension, we need
      // to send it manually. Debounce transient inactive blips caused by
      // fresh-loaded NETunnelProviderManager status reads (see Fix 2 in
      // TunnelsManager.swift) before synthesizing the backend-down event.
      if (onData.status == TunnelStatus.inactive) {
        _tunnelInactiveDebounceTimer?.cancel();
        _tunnelInactiveDebounceTimer = Timer(_tunnelInactiveDebounce, () async {
          _tunnelInactiveDebounceTimer = null;
          if (Platform.isIOS && _recentPeerMessagingTransportError()) {
            try {
              final status = await this.status(light: true, fast: true);
              final backendState = BackendState.fromString(status.backendState);
              if (backendState == BackendState.running) {
                _logger.w(
                  "Ignoring transient tunnel inactive after peer messaging "
                  "transport error; backend still reports running",
                );
                return;
              }
            } catch (e) {
              _logger.w(
                "Ignoring tunnel inactive after recent peer messaging "
                "transport error; backend status check failed: $e",
              );
              return;
            }
          }
          _logger.d(
            "Tunnel status stayed inactive (caller=local-tunnel-inactive)",
          );
          final n = IpnNotification(
            state: BackendState.noState.value,
          );
          _logger.d("Sending notification: $n");
          _notificationController.add(n);
        });
      } else {
        _tunnelInactiveDebounceTimer?.cancel();
        _tunnelInactiveDebounceTimer = null;
      }
    });
  }

  static bool _recentPeerMessagingTransportError() {
    final at = _lastPeerMessagingTransportErrorAt;
    if (at == null) {
      return false;
    }
    return DateTime.now().difference(at) < _peerMessagingTransportErrorGrace;
  }

  Stream<IpnNotification> get notificationStream =>
      _notificationController.stream;

  Stream<PeerMessagingEvent> get peerMessagingEventStream =>
      _peerMessagingController.stream;

  List<PeerMessagingEvent> takePendingPeerMessagingEvents() {
    if (_pendingPeerMessagingEvents.isEmpty) {
      return const [];
    }
    final pending = List<PeerMessagingEvent>.from(_pendingPeerMessagingEvents);
    _pendingPeerMessagingEvents.clear();
    return pending;
  }

  Future<void> initializeEngine(
    Function(Object error, StackTrace stack) onError,
  ) async {
    try {
      await startEngine(onError);
    } catch (e) {
      _logger.e('Failed to initialize VPN engine: $e');
      rethrow;
    }
  }

  void _initMethodChannel() {
    _channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case "logs":
          try {
            final id = call.arguments['id'] as String;
            final logs = (call.arguments['logs'] as List<Object?>)
                .map((e) => e as String)
                .toList();
            _logger.d("Received logs: $id: size ${logs.length}");
            final c = _commandCompleters[id];
            if (c != null) {
              c.complete(logs);
              _commandCompleters.remove(id);
            } else {
              _logger.d("Received logs but no completer");
            }
          } catch (e) {
            _logger.e("Failed to handle logs: $e");
          }
          break;
        case "commandResult":
          //_logger.d(
          //  "Received command result: ${call.arguments}".shortString(200),
          //);
          String? cmd;
          try {
            final arguments = call.arguments;
            if (arguments is! Map) {
              _logger.e("Invalid arguments: ${call.arguments.runtimeType}");
              return;
            }
            cmd = arguments["cmd"] as String?;
            final id = arguments["id"] as String?;
            final result = arguments["result"] as String?;
            if (cmd == null || result == null || id == null) {
              _logger.e("Missing command or result: $arguments");
              return;
            }
            final c = _commandCompleters[id];
            if (c != null) {
              c.complete(result);
              _commandCompleters.remove(id);
            } else {
              _logger.d("Received command $cmd result but no completer");
            }
          } catch (e) {
            _logger.e("Failed to handle command '$cmd' result: $e");
          }
          break;
        case 'handleAppLink':
          try {
            final json = call.arguments;
            _logger.d("Received app link: $json. Just close webview for now.");
            closeInAppWebView();
          } catch (e) {
            _logger.e("Failed to handle app link: $e");
          }
          break;
        case "notification":
          try {
            final args = call.arguments;
            String s;
            String caller = "unknown";
            int? enqueuedAtUs;
            String? id;
            if (args is String) {
              s = args;
            } else if (args is Map) {
              s = args["notification"] as String;
              caller = (args["caller"] as String?) ?? "unknown";
              final ts = args["enqueuedAtUs"];
              if (ts is int) {
                enqueuedAtUs = ts;
              } else if (ts is double) {
                enqueuedAtUs = ts.toInt();
              }
              id = args["id"] as String?;
            } else {
              _logger.e(
                "Invalid notification arguments: ${args.runtimeType}",
              );
              break;
            }
            final json = jsonDecode(s);
            final v = IpnNotification.fromJson(json);
            if (v.state != null) {
              if (enqueuedAtUs != null) {
                final nowUs = DateTime.now().microsecondsSinceEpoch;
                final ageUs = nowUs - enqueuedAtUs;
                if (ageUs > 1000000) {
                  _logger.w(
                    "Stale notification state=${v.state} caller=$caller id=$id ageUs=$ageUs",
                  );
                } else {
                  _logger.d(
                    "Notification state=${v.state} caller=$caller id=$id ageUs=$ageUs",
                  );
                }
              } else {
                _logger.d(
                  "Notification state=${v.state} caller=$caller",
                );
              }
            }
            eventBus.fire(BackendNotifyEvent(v));
          } catch (e, trace) {
            _logger.e("Failed to handle notification: $e: $trace");
          }
          break;
        case "peerMessageEvent":
          try {
            final s = call.arguments as String;
            final event = PeerMessagingEvent.fromEncodedJson(s);
            _pendingPeerMessagingEvents.add(event);
            _peerMessagingController.add(event);
            eventBus.fire(PeerMessagingBridgeEvent(event));
          } catch (e, trace) {
            _logger.e("Failed to handle peer messaging event: $e: $trace");
          }
          break;
        case "tunnelStatus":
          try {
            _logger.d("Received tunnel status: ${call.arguments}");
            final status = call.arguments['status'] as String?;
            final error = call.arguments['error'] as String?;
            if (status == null) {
              throw Exception("missing tunnel status value");
            }
            // Dedupe based on what this app has actually received: the native
            // side may emit the same status repeatedly (e.g. refreshStatus
            // fired by multiple observers), but the app only needs to see a
            // transition. Errors always pass through so they are not lost.
            if (error == null && _lastReceivedTunnelStatus == status) {
              _logger.d("Skipping duplicate tunnel status: $status");
              break;
            }
            _lastReceivedTunnelStatus = status;
            _logger.d("Broadcasting tunnel status event");
            eventBus.fire(
              TunnelStatusEvent(TunnelStatus(status), error: error),
            );
          } catch (e) {
            _logger.e("Failed to handle tunnelStatus: $e");
          }
          break;
        case "tunnelCreated":
          _logger.d("tunnel created result: ${call.arguments}");
          try {
            final id = call.arguments['id'] as String;
            if (id.isEmpty) {
              _logger.d("missing tunnel creation result id, skipping");
              return;
            }
            _commandCompleters[id]
                ?.complete(call.arguments['isCreated'] as bool);
            _commandCompleters.remove(id);
          } catch (e) {
            _logger.e("Invalid tunnel creation result: $e");
          }
          break;
        case "vpnPermissionResult":
          _logger.d("VPN permission result: ${call.arguments}");
          try {
            final isGranted = call.arguments['granted'] as bool?;
            if (isGranted == null) {
              _logger.e("Missing isGranted in VPN permission result");
              return;
            }
            eventBus.fire(
              VpnPermissionEvent(isGranted: isGranted),
            );
          } catch (e) {
            _logger.e("Invalid VPN permission result: $e");
          }
          break;
        case "webAuthDone":
          _logger.d("Web auth done: ${call.arguments}");
          _commandCompleters['web_auth']?.complete(call.arguments);
          _commandCompleters.remove('web_auth');
          break;
        default:
          _logger.d("unknown method call: ${call.method}");
          break;
      }
    });
  }

  void loginComplete() {
    _channel.invokeMethod("loginComplete");
  }

  static void returnToPreviousApp() {
    _channel.invokeMethod("returnToPreviousApp");
  }

  Future<void> sendPeerFiles(String peerID, List<OutgoingFile> files) async {
    Timer? currentTimer;
    final c = Completer();
    late final StreamSubscription<BackendNotifyEvent> sub;

    // Use a longer initial timeout (60s) since the backend may take time
    // to establish a connection to the peer before progress events start.
    // Once progress events arrive, use a shorter 30s inactivity timeout.
    var timeoutDuration = const Duration(seconds: 60);
    void setTimeout() {
      currentTimer = Timer(timeoutDuration, () {
        if (!c.isCompleted) {
          c.completeError(
            TimeoutException(
              "Transfer to peer timed out",
              timeoutDuration,
            ),
          );
        }
        _logger.e(
          "Transfer to peer $peerID timed out",
          sendToIpn: !_useHttpLocalApi,
        );
      });
    }

    Timer? pollingTimer;
    try {
      sub = eventBus.on<BackendNotifyEvent>().listen((event) {
        final outgoingFiles = event.notification.outgoingFiles ?? [];
        // Only reset timeout if we see progress for our files
        if (outgoingFiles.any((f) => f.peerID == peerID)) {
          // Switch to shorter inactivity timeout after first progress
          timeoutDuration = const Duration(seconds: 30);
          currentTimer?.cancel();
          setTimeout();
        }
      });

      // Namedpipe socket is still not reliable. Let's also do polling
      // for outgoing files.
      if (Platform.isWindows && !useWindowsTcpClient) {
        pollingTimer =
            Timer.periodic(const Duration(seconds: 1), (timer) async {
          try {
            final result = await _sendCommandOverHttp(
              Uri(
                scheme: 'http',
                host: _localApiHost,
                path: '$_localApiPrefix/files/',
                queryParameters: {
                  'outgoing': "true",
                },
              ),
              'GET',
            );
            final list = jsonDecode(result) as List<dynamic>?;
            final outgoingFiles = <OutgoingFile>[];
            for (final item in list ?? []) {
              final file = OutgoingFile.fromJson(item);
              if (file.peerID == peerID) {
                outgoingFiles.add(file);
              }
            }
            if (outgoingFiles.isNotEmpty) {
              _logger.d(
                "Polling found ${outgoingFiles.length} outgoing files for peer $peerID",
                sendToIpn: !_useHttpLocalApi,
              );
              eventBus.fire(
                BackendNotifyEvent(
                  IpnNotification(outgoingFiles: outgoingFiles),
                ),
              );
            }
          } catch (e) {
            _logger.e("Failed to get outgoing files: $e");
          }
        });
      }

      final result = _useHttpLocalApi
          ? await _sendPeerFilesOverHttp(
              peerID,
              files,
            )
          : await _sendCommand(
              'send_files_to_peer',
              jsonEncode({
                'peer_id': peerID,
                'files': files,
              }),
              onSetTimeout: setTimeout,
            );

      _logger.d(
        "Send files to peer $peerID: $result",
        sendToIpn: !_useHttpLocalApi,
      );
      if (!result.startsWith("Success")) {
        throw Exception("Failed to send file to peer: result='$result'");
      }
    } finally {
      sub.cancel();
      currentTimer?.cancel();
      pollingTimer?.cancel();
    }
  }

  Future<void> createTunnelsManager(String id) async {
    if (!isApple()) {
      return;
    }
    final result = await _channel.invokeMethod('create_tunnels_manager', id);
    _logger.d("create tunnels manager: $result");
    if (result != "Success") {
      throw Exception(result);
    }
  }

  Future<void> logout() async {
    if (_useHttpLocalApi) {
      await _sendCommandOverHttp(Uri.parse('$_localBaseURL/logout'), 'POST');
      return;
    }
    final result = await _sendCommand("logout", "");
    if (result != 'Success') {
      throw Exception(result);
    }
  }

  Future<String> getDebugStateTraces() async {
    if (_useHttpLocalApi) {
      return await _sendCommandOverHttp(
        Uri.parse('$_localBaseURL/debug-state-traces'),
        'GET',
      );
    }
    return await _sendCommand('debug_state_traces', '');
  }

  Future<List<String>> _getDebugStateTraceLines() async {
    try {
      final raw = await getDebugStateTraces();
      if (raw.trim().isEmpty) return const [];
      const header = '===== IPN state-send trace ring buffer =====';
      return [header, ...raw.split('\n')];
    } catch (e) {
      _logger.w("failed to get IPN state-send traces: $e");
      return ['===== IPN state-send trace fetch failed: $e ====='];
    }
  }

  Future<List<String>> getLogs() async {
    List<String> base;
    if (Platform.isWindows) {
      base = await WindowsServiceLogReader.readLatestServiceLog();
    } else if (Platform.isLinux) {
      base = await LinuxServiceLogReader.readLatestServiceLog();
    } else if (isDirectDistribution) {
      base = await MacOSDirectServiceLogReader.readLatestServiceLog();
    } else {
      final completer = Completer<List<String>>();
      final id = const Uuid().v4();
      _commandCompleters[id] = completer;
      final String result = await _channel.invokeMethod(
        'getLogs',
        id,
      );
      if (result != "Success") {
        throw Exception(result);
      }

      const timeout = Duration(seconds: 3);
      try {
        base = await completer.future.timeout(timeout);
      } catch (e) {
        _logger.e("failed to get logs: $e");
        rethrow;
      }
    }
    final traces = await _getDebugStateTraceLines();
    if (traces.isEmpty) return base;
    return [...base, '', ...traces];
  }

  // _sendCommand sends `cmd` with `args` to the native libtailscale bridge
  // and waits for its result. If the native side reports the libtailscale
  // App global is not yet initialized (returned as the literal string
  // "App not initialized"), this retries with exponential backoff: that
  // race happens between flutter engine startup and libtailscale init in
  // App.kt / WireGuardAdapter.swift, and is short-lived in practice.
  Future<String> _sendCommand(
    String cmd,
    String args, {
    int timeoutMilliseconds = 10000,
    Completer? completer,
    void Function()? onSetTimeout,
  }) async {
    const maxAttempts = 10;
    var delayMs = 50;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await _sendCommandOnce(
          cmd,
          args,
          timeoutMilliseconds: timeoutMilliseconds,
          completer: completer,
          onSetTimeout: onSetTimeout,
        );
      } on _AppNotInitializedException {
        if (attempt == maxAttempts) {
          _logger.e(
              "command '$cmd': App still not initialized after $maxAttempts retries");
          rethrow;
        }
        _logger.d(
            "command '$cmd': App not initialized yet, retry $attempt/$maxAttempts in ${delayMs}ms");
        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs = (delayMs * 2).clamp(50, 500);
      }
    }
    throw StateError("unreachable");
  }

  Future<String> _sendCommandOnce(
    String cmd,
    String args, {
    int timeoutMilliseconds = 10000,
    Completer? completer,
    void Function()? onSetTimeout,
  }) async {
    final c = completer ?? Completer();
    final id = const Uuid().v4();
    _commandCompleters[id] = c;
    Timer? timeoutTimer;

    // Create timeout function that can be called by the caller
    void setTimeoutTimer() {
      if (onSetTimeout != null) {
        onSetTimeout();
        return;
      }
      timeoutTimer?.cancel();
      timeoutTimer = Timer(Duration(milliseconds: timeoutMilliseconds), () {
        if (!c.isCompleted) {
          _logger.e(
              "\n\n*******Timeout waiting for command '$cmd' result****\n\n");
          c.completeError(TimeoutException(
            "Timeout waiting for command '$cmd' result",
            Duration(milliseconds: timeoutMilliseconds),
          ));
          _commandCompleters.remove(id);
        }
      });
    }

    try {
      final result = await _channel.invokeMethod(
        "sendCommand",
        <String, String>{"cmd": cmd, 'id': id, "args": args},
      );
      if (result is! String || result != 'Success') {
        throw Exception("Send command '$cmd' failed: $result");
      }
      // Start initial timeout
      setTimeoutTimer();

      final response = await c.future;
      if (response is! String) {
        throw Exception("Invalid result: $response");
      }
      if (response == "App not initialized") {
        // Race between flutter engine startup and libtailscale init.
        // _sendCommand will catch this and retry.
        throw _AppNotInitializedException();
      }
      return response;
    } catch (e) {
      if (e is! _AppNotInitializedException) {
        _logger.e("failed to wait for command '$cmd' result: $e");
      }
      rethrow;
    } finally {
      timeoutTimer?.cancel();
    }
  }

  Future<bool> checkVPNPermission() async {
    try {
      if (Platform.isLinux || Platform.isWindows) {
        // On Linux and Windows, we don't need to check VPN permission.
        return true;
      }
      if (Platform.isAndroid) {
        for (var i = 0; i < 3; i++) {
          _logger.d("Checking VPN permission (attempt ${i + 1})");
          final result = await _channel.invokeMethod("checkVPNPermission");
          if (result is bool) {
            if (result) {
              return true;
            }
          } else {
            throw Exception(
              "checkVPNPermission returned unexpected result: $result",
            );
          }
          await Future.delayed(const Duration(seconds: 1));
        }
        return false;
      }
      final completer = Completer<bool>();
      final id = const Uuid().v4();
      _commandCompleters[id] = completer;
      final result = await _channel.invokeMethod(
        "checkVPNPermission",
        id,
      );
      if (result != "Success") {
        throw Exception("command invocation error: $result");
      }
      final created = await completer.future.timeout(
        // IOS may take a while to load the tunnel config after app launch.
        const Duration(seconds: 25),
      );
      return created;
    } catch (e) {
      throw Exception("Check VPN permission failed: $e");
    }
  }

  Future<bool> requestVPNPermission() async {
    try {
      final id = const Uuid().v4();
      if (isApple()) {
        final completer = Completer<bool>();
        _commandCompleters[id] = completer;
        await createTunnelsManager(id);
        final granted = await completer.future.timeout(
          const Duration(seconds: 120),
        );
        return granted;
      } else if (Platform.isAndroid) {
        await _channel.invokeMethod("requestVPNPermission", id);
        return await checkVPNPermission();
      } else {
        throw Exception(
          "VPN permission request is not supported on this platform",
        );
      }
    } catch (e) {
      throw Exception("request VPN permission failed: $e");
    }
  }

  Future<bool> requestLocalNetworkPermission() async {
    if (!isApple()) {
      return true;
    }
    try {
      final result =
          await _channel.invokeMethod("requestLocalNetworkPermission");
      if (result is bool) {
        return result;
      }
      if (result is String) {
        return parseBool(result);
      }
      _logger.e(
        "requestLocalNetworkPermission returned unexpected result: $result",
      );
      return false;
    } catch (e) {
      _logger.e("requestLocalNetworkPermission failed: $e");
      return false;
    }
  }

  Future<void> _loginInteractive() async {
    if (_useHttpLocalApi) {
      await _sendCommandOverHttp(
        Uri.parse('$_localBaseURL/login-interactive'),
        'POST',
      );
      return;
    }
    final result = await _sendCommand('start_login_interactive', '');
    if (result != 'Success') {
      throw Exception('Login interactive failed: $result');
    }
  }

  Future<IpnPrefs> editPrefs(
    MaskedPrefs edits, {
    int timeOutMilliseconds = 10000,
  }) async {
    final result = _useHttpLocalApi
        ? await _sendCommandOverHttp(
            Uri.parse('$_localBaseURL/prefs'),
            'PATCH',
            body: edits,
            timeoutMilliseconds: timeOutMilliseconds,
          )
        : await _sendCommand(
            'edit_prefs',
            jsonEncode(edits),
            timeoutMilliseconds: timeOutMilliseconds,
          );
    if (result.startsWith("Error")) {
      throw Exception("Failed to edit prefs: $result");
    }
    try {
      final json = jsonDecode(result) as Map<String, dynamic>;
      final prefs = IpnPrefs.fromJson(json);
      _logger.d("Edited prefs: $prefs", sendToIpn: false);
      return prefs;
    } catch (e) {
      _logger.e("Failed to parse returned prefs: $result: $e");
      throw Exception("Failed to parse edited prefs: $result: $e");
    }
  }

  Future<void> _turnOffVPN() async {
    if (_useHttpLocalApi) {
      // For direct/daemon mode, set WantRunning=false via prefs
      await _sendCommandOverHttp(
        Uri.parse('$_localBaseURL/prefs'),
        'PATCH',
        body: {'WantRunningSet': true, 'WantRunning': false},
      );
      return;
    }
    final result = await _sendCommand('turn_off_vpn', '');
    if (result != 'Success') {
      throw Exception('Turn off VPN failed: $result');
    }
  }

  Future<void> _start(IpnOptions options) async {
    _logger.d("Starting backend with options: $options");
    if (_useHttpLocalApi) {
      await _sendCommandOverHttp(
        Uri.parse('$_localBaseURL/start'),
        'POST',
        body: options,
      );
      return;
    }
    final result = await _sendCommand('start', jsonEncode(options));
    if (result != 'Success') {
      throw Exception('Start failed: $result');
    }
  }

  Future<void> start() async {
    await _start(const IpnOptions());
  }

  Future<HttpClient> watchNotificationsOverHttp(
    Function(Object error, StackTrace stack) onError,
  ) async {
    void restart() async {
      try {
        await watchNotifications(onError);
      } catch (e, stack) {
        _logger.e('Failed to restart notification watch: $e');
        onError(e, stack);
      }
    }

    final client = _httpClient;
    try {
      _logger.d("Watching notifications over HTTP", sendToIpn: false);

      final mask = NotifyWatchOpt.combine([
        NotifyWatchOpt.noPrivateKeys,
        NotifyWatchOpt.initialPrefs,
        NotifyWatchOpt.initialState,
        NotifyWatchOpt.initialNetMap,
        NotifyWatchOpt.initialHealthState,
      ]);

      final request = await client.openUrl(
        'GET',
        Uri.parse('$_localBaseURL/watch-ipn-bus?mask=$mask'),
      );

      final response = await request.close();
      if (response.statusCode != 200) {
        client.close();
        throw Exception(
          "Request failed with status code: ${response.statusCode}. ",
        );
      }
      final contentType = response.headers.contentType;
      final charset = contentType?.charset?.toLowerCase() ?? 'utf-8';
      if (charset != 'utf-8') {
        _logger.w(
          "Received notification with charset $charset, "
          "which is not utf-8. This may cause issues.",
        );
        _logger.d("Received content: $response", sendToIpn: false);
        throw Exception(
          "Unsupported charset: $charset. Only utf-8 is supported.",
        );
      }

      response.transform(utf8.decoder).transform(const LineSplitter()).listen(
        (data) {
          if (data.isEmpty) return;
          //_logger.d("Notification: ${data.length} bytes", sendToIpn: false);
          try {
            final json = jsonDecode(data);
            final notification = IpnNotification.fromJson(json);
            if (notification.outgoingFiles != null) {
              for (final f in notification.outgoingFiles!) {
                _logger.d(
                  "Received outgoing file: ${f.id} (${f.sent} bytes)",
                  sendToIpn: false,
                );
              }
            }
            if (notification.state != null) {
              _logger.d(
                "Notification: backend state = ${notification.state}",
                sendToIpn: false,
              );
            }
            // Handle peer message events from watch-ipn-bus (daemon mode)
            if (notification.peerMessageEvent != null) {
              try {
                final event = PeerMessagingEvent.fromJson(
                  notification.peerMessageEvent!,
                );
                _pendingPeerMessagingEvents.add(event);
                _peerMessagingController.add(event);
                eventBus.fire(PeerMessagingBridgeEvent(event));
              } catch (e) {
                _logger.e(
                  'Failed to parse peer message event from notification: $e',
                );
              }
            }
            eventBus.fire(BackendNotifyEvent(notification));
          } catch (e) {
            _logger.e('Failed to parse notification: $e');
          }
        },
        onError: (e, stack) {
          _logger.e('Error in notification stream: $e\n$stack');
          onError(e, stack);
          restart();
        },
        onDone: () {
          _logger.d("Notification stream done. Restarting watch.");
          restart();
        },
      );

      _logger.d("Notification watch initiated", sendToIpn: false);
      return client;
    } catch (e) {
      client.close();
      rethrow;
    }
  }

  Future<void> watchNotifications(
    Function(Object error, StackTrace stack) onError,
  ) async {
    if (_useHttpLocalApi) {
      // Close any existing client
      _notificationClient?.close();
      _notificationClient = await watchNotificationsOverHttp(onError);
      return;
    }
    final result = await _sendCommand(
      'watch_notifications',
      '',
      timeoutMilliseconds: 1000,
    );
    if (result != 'Success') {
      throw Exception('Watch notifications failed: $result');
    }
    _logger.i("Watching notifications started successfully.");
  }

  Future<String> _getMdmControlURL() async {
    // Not yet implemented.
    return "";
  }

  Future<void> startVpn() async {
    await editPrefs(const MaskedPrefs(
      wantRunning: true,
      wantRunningSet: true,
    ));
  }

  Future<void> stopVpn() async {
    await editPrefs(const MaskedPrefs(
      wantRunning: false,
      wantRunningSet: true,
    ));
    if (isApple() && !isDirectDistribution) await _turnOffVPN();
  }

  Future<void> stopPing() async {
    return;
  }

  Future<List<LoginProfile>?> getProfiles() async {
    final result = await (_useHttpLocalApi
        ? _sendCommandOverHttp(Uri.parse('$_localBaseURL/profiles/'), 'GET')
        : _sendCommand('profiles', ''));
    if (result.startsWith("Error")) {
      throw Exception("Failed to get profiles: $result");
    }
    final list = jsonDecode(result) as List<dynamic>?;
    return list?.map((e) => LoginProfile.fromJson(e)).toList();
  }

  Future<PingResult> ping(Node peer) async {
    final addr = peer.primaryIPv4Address ?? "";
    if (addr.isEmpty) {
      throw Exception("Peer has no address");
    }
    final pingType = (peer.isWireGuardOnly ?? false) ? 'ICMP' : 'disco';
    final result = await (_useHttpLocalApi
        ? _sendCommandOverHttp(
            Uri(
              scheme: 'http',
              host: _localApiHost,
              path: '$_localApiPrefix/ping',
              queryParameters: {
                'ip': addr,
                'type': pingType,
              },
            ),
            'POST',
          )
        : _sendCommand('ping', '$addr $pingType'));
    return PingResult.fromJson(jsonDecode(result));
  }

  Future<Status> status({bool light = false, bool fast = false}) async {
    final timeoutMilliseconds = fast ? 500 : 5000;

    final result = _useHttpLocalApi
        ? await _sendCommandOverHttp(
            light
                ? Uri(
                    scheme: 'http',
                    host: _localApiHost,
                    path: '$_localApiPrefix/status',
                    queryParameters: {'peers': 'false'})
                : Uri.parse('$_localBaseURL/status'),
            'GET',
            timeoutMilliseconds: timeoutMilliseconds,
          )
        : await _sendCommand(
            'status',
            light ? jsonEncode({"peers": false}) : '',
            timeoutMilliseconds: timeoutMilliseconds,
          );
    if (result.startsWith("Error")) {
      throw Exception("Failed to get status: $result");
    }
    return Status.fromJson(jsonDecode(result));
  }

  Future<LoginProfile> currentProfile({bool fast = false}) async {
    final result = _useHttpLocalApi
        ? await _sendCommandOverHttp(
            Uri.parse('$_localBaseURL/profiles/current'),
            'GET',
            timeoutMilliseconds: fast ? 500 : 5000,
          )
        : await _sendCommand(
            'current_profile',
            '',
            timeoutMilliseconds: fast ? 500 : 5000,
          );
    if (result.startsWith("Error")) {
      throw Exception("Failed to get current profile: $result");
    }
    return LoginProfile.fromJson(jsonDecode(result));
  }

  Future<void> addProfile() async {
    if (_useHttpLocalApi) {
      await _sendCommandOverHttp(
        Uri.parse('$_localBaseURL/profiles/'),
        'PUT',
      );
      return;
    }
    final result = await _sendCommand('add_profile', '');
    if (result != "Success") {
      throw Exception("Failed to add profile: $result");
    }
  }

  Future<void> deleteProfile(String profileID) async {
    if (_useHttpLocalApi) {
      await _sendCommandOverHttp(
        Uri.parse('$_localBaseURL/profiles/$profileID'),
        'DELETE',
      );
      return;
    }
    final result = await _sendCommand('delete_profile', profileID);
    if (result != "Success") {
      throw Exception("Failed to delete profile: $result");
    }
  }

  Future<void> startTailchat() async {
    final cacheDir = await _channel.invokeMethod('getSharedFolderPath');
    final result = await _sendCommand(
      'start_tailchat',
      jsonEncode({
        'CacheDir': '$cacheDir/tailchat',
      }),
    );
    if (result != "Success") {
      throw Exception("Failed to start tailchat: $result");
    }
  }

  Future<void> stopTailchat() async {
    final result = await _sendCommand('stop_tailchat', '');
    if (result != "Success") {
      throw Exception("Failed to stop tailchat: $result");
    }
  }

  Future<bool> isTailchatRunning() async {
    // Only check on iOS, as Tailchat proxy is not supported on other platforms.
    if (!Platform.isIOS) {
      return false;
    }
    final result = await _sendCommand('is_tailchat_running', '');
    return result == "true";
  }

  Future<void> sendOpenClawMessage(Map<String, dynamic> payload) async {
    final result = await _sendCommand(
      'send_openclaw_message',
      jsonEncode(payload),
    );
    if (result != "Success") {
      throw Exception("Failed to send OpenClaw message: $result");
    }
  }

  Future<PeerMessagingSendResult> sendPeerMessagingMessage(
    Map<String, dynamic> payload,
  ) async {
    if (_useHttpLocalApi) {
      final result = await _sendCommandOverHttp(
        Uri.parse('$_localBaseURL/peer-message/send'),
        'POST',
        body: payload,
      );
      if (result.trimLeft().startsWith('{')) {
        return PeerMessagingSendResult.fromJson(
          Map<String, dynamic>.from(jsonDecode(result) as Map),
        );
      }
      return const PeerMessagingSendResult(
        accepted: true,
        queued: false,
        deliveryStatus: PeerMessagingDeliveryStatus.delivered,
      );
    }
    String result;
    try {
      if (Platform.isIOS) {
        _lastPeerMessagingTransportErrorAt = DateTime.now();
      }
      result = await _sendCommand(
        'send_peer_message',
        jsonEncode(payload),
      );
    } catch (_) {
      if (Platform.isIOS) {
        _lastPeerMessagingTransportErrorAt = DateTime.now();
      }
      rethrow;
    }
    if (Platform.isIOS && result.startsWith("Error sending peerMessage:")) {
      _lastPeerMessagingTransportErrorAt = DateTime.now();
    } else if (Platform.isIOS) {
      _lastPeerMessagingTransportErrorAt = null;
    }
    if (result == "Success") {
      return const PeerMessagingSendResult(
        accepted: true,
        queued: false,
        deliveryStatus: PeerMessagingDeliveryStatus.delivered,
      );
    }
    if (!result.trimLeft().startsWith('{')) {
      throw Exception("Failed to send peer messaging message: $result");
    }
    return PeerMessagingSendResult.fromJson(
      Map<String, dynamic>.from(jsonDecode(result) as Map),
    );
  }

  Future<void> switchProfile(String id) async {
    if (_useHttpLocalApi) {
      await _sendCommandOverHttp(
        Uri.parse('$_localBaseURL/profiles/$id'),
        'POST',
      );
      return;
    }
    final result = await _sendCommand('switch_profile', id);
    if (result != "Success") {
      throw Exception("Failed to switch profile: $result");
    }
  }

  Future<List<AwaitingFile>?> getWaitingFiles({
    int timeoutMilliseconds = 5000,
  }) async {
    final result = _useHttpLocalApi
        ? await _sendCommandOverHttp(
            Uri.parse('$_localBaseURL/files/'),
            'GET',
            timeoutMilliseconds: timeoutMilliseconds,
          )
        : await _sendCommand(
            'get_waiting_files',
            '',
            timeoutMilliseconds: timeoutMilliseconds,
          );
    if (result.startsWith("Error")) {
      throw Exception("Failed to get waiting files: $result");
    }
    _logger.d("Received waiting files: $result");
    final list = jsonDecode(result) as List<dynamic>?;
    return list?.map((e) => AwaitingFile.fromJson(e)).toList();
  }

  Future<void> saveFile(String file, String path) async {
    final result = _useHttpLocalApi
        ? await _saveFileOverHttp(file, path)
        : await _sendCommand('get_file', '$file:$path');
    if (result.startsWith("Error")) {
      throw Exception("Failed to get waiting files: $result");
    }
  }

  Future<String> getFilePath(String baseName) async {
    if (_useHttpLocalApi) {
      throw Exception(
        "GetFilePath is not supported over HTTP API",
      );
    }
    final result = await _sendCommand('get_file_path', baseName);
    if (result.startsWith("Error")) {
      throw Exception("Failed to get file path: $result");
    }
    return result;
  }

  Future<String?> getSharedFolderPath() async {
    if (!isApple()) {
      return null;
    }
    final result = await _channel.invokeMethod<String>('getSharedFolderPath');
    if (result == null || result.isEmpty) {
      return null;
    }
    return result;
  }

  Future<void> setNotificationPreviewEnabled(bool enabled) async {
    if (!isApple()) {
      return;
    }
    final result = await _channel.invokeMethod<String>(
      'setNotificationPreviewEnabled',
      enabled,
    );
    if (result != null && result != 'Success') {
      throw Exception('Failed to set notification preview preference: $result');
    }
  }

  Future<Map<String, String>> consumeAutoSavedFilePaths() async {
    if (!isApple()) {
      return const {};
    }
    final result = await _channel.invokeMethod<dynamic>(
      'consumeAutoSavedFilePaths',
    );
    if (result is! Map) {
      _logger.d('consumeAutoSavedFilePaths returned non-map: $result');
      return const {};
    }
    final mapped = result.map(
      (key, value) => MapEntry(
        key?.toString() ?? '',
        value?.toString() ?? '',
      ),
    )..removeWhere((key, value) => key.isEmpty || value.isEmpty);
    _logger.d(
        'consumeAutoSavedFilePaths returned ${mapped.length} entries: $mapped');
    return mapped;
  }

  Future<void> replayPendingPeerMessageEvents() async {
    if (!isApple()) {
      return;
    }
    final result = await _channel.invokeMethod<String>(
      'replayPendingPeerMessageEvents',
    );
    if (result != null && result != 'Success') {
      throw Exception('Failed to replay pending peer message events: $result');
    }
  }

  Future<void> previewLocalFile(String path) async {
    await _channel.invokeMethod('previewLocalFile', path);
  }

  Future<String> _saveFileOverHttp(String file, String path) async {
    HttpClient? client;
    IOSink? sink;
    try {
      client = _httpClient;
      final uri = Uri(
        scheme: 'http',
        host: _localApiHost,
        path: '$_localApiPrefix/files/${Uri.encodeComponent(file)}',
      );
      final request = await client.openUrl('GET', uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/octet-stream');
      if (Platform.isWindows) {
        request.headers.set(HttpHeaders.connectionHeader, "close");
      }
      final response = await request.close().timeout(
            const Duration(seconds: 30),
          );

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to download file '$file': ${response.statusCode} ${response.reasonPhrase}",
        );
      }

      final fileToSave = File(path);
      sink = fileToSave.openWrite();
      await response.forEach((chunk) {
        sink!.add(chunk);
      });
      await sink.flush();
      await sink.close();
      _logger.d("File saved to $path");
      return "Success";
    } catch (e) {
      _logger.e("Failed to save file '$file' to '$path': $e");
      throw Exception("Failed to save file '$file' to '$path': $e");
    } finally {
      await sink?.close();
      client?.close();
    }
  }

  Future<void> deleteFile(String file) async {
    final result = _useHttpLocalApi
        ? await _sendCommandOverHttp(
            Uri(
              scheme: 'http',
              host: _localApiHost,
              path: '$_localApiPrefix/files/${Uri.encodeComponent(file)}',
            ),
            'DELETE',
          )
        : await _sendCommand('delete_file', Uri.encodeComponent(file));
    if (result.startsWith("Error")) {
      throw Exception("Failed to delete file '$file': $result");
    }
  }

  Future<void> setAlwaysUseDerp(bool on) async {
    if (_useHttpLocalApi) {
      // Http api returns 201 with empty body for success.
      // Failures will throw exceptions.
      await _sendCommandOverHttp(
        Uri(
          scheme: 'http',
          host: _localApiHost,
          path: '$_localApiPrefix/envknob',
          queryParameters: {
            'env': jsonEncode({'TS_DEBUG_ALWAYS_USE_DERP': on ? "1" : "0"}),
          },
        ),
        'POST',
      );
      return;
    }
    final result = await _sendCommand(
      'set_env_knobs',
      'TS_DEBUG_ALWAYS_USE_DERP=${on ? 1 : 0}',
    );
    if (result != "Success") {
      throw Exception("Failed to set always use relay: $result");
    }
    _logger.d("Set always use relay to $on DONE.");
  }

  Future<void> setLocalDiscoveryRelay(bool on) async {
    final op = on ? 'add' : 'del';
    final caps = <String>[_capRelayL2Discovery];
    final shouldInject = Platform.isAndroid ||
        Platform.isLinux ||
        Platform.isWindows ||
        (Platform.isMacOS && _useHttpLocalApi);
    if (shouldInject) {
      caps.add(_capInjectL2Discovery);
    }

    if (_useHttpLocalApi) {
      for (final cap in caps) {
        await _sendCommandOverHttp(
          Uri(
            scheme: 'http',
            host: _localApiHost,
            path: '$_localApiPrefix/cap',
            queryParameters: {
              'cap': cap,
              'op': op,
            },
          ),
          'POST',
        );
      }
      return;
    }
    for (final cap in caps) {
      final result = await _sendCommand(
        'add_del_cap',
        '$cap $op',
      );
      if (result != "Success") {
        throw Exception(
            "Failed to set local discovery relay ($cap/$op): $result");
      }
    }
    _logger.d("Set local discovery relay to $on DONE.");
  }

  Future<void> setL2RelayCapture(bool on) async {
    if (_useHttpLocalApi) {
      await _sendCommandOverHttp(
        Uri(
          scheme: 'http',
          host: _localApiHost,
          path: '$_localApiPrefix/l2relay-capture',
          queryParameters: {
            'enabled': on ? 'true' : 'false',
          },
        ),
        'POST',
      );
      return;
    }
    final result = await _sendCommand(
      'set_l2relay_capture',
      on ? '1' : '0',
    );
    if (result != "Success") {
      throw Exception("Failed to set l2relay capture: $result");
    }
    _logger.d("Set l2relay capture to $on DONE.");
  }

  Future<void> setL2RelayVerboseDebug(bool on) async {
    if (_useHttpLocalApi) {
      await _sendCommandOverHttp(
        Uri(
          scheme: 'http',
          host: _localApiHost,
          path: '$_localApiPrefix/envknob',
          queryParameters: {
            'env': jsonEncode({'TS_DEBUG_L2RELAY_VERBOSE': on ? '1' : '0'}),
          },
        ),
        'POST',
      );
      return;
    }
    final result = await _sendCommand(
      'set_env_knobs',
      'TS_DEBUG_L2RELAY_VERBOSE=${on ? 1 : 0}',
    );
    if (result != "Success") {
      throw Exception("Failed to set l2relay verbose debug: $result");
    }
    _logger.d("Set l2relay verbose debug to $on DONE.");
  }

  Future<void> setUserDialUseRoutes(bool on) async {
    if (_useHttpLocalApi) {
      await _sendCommandOverHttp(
        Uri(
          scheme: 'http',
          host: _localApiHost,
          path: '$_localApiPrefix/cap',
          queryParameters: {
            'cap': 'user-dial-routes',
            'op': on ? 'add' : 'del'
          },
        ),
        'POST',
      );
      return;
    }
    final result = await _sendCommand(
      'add_del_cap',
      'user-dial-routes ' + (on ? 'add' : 'del'),
    );
    if (result != "Success") {
      throw Exception("Failed to set user dial use routes: $result");
    }
    _logger.d("Set user dial use routes to $on DONE.");
  }

  Future<void> setSendDNSToExitNodeInTunnel(bool on) async {
    if (_useHttpLocalApi) {
      await _sendCommandOverHttp(
        Uri(
          scheme: 'http',
          host: _localApiHost,
          path: '$_localApiPrefix/envknob',
          queryParameters: {
            'env': jsonEncode({
              'TS_DEBUG_SEND_DNS_TO_EXIT_NODE_IN_TUNNEL': on ? "1" : "0",
            }),
          },
        ),
        'POST',
      );
      return;
    }
    final result = await _sendCommand(
      'set_env_knobs',
      'TS_DEBUG_SEND_DNS_TO_EXIT_NODE_IN_TUNNEL=${on ? 1 : 0}',
    );
    if (result != "Success") {
      throw Exception(
        "Failed to set 'send dns to exit node in tunnel': $result",
      );
    }
    _logger.d("Set 'send dns to exit node in tunnel' to $on DONE.");
  }

  Future<DNSQueryResponse> queryDNS(String name, {String? type}) async {
    late final String result;
    if (_useHttpLocalApi) {
      result = await _sendCommandOverHttp(
        Uri(
          scheme: 'http',
          host: _localApiHost,
          path: '$_localApiPrefix/dns-query',
          queryParameters: {
            'name': name,
            'type': type ?? '',
          },
        ),
        'GET',
      );
    } else {
      result = await _sendCommand(
        'dns_query',
        '$name ${type ?? ''}',
      );
    }
    if (result.startsWith("Error")) {
      throw Exception(result);
    }
    _logger.d("DNS query for $name($type) SUCCESS.");
    return DNSQueryResponse.fromJson(jsonDecode(result));
  }

  // Parses a string into a boolean value.
  // Accepts 1, t, T, TRUE, true, True, 0, f, F, FALSE, false, False.
  // Any other value throws a FormatException.
  static bool parseBool(String str) {
    switch (str) {
      case '1':
      case 't':
      case 'T':
      case 'true':
      case 'TRUE':
      case 'True':
        return true;
      case '':
      case '0':
      case 'f':
      case 'F':
      case 'false':
      case 'FALSE':
      case 'False':
        return false;
      default:
        throw FormatException('Invalid boolean string: $str');
    }
  }

  Future<bool> getAlwaysUseDerp() async {
    if (_useHttpLocalApi) {
      final result = await _sendCommandOverHttp(
        Uri.parse('$_localBaseURL/envknob?env=TS_DEBUG_ALWAYS_USE_DERP'),
        'GET',
        timeoutMilliseconds: 2000,
      );
      try {
        final v = jsonDecode(result);
        return v['value'] != null ? parseBool(v['value'] as String) : false;
      } catch (e) {
        throw Exception("Failed to get always use relay: $result");
      }
    }
    final result = await _sendCommand(
      'get_env_knob',
      'TS_DEBUG_ALWAYS_USE_DERP',
      timeoutMilliseconds: 2000,
    );
    try {
      final v = parseBool(result);
      return v;
    } catch (e) {
      throw Exception("Failed to get always use relay: $result");
    }
  }

  Future<bool> getLocalDiscoveryRelay() async {
    final result = await (_useHttpLocalApi
        ? _sendCommandOverHttp(
            Uri.parse('$_localBaseURL/status?peers=false'),
            'GET',
            timeoutMilliseconds: 2000,
          )
        : _sendCommand(
            'status',
            '',
            timeoutMilliseconds: 2000,
          ));
    try {
      final v = jsonDecode(result) as Map<String, dynamic>;
      final selfNode = v['Self'] as Map<String, dynamic>?;
      final capMap = selfNode?['CapMap'] as Map<String, dynamic>?;
      return capMap?.containsKey(_capRelayL2Discovery) ?? false;
    } catch (e) {
      throw Exception("Failed to get local discovery relay: $e");
    }
  }

  Future<bool> getL2RelayCapture() async {
    if (_useHttpLocalApi) {
      final result = await _sendCommandOverHttp(
        Uri.parse('$_localBaseURL/l2relay-capture'),
        'GET',
        timeoutMilliseconds: 2000,
      );
      try {
        final v = jsonDecode(result);
        return v['enabled'] == true;
      } catch (e) {
        throw Exception("Failed to get l2relay capture: $result");
      }
    }
    final result = await _sendCommand(
      'get_l2relay_capture',
      '',
      timeoutMilliseconds: 2000,
    );
    try {
      return parseBool(result);
    } catch (e) {
      throw Exception("Failed to get l2relay capture: $result");
    }
  }

  Future<bool> getL2RelayVerboseDebug() async {
    if (_useHttpLocalApi) {
      final result = await _sendCommandOverHttp(
        Uri.parse('$_localBaseURL/envknob?env=TS_DEBUG_L2RELAY_VERBOSE'),
        'GET',
        timeoutMilliseconds: 2000,
      );
      try {
        final v = jsonDecode(result);
        return v['value'] != null ? parseBool(v['value'] as String) : false;
      } catch (e) {
        throw Exception('Failed to get l2relay verbose debug: ');
      }
    }
    final result = await _sendCommand(
      'get_env_knob',
      'TS_DEBUG_L2RELAY_VERBOSE',
      timeoutMilliseconds: 2000,
    );
    try {
      return parseBool(result);
    } catch (e) {
      throw Exception('Failed to get l2relay verbose debug: ');
    }
  }

  Future<void> login({
    MaskedPrefs? maskedPrefs,
    String? authKey,
    String? controlURL,
  }) async {
    try {
      // Stop VPN before setting the prefs so that it won't apply
      // to the current login profile.
      Future<void> editPrefsBeforeLogin() async {
        // Handle MDM control URL (assuming you have MDM settings)
        var prefs = maskedPrefs;
        final isInteractiveLogin = authKey == null || authKey.isEmpty;
        final mdmControlURL = await _getMdmControlURL();
        if (mdmControlURL.isNotEmpty) {
          controlURL = mdmControlURL;
          _logger.i('Overriding control URL with MDM value: $mdmControlURL');
        } else {
          controlURL ??= "https://manage.cylonix.io";
        }
        prefs ??= const MaskedPrefs();
        prefs = prefs.copyWith(
          controlURL: controlURL,
          controlURLSet: true,
          wantRunning: true,
          wantRunningSet: true,
        );
        if (isInteractiveLogin) {
          prefs = prefs.copyWith(
            authKey: '',
            authKeySet: true,
          );
          _logger.d("Clearing stored auth key before interactive login");
        }
        _logger.d("apply control URL $controlURL");
        await editPrefs(prefs);
      }

      Future<void> stopThenLogin() async {
        try {
          await stopVpn();
        } catch (e) {
          _logger.e('Failed to stop: $e. Aborting login.');
          rethrow;
        }
        await editPrefsBeforeLogin();
        final options = IpnOptions(authKey: authKey);
        await _start(options);
        await _loginInteractive();
      }

      Future<void> startAction() async {
        final options = IpnOptions(authKey: authKey);
        try {
          await _start(options);
        } catch (e) {
          _logger.e('Start failed: $e.');
          rethrow;
        }
        await stopThenLogin();
      }

      await startAction();
    } catch (e) {
      _logger.e('Error during login: $e');
      rethrow;
    }
  }

  // Helper methods for specific login scenarios
  Future<void> loginWithAuthKey(String authKey) async {
    const prefs = MaskedPrefs(
      wantRunning: true,
      wantRunningSet: true,
    );
    await login(maskedPrefs: prefs, authKey: authKey);
  }

  Future<void> loginWithCustomControlURL(String controlURL) async {
    final prefs = MaskedPrefs(controlURL: controlURL, controlURLSet: true);
    await login(maskedPrefs: prefs);
  }

  Future<void> startEngine(
    Function(Object error, StackTrace stack) onError,
  ) async {
    _logger.d("Starting engine...");
    // Reset so the dedup filter in _initMethodChannel won't suppress the
    // "active" status that createTunnelsManager is about to emit.
    _lastReceivedTunnelStatus = null;
    final completer = Completer<TunnelStatusEvent>();
    final id = const Uuid().v4();
    _commandCompleters[id] = completer;
    var tunnelStatusReceived = false;
    final tunnelStatusSub = eventBus.on<TunnelStatusEvent>().listen((event) {
      _logger.d(
        "Received tunnel status event $event "
        "tunnelStatusReceived = $tunnelStatusReceived",
      );
      if (!event.status.readyToStart) {
        _logger.d("Wait for ready to start status");
        return;
      } else {
        _logger.d("tunnel is ready to start: status=${event.status}");
      }
      if (!tunnelStatusReceived) {
        completer.complete(event);
        tunnelStatusReceived = true;
      }
    });
    try {
      if (isApple() && !isDirectDistribution) {
        try {
          await createTunnelsManager(/* don't care about the result */ "");
          final e = await completer.future.timeout(const Duration(seconds: 15));
          tunnelStatusSub.cancel();
          if (e.status == TunnelStatus.inactive) {
            throw "tunnel inactive: ${e.error}";
          }
          _logger.d("Tunnel setup success. Proceed to start VPN engine.");
        } on TimeoutException {
          _logger.e("Timeout waiting for tunnel being active");
          throw "Timeout waiting for VPN tunnel to be ready for configuration";
        } catch (e) {
          throw Exception("Failed to setup VPN: $e");
        }
      }
      _logger.d("Starting VPN engine...");
      // Don't use fast:true here — the 500ms timeout races libtailscale's
      // cold start (lb.Start holds b.mu while serveStatus waits for it).
      // The regular 5s timeout gives the backend time to settle. If the
      // status read still fails, fall through and call _start() anyway:
      // we'd otherwise be stuck waiting for a notification that requires
      // the backend to be started in the first place.
      try {
        final ret = await status(light: true);
        final s = ret.toString().length > 256
            ? ret.toString().substring(0, 256) + "..."
            : ret.toString();
        _logger.d("status: $s");
        final state = BackendState.fromString(ret.backendState);
        await watchNotifications(onError);
        if (state.value > BackendState.needsLogin.value) {
          _logger.i(
            "Tunnel already started with state: ${ret.backendState} "
            "> ${BackendState.needsLogin.name}",
          );
        } else {
          _logger.i(
            "Starting tunnel with state: ${ret.backendState}",
          );
          await _start(const IpnOptions());
        }
        return;
      } catch (e) {
        _logger.e(
            "Failed to get status: $e. Starting tunnel anyway and watching notifications.");
      }
      _logger.d("Status unknown; starting tunnel and watching notifications.");
      await watchNotifications(onError);
      // Without a successful status read we don't know what state the
      // backend is in, but the only state from which we'd want to skip
      // _start is "already running past needsLogin". If the backend was
      // already past that, _start is a no-op-ish; if it wasn't, we need
      // _start to drive the state machine forward (otherwise no
      // notifications are emitted and the UI stays at "connecting"
      // forever).
      try {
        await _start(const IpnOptions());
      } catch (e) {
        _logger.w("Fallback _start after status failure also failed: $e");
      }
      _startEngineBackendNotifySub?.cancel();
      _startEngineBackendNotifySub =
          eventBus.on<BackendNotifyEvent>().listen((_) async {
        _logger.d("Received first notification. Starting VPN.");
        _startEngineBackendNotifySub?.cancel();
        await _start(const IpnOptions());
      });
    } finally {
      tunnelStatusSub.cancel();
    }
  }

  static bool _httpInProgress = false;
  static Future<void> _waitForHttpLock({int timeoutMs = 10000}) async {
    var waited = 0;
    while (_httpInProgress) {
      if (waited >= timeoutMs) {
        throw TimeoutException(
          'Timeout waiting for HTTP lock after ${timeoutMs}ms',
        );
      }
      await Future.delayed(const Duration(milliseconds: 100));
      waited += 100;
    }
    _httpInProgress = true;
  }

  static void _sendLogOverHttp(String log, {bool priority = false}) async {
    // For windows, named pipes connection has max number of concurrent
    // connections, so we need to wait for previous log to be sent to
    // avoid sending logs in parallel.
    try {
      if (Platform.isWindows && !useWindowsTcpClient) {
        try {
          await _waitForHttpLock(timeoutMs: 1000);
        } catch (e) {
          if (!priority) {
            _logger.w(
              "Timeout waiting for log to be sent. "
              "Drop the log.",
              sendToIpn: false,
            );
            return;
          }
        }
      }
      try {
        _logClient ??= _httpClient;
        final request = await _logClient!.openUrl(
          'POST',
          Uri.parse('$_localBaseURL/log'),
        );
        request.add(utf8.encode(log));
        await request.close();
      } catch (e) {
        _logger.e('Failed to send log over stream: $e', sendToIpn: false);
        _logClient?.close();
        _logClient = null;
      }
    } finally {
      _httpInProgress = false;
    }
  }

  // Don't care about the result as caller cannot wait for it.
  static void sendLog(String log, {bool priority = false}) async {
    if (_useHttpLocalApi) {
      _sendLogOverHttp(log, priority: priority);
      return;
    }
    _channel.invokeMethod(
      "sendCommand",
      <String, String>{"cmd": "log", 'id': "", "args": log},
    );
  }

  Future<void> startWebAuth(String url, VoidCallback onStart) async {
    _logger.d("Starting web auth with URL: $url");
    final completer = Completer();
    _commandCompleters['web_auth'] = completer;
    final result = await _channel.invokeMethod('startWebAuth', url);
    if (result != "Success") {
      throw Exception("Failed to start web auth: $result");
    }
    onStart();
    final authResult =
        await completer.future.timeout(const Duration(minutes: 5));
    _logger.d("Web auth completed with result: $authResult");
    if (authResult is! Map<dynamic, dynamic>) {
      throw Exception("Unknown auth result: $authResult");
    }
    if (authResult['canceled'] == true) {
      throw WebAuthCanceledException("Web auth was cancelled by user");
    }
    if (authResult['success'] != true) {
      throw Exception("Web auth failed: ${authResult['error']}");
    }
  }

  Future<http.Response?> signinWithApple(String url) async {
    _logger.d("Starting Sign in with Apple with URL: $url");
    try {
      // Extract state from second path element
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isEmpty || pathSegments.length < 2) {
        throw Exception("Invalid URL: missing state in path");
      }
      final state = pathSegments[1];
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final addTokenEndpoint = Uri.https(
        'manage.cylonix.io',
        '/manager/v2/login/oauth/token',
        {
          'provider': 'apple',
          'session_id': state,
        },
      );
      final response = await http.post(
        addTokenEndpoint,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': credential.identityToken,
        }),
      );

      if (response.statusCode != 200) {
        if (response.statusCode == 302) {
          _logger
              .d("Redirect response received: ${response.headers['location']}");
          return response;
        }
        throw Exception(
          "Failed to add Apple token: ${response.statusCode} ${response.body}",
        );
      }
      return null;
    } catch (e) {
      _logger.e("Apple Sign In setup failed: $e");
      rethrow;
    }
  }

  Future<void> confirmDeviceConnection(
      http.Response resp, String sessionID) async {
    _logger.d("Confirming device connection for session $sessionID");
    final headers = resp.headers;
    headers['content-length'] = '0';
    headers['content-type'] = 'plain/text';
    headers['cookie'] = resp.headers['set-cookie'] ?? '';
    final r = await http.post(
      Uri.https(
        "manage.cylonix.io",
        "/manager/v2/login/confirm-session",
        {
          "session_id": sessionID,
        },
      ),
      headers: headers,
      body: "",
    );
    if (r.statusCode != 200) {
      final msg = "Failed to confirm Apple signin: ${r.statusCode} ${r.body}";
      throw Exception(msg);
    }
  }

  static const useWindowsTcpClient = true;

  static HttpClient get _httpClient {
    if (!_useHttpLocalApi) {
      throw UnsupportedError(
          "Http client is not supported for this platform/distribution.");
    }
    final String socket;
    if (Platform.isLinux || isDirectDistribution) {
      socket = "/var/run/cylonix/cylonixd.sock";
    } else if (Platform.isWindows) {
      socket = r'\\.\pipe\ProtectedPrefix\Administrators\Cylonix\cylonixd';
    } else {
      throw UnsupportedError("No socket path for this platform.");
    }
    final address = InternetAddress(socket, type: InternetAddressType.unix);

    final client = HttpClient()
      ..connectionFactory = (Uri uri, String? proxyHost, int? proxyPort) {
        assert(proxyHost == null);
        assert(proxyPort == null);
        return (Platform.isLinux || isDirectDistribution)
            ? Socket.startConnect(address, 0)
            : useWindowsTcpClient
                ? Socket.startConnect("127.0.0.1", 41112)
                : NamedPipeSocket(socket, uri.path).createConnectionTask();
      }
      ..findProxy = (Uri uri) => 'DIRECT';
    return client;
  }

  static const _distributionMode = String.fromEnvironment('DISTRIBUTION_MODE');

  static bool get isDirectDistribution =>
      Platform.isMacOS && _distributionMode == 'direct';

  static bool get _useHttpLocalApi {
    return Platform.isLinux || Platform.isWindows || isDirectDistribution;
  }

  Future<String> _listenToHttpResponse(
    HttpClientResponse response, {
    int timeoutMilliseconds = 10000,
    String endpoint = "",
  }) async {
    final completer = Completer<String>();
    final buffer = StringBuffer();
    response.transform(utf8.decoder).listen(
      (data) {
        buffer.write(data);
      },
      onError: (error, stack) {
        _logger.e('$endpoint: Stream error: $error', sendToIpn: false);
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(buffer.toString());
        }
        if (endpoint.contains('/log')) {
          _logger.d("$endpoint: Stream done", sendToIpn: false);
        }
      },
      cancelOnError: true,
    );
    return completer.future.timeout(Duration(
      milliseconds: timeoutMilliseconds,
    ));
  }

  Future<String> _sendCommandOverHttp(
    Uri uri,
    String method, {
    int timeoutMilliseconds = 10000,
    dynamic body,
  }) async {
    final client = _httpClient;
    final path = uri.path;
    try {
      final request = await client.openUrl(method, uri);
      request.headers.contentType = ContentType.json;
      if (Platform.isWindows) {
        request.headers.set(HttpHeaders.connectionHeader, "close");
      }
      if (body != null) {
        final jsonBody = jsonEncode(body);
        request.write(jsonBody);
      }
      final response = await request.close().timeout(
            Duration(milliseconds: timeoutMilliseconds),
          );
      final stringData = await _listenToHttpResponse(
        response,
        timeoutMilliseconds: timeoutMilliseconds,
        endpoint: path,
      );
      if (response.statusCode >= 300) {
        final errorMsg = "HTTP $method $path failed: ${response.statusCode} "
            "${response.reasonPhrase}: $stringData";
        _logger.e("$path: $errorMsg", sendToIpn: false);
        throw Exception(errorMsg);
      }
      return stringData;
    } catch (e) {
      _logger.e("$path: Failed to send command over HTTP: $e",
          sendToIpn: false);
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<String> _sendPeerFilesOverHttp(
      String peerID, List<OutgoingFile> files) async {
    // For windows, post multiple does not work yet due to multiple content
    // length issue, so we need to send files one by one. We cannot use
    // the direct single file put API due to the server managing the id field.
    if (Platform.isWindows && files.length > 1) {
      for (final file in files) {
        await _sendPeerFilesOverHttp(peerID, [file]);
      }
      return "Success";
    }
    for (final file in files) {
      _logger.d(
        "Sending file to peer $peerID/${file.id}/${file.name}",
        sendToIpn: false,
      );
    }

    // Create manifest
    final manifest = jsonEncode(files);
    final manifestBytes = utf8.encode(manifest);

    final parts = <FilePart>[
      // Add manifest as first part
      FilePart(
        filename: 'manifest.json',
        contentType: 'application/json',
        contentLength: manifestBytes.length,
        file: await _bytesToTempFile(manifestBytes),
      ),
      // Add actual files
      for (final file in files)
        FilePart(
          filename: file.name,
          contentLength: file.declaredSize,
          file: File(file.path!),
        ),
    ];

    try {
      final result = await _postMultipart(
        'file-put/$peerID',
        parts,
      );
      // For windows, a success means the files are sent.
      if (result.startsWith("Success") && Platform.isWindows) {
        final outgoingFiles = files.map((e) => OutgoingFile(
              id: e.id,
              peerID: e.peerID,
              name: e.name,
              declaredSize: e.declaredSize,
              finished: true,
              sent: e.declaredSize,
              succeeded: true,
            ));
        _logger.d(
          "Files sent successfully to peer $peerID: ${outgoingFiles.length}",
          sendToIpn: false,
        );
        eventBus.fire(
          BackendNotifyEvent(
            IpnNotification(outgoingFiles: outgoingFiles.toList()),
          ),
        );
      }
      return result;
    } finally {
      // Clean up temporary manifest file
      await parts.first.file.delete();
    }
  }

  Future<String> _postMultipart(String path, List<FilePart> parts) async {
    final client = _httpClient;
    final uri = Uri.parse('$_localBaseURL/$path');
    final request = await client.openUrl('POST', uri);

    try {
      final boundary = '__X_BOUNDARY__${const Uuid().v4()}__';
      request.headers.set(
        'Content-Type',
        'multipart/form-data; boundary=$boundary',
      );
      request.headers.chunkedTransferEncoding = true;

      // Start writing multipart data
      for (final part in parts) {
        // Write part header
        final asciiFallback = _escapeQuotes(
            part.filename.replaceAll(RegExp(r'[^\x00-\x7F]'), '_'));
        final encodedFilename = _encodeFilenameRFC5987(part.filename);
        request.write(
          '--$boundary\r\n'
          'Content-Disposition: form-data; name="file"; '
          'filename="$asciiFallback";'
          'filename*=UTF-8\'\'$encodedFilename\r\n'
          'Content-Type: ${part.contentType}\r\n'
          '\r\n',
        );

        // Write file data in chunks
        final stream = part.file.openRead();
        await for (final chunk in stream) {
          request.add(chunk);
        }
        request.write('\r\n');
      }

      // Write final boundary
      request.write('--$boundary--\r\n');

      final response = await request.close();
      final responseBody = await _listenToHttpResponse(
        response,
        timeoutMilliseconds: 24 * 3600 * 1000 /* 24 hours */,
        endpoint: path,
      );
      if (response.statusCode == 200) {
        return "Success: $responseBody";
      }

      if (response.statusCode >= 300) {
        throw Exception(
          'HTTP POST $path failed: ${response.statusCode} $responseBody',
        );
      }

      return responseBody;
    } finally {
      client.close();
    }
  }

  // Helper method to create a temporary file from bytes
  Future<File> _bytesToTempFile(List<int> bytes) async {
    final temp = await File(
            '${Directory.systemTemp.path}/manifest_${const Uuid().v4()}.json')
        .create();
    await temp.writeAsBytes(bytes);
    return temp;
  }

  // Helper method to escape quotes in filenames
  String _escapeQuotes(String str) {
    return str.replaceAll('"', '\\"').replaceAll(r'\', r'\\');
  }

  String _encodeFilenameRFC5987(String filename) {
    final utf8Bytes = utf8.encode(filename);
    final sb = StringBuffer();
    for (final b in utf8Bytes) {
      // Unreserved characters according to RFC 3986
      if ((b >= 0x41 && b <= 0x5A) || // A-Z
          (b >= 0x61 && b <= 0x7A) || // a-z
          (b >= 0x30 && b <= 0x39) || // 0-9
          b == 0x2D || // -
          b == 0x2E || // .
          b == 0x5F || // _
          b == 0x7E) {
        // ~
        sb.writeCharCode(b);
      } else {
        sb.write('%');
        sb.write(b.toRadixString(16).padLeft(2, '0').toUpperCase());
      }
    }
    return sb.toString();
  }

  Future<IpnPrefs?> setRunningExitNode(
      IpnPrefs? currentPrefs, bool isOn) async {
    if (currentPrefs == null) return currentPrefs;
    var routes = <String>[];
    if (currentPrefs.advertiseRoutes?.isNotEmpty == true) {
      routes.addAll(currentPrefs.advertiseRoutes!);
    }
    final hasV4 = routes.contains("0.0.0.0/0");
    final hasV6 = routes.contains("::/0");
    if (isOn) {
      if (hasV4 && hasV6) {
        _logger.d("Already has both v4 and v6 default routes. Skip...");
        return currentPrefs;
      }
      if (!hasV4) routes.add("0.0.0.0/0");
      if (!hasV6) routes.add("::/0");
    } else {
      if (!hasV4 && !hasV6) {
        _logger.d("Already has neither v4 or v6 default routes. Skip...");
        return currentPrefs;
      }
      if (hasV4) routes.removeWhere((r) => r == "0.0.0.0/0");
      if (hasV6) routes.removeWhere((r) => r == "::/0");
    }
    return await editPrefs(
      MaskedPrefs(
        advertiseRoutes: routes,
        advertiseRoutesSet: true,
      ),
    );
  }

  Future<void> excludeAppFromVPN(String packageName, bool isOn) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        "Excluding apps from VPN is only supported on Android.",
      );
    }
    final result = await _channel.invokeMethod(
      'excludeAppFromVPN',
      <String, dynamic>{
        'packageName': packageName,
        'isOn': isOn,
      },
    );
    if (result != "Success") {
      throw Exception("Failed to exclude app from VPN: $result");
    }
  }

  Future<bool> getAutoStartEnabled() async {
    final result = await _channel.invokeMethod('getAutoStartEnabled');
    if (result is! bool) {
      throw Exception("Failed to get auto start enabled: $result");
    }
    return result;
  }

  Future<void> setAutoStartEnabled(bool isEnabled) async {
    final result = await _channel.invokeMethod(
      'setAutoStartEnabled',
      {'enabled': isEnabled},
    );
    if (result != "Success") {
      throw Exception("Failed to set auto start enabled: $result");
    }
  }
}

class EventBusSender {
  static void fireEvent(List<dynamic> args) {
    final IpnNotification notification = args[0];
    final EventBus eventBus = args[1];
    eventBus.fire(BackendNotifyEvent(notification));
  }
}

// Thrown when libtailscale's native bridge reports that the App global
// is not yet initialized. _sendCommand catches this internally and
// retries with backoff via _sendCommandWithInitRetry; callers should
// not see it.
class _AppNotInitializedException implements Exception {
  @override
  String toString() => '_AppNotInitializedException';
}
