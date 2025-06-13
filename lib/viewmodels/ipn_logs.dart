import 'dart:collection';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../providers/ipn.dart';
import '../services/ipn.dart';
import '../utils/logger.dart' as logger;

class IpnLogsViewModel extends StateNotifier<AsyncValue<List<String>>> {
  final IpnService _ipnService;
  final _logger = logger.Logger(tag: "IpnLogsViewModel");
  final timestampRegex =
      RegExp(r'^(\[[\d\-]+T[\d:\.]+Z\]|\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2})');

  IpnLogsViewModel(this._ipnService) : super(const AsyncValue.data([]));

  Future<List<String>> fetchLogs() async {
    try {
      state = const AsyncValue.loading();
      final logs = await _ipnService.getLogs();
      state = AsyncValue.data(logs);
      return logs;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return [''];
    }
  }

  Future<ListQueue<OutputEvent>> getLogs() async {
    ListQueue<OutputEvent> events = ListQueue();

    try {
      var logs = await fetchLogs();
      _logger.d("Logs ${logs.length} lines.");
      if (logs.length > 5000) {
        logs = logs.sublist(logs.length - 5000);
      }

      LogEvent? currentLogEvent;
      List<String> currentLines = [];

      for (var line in logs) {
        line = line.trim();
        if (line.isEmpty) continue;

        final timestampMatch = timestampRegex.firstMatch(line);

        if (Platform.isLinux || timestampMatch != null) {
          // New log entry starts
          if (currentLogEvent != null) {
            // Add previous log entry
            events.add(OutputEvent(currentLogEvent, currentLines));
            currentLines = [];
          }

          // Extract timestamp
          final timestamp = timestampMatch?.group(1)!;
          //line = line.substring(timestampMatch.end).trim();

          // Determine log level and clean up line.
          // Multiple tags can be present, so we check for each one
          // with higher priority for more severe levels.
          var level = Level.info;
          if (line.contains("[FATAL]")) {
            level = Level.fatal;
          } else if (line.contains("[ERROR]")) {
            level = Level.error;
          } else if (line.contains("[WARNING]")) {
            level = Level.warning;
          } else if (line.contains("INFO")) {
            level = Level.info;
          } else if (line.contains("[DEBUG]")) {
            level = Level.debug;
          }
          // Create new log event
          currentLogEvent = LogEvent(
            level,
            "",
            time: timestamp != null ? DateTime.parse(timestamp) : null,
          );
          currentLines.add(line.trim());
        } else if (currentLogEvent != null) {
          // Continue previous log entry
          currentLines.add(line);
        }
      }

      // Add the last log entry
      if (currentLogEvent != null && currentLines.isNotEmpty) {
        events.add(OutputEvent(currentLogEvent, currentLines));
      }
    } catch (e) {
      _logger.e("Failed to get logs: $e");
    }
    _logger.d("Logs ${events.length} events.");
    return events;
  }
}

final ipnLogsProvider =
    StateNotifierProvider<IpnLogsViewModel, AsyncValue<List<String>>>((ref) {
  return IpnLogsViewModel(ref.watch(ipnServiceProvider));
});
