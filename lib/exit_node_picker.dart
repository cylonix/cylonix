// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/ipn.dart';
import 'providers/exit_node.dart';
import 'providers/ipn.dart';
import 'utils/logger.dart';
import 'utils/utils.dart';
import 'widgets/adaptive_widgets.dart';
import 'widgets/alert_dialog_widget.dart';

class ExitNodePicker extends ConsumerWidget {
  const ExitNodePicker({
    super.key,
    this.onNavigateBackHome,
    this.onNavigateToMullvad,
    required this.onNavigateToRunAsExitNode,
  });

  final VoidCallback? onNavigateBackHome;
  final VoidCallback? onNavigateToMullvad;
  final VoidCallback onNavigateToRunAsExitNode;
  static final _logger = Logger(tag: "ExitNodePicker");

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(exitNodePickerProvider);

    return isApple()
        ? _buildCupertinoView(context, ref, model)
        : _buildMaterialView(context, ref, model);
  }

  Widget _buildCupertinoView(
      BuildContext context, WidgetRef ref, ExitNodeState model) {
    final isLoading = ref.watch(exitNodeLoadingProvider);
    return CupertinoPageScaffold(
      backgroundColor: appleScaffoldBackgroundColor(context),
      navigationBar: CupertinoNavigationBar(
        automaticBackgroundVisibility: false,
        backgroundColor: Colors.transparent,
        middle: const Text('Choose Exit Node'),
        leading: onNavigateBackHome == null
            ? null
            : AppleBackButton(
                onPressed: onNavigateBackHome,
              ),
      ),
      child: LoadingIndicator(
        isLoading: isLoading,
        child: _buildContent(context, ref, model, true),
      ),
    );
  }

  Widget _buildMaterialView(
      BuildContext context, WidgetRef ref, ExitNodeState model) {
    final isLoading = ref.watch(exitNodeLoadingProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Exit Node'),
        leading: onNavigateBackHome == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onNavigateBackHome,
              ),
      ),
      body: LoadingIndicator(
        isLoading: isLoading,
        child: _buildContent(context, ref, model, false),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, ExitNodeState model,
      bool isCupertino) {
    final exitNodeID = ref.watch(exitNodeIDProvider);
    final netmap = ref.watch(netmapProvider);
    final exitNodeInNetmap = exitNodeID != null &&
        netmap?.peers?.any((peer) => peer.stableID == exitNodeID) == true;
    final children = [
      AdaptiveListSection.insetGrouped(
        header: const Text("Exit Node Settings"),
        footer: const Text(
          "Choose an exit node to route your traffic through.",
        ),
        children: [
          if (model.forcedExitNodeID != null)
            _buildManagedByOrgText(
              context,
              model.managedByOrganization,
              isCupertino,
            )
          else
            ExitNodeItem(
              node: ExitNode(
                label: 'None',
                online: true,
                selected: !model.anyActive && exitNodeID == null,
              ),
              onTap: () => _setExitNode(context, ref, null),
            ),
          if (!exitNodeInNetmap && exitNodeID != null)
            ExitNodeItem(
              node: ExitNode(
                id: exitNodeID,
                label: "$exitNodeID (Not connected! All Traffic is dropped)",
                online: false,
                selected: true,
              ),
            ),
          ...model.tailnetExitNodes.map(
            (node) => ExitNodeItem(
              node: node,
              onTap: () => _setExitNode(context, ref, node),
            ),
          ),
          if (model.mullvadExitNodeCount > 0) ...[
            _buildMullvadItem(context, model, isCupertino),
          ] else if (model.shouldShowMullvadInfo) ...[
            _buildMullvadInfoItem(context, isCupertino),
          ],
          if (!model.isLanAccessHidden) ...[
            _buildAllowLanAccess(context, ref, model),
          ],
        ],
      ),
      if (model.showRunAsExitNode)
        AdaptiveListSection.insetGrouped(
          children: [
            _buildRunAsExitNodeItem(context, ref, model, isCupertino),
          ],
        ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      alignment: Alignment.topCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          children: children,
        ),
      ),
    );
  }

  void _setExitNode(BuildContext context, WidgetRef ref, ExitNode? node) async {
    try {
      await ref.read(exitNodePickerProvider.notifier).setExitNode(node);
    } catch (e) {
      _logger.e("Failed to set exit node: $e");
      if (context.mounted) {
        await showAlertDialog(
          context,
          'Error',
          'Failed to set exit node: $e',
        );
      }
    }
  }

  Widget _buildManagedByOrgText(
      BuildContext context, String? organization, bool isCupertino) {
    final text = organization != null
        ? 'Exit node settings are managed by $organization'
        : 'Exit node settings are managed by your organization';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        text,
        style: isCupertino
            ? CupertinoTheme.of(context).textTheme.textStyle
            : Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildRunAsExitNodeItem(BuildContext context, WidgetRef ref,
      ExitNodeState model, bool isCupertino) {
    final widget = AdaptiveListTile(
      leading: model.isRunningExitNodePendingApproval
          ? Icon(
              isApple()
                  ? CupertinoIcons.exclamationmark_triangle
                  : Icons.pending,
              color: Colors.orange,
            )
          : null,
      title: const Text('Run as exit node'),
      subtitle: model.isRunningExitNode
          ? null
          : Text(
              model.isRunningExitNodePendingApproval
                  ? 'Pending approval from your network administrator'
                  : 'Allow this device to act as an exit node for your network',
            ),
      trailing: model.isRunningExitNodePendingApproval
          ? TextButton(
              onPressed: () => _setRunAsExitNode(context, ref, false),
              child: const Text('Cancel'),
            )
          : const CupertinoListTileChevron(),
      onTap: model.isRunningExitNodePendingApproval
          ? null
          : onNavigateToRunAsExitNode,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget,
        if (model.isRunningExitNode)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              'This device is running as an exit node',
              style: TextStyle(
                color: isCupertino
                    ? CupertinoColors.systemGrey
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
      ],
    );
  }

  void _setRunAsExitNode(BuildContext context, WidgetRef ref, bool isOn) async {
    try {
      await ref.read(exitNodePickerProvider.notifier).setRunAsExitNode(isOn);
    } catch (e) {
      _logger.e("Failed to set run as exit node: $e");
      if (context.mounted) {
        await showAlertDialog(
          context,
          'Error',
          'Failed to set run as exit node: $e',
        );
      }
    }
  }

  Widget _buildMullvadItem(
      BuildContext context, ExitNodeState model, bool isCupertino) {
    if (isCupertino) {
      return CupertinoListTile(
        title: const Text('Mullvad Exit Nodes'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${model.mullvadExitNodeCount} nodes',
              style: const TextStyle(color: CupertinoColors.systemGrey),
            ),
            const CupertinoListTileChevron(),
          ],
        ),
        onTap: onNavigateToMullvad,
      );
    }

    return ListTile(
      title: const Text('Mullvad Exit Nodes'),
      subtitle: Text('${model.mullvadExitNodeCount} nodes'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onNavigateToMullvad,
    );
  }

  Widget _buildMullvadInfoItem(BuildContext context, bool isCupertino) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mullvad Exit Nodes',
          style: isCupertino
              ? CupertinoTheme.of(context).textTheme.textStyle
              : Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Connect through Mullvad\'s secure network for enhanced privacy.',
          style: TextStyle(
            color: isCupertino
                ? CupertinoColors.systemGrey
                : Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: content,
    );
  }

  Widget _buildAllowLanAccess(
      BuildContext context, WidgetRef ref, ExitNodeState model) {
    return AdaptiveSwitchListTile(
      leading: const Icon(CupertinoIcons.wifi),
      title: const Text('Allow LAN Access'),
      subtitle: const Text(
        'Allow access to your local network why using an exit node',
      ),
      value: model.allowLANAccess,
      onChanged: (value) => _toggleAllowLANAccess(context, ref),
    );
  }

  void _toggleAllowLANAccess(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(exitNodePickerProvider.notifier).toggleAllowLANAccess();
    } catch (e) {
      _logger.e("Failed to toggle LAN access: $e");
      if (context.mounted) {
        await showAlertDialog(
          context,
          'Error',
          'Failed to toggle LAN access: $e',
        );
      }
    }
  }
}

class ExitNodeItem extends StatelessWidget {
  const ExitNodeItem({
    super.key,
    required this.node,
    this.onTap,
  });

  final ExitNode node;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = node.online;

    return AdaptiveListTile.notched(
      leading: CircleAvatar(
        backgroundColor: node.online
            ? isApple()
                ? CupertinoColors.activeGreen.resolveFrom(context)
                : Colors.green
            : null,
        child: Text(
          (node.city.isEmpty ? node.label : node.city)
              .substring(0, 1)
              .capitalize(),
        ),
      ),
      title: Text(node.city.isEmpty ? node.label : node.city),
      subtitle: Text(
        'Priority: ${node.priority} '
        '${node.city.isEmpty ? '' : node.label}',
      ),
      trailing: node.selected
          ? Padding(
              padding: const EdgeInsetsGeometry.only(right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  if (!node.online) const Text('Offline'),
                  Icon(
                    isApple() ? CupertinoIcons.check_mark_circled : Icons.check,
                    size: 32,
                  ),
                ],
              ),
            )
          : node.online
              ? null
              : const Padding(
                  padding: EdgeInsetsGeometry.only(right: 4),
                  child: Text('Offline'),
                ),
      onTap: enabled ? onTap : null,
    );
  }
}
