import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/ipn.dart';
import 'providers/ipn.dart';
import 'utils/utils.dart';
import 'viewmodels/state_notifier.dart';
import 'widgets/adaptive_widgets.dart';

class HealthView extends ConsumerWidget {
  final VoidCallback? onNavigateBack;

  const HealthView({
    super.key,
    this.onNavigateBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isApple()) {
      return _buildApple(context, ref);
    }
    return _buildMaterial(context, ref);
  }

  Widget _buildApple(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      backgroundColor:
          CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
        context,
      ),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        automaticBackgroundVisibility: false,
        transitionBetweenRoutes: false,
        leading: onNavigateBack != null
            ? AppleBackButton(
                onPressed: onNavigateBack,
              )
            : null,
        middle: const Text('Health Status'),
      ),
      child: const Center(child: HealthStateWidget()),
    );
  }

  Widget _buildMaterial(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: onNavigateBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onNavigateBack,
              )
            : null,
        title: const Text('Health Status'),
      ),
      body: const Center(child: HealthStateWidget()),
    );
  }
}

class HealthStateWidget extends ConsumerWidget {
  const HealthStateWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthProvider);
    if (healthState == null) {
      return const SizedBox.shrink();
    }
    return _buildHealthState(context, healthState);
  }

  Widget _buildHealthState(BuildContext context, HealthState healthState) {
    if (healthState.warnings?.isEmpty ?? true) {
      return _buildHealthyState(context);
    }
    return const HealthWarningList();
  }

  Widget _buildHealthyState(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          AdaptiveHealthyIcon(
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No Issues Found',
            style: isApple()
                ? TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  )
                : Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 2),
          Text(
            'Cylonix is operating normally',
            style: TextStyle(
              color: isApple()
                  ? CupertinoColors.label.resolveFrom(context)
                  : Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class HealthWarningList extends ConsumerWidget {
  final Color? color;
  const HealthWarningList({super.key, this.color});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthProvider);
    if (healthState == null || (healthState.warnings?.isEmpty ?? true)) {
      return const SizedBox.shrink();
    }
    return _buildWarningsList(context, healthState, ref);
  }

  Widget _buildWarningsList(
      BuildContext context, HealthState healthState, WidgetRef ref) {
    final list = <_HealthWarningTile>[];
    final user = ref.watch(currentLoginProfileProvider);
    healthState.warnings?.forEach((key, value) {
      if (value != null) {
        list.add(
          _HealthWarningTile(
            warning: value,
            user: user,
          ),
        );
      }
    });
    if (isApple()) {
      return AdaptiveListSection.insetGrouped(
        backgroundColor: Colors.transparent,
        margin: const EdgeInsets.only(left: 16, right: 16, top: 120),
        children: [
          AdaptiveListSection.insetGrouped(
            header: const Text("Warnings"),
            backgroundColor: Colors.transparent,
            children: list,
          ),
        ],
      );
    }
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 64),
      children: [
        const SizedBox(height: 16),
        Text("Warnings", style: Theme.of(context).textTheme.titleMedium),
        ...list,
      ],
    );
  }
}

class _HealthWarningTile extends ConsumerWidget {
  final UnhealthyState warning;
  final LoginProfile? user;

  const _HealthWarningTile({required this.warning, this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCylonixController = ref.watch(isCylonixControllerProvider);
    final isUserWithCylonixController = user?.controlURL.contains("cylonix.io");
    if (isApple()) {
      return CupertinoListTile(
        padding: const EdgeInsets.all(8),
        leading: warning.severity == Severity.high
            ? const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: CupertinoColors.systemRed,
              )
            : warning.severity == Severity.medium
                ? const Icon(
                    CupertinoIcons.exclamationmark_circle_fill,
                    color: CupertinoColors.systemOrange,
                  )
                : const Icon(
                    CupertinoIcons.exclamationmark_circle,
                    color: CupertinoColors.systemGrey,
                  ),
        backgroundColor: _getBackgroundColor(context),
        title: Text(
          isUserWithCylonixController ?? isCylonixController
              ? warning.title.replaceAll("Tailscale", "Cylonix")
              : warning.title,
          style: CupertinoTheme.of(context)
              .textTheme
              .textStyle
              .copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
          child: Text(
            isUserWithCylonixController ?? isCylonixController
                ? warning.text.replaceAll("Tailscale", "Cylonix")
                : warning.text,
            style: CupertinoTheme.of(context)
                .textTheme
                .textStyle
                .copyWith(fontSize: 13, fontWeight: FontWeight.w200),
            maxLines: 100, // Allow unlimited lines
            overflow: TextOverflow.visible, // Don't truncate with ellipsis
          ),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.only(left: 8, right: 8),
      color: _getBackgroundColor(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (warning.title.isNotEmpty)
            Text(
              warning.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
            child: Text(
              warning.text,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: null, // Allow unlimited lines
              overflow: TextOverflow.visible, // Don't truncate with ellipsis
            ),
          ),
        ],
      ),
    );
  }

  Color? _getBackgroundColor(BuildContext context) {
    switch (warning.severity) {
      case Severity.high:
        return isApple()
            ? CupertinoColors.systemBrown
            : Theme.of(context).colorScheme.errorContainer;
      case Severity.medium:
        return isApple()
            ? CupertinoColors.secondarySystemFill
            : Theme.of(context).colorScheme.secondaryContainer;
      default:
        return isApple()
            ? CupertinoColors.tertiarySystemFill
            : Theme.of(context).colorScheme.surfaceContainerLow;
    }
  }
}
