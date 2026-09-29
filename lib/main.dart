// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'models/platform.dart';
import 'models/shared_file.dart';
import 'providers/share_file.dart';
import 'services/desktop_notifications.dart';
import 'services/share_request_inbox.dart';
import 'services/system_tray_service.dart';
import 'services/windows_share_handoff.dart';
import 'utils/applog.dart';
import 'utils/logger.dart';
import 'package:window_manager/window_manager.dart';

var _logger = Logger(tag: "Main");

void main(List<String> args) async {
  const _channel = MethodChannel('io.cylonix.sase/share_channel');
  await _loadEnv();
  await _initLogger();
  await initializePlatform();
  _logger = Logger(tag: "Main");

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize system tray and window manager for Windows and macOS
  if (Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);
    await SystemTrayService.init();
  }

  // Desktop (Windows/Linux) toast notifications for incoming files. Self-guards
  // to supported platforms.
  await DesktopNotifications.init();

  _logger.i("Starting Cylonix app with args: $args");
  _logger.i("Setting up MethodChannel for share events");
  _channel.setMethodCallHandler((call) async {
    _logger.i(
      "SHARE CHANNEL: ${call.method} ${call.arguments}",
    );
    if (call.method == 'onShare') {
      _logger.i("Received shared files: ${call.arguments}");
      shareFileEventBus.fire(ShareFileEvent(call.arguments.toString()));
    } else if (call.method == 'onShareRequest') {
      // The Windows share window handed a Peer Message share to this (main)
      // instance: the runner forwarded the manifest path it was started
      // with. Queued for the home page to present.
      final path = call.arguments.toString().trim();
      _logger.i("Received share request manifest: $path");
      final request = await WindowsShareHandoff.loadManifest(path);
      if (request != null) {
        ShareRequestInbox.push(request);
      }
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
  } else if (Platform.isWindows) {
    await _queueWindowsShareRequests(args);
  }
  runApp(
    ProviderScope(child: App(sharedFiles: sharedFiles)),
  );
}

/// Main-app start on Windows: a share window may have started this process
/// with `--share-request <manifest>` (no main instance was running to
/// forward to), and manifests from hand-offs that never reached an app are
/// still on disk. Both go to the inbox; the home page drains it on first
/// frame.
Future<void> _queueWindowsShareRequests(List<String> args) async {
  final index = args.indexOf(WindowsShareHandoff.argument);
  if (index != -1 && index < args.length - 1) {
    final path = args[index + 1];
    _logger.i("Started with share request manifest: $path");
    final request = await WindowsShareHandoff.loadManifest(path);
    if (request != null) {
      ShareRequestInbox.push(request);
    }
  }
  try {
    for (final request in await WindowsShareHandoff.drainPending()) {
      _logger.i("Recovered pending share request: $request");
      ShareRequestInbox.push(request);
    }
  } catch (e) {
    _logger.e("Failed to drain pending share requests: $e");
  }
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
  } on EmptyEnvFileError catch (e) {
    _logger.w("Optional env file not found: $e. Continuing without it.");
  } catch (e) {
    _logger.e("Failed to load the optional env file: $e");
  }
}
