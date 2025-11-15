import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'viewmodels/split_tunnel_view.dart';
import 'widgets/adaptive_widgets.dart';
import 'utils/utils.dart';

class SplitTunnelAppPickerView extends ConsumerWidget {
  final VoidCallback onBackToSettings;

  const SplitTunnelAppPickerView({
    super.key,
    required this.onBackToSettings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Tunneling'),
        leading: AdaptiveButton(
          iconButton: true,
          child: Icon(isApple() ? CupertinoIcons.back : Icons.arrow_back),
          onPressed: onBackToSettings,
        ),
      ),
      body: Container(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _buildContext(context, ref),
        ),
      ),
    );
  }

  Widget _buildContext(BuildContext context, WidgetRef ref) {
    final state = ref.watch(splitTunnelProvider);
    final isLoading = ref.watch(splitTunnelLoadingProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdaptiveListTile(
          title: Text(
            'Selected apps will access the internet directly '
            'without using Cylonix',
          ),
        ),
        if (state.mdmExcludedPackages?.isNotEmpty ?? false)
          const ListTile(
            title: Text('Certain apps are not routed via Cylonix'),
          )
        else if (state.mdmIncludedPackages?.isNotEmpty ?? false)
          const ListTile(
            title: Text('Only specific apps are routed via Cylonix'),
          )
        else
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${state.excludedPackageNames.length} Excluded Apps',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
        const Divider(),
        Expanded(
          child: LoadingIndicator(
            isLoading: isLoading,
            child: _buildAppList(context, ref, state),
          ),
        ),
      ],
    );
  }

  Widget _buildAppList(
      BuildContext context, WidgetRef ref, SplitTunnelState state) {
    return ListView.builder(
      itemCount: state.installedApps.length,
      itemBuilder: (context, index) {
        final app = state.installedApps[index];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAppTile(context, ref, state, app),
            const Divider(),
          ],
        );
      },
    );
  }

  Widget _buildAppTile(
    BuildContext context,
    WidgetRef ref,
    SplitTunnelState state,
    InstalledApp app,
  ) {
    final isExcluded = state.excludedPackageNames.contains(app.packageName);
    final isDisabled =
        state.builtInDisallowedPackageNames.contains(app.packageName);
    return ListTile(
      leading: app.icon != null
          ? Image.memory(
              app.icon!,
              width: 40,
              height: 40,
            )
          : const Icon(Icons.android),
      title: Text(
        app.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        app.packageName,
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 12,
        ),
      ),
      trailing: AdaptiveButton(
        iconButton: true,
        onPressed: () => {},
        child: Checkbox(
          value: isExcluded,
          onChanged: isDisabled
              ? null
              : (checked) {
                  if (checked ?? false) {
                    ref
                        .read(splitTunnelProvider.notifier)
                        .exclude(app.packageName);
                  } else {
                    ref
                        .read(splitTunnelProvider.notifier)
                        .unexclude(app.packageName);
                  }
                },
        ),
      ),
    );
  }
}
