import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/ipn.dart';
import 'providers/exit_node.dart';
import 'utils/utils.dart';
import 'widgets/adaptive_widgets.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(exitNodeLoadingProvider);
    final model = ref.watch(exitNodePickerProvider);

    if (isLoading) {
      return isApple()
          ? const CupertinoActivityIndicator()
          : const CircularProgressIndicator();
    }

    return isApple()
        ? _buildCupertinoView(context, ref, model)
        : _buildMaterialView(context, ref, model);
  }

  Widget _buildCupertinoView(
      BuildContext context, WidgetRef ref, ExitNodeState model) {
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
      child: _buildContent(context, ref, model, true),
    );
  }

  Widget _buildMaterialView(
      BuildContext context, WidgetRef ref, ExitNodeState model) {
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
      body: _buildContent(context, ref, model, false),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, ExitNodeState model,
      bool isCupertino) {
    var children = [
      if (model.forcedExitNodeId != null)
        _buildManagedByOrgText(
            context, model.managedByOrganization, isCupertino)
      else
        ExitNodeItem(
          node: ExitNode(
            label: 'None',
            online: true,
            selected: !model.anyActive,
          ),
          onTap: () =>
              ref.read(exitNodePickerProvider.notifier).setExitNode(null),
          isCupertino: isCupertino,
        ),
      if (model.showRunAsExitNode)
        _buildRunAsExitNodeItem(context, ref, model, isCupertino),
      ...model.tailnetExitNodes.map(
        (node) => ExitNodeItem(
          node: node,
          onTap: () =>
              ref.read(exitNodePickerProvider.notifier).setExitNode(node),
          isCupertino: isCupertino,
        ),
      ),
      if (model.mullvadExitNodeCount > 0) ...[
        _buildMullvadItem(context, model, isCupertino),
      ] else if (model.shouldShowMullvadInfo) ...[
        _buildMullvadInfoItem(context, isCupertino),
      ],
      if (!model.isLanAccessHidden) ...[
        _buildAllowLanAccess(context, ref, model, isCupertino),
      ],
    ];
    children = [
      AdaptiveListSection.insetGrouped(
        children: children,
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.topCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          children: children,
        ),
      ),
    );
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
      title: const Text('Run as exit node'),
      trailing: const CupertinoListTileChevron(),
      onTap: onNavigateToRunAsExitNode,
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

  Widget _buildAllowLanAccess(BuildContext context, WidgetRef ref,
      ExitNodeState model, bool isCupertino) {
    if (isCupertino) {
      return AdaptiveListTile.notched(
        leading: const Icon(CupertinoIcons.wifi),
        title: const Text('Allow LAN Access'),
        trailing: CupertinoSwitch(
          value: model.allowLANAccess,
          onChanged: (value) =>
              ref.read(exitNodePickerProvider.notifier).toggleAllowLANAccess(),
        ),
      );
    }

    return SwitchListTile(
      title: const Text('Allow LAN Access'),
      value: model.allowLANAccess,
      onChanged: (value) =>
          ref.read(exitNodePickerProvider.notifier).toggleAllowLANAccess(),
    );
  }
}

class ExitNodeItem extends StatelessWidget {
  const ExitNodeItem({
    super.key,
    required this.node,
    required this.onTap,
    required this.isCupertino,
  });

  final ExitNode node;
  final VoidCallback onTap;
  final bool isCupertino;

  @override
  Widget build(BuildContext context) {
    final enabled = node.online && !node.isRunningExitNode;

    return AdaptiveListTile.notched(
      leading: CircleAvatar(
        backgroundColor: node.online
            ? isCupertino
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
      subtitle: !node.online ? const Text('Offline') : null,
      trailing: node.selected
          ? Padding(
              padding: const EdgeInsetsGeometry.only(right: 4),
              child: Icon(
                isCupertino ? CupertinoIcons.check_mark_circled : Icons.check,
                size: 32,
              ),
            )
          : null,
      onTap: enabled ? onTap : null,
    );
  }
}
