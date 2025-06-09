import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ipn.dart';
import '../providers/ipn.dart';
import '../providers/theme.dart';
import '../utils/utils.dart';
import 'adaptive_widgets.dart';

class MainDrawer extends ConsumerWidget {
  final Function() onNavigateToSettings;
  final Function() onNavigateToUserSwitch;
  final Function()? onNavigateToExitNodes;
  final Function()? onNavigateToHealth;
  final Function()? onNavigateToHome;
  final Function()? onNavigateToAbout;

  const MainDrawer({
    super.key,
    required this.onNavigateToSettings,
    required this.onNavigateToUserSwitch,
    this.onNavigateToExitNodes,
    this.onNavigateToHealth,
    this.onNavigateToHome,
    this.onNavigateToAbout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    final health = ref.watch(healthProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, user),
            Expanded(
              child: ListView(
                children: [
                  if (onNavigateToHome != null)
                    _buildDrawerItem(
                      context,
                      title: 'Home',
                      icon: isApple() ? CupertinoIcons.home : Icons.home,
                      onTap: onNavigateToHome!,
                    ),
                  _buildDrawerItem(
                    context,
                    title: 'Settings',
                    icon: isApple() ? CupertinoIcons.settings : Icons.settings,
                    onTap: () => {
                      Navigator.of(context).pop(), // Close the drawer
                      onNavigateToSettings(),
                    },
                  ),
                  if (onNavigateToExitNodes != null)
                    _buildDrawerItem(
                      context,
                      title: 'Exit Nodes',
                      icon: isApple()
                          ? CupertinoIcons.arrow_up_right_circle
                          : Icons.exit_to_app,
                      onTap: onNavigateToExitNodes!,
                    ),
                  if (onNavigateToHealth != null)
                    _buildHealthItem(context, health),
                  if (onNavigateToAbout != null)
                    _buildDrawerItem(
                      context,
                      title: 'About',
                      icon: isApple() ? CupertinoIcons.info : Icons.info,
                      onTap: onNavigateToAbout!,
                    ),
                ],
              ),
            ),
            const Divider(),
            _buildFooter(context, ref, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserProfile? user) {
    final child = Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: isApple()
              ? CupertinoColors.systemGrey5
              : Theme.of(context).colorScheme.secondaryContainer,
          backgroundImage: (user?.profilePicURL.isNotEmpty ?? false)
              ? NetworkImage(user!.profilePicURL)
              : null,
          child: (user?.profilePicURL.isEmpty ?? true)
              ? Text(
                  user?.displayName.characters.first.toUpperCase() ?? '',
                  style: isApple()
                      ? const TextStyle(
                          color: CupertinoColors.label,
                          fontSize: 24,
                        )
                      : Theme.of(context).textTheme.headlineMedium,
                )
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          user?.displayName ?? 'Not logged in',
          style: isApple()
              ? const TextStyle(fontSize: 17)
              : Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
    return DrawerHeader(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop(); // Close the drawer
            onNavigateToUserSwitch();
          },
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    if (isApple()) {
      return AdaptiveListTile(
        title: Text(title),
        leading: Icon(
          icon,
          color: CupertinoColors.label.resolveFrom(context),
        ),
        trailing: const CupertinoListTileChevron(),
        onTap: onTap,
      );
    }

    return ListTile(
      title: Text(title),
      leading: Icon(icon),
      onTap: onTap,
    );
  }

  Widget _buildHealthItem(BuildContext context, HealthState? health) {
    final hasWarnings = health?.warnings?.isNotEmpty == true;
    final hasCritical = health?.warnings?.values
            .any((warning) => warning?.severity == Severity.high) ??
        false;

    if (isApple()) {
      return AdaptiveListTile(
        title: const Text('Health'),
        leading: Icon(
          CupertinoIcons.shield,
          color: hasWarnings
              ? (hasCritical
                  ? CupertinoColors.systemRed
                  : CupertinoColors.systemOrange)
              : CupertinoColors.label,
        ),
        trailing: const CupertinoListTileChevron(),
        onTap: onNavigateToHealth,
      );
    }

    return ListTile(
      title: const Text('Health'),
      leading: Icon(
        Icons.health_and_safety,
        color: hasWarnings ? (hasCritical ? Colors.red : Colors.orange) : null,
      ),
      onTap: onNavigateToHealth,
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              isDarkMode
                  ? (isApple() ? CupertinoIcons.sun_max : Icons.light_mode)
                  : (isApple() ? CupertinoIcons.moon : Icons.dark_mode),
            ),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
    );
  }
}
