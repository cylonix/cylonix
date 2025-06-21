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
import '../models/ipn.dart';
import '../utils/logger.dart';
import '../utils/utils.dart';

class IpnService {
  static bool _initialized = false;
  static const _channel = MethodChannel('io.cylonix.sase/wg');
  static final _logger = Logger(tag: "IpnService");
  static final eventBus = EventBus();
  static final _commandCompleters =
      <String, Completer>{}; // key is command uuid
  static final _notificationController =
      StreamController<IpnNotification>.broadcast();

  StreamSubscription<BackendNotifyEvent>? _startEngineBackendNotifySub;

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
      // to send it manually.
      if (onData.status == TunnelStatus.inactive) {
        _logger.d("Tunnel status changed to inactive");
        final n = IpnNotification(
          state: BackendState.noState.value,
        );
        _logger.d("Sending notification: $n");
        _notificationController.add(n);
      }
    });
  }

  Stream<IpnNotification> get notificationStream =>
      _notificationController.stream;

  Future<void> initializeEngine() async {
    try {
      await startEngine();
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
            final s = call.arguments as String;
            final json = jsonDecode(s);
            final v = IpnNotification.fromJson(json);
            eventBus.fire(BackendNotifyEvent(v));
          } catch (e, trace) {
            _logger.e("Failed to handle notification: $e: $trace");
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
          // Nothing to do here for now.
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

    void setTimeout() {
      currentTimer = Timer(const Duration(seconds: 10), () {
        if (!c.isCompleted) {
          c.completeError(
            TimeoutException(
              "Transfer to peer timed out",
              const Duration(seconds: 10),
            ),
          );
        }
        _logger.e("Transfer to peer $peerID timed out");
      });
    }

    try {
      sub = eventBus.on<BackendNotifyEvent>().listen((event) {
        final outgoingFiles = event.notification.outgoingFiles ?? [];
        // Only reset timeout if we see progress for our files
        if (outgoingFiles.any((f) => f.peerID == peerID)) {
          currentTimer?.cancel();
          setTimeout();
        }
      });

      final result = await _sendCommand(
        'send_files_to_peer',
        jsonEncode({
          'peer_id': peerID,
          'files': files,
        }),
        onSetTimeout: setTimeout,
      );

      _logger.d("Send files to peer $peerID: $result");
      if (!result.startsWith("Success")) {
        throw Exception("Failed to send file to peer: result='$result'");
      }
    } finally {
      sub.cancel();
      currentTimer?.cancel();
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
      await _sendCommandOverHttp('logout', 'POST');
      return;
    }
    final result = await _sendCommand("logout", "");
    if (result != 'Success') {
      throw Exception(result);
    }
  }

  Future<List<String>> getLogs() async {
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
      final ret = await completer.future.timeout(timeout);
      return ret;
    } catch (e) {
      _logger.e("failed to get logs: $e");
      rethrow;
    }
  }

  Future<String> _sendCommand(
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
      return response;
    } catch (e) {
      _logger.e("failed to wait for command '$cmd' result: $e");
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
      final completer = Completer<bool>();
      _commandCompleters[id] = completer;
      await createTunnelsManager(id);
      final created = await completer.future.timeout(
        const Duration(seconds: 120),
      );
      return created;
    } catch (e) {
      throw Exception("request VPN permission failed: $e");
    }
  }

  Future<void> _loginInteractive() async {
    if (_useHttpLocalApi) {
      await _sendCommandOverHttp('login-interactive', 'POST');
      return;
    }
    final result = await _sendCommand('start_login_interactive', '');
    if (result != 'Success') {
      throw Exception('Login interactive failed: $result');
    }
  }

  Future<void> _editPrefs(MaskedPrefs edits) async {
    if (_useHttpLocalApi) {
      await _sendCommandOverHttp('prefs', 'PATCH', body: edits);
      return;
    }
    final result = await _sendCommand('edit_prefs', jsonEncode(edits));
    if (result != 'Success') {
      _logger.e("Edit prefs failed: $result");
      throw Exception('Edit prefs failed: $result');
    }
  }

  Future<void> _turnOffVPN() async {
    final result = await _sendCommand('turn_off_vpn', '');
    if (result != 'Success') {
      throw Exception('Turn off VPN failed: $result');
    }
  }

  Future<void> _start(IpnOptions options) async {
    if (_useHttpLocalApi) {
      await _sendCommandOverHttp('start', 'POST', body: options);
      return;
    }
    final result = await _sendCommand('start', jsonEncode(options));
    if (result != 'Success') {
      throw Exception('Start failed: $result');
    }
  }

  Future<HttpClient> _watchNotificationsOverHttp() async {
    final client = _httpClient;
    try {
      // Calculate notification bits
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
          'Watch notifications failed: ${response.statusCode} ${response.reasonPhrase}',
        );
      }

      // Start listening to the stream without awaiting
      response.transform(utf8.decoder).transform(const LineSplitter()).listen(
        (data) {
          if (data.isEmpty) return; // Skip empty lines (server flushes)

          try {
            final json = jsonDecode(data);
            final notification = IpnNotification.fromJson(json);
            eventBus.fire(BackendNotifyEvent(notification));
          } catch (e, stack) {
            _logger.e('Failed to parse notification: $e\n$stack');
          }
        },
        onError: (e, stack) {
          _logger.e('Error in notification stream: $e\n$stack');
        },
      );

      return client;
    } catch (e) {
      client.close();
      rethrow;
    }
  }

  HttpClient? _notificationClient;
  Future<void> _watchNotifications() async {
    if (_useHttpLocalApi) {
      // Close any existing client
      _notificationClient?.close();
      _notificationClient = await _watchNotificationsOverHttp();
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
    return "";
    //return Pst.mdmControlURL ?? "";
  }

  Future<void> startVpn() async {
    await _editPrefs(const MaskedPrefs(
      wantRunning: true,
      wantRunningSet: true,
    ));
  }

  Future<void> stopVpn() async {
    await _editPrefs(const MaskedPrefs(
      wantRunning: false,
      wantRunningSet: true,
    ));
    if (isApple()) await _turnOffVPN();
  }

  Future<void> stopPing() async {
    return;
  }

  Future<List<LoginProfile>?> getProfiles() async {
    final result = await (_useHttpLocalApi
        ? _sendCommandOverHttp('profiles/', 'GET')
        : _sendCommand('profiles', ''));
    final list = jsonDecode(result) as List<dynamic>?;
    return list?.map((e) => LoginProfile.fromJson(e)).toList();
  }

  Future<PingResult> ping(Node peer) async {
    final addr = peer.primaryIPv4Address ?? "";
    if (addr.isEmpty) {
      throw Exception("Peer has no address");
    }
    final result = await (_useHttpLocalApi
        ? _sendCommandOverHttp(
            'ping?ip=${Uri.encodeQueryComponent(addr)}&type=disco',
            'POST',
          )
        : _sendCommand('ping', addr));
    return PingResult.fromJson(jsonDecode(result));
  }

  Future<Status> status({bool light = false, bool fast = false}) async {
    final timeoutMilliseconds = fast ? 500 : 5000;

    final result = _useHttpLocalApi
        ? await _sendCommandOverHttp(
            light ? 'status?peers=false' : 'status',
            'GET',
            timeoutMilliseconds: timeoutMilliseconds,
          )
        : await _sendCommand(
            'status',
            light ? jsonEncode({"peers": false}) : '',
            timeoutMilliseconds: timeoutMilliseconds,
          );
    return Status.fromJson(jsonDecode(result));
  }

  Future<LoginProfile> currentProfile({bool fast = false}) async {
    final result = _useHttpLocalApi
        ? await _sendCommandOverHttp(
            'profiles/current',
            'GET',
            timeoutMilliseconds: fast ? 500 : 5000,
          )
        : await _sendCommand(
            'current_profile',
            '',
            timeoutMilliseconds: fast ? 500 : 5000,
          );
    return LoginProfile.fromJson(jsonDecode(result));
  }

  Future<void> addProfile() async {
    if (_useHttpLocalApi) {
      await _sendCommandOverHttp(
        'profiles',
        'PUT',
      );
      return;
    }
    final result = await _sendCommand('add_profile', '');
    if (result != "Success") {
      throw Exception("Failed to add profile: $result");
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

  Future<void> switchProfile(String id) async {
    if (_useHttpLocalApi) {
      await _sendCommandOverHttp('profiles/$id', 'POST');
      return;
    }
    final result = await _sendCommand('switch_profile', id);
    if (result != "Success") {
      throw Exception("Failed to switch profile: $result");
    }
  }

  Future<void> setAlwaysUseDerp(bool on) async {
    final result = await _sendCommand(
      'set_env_knobs',
      'TS_DEBUG_ALWAYS_USE_DERP=${on ? 1 : 0}',
    );
    if (result != "Success") {
      throw Exception("Failed to set always use relay: $result");
    }
    _logger.d("Set always use relay to $on DONE.");
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
        'envknob?env=TS_DEBUG_ALWAYS_USE_DERP',
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
        if (authKey != null) {
          prefs ??= const MaskedPrefs();
          prefs = prefs.copyWith(
            wantRunning: true,
            wantRunningSet: true,
          );
        }
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
        );
        _logger.d("apply control URL $controlURL");
        await _editPrefs(prefs);
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

  Future<void> startEngine() async {
    _logger.d("Starting engine...");
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
      if (isApple()) {
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
      try {
        final ret = await status(light: true, fast: true);
        _logger.d("status: $ret");
        final state = BackendState.fromString(ret.backendState);
        _watchNotifications();
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
        _logger.e("Failed to get status: $e. Wait for notification to start.");
      }
      _logger.d("Tunnel started. Waiting for notification to start VPN.");
      _watchNotifications();
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

  // Don't care about the result as caller cannot wait for it.
  HttpClient? _logClient;
  void sendLog(String log) async {
    if (_useHttpLocalApi) {
      _logClient ??= _httpClient;
      HttpClientRequest? request;
      try {
        request = await _logClient!.openUrl(
          'POST',
          Uri.parse('$_localBaseURL/log'),
        );
        request.headers.contentType = ContentType.text;
        request.write(log);
        final response = await request.close();
        // Drain response to properly close the connection
        await response.drain<void>();
      } catch (e) {
        _logger.e('Failed to send log: $e');
      } finally {
        // Don't close the client, but close the request
        request?.close();
      }
      return;
    }
    _channel.invokeMethod(
      "sendCommand",
      <String, String>{"cmd": "log", 'id': "", "args": log},
    );
  }

  Future<void> startWebAuth(String url) async {
    _logger.d("Starting web auth with URL: $url");
    final result = await _channel.invokeMethod('startWebAuth', url);
    if (result != "Success") {
      throw Exception("Failed to start web auth: $result");
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

  HttpClient get _httpClient {
    if (!Platform.isLinux && !Platform.isWindows) {
      throw UnsupportedError(
          "Http client is only supported on Linux and Windows platforms.");
    }
    final socket = Platform.isLinux
        ? "/var/run/cylonix/cylonixd.sock"
        : r'\\.\pipe\ProtectedPrefix\Administrators\Tailscale\tailscaled';
    final address = InternetAddress(socket, type: InternetAddressType.unix);

    final client = HttpClient()
      ..connectionFactory = (Uri uri, String? proxyHost, int? proxyPort) {
        assert(proxyHost == null);
        assert(proxyPort == null);
        return Socket.startConnect(address, 0);
      }
      ..findProxy = (Uri uri) => 'DIRECT';

    return client;
  }

  bool get _useHttpLocalApi {
    // Use HTTP local API only on Linux and Windows.
    return Platform.isLinux || Platform.isWindows;
  }

  static const _localBaseURL = "http://local-tailscaled.sock/localapi/v0";
  Future<String> _sendCommandOverHttp(
    String url,
    String method, {
    int timeoutMilliseconds = 10000,
    dynamic body,
  }) async {
    final client = _httpClient;
    try {
      final request = await client.openUrl(
          method,
          Uri.parse(
            '$_localBaseURL/$url',
          ));
      request.headers.contentType = ContentType.json;
      if (body != null) {
        final jsonBody = jsonEncode(body);
        request.write(jsonBody);
      }
      final response = await request.close().timeout(
            Duration(milliseconds: timeoutMilliseconds),
          );
      if (response.statusCode >= 300) {
        final errorMsg = "HTTP $method $url failed: ${response.statusCode} "
            "${response.reasonPhrase}";
        _logger.e(errorMsg);
        throw Exception(errorMsg);
      }

      // Convert response to string
      final stringData = await response.transform(utf8.decoder).join();
      return stringData;
    } finally {
      client.close();
    }
  }
}
