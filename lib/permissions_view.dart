import 'dart:io';
import 'package:cylonix/widgets/adaptive_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings.dart';
import '../utils/utils.dart';

class PermissionsView extends ConsumerWidget {
  final VoidCallback? onNavigateBack;

  const PermissionsView({
    super.key,
    this.onNavigateBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          backgroundColor: Colors.transparent,
          middle: const Text('Permissions'),
          leading: onNavigateBack == null
              ? null
              : AppleBackButton(
                  onPressed: onNavigateBack,
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
        leading: onNavigateBack == null
            ? null
            : BackButton(onPressed: onNavigateBack),
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
