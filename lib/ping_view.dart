import 'dart:math' show max;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'models/ipn.dart';
import 'utils/utils.dart';
import 'viewmodels/peer_details.dart' as pd;
import 'viewmodels/ping_view.dart';
import 'widgets/adaptive_widgets.dart';

class PingView extends ConsumerWidget {
  const PingView({super.key, required this.peer});
  final Node peer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pingStateProvider);

    return state.when(
      loading: () => isApple()
          ? const CupertinoActivityIndicator()
          : const CircularProgressIndicator(),
      error: (error, stack) => Text(
        'Error: $error',
        style: isApple()
            ? CupertinoTheme.of(context).textTheme.textStyle
            : Theme.of(context).textTheme.bodyMedium,
      ),
      data: (data) => isApple()
          ? _buildCupertinoScaffold(context, ref, data)
          : _buildMaterialScaffold(context, ref, data),
    );
  }

  Widget _buildCupertinoScaffold(
      BuildContext context, WidgetRef ref, PingState data) {
    final isPinging = ref.watch(isPingingProvider);
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        automaticallyImplyLeading: false,
        transitionBetweenRoutes: false,
        middle: Text('Ping ${peer.computedName}'),
        trailing: _actionButton(isPinging, ref, context),
      ),
      child: SafeArea(
        child: _buildPingContent(context, data, true),
      ),
    );
  }

  Widget _buildMaterialScaffold(
      BuildContext context, WidgetRef ref, PingState data) {
    final isPinging = ref.watch(isPingingProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Ping ${peer.computedName}'),
        actions: [
          _actionButton(isPinging, ref, context),
        ],
      ),
      body: _buildPingContent(context, data, false),
    );
  }

  Widget _actionButton(bool isPinging, WidgetRef ref, BuildContext context) {
    return AdaptiveButton(
      textButton: true,
      small: true,
      child: isPinging ? const Text("Stop") : const Text("Close"),
      onPressed: () {
        if (isPinging) {
          ref.read(pingStateProvider.notifier).stopPing();
        } else {
          ref.read(pd.peerDetailsViewModelProvider.notifier).close();
          Navigator.of(context).pop();
        }
      },
    );
  }

  Widget _buildPingContent(
      BuildContext context, PingState data, bool isCupertino) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.errorMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCupertino
                    ? CupertinoColors.systemRed.withOpacity(0.1)
                    : Theme.of(context).colorScheme.error.withValues(
                          alpha: 0.1,
                        ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                data.errorMessage!,
                style: TextStyle(
                  color: isCupertino
                      ? CupertinoColors.systemRed
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 16),
          _buildInfoRow(
            isCupertino,
            'Connection',
            data.connectionMode,
            context,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            isCupertino,
            'Last Latency',
            data.lastLatencyValue,
            context,
          ),
          if (data.latencyValues.isNotEmpty) ...[
            const SizedBox(height: 24),
            Expanded(
              child:
                  _buildLatencyChart(data.latencyValues, isCupertino, context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      bool isCupertino, String label, String value, BuildContext context) {
    final textStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.textStyle
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textStyle),
        Text(value, style: textStyle),
      ],
    );
  }

  Widget _buildLatencyChart(
      List<double> values, bool isCupertino, BuildContext context) {
    final lineColor = isCupertino
        ? CupertinoTheme.of(context).primaryColor
        : Theme.of(context).colorScheme.primary;

    // Find max value for scaling
    final maxY = values.isEmpty
        ? 10.0
        : (values.reduce(max) * 125 / 100).floor().toDouble();

    return LineChart(
      LineChartData(
        backgroundColor: isApple()
            ? CupertinoColors.systemBackground.resolveFrom(context)
            : Theme.of(context).colorScheme.surface,
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false, // Hide vertical grid lines
          horizontalInterval:
              maxY / 5, // Show 5 horizontal lines (20% intervals)
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: lineColor.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),
          rightTitles:
              const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: maxY / 5, // Show labels at 20% intervals
              getTitlesWidget: (value, meta) {
                // Only show labels at 20% intervals
                if (value % (maxY / 5) != 0) return const SizedBox.shrink();
                return Text(
                  '${value.toInt()} ms',
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: lineColor.withValues(alpha: 0.2)),
            bottom: BorderSide(color: lineColor.withValues(alpha: 0.2)),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: values
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList(),
            color: lineColor,
            dotData: const FlDotData(show: true),
            isCurved: true,
            preventCurveOverShooting: true,
            curveSmoothness: 0.4,
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withValues(alpha: 0.1),
              spotsLine: const BarAreaSpotsLine(show: false),
            ),
          ),
        ],
      ),
    );
  }
}
