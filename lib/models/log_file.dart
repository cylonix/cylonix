// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';
import 'package:downloadsfolder/downloadsfolder.dart' as sse;
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
    final dir = await sse.getDownloadDirectory();
    final path = p.join(
      dir.path,
      'Cylonix',
      'Logs',
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

abstract class ServiceLogReader {
  // Helper to read last N lines of a file
  static Future<List<String>> readLastLines(File file, int count,
      {String? match}) async {
    final lines = <String>[];

    // Read file backwards in chunks
    final length = await file.length();
    var position = length;
    const chunkSize = 4096;

    while (position > 0 && lines.length < count) {
      final size = position > chunkSize ? chunkSize : position;
      position -= size;

      final chunk = await file.openRead(position, position + size).toList();
      final text = String.fromCharCodes(chunk.expand((x) => x));
      var chunkLines = text.split('\n');
      if (match != null) {
        chunkLines = chunkLines.where((e) => e.contains(match)).toList();
      }

      lines.insertAll(0, chunkLines);

      // Keep only last N lines
      if (lines.length > count) {
        lines.removeRange(0, lines.length - count);
      }
    }

    return lines;
  }
}

class WindowsServiceLogReader extends ServiceLogReader {
  static Future<List<String>> readLatestServiceLog({int lines = 5000}) async {
    // Get ProgramData path from environment
    final programData = Platform.environment['ProgramData'];
    if (programData == null) {
      throw Exception('ProgramData environment variable not found');
    }

    // Build path to logs directory
    final logPath = p.join(programData, 'Cylonix', 'Logs');
    final logDir = Directory(logPath);

    if (!await logDir.exists()) {
      throw Exception('Log directory not found: $logPath');
    }

    // Find latest cylonix-service log file
    final logs = await logDir
        .list()
        .where((f) =>
            f is File && p.basename(f.path).startsWith('cylonix-service'))
        .cast<File>()
        .toList();

    if (logs.isEmpty) {
      throw Exception('No cylonix-service log files found');
    }

    // Sort by last modified time to get the latest
    logs.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    final latestLog = logs.first;
    final file = File(latestLog.path);

    // Read last N lines
    return await ServiceLogReader.readLastLines(file, lines);
  }
}

class LinuxServiceLogReader extends ServiceLogReader {
  static Future<List<String>> readLatestServiceLog({int lines = 5000}) async {

    final file = File('/var/log/syslog');

    // Read last N lines
    return await ServiceLogReader.readLastLines(file, lines, match: 'cylonixd');
  }
}
