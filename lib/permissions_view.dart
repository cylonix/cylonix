// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';
import 'package:cylonix/widgets/adaptive_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings.dart';
import '../utils/utils.dart';

class PermissionsView extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateBack;

  const PermissionsView({
    super.key,
    this.onNavigateBack,
  });

  @override
  ConsumerState<PermissionsView> createState() => _PermissionsViewState();
}

class _PermissionsViewState extends ConsumerState<PermissionsView> {
  Future<void> _showLocalNetworkPermissionDialog(BuildContext context) async {
    const title = 'Local Network Discovery';
    const body = 'When enabled, Cylonix can relay local discovery traffic '
        '(like AirPrint/mDNS and game discovery) across your Tailnet.\n\n'
        'Why this permission is requested:\n'
        '- To discover printers and local services on your LAN.\n'
        '- To let remote trusted devices discover those services.\n\n'
        'What Cylonix does not do:\n'
        '- It does not enable this by default.\n'
        '- It does not relay traffic unless you explicitly enable Local '
        'Discovery Relay.\n\n'
        'You can disable this anytime in app settings and in system privacy settings.';

    if (isApple()) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text(title),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(body),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(title),
        content: const Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVPNGranted = ref.watch(vpnPermissionStateProvider);

    if (isApple()) {
      final children = [
        AdaptiveListSection.insetGrouped(
          header: const Text('REQUIRED'),
          footer: const Text(
            'These permissions are necessary for core app functionality',
          ),
          children: [
            AdaptiveListTile.notched(
              title: const Text('VPN Configuration'),
              subtitle: const Text(
                'Required to create secure network connections',
              ),
              trailing: Icon(
                isVPNGranted
                    ? CupertinoIcons.checkmark_circle
                    : CupertinoIcons.xmark_circle,
                color: isVPNGranted
                    ? CupertinoColors.activeGreen
                    : CupertinoColors.systemRed,
              ),
            ),
          ],
        ),
        const AdaptiveListSection.insetGrouped(
          header: Text('OPTIONAL'),
          footer: Text(
            'These permissions enhance app functionality but aren\'t required',
          ),
          children: [
            AdaptiveListTile.notched(
              title: Text('Notifications'),
              subtitle: Text(
                'To notify you when receiving files',
              ),
              // TODO: Add actual notification permission status check
            ),
          ],
        ),
        AdaptiveListSection.insetGrouped(
          header: const Text('LOCAL DISCOVERY'),
          footer: const Text(
            'Local Network permission is only requested when Local Discovery Relay is explicitly enabled.',
          ),
          children: [
            AdaptiveListTile.notched(
              title: const Text('Local Network Discovery'),
              subtitle: const Text(
                'Needed for AirPrint, Bonjour/mDNS, and game discovery relay',
              ),
              trailing: const Icon(CupertinoIcons.info_circle),
              onTap: () => _showLocalNetworkPermissionDialog(context),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Cylonix requires certain system permissions to function properly. '
            'You can manage these permissions in System Settings.',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontSize: 13,
            ),
          ),
        ),
      ];
      return CupertinoPageScaffold(
        backgroundColor:
            CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Permissions'),
          leading: widget.onNavigateBack == null
              ? null
              : AppleBackButton(
                  onPressed: widget.onNavigateBack,
                ),
        ),
        child: SafeArea(
          child: Container(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(children: children),
            ),
          ),
        ),
      );
    }

    // Material Design version
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
        leading: widget.onNavigateBack == null
            ? null
            : BackButton(onPressed: widget.onNavigateBack),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text(
              'Required',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            title: const Text('VPN Configuration'),
            subtitle: const Text(
              'Required to create secure network connections',
            ),
            trailing: Icon(
              isVPNGranted ? Icons.check_circle : Icons.error,
              color: isVPNGranted ? Colors.green : Colors.red,
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text(
              'Optional',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          if (!Platform.isLinux) ...[
            const ListTile(
              title: Text('Notifications'),
              subtitle: Text(
                'To notify you when receiving files',
              ),
              // TODO: Add actual notification permission status check
            ),
            ListTile(
              title: const Text('Local Network Discovery'),
              subtitle: const Text(
                'Needed for AirPrint, Bonjour/mDNS, and game discovery relay',
              ),
              trailing: const Icon(Icons.info_outline),
              onTap: () => _showLocalNetworkPermissionDialog(context),
            ),
          ],
          if (Platform.isWindows) ...[
            const ListTile(
              title: Text('Downloads Folder'),
              subtitle: Text(
                'Access to save files received from other devices',
              ),
              // TODO: Add actual permission status check
              trailing: Icon(Icons.info_outline),
            ),
          ],
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Cylonix requires certain system permissions to function properly. '
              'You can manage these permissions in System Settings.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
