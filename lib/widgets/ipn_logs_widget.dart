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

  Widget _buildLogConsole(
    BuildContext context,
    WidgetRef ref,
    ListQueue<OutputEvent> events,
  ) {
    final viewModel = ref.read(ipnLogsProvider.notifier);
    return LogConsole(
      backButton: onNavigateBack != null
          ? AdaptiveBackButton(
              onPressed: onNavigateBack,
            )
          : null,
      events: events,
      getLogOutputEvents: viewModel.getLogs,
      showRefreshButton: true,
      dark: Theme.of(context).brightness == Brightness.dark,
      saveFile: _save,
      shareFile: Platform.isLinux ? null : (logs) => _share(context, logs),
      useAnsiParser: false,
    );
  }

  void _showLogConsole(BuildContext context, WidgetRef ref) async {
    final viewModel = ref.read(ipnLogsProvider.notifier);
    final events = await viewModel.getLogs();
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
