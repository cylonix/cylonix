import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'models/platform.dart';
import 'models/shared_file.dart';
import 'providers/share_file.dart';
import 'utils/applog.dart';
import 'utils/logger.dart';

var _logger = Logger(tag: "Main");
void main(List<String> args) async {
  const _channel = MethodChannel('io.cylonix.sase/share_channel');
  await _loadEnv();
  await _initLogger();
  await initializePlatform();
  _logger = Logger(tag: "Main");

  WidgetsFlutterBinding.ensureInitialized();

  _logger.i("Starting Cylonix app with args: $args");
  _logger.i("Setting up MethodChannel for share events");
  _channel.setMethodCallHandler((call) async {
    _logger.i(
      "SHARE CHANNEL: ${call.method} ${call.arguments}",
    );
    if (call.method == 'onShare') {
      _logger.i("Received shared files: ${call.arguments}");
      shareFileEventBus.fire(ShareFileEvent(call.arguments.toString()));
    } else {
      _logger.w("Unknown method call: ${call.method}");
    }
  });

  // Get test arguments if running in debug
  const testArgs = String.fromEnvironment('FLUTTER_TEST_ARGS');
  if (testArgs.isNotEmpty) {
    args = testArgs.split(',');
  }
  _logger.i("Final args: $args");

  bool isShare = args.contains('--share');
  List<String> sharedFiles = [];

  if (isShare) {
    int shareIndex = args.indexOf('--share');
    if (shareIndex < args.length - 1) {
      sharedFiles = args.sublist(shareIndex + 1);
    }
  }
  runApp(
    ProviderScope(child: App(sharedFiles: sharedFiles)),
  );
}

Future<void> _initLogger() async {
  try {
    await AppLog.init();
    _logger.d("Logger initialized");
  } catch (e) {
    _logger.e("Failed to initialize logger: $e");
  }
}

/// Load env setting.
Future<void> _loadEnv() async {
  try {
    await dotenv.load(fileName: ".env.local", isOptional: true);
  } catch (e) {
    _logger.e("Failed to load the optional env file: $e");
  }
}
