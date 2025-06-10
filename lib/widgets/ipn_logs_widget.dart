import 'dart:collection';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_logger/flutter_logger.dart';
import 'package:logger/logger.dart';
import 'adaptive_widgets.dart';
import '../models/log_file.dart';
import '../utils/logger.dart' as logger;
import '../utils/utils.dart';
import '../viewmodels/ipn_logs.dart';

class IpnLogsWidget extends ConsumerWidget {
  final VoidCallback? onNavigateBack;
  final Function(Widget)? onNavigateToLogConsole;
  const IpnLogsWidget({
    super.key,
    this.onNavigateBack,
    this.onNavigateToLogConsole,
  });
  static final _logger = logger.Logger(tag: "IpnLogsWidget");

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(ipnLogsProvider);
    return logs.when(
      data: (_) => AdaptiveListTile.notched(
        title: Text(isApple()
            ? "View Network Extension Logs"
            : "View Network Service Logs"),
        trailing: const AdaptiveListTileChevron(),
        onTap: () => _showLogConsole(context, ref),
      ),
      loading: () => AdaptiveListTile.notched(
        title: Text(isApple()
            ? "Loading Network Extension Logs"
            : "Loading Network Service Logs"),
        trailing: const AdaptiveLoadingWidget(),
      ),
      error: (error, stackTrace) => AdaptiveListTile.notched(
        title: Text(isApple()
            ? "Error Loading Network Extension Logs"
            : "Error Loading Network Service Logs"),
        subtitle: Text(
          "$error",
          style: const TextStyle(color: Colors.red),
        ),
        trailing: const Icon(CupertinoIcons.refresh_circled),
        onTap: () => _showLogConsole(context, ref),
      ),
    );
  }

  LogFile _logFile(List<OutputEvent> logs) {
    return LogFile(
      logs: logs.map((e) => e.lines).expand((x) => x).toList(),
      name: "ipn_logs",
    );
  }

  Future<String?> _save(List<OutputEvent> logs) async {
    try {
      return await _logFile(logs).save();
    } catch (e) {
      _logger.e("Failed to save logs: $e");
      rethrow;
    }
  }

  Future<void> _share(BuildContext context, List<OutputEvent> logs) async {
    try {
      await _logFile(logs).share(context);
    } catch (e) {
      _logger.e("Failed to share logs: $e");
      rethrow;
    }
  }

  Future<ListQueue<OutputEvent>> _getLogs(WidgetRef ref) async {
    final viewModel = ref.read(ipnLogsProvider.notifier);
    ListQueue<OutputEvent> events = ListQueue();
    final timestampRegex = RegExp(
        r'^(\[[\d\-]+T[\d:\.]+Z\]|\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2})');

    try {
      var logs = await viewModel.fetchLogs();
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

  Widget _buildLogConsole(
    BuildContext context,
    WidgetRef ref,
    ListQueue<OutputEvent> events,
  ) {
    return LogConsole(
      backButton: isApple() && onNavigateBack != null
          ? AppleBackButton(
              onPressed: onNavigateBack,
            )
          : null,
      events: events,
      getLogOutputEvents: () => _getLogs(ref),
      showRefreshButton: true,
      dark: Theme.of(context).brightness == Brightness.dark,
      saveFile: _save,
      shareFile: (logs) => _share(context, logs),
      useAnsiParser: false,
    );
  }

  void _showLogConsole(BuildContext context, WidgetRef ref) async {
    final events = await _getLogs(ref);
    LogConsole.init();
    if (onNavigateToLogConsole != null) {
      onNavigateToLogConsole!(_buildLogConsole(context, ref, events));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _buildLogConsole(_, ref, events),
      ),
    );
  }
}
