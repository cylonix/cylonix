// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/exit_node.dart';
import 'providers/ipn.dart';
import 'utils/utils.dart';
import 'viewmodels/state_notifier.dart';
import 'widgets/adaptive_widgets.dart';
import 'widgets/alert_dialog_widget.dart';

class RunExitNodeView extends ConsumerWidget {
  final VoidCallback onNavigateBackToExitNodes;

  const RunExitNodeView({
    super.key,
    required this.onNavigateBackToExitNodes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exitNodePickerProvider);
    final loading = ref.watch(exitNodeLoadingProvider);
    final selfNode = ref.watch(selfNodeProvider);
    final isAndroidTV = ref.watch(isAndroidTVProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Run as Exit Node'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onNavigateBackToExitNodes,
        ),
      ),
      body: LoadingIndicator(
        isLoading: loading,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 16,
              children: [
                RunExitNodeGraphic(os: selfNode?.hostinfo?.os ?? 'unknown'),
                const SizedBox(height: 24),
                if (state.isRunningExitNode) ...[
                  Text(
                    'Run Exit Node',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Text(
                    'Your device is acting as an exit node for your network.',
                  ),
                ] else ...[
                  Text(
                    'Run this device as an exit node',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Text(
                    'Allow other devices to route their traffic '
                    'through this device.',
                    textAlign: TextAlign.center,
                  ),
                ],
                if (isMobile() && !isAndroidTV) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Caution: Running as an exit node may consume additional '
                    'battery and data. Make sure you understand the '
                    'implications.',
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                AdaptiveButton(
                  filled: true,
                  autofocus: true,
                  onPressed: () async {
                    try {
                      await ref
                          .read(exitNodePickerProvider.notifier)
                          .setRunAsExitNode(!state.isRunningExitNode);
                      if (context.mounted) {
                        await showAlertDialog(
                          context,
                          'Success',
                          "Exit node status updated successfully. "
                              "Network administrator may need to "
                              "approve your exit node request if applicable.",
                          showSuccessIcon: true,
                        );
                      }
                      onNavigateBackToExitNodes();
                    } catch (e) {
                      showAlertDialog(
                        context,
                        'Failed to toggle exit node',
                        '$e',
                      );
                    }
                  },
                  child: Text(
                    state.isRunningExitNode
                        ? 'Stop Running Exit Node'
                        : 'Start Running Exit Node',
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RunExitNodeGraphic extends StatelessWidget {
  final String os;
  const RunExitNodeGraphic({super.key, required this.os});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 32,
        children: [
          Icon(
            Icons.devices,
            size: 36,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          Icon(
            Icons.arrow_forward,
            size: 24,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          Icon(
            osIcon(os),
            size: 36,
            color: Colors.green,
          ),
          Icon(
            Icons.arrow_forward,
            size: 24,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          Icon(
            Icons.public,
            size: 36,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
    );
  }
}
