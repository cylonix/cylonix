// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';
//import 'package:downloadsfolder/downloadsfolder.dart' as sse;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'date_time_extension.dart';
import '../utils/logger.dart';

class LogFile {
  late final Logger _logger;
  final List<String> logs;
  final String name;
  LogFile({required this.logs, required this.name}) {
    _logger = Logger(tag: "LogFile:$name");
  }

  String get _fileName {
    final now = DateTime.now().toLocal().toFilenameString();
    return '${name}_$now.txt';
  }

  /// Save the logs to a file.
  /// Caller to make sure saveFile is supported on the platform.
  Future<String?> save() async {
    if (logs.isEmpty) {
      _logger.i("Log is empty. Skip saving to a file.");
      throw Exception("Log is empty");
    }

    if (Platform.isIOS) {
      final path = await _iosDocFilePath(_fileName);
      return await _saveToPath(path);
    }
    if (Platform.isAndroid) {
      return await _saveAndroid();
    }
    final result = await FilePicker.platform.saveFile(
      dialogTitle: "Choose the file to be saved",
      type: FileType.custom,
      fileName: _fileName,
      allowedExtensions: ["txt"],
    );

    if (result == null) {
      return null; // User canceled the picker
    }
    return await _saveToPath(result);
  }

  Future<String> _saveToPath(String path) async {
    final file = await File(path).create(recursive: true);
    await file.writeAsString(logs.join("\n"));
    return file.path;
  }

  Future<String> _iosDocFilePath(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(
      dir.path,
      'logs',
      fileName,
    );
  }

  Future<String> _saveAndroid() async {
    final fileName = _fileName;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(
      dir.path,
      'logs',
      fileName,
    );
    return await _saveToPath(path);
  }

  Rect? _sharePositionOrigin(BuildContext context) {
    if (!Platform.isIOS) {
      return null;
    }
    final box = context.findRenderObject() as RenderBox?;
    return box != null
        ? Rect.fromPoints(
            box.localToGlobal(Offset.zero),
            box.localToGlobal(box.size.bottomRight(Offset.zero)),
          )
        : null;
  }

  /// Share the logs as a file.
  Future<void> share(BuildContext context) async {
    if (logs.isEmpty) {
      throw Exception("Log is empty");
    }
    try {
      final dir = await getTemporaryDirectory();
      final path = p.join(dir.path, _fileName);
      await _saveToPath(path);
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Log File: $_fileName',
        sharePositionOrigin: _sharePositionOrigin(context),
      );
    } catch (e) {
      _logger.e("Failed to share log file: $e");
      rethrow;
    }
  }
}
