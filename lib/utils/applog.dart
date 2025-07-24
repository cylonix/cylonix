// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import "package:flutter_logger/flutter_logger.dart" as log_console;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AppLog {
  static late Directory _logDirectory;
  static late File _logFile;
  static const _defaultLogBufferSize = 1024; // entries
  static final _appOutput = MemoryOutput(bufferSize: _defaultLogBufferSize);
  static const _rotateLogInterval = 6; // hours
  static final _printer = SimplePrinter(printTime: true, colors: false);
  static bool _initDone = false;
  static var logger = Logger(
    filter: ProductionFilter(),
    printer: _printer,
    level: Level.debug,
    output: MultiOutput([ConsoleOutput(), _appOutput]),
  );

  static void _startLoggerPeriodical() {
    Timer.periodic(const Duration(hours: _rotateLogInterval), (timer) async {
      await _rotateLogFile(_logDirectory);
    });
    logger.d("logger timer started");
  }

  /// Rotate log file to a new one and keep only the last 10 files.
  static Future<void> _rotateLogFile(Directory dir) async {
    final currentLogFileName = _logFile.path;
    final current = _logFile;
    const maxLogFileSize = 100000; // 100KB
    const maxLogFileDays = 2; // number of days for log files outstanding
    try {
      if (!await current.exists()) {
        logger.d(
          "Log file does not exist, creating empty log file: "
          "$currentLogFileName",
        );
        await current.create(recursive: true);
        return;
      }
      final size = await current.length();
      logger.d("rotate log file size $size bytes max $maxLogFileSize bytes");
      logger.i("log file $currentLogFileName");
      if (size > maxLogFileSize) {
        final now = DateTime.now().toLocal().toIso8601String();
        final logDirName = path.join(dir.path, "cylonix-logs");
        final logDir = await Directory(logDirName).create();
        logger.d("log dir ${logDir.path}, date $now");
        final entities = await logDir.list().toList();
        for (var entity in entities) {
          if (entity is File) {
            final lastMod = await entity.lastModified();
            logger.d("log file ${entity.path} last modified $lastMod");
            if (DateTime.now().difference(lastMod).inDays > maxLogFileDays) {
              logger.d("delete log file ${entity.path}");
              entity.delete();
            }
          }
        }
        final nowFixed = now.replaceAll(":", "_");
        final newName = path.join(logDir.path, "cylonix_log_$nowFixed.txt");
        logger.i("Moving current log file to $newName");
        await current.rename(newName);
      }
    } catch (e) {
      logger.e("log file rotation failed: $e");
    }
  }

  static List<String> getAppBufferLogs() {
    var logs = <String>[];
    for (var event in _appOutput.buffer) {
      logs.addAll(event.lines);
    }
    return logs;
  }

  static void setLogConsoleLocalTexts(BuildContext context) {
    log_console.LogConsole.setLocalTexts();
  }

  static Future<void> init() async {
    if (_initDone) {
      logger.w("AppLog already initialized, skipping init");
      return;
    }
    _initDone = true;
    log_console.LogConsole.init(bufferSize: _defaultLogBufferSize);
    log_console.LogConsole.setLogOutput(_appOutput);

    if (Platform.isWindows) {
      // Use %ProgramData%\Cylonix\Logs\
      final programData =
          Platform.environment['ProgramData'] ?? r'C:\ProgramData';
      final logDirPath = path.join(programData, 'Cylonix', 'Logs');
      _logDirectory = await Directory(logDirPath).create(recursive: true);
      logger.d("Using log directory: ${_logDirectory.path}");
    } else {
      _logDirectory = await getApplicationSupportDirectory();
    }
    _logFile = File(path.join(_logDirectory.path, "cylonix-log.txt"));
    await _rotateLogFile(_logDirectory);
    _startLoggerPeriodical();

    final fileOutput = FileOutput(file: _logFile);
    final multiOutputWithFile = MultiOutput([
      fileOutput,
      ConsoleOutput(),
      _appOutput,
    ]);
    const bool isDebug = bool.fromEnvironment('DEBUG');
    const bool verbose = bool.fromEnvironment('VERBOSE', defaultValue: true);
    if (isDebug || verbose) {
      logger.d("Debug or verbose mode");
      logger = Logger(
        filter: ProductionFilter(),
        printer: _printer,
        level: Level.debug,
        output: multiOutputWithFile,
      );
    } else {
      logger.d("Production mode");
      logger = Logger(
        filter: ProductionFilter(),
        printer: _printer,
        level: Level.debug, // use debug level for production for now.
        output: multiOutputWithFile,
      );
    }
    logger.d("init done");
  }
}
