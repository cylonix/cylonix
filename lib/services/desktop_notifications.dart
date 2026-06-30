// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

import 'package:local_notifier/local_notifier.dart';

import '../utils/logger.dart';

/// Desktop (Windows/Linux) toast notifications for incoming files.
///
/// flutter_local_notifications 17.x has no Windows backend, so local_notifier
/// covers the desktop path. iOS/Android/macOS post their own notifications
/// natively (Network Extension / channel / LaunchAgent), so this is scoped to
/// Windows and Linux and is a no-op elsewhere.
class DesktopNotifications {
  static final _logger = Logger(tag: "DesktopNotifications");
  static bool _initialized = false;

  static bool get _supported => Platform.isWindows || Platform.isLinux;

  /// Initializes local_notifier. Safe to call once at startup; a no-op on
  /// unsupported platforms or if already initialized.
  static Future<void> init() async {
    if (!_supported || _initialized) return;
    try {
      await localNotifier.setup(appName: 'Cylonix');
      _initialized = true;
    } catch (e) {
      _logger.w('local_notifier setup failed: $e');
    }
  }

  /// Shows a "file received" toast. Clicking it reveals the file in the OS file
  /// manager (e.g. the Downloads/Cylonix folder it landed in).
  static Future<void> showFileReceived({
    required String name,
    required String path,
  }) async {
    if (!_supported) return;
    await init();
    if (!_initialized) return;
    try {
      final notification = LocalNotification(
        title: 'File received',
        body: name.isNotEmpty ? name : 'A file was received',
      );
      notification.onClick = () => _reveal(path);
      await notification.show();
    } catch (e) {
      _logger.w('failed to show file-received notification: $e');
    }
  }

  static Future<void> _reveal(String filePath) async {
    if (filePath.isEmpty) return;
    try {
      if (Platform.isWindows) {
        // explorer /select, highlights the file; fall back to opening the
        // containing folder if it has already been moved.
        if (await File(filePath).exists()) {
          await Process.start('explorer.exe', ['/select,', filePath]);
        } else {
          await Process.start('explorer.exe', [File(filePath).parent.path]);
        }
      } else {
        await Process.start('xdg-open', [File(filePath).parent.path]);
      }
    } catch (e) {
      _logger.w('failed to reveal $filePath: $e');
    }
  }
}
