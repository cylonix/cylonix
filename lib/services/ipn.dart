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
import '../models/ipn.dart';
import '../models/log_file.dart';
import '../utils/logger.dart';
import '../utils/utils.dart';
import 'named_pipe_socket.dart';

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

  Future<List<String>> getLogs() async {
    if (Platform.isWindows) {
      return await WindowsServiceLogReader.readLatestServiceLog();
    }
    if (Platform.isLinux) {
      return await LinuxServiceLogReader.readLatestServiceLog();
    }
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
      if (Platform.isAndroid) {
        for (var i = 0; i < 10; i++) {
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

  Future<IpnPrefs> editPrefs(MaskedPrefs edits) async {
    final result = _useHttpLocalApi
        ? await _sendCommandOverHttp(
            Uri.parse('$_localBaseURL/prefs'),
            'PATCH',
            body: edits,
          )
        : await _sendCommand('edit_prefs', jsonEncode(edits));
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
    final result = await _sendCommand('turn_off_vpn', '');
    if (result != 'Success') {
      throw Exception('Turn off VPN failed: $result');
    }
  }

  Future<void> _start(IpnOptions options) async {
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
    if (isApple()) await _turnOffVPN();
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
    final result = await (_useHttpLocalApi
        ? _sendCommandOverHttp(
            Uri(
              scheme: 'http',
              host: _localApiHost,
              path: '$_localApiPrefix/ping',
              queryParameters: {
                'ip': addr,
                'type': 'disco',
              },
            ),
            'POST',
          )
        : _sendCommand('ping', addr));
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
    print("Received waiting files: $result");
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
            const Duration(milliseconds: 1000),
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
        _logger.e("Failed to get status: $e. Wait for notification to start.");
      }
      _logger.d("Tunnel started. Waiting for notification to start VPN.");
      await watchNotifications(onError);
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
        request.write(log);
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

  static const useWindowsTcpClient = true;

  static HttpClient get _httpClient {
    if (!Platform.isLinux && !Platform.isWindows) {
      throw UnsupportedError(
          "Http client is only supported on Linux and Windows platforms.");
    }
    final socket = Platform.isLinux
        ? "/var/run/cylonix/cylonixd.sock"
        : r'\\.\pipe\ProtectedPrefix\Administrators\Cylonix\cylonixd';
    final address = InternetAddress(socket, type: InternetAddressType.unix);

    final client = HttpClient()
      ..connectionFactory = (Uri uri, String? proxyHost, int? proxyPort) {
        assert(proxyHost == null);
        assert(proxyPort == null);
        return Platform.isLinux
            ? Socket.startConnect(address, 0)
            : useWindowsTcpClient
                ? Socket.startConnect("127.0.0.1", 41112)
                : NamedPipeSocket(socket, uri.path).createConnectionTask();
      }
      ..findProxy = (Uri uri) => 'DIRECT';
    return client;
  }

  static bool get _useHttpLocalApi {
    // Use HTTP local API only on Linux and Windows.
    return Platform.isLinux || Platform.isWindows;
  }

  Future<String> _listenToHttpResponse(
    HttpClientResponse response, {
    int timeoutMilliseconds = 10000,
    String endpoint = "",
  }) async {
    Completer? completer;
    completer = Completer();
    response.transform(utf8.decoder).listen(
      (data) {
        if (completer == null || (completer?.isCompleted ?? false)) {
          _logger.e(
            "$endpoint: Completer is null or completed, "
            "cannot set http response",
            sendToIpn: false,
          );
          return;
        }
        completer?.complete(data);
        completer = null;
      },
      onError: (error, stack) {
        _logger.e('$endpoint: Stream error: $error', sendToIpn: false);
        if (completer != null && !(completer?.isCompleted ?? false)) {
          completer?.completeError(error);
          completer = null;
        }
      },
      onDone: () {
        if (completer != null && !(completer?.isCompleted ?? false)) {
          completer?.complete("");
          completer = null;
        }
        if (endpoint.contains('/log')) {
          _logger.d("$endpoint: Stream done", sendToIpn: false);
        }
      },
      cancelOnError: true,
    );
    final result = await completer?.future.timeout(Duration(
      milliseconds: timeoutMilliseconds,
    ));
    completer = null;
    if (result is! String) {
      _logger.e("$endpoint: HTTP request failed: $result", sendToIpn: false);
      throw Exception("HTTP request failed: $result");
    }
    return result;
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
}

class EventBusSender {
  static void fireEvent(List<dynamic> args) {
    final IpnNotification notification = args[0];
    final EventBus eventBus = args[1];
    eventBus.fire(BackendNotifyEvent(notification));
  }
}
