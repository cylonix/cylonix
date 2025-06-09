import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_logger/flutter_logger.dart';
import 'package:logger/logger.dart';
import '../models/log_file.dart';
import '../utils/logger.dart' as logger;
import '../utils/utils.dart';
import 'adaptive_widgets.dart';

class UILogsWidget extends StatelessWidget {
  final VoidCallback? onNavigateBack;
  final Function(Widget)? onNavigateToLogConsole;
  const UILogsWidget({
    super.key,
    this.onNavigateBack,
    this.onNavigateToLogConsole,
  });
  static final _logger = logger.Logger(tag: "UILogsWidget");

  @override
  Widget build(BuildContext context) {
    return AdaptiveListTile.notched(
      title: const Text("View App Logs"),
      trailing: const AdaptiveListTileChevron(),
      onTap: () => _showLogConsole(context),
    );
  }

  LogFile _logFile(List<OutputEvent> logs) {
    return LogFile(
      logs: logs.map((e) => e.lines).expand((x) => x).toList(),
      name: "cylonix_app_logs",
    );
  }

  Future<String?> _save(List<OutputEvent> logs) async {
    try {
      final path = await _logFile(logs).save();
      _logger.i("Logs saved to: $path");
      return path;
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

  Widget _buildLogConsole(BuildContext context) {
    return LogConsole(
      backButton: isApple() && onNavigateBack != null
          ? AppleBackButton(
              onPressed: onNavigateBack,
            )
          : null,
      showRefreshButton: true,
      dark: Theme.of(context).brightness == Brightness.dark,
      saveFile: _save,
      shareFile: (logs) => _share(context, logs),
      useAnsiParser: false,
    );
  }

  void _showLogConsole(BuildContext context) async {
    LogConsole.init();
    if (onNavigateToLogConsole != null) {
      onNavigateToLogConsole!(_buildLogConsole(context));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _buildLogConsole(_),
      ),
    );
  }
}
