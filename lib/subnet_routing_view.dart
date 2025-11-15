// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/alert.dart';
import 'models/platform.dart';
import 'utils/utils.dart';
import 'viewmodels/settings.dart';
import 'widgets/adaptive_widgets.dart';
import 'widgets/alert_chip.dart';
import 'widgets/alert_dialog_widget.dart';
import 'widgets/dialog_action.dart';

class SubnetRoutingView extends ConsumerWidget {
  final VoidCallback onBackToSettings;

  const SubnetRoutingView({
    super.key,
    required this.onBackToSettings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isApple()) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Subnet Routes'),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.back),
            onPressed: onBackToSettings,
          ),
        ),
        child: _buildBody(context, ref),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subnet Routes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBackToSettings,
        ),
      ),
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(subnetRoutingLoadingProvider);
    return LoadingIndicator(
      isLoading: isLoading,
      child: Container(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _buildContent(context, ref),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subnetRoutingProvider);

    return ListView(
      children: [
        AdaptiveListSection.insetGrouped(
          header: const AdaptiveGroupedHeader(
            'Accept Routes',
          ),
          footer: const AdaptiveGroupedFooter(
            'Accept routes advertised by other devices in your mesh network',
          ),
          children: [
            if (state.currentError != null)
              AlertChip(
                Alert('Failed to Save: ${state.currentError}'),
                onDeleted: () =>
                    ref.read(subnetRoutingProvider.notifier).dismissError(),
              ),
            AdaptiveSwitchListTile(
              title: const Text('Use Cylonix Subnets'),
              value: state.routeAll,
              onChanged: (_) =>
                  ref.read(subnetRoutingProvider.notifier).toggleUseSubnets(),
            ),
          ],
        ),
        AdaptiveListSection.insetGrouped(
          header: const AdaptiveGroupedHeader(
            'Advertised Routes',
          ),
          footer: const AdaptiveGroupedFooter(
            'These routes make your local network available to '
            'other devices in your mesh network',
          ),
          children: [
            ...state.advertisedRoutes.map(
              (route) => SubnetRouteRow(
                route: route,
                onEdit: () => _editRoute(context, ref, route),
                onDelete: () => _deleteRoute(context, ref, route),
              ),
            ),
            AdaptiveListTile.notched(
              leading: const Icon(Icons.add),
              title: const Text('Add New Route'),
              onTap: () => _editRoute(context, ref, ''),
            ),
          ],
        ),
      ],
    );
  }

  void _editRoute(BuildContext context, WidgetRef ref, String route) async {
    try {
      ref.read(subnetRoutingProvider.notifier).startEditingRoute(route);
      await AdaptiveModalPopup(
        height:
            isNativeAndroidTV ? MediaQuery.of(context).size.height * 0.9 : null,
        child: const EditSubnetRoutePopup(),
      ).show(context, adaptive: false);
    } finally {
      ref.read(subnetRoutingProvider.notifier).stopEditingRoute();
    }
  }

  void _deleteRoute(BuildContext context, WidgetRef ref, String route) async {
    final confirm = await showAlertDialog(
      context,
      'Delete Route',
      'Are you sure you want to delete the route "$route"?',
      showOK: false,
      showCancel: true,
      actions: [
        DialogAction(
          isDestructive: true,
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
    if (confirm != true) return;
    try {
      await ref.read(subnetRoutingProvider.notifier).deleteRoute(route);
    } catch (e) {
      if (context.mounted) {
        await showAlertDialog(
          context,
          'Error Deleting Route',
          'Failed to delete route "$route": $e',
        );
      }
      return;
    }
  }
}

class SubnetRouteRow extends StatelessWidget {
  final String route;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SubnetRouteRow({
    super.key,
    required this.route,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveListTile(
      title: Text(route),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdaptiveButton(
            iconButton: true,
            child: Icon(isApple() ? CupertinoIcons.pencil : Icons.edit),
            onPressed: onEdit,
          ),
          AdaptiveButton(
            iconButton: true,
            child: Icon(isApple() ? CupertinoIcons.delete : Icons.delete,
                color: isApple()
                    ? CupertinoColors.systemRed.resolveFrom(context)
                    : Theme.of(context).colorScheme.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class EditSubnetRoutePopup extends ConsumerWidget {
  const EditSubnetRoutePopup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subnetRoutingProvider);
    final isLoading = ref.watch(subnetRoutingLoadingProvider);

    return LoadingIndicator(
      isLoading: isLoading,
      child: Container(
        alignment: Alignment.topCenter,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 32,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AdaptiveTitle(
                  state.editingRoute.isEmpty ? 'Add Route' : 'Edit Route',
                ),
                AdaptiveButton(
                  small: true,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
            AdaptiveTextFormField(
              autofocus: true,
              initialValue: state.dialogTextFieldValue,
              onChanged: (value) => ref
                  .read(subnetRoutingProvider.notifier)
                  .updateDialogValue(value),
              labelText: "Route",
              placeholder: "e.g., 192.168.1.0/24",
              errorText:
                  !state.isTextFieldValueValid ? 'Invalid CIDR format' : null,
            ),
            AdaptiveButton(
              filled: true,
              onPressed: () => _save(context, ref),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _save(BuildContext context, WidgetRef ref) async {
    final state = ref.read(subnetRoutingProvider);
    if (state.isTextFieldValueValid) {
      try {
        await ref.read(subnetRoutingProvider.notifier).saveRoute();
        Navigator.of(context).pop();
      } catch (e) {
        if (context.mounted) {
          await showAlertDialog(
            context,
            'Error Saving Route',
            'Failed to save route: $e',
          );
        }
      }
    } else {
      await showAlertDialog(
        context,
        'Invalid Route',
        'Please enter a valid CIDR route.',
      );
      return;
    }
  }
}
