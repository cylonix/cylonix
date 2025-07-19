import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ipn.dart';
import '../providers/exit_node.dart';
import '../providers/ipn.dart';
import '../utils/utils.dart';
import 'adaptive_widgets.dart';

class ExitNodeStatusWidget extends ConsumerWidget {
  final VoidCallback onNavigate;

  const ExitNodeStatusWidget({
    Key? key,
    required this.onNavigate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodeState = ref.watch(nodeStateProvider);
    final exitNodeID = ref.watch(exitNodeIDProvider);
    final exitNode = ref.watch(exitNodeProvider);
    final managedByOrg = ref.watch(managedByOrganizationProvider);
    final isRunningExitNode =
        ref.watch(exitNodePickerProvider).isRunningExitNode;

    return AdaptiveListSection.insetGrouped(
      children: [
        if (nodeState == NodeState.offlineMdm)
          isApple()
              ? _buildCupertinoMdmWarning(context, managedByOrg)
              : _buildMdmWarning(context, managedByOrg),
        _buildExitNodeTile(
          context,
          nodeState,
          exitNode,
          exitNodeID,
          isRunningExitNode,
        ),
      ],
    );
  }

  Widget _buildMdmWarning(BuildContext context, bool managedByOrg) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exit Node Unavailable',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                  if (managedByOrg)
                    Text(
                      'Contact your organization administrator',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCupertinoMdmWarning(BuildContext context, bool managedByOrg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: CupertinoColors.systemRed,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Exit Node Unavailable',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.systemRed,
                  ),
                ),
                if (managedByOrg)
                  const Text(
                    'Contact your organization administrator',
                    style: TextStyle(
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSubtitle(
    BuildContext context,
    NodeState nodeState,
    Node? exitNode,
    String? exitNodeID,
    bool isRunningExitNode,
  ) {
    final bool isOffline = nodeState == NodeState.activeNotRunning;
    var nodeName = exitNode?.name ?? "Not connected";
    if (exitNodeID != null && exitNode == null) {
      nodeName = "$exitNodeID (Offline! All Traffic is dropped)";
    }
    return Text(
      nodeState == NodeState.none
          ? "None${isRunningExitNode ? ' (self is running as exit node)' : ''}"
          : nodeName,
      style: TextStyle(
        color: nodeState == NodeState.none
            ? null
            : isOffline
                ? isApple()
                    ? CupertinoColors.systemRed
                    : Theme.of(context).colorScheme.error
                : null,
      ),
    );
  }

  Widget _buildExitNodeTile(
    BuildContext context,
    NodeState nodeState,
    Node? exitNode,
    String? exitNodeID,
    bool isRunningExitNode,
  ) {
    final bool isActive = nodeState == NodeState.activeAndRunning;
    final bool isNotConnected = exitNode == null && exitNodeID != null;

    return AdaptiveListTile.notched(
      title: const Text('Exit Node'),
      subtitle: _getSubtitle(
        context,
        nodeState,
        exitNode,
        exitNodeID,
        isRunningExitNode,
      ),
      leading: nodeState == NodeState.none
          ? null
          : isApple()
              ? Icon(
                  isActive
                      ? CupertinoIcons.arrow_up_right_circle_fill
                      : CupertinoIcons.arrow_up_right_circle,
                  color: isActive
                      ? CupertinoColors.activeBlue.resolveFrom(context)
                      : isNotConnected
                          ? CupertinoColors.systemRed.resolveFrom(context)
                          : CupertinoColors.systemGrey.resolveFrom(context),
                )
              : Icon(
                  isActive ? Icons.exit_to_app : Icons.exit_to_app_outlined,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : isNotConnected
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).disabledColor,
                ),
      trailing: const AdaptiveListTileChevron(),
      onTap: onNavigate,
    );
  }
}
