// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'adaptive_widgets.dart';
import '../models/ipn.dart';
import '../models/platform.dart';
import '../providers/ipn.dart';
import '../providers/theme.dart';
import '../utils/utils.dart';
import '../viewmodels/state_notifier.dart';

class MainNavigationRail extends ConsumerStatefulWidget {
  final Function() onNavigateToUserSwitcher;
  final Function() onNavigateToSettings;
  final Function() onNavigateToExitNodes;
  final Function() onNavigateToSendFiles;
  final Function() onNavigateToHealth;
  final Function() onNavigateToHome;
  final Function() onNavigateToAbout;

  const MainNavigationRail({
    super.key,
    required this.onNavigateToUserSwitcher,
    required this.onNavigateToSettings,
    required this.onNavigateToExitNodes,
    required this.onNavigateToSendFiles,
    required this.onNavigateToHealth,
    required this.onNavigateToHome,
    required this.onNavigateToAbout,
  });

  @override
  ConsumerState<MainNavigationRail> createState() => _MainNavigationRailState();
}

class _MainNavigationRailState extends ConsumerState<MainNavigationRail> {
  bool get _extended => isApple() || isAndroidTV ? true : _isExtended;
  bool _isExtended = false;

  IconData get _homeIcon => isApple() ? CupertinoIcons.home : Icons.home;

  IconData get _settingsIcon =>
      isApple() ? CupertinoIcons.settings : Icons.settings;

  IconData get _exitNodeIcon =>
      isApple() ? CupertinoIcons.arrow_up_right_circle : Icons.exit_to_app;

  IconData get _healthIcon =>
      isApple() ? CupertinoIcons.shield : Icons.health_and_safety;

  IconData get _lightModeIcon =>
      isApple() ? CupertinoIcons.sun_max : Icons.light_mode;

  IconData get _darkModeIcon =>
      isApple() ? CupertinoIcons.moon : Icons.dark_mode;

  IconData get _infoIcon => isApple() ? CupertinoIcons.info : Icons.info;

  TextStyle? get _labelStyle {
    return isApple() ? const TextStyle(fontSize: 13) : null;
  }

  bool get _isIpad {
    return Platform.isIOS && (MediaQuery.of(context).size.shortestSide >= 600);
  }

  Widget _appleIcon(IconData icon) {
    return Icon(
      icon,
      color: CupertinoColors.activeBlue,
      size: _isIpad ? 24 : 16,
    );
  }

  Widget _buildAppleRail(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    final health = ref.watch(healthProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final labelStyle = TextStyle(
      color: CupertinoColors.label.resolveFrom(context),
      fontSize: _isIpad ? 16 : 14,
      fontWeight: FontWeight.w500,
    );

    Widget row(String title, Widget leading, VoidCallback onTap) {
      return CupertinoButton(
        onPressed: onTap,
        sizeStyle: CupertinoButtonSize.small,
        padding: EdgeInsets.symmetric(vertical: _isIpad ? 16 : 8),
        child: Row(children: [
          leading,
          SizedBox(width: _isIpad ? 16 : 8),
          Flexible(
            child: Text(title, style: labelStyle),
          ),
        ]),
      );
    }

    return Container(
      width: 300,
      color:
          CupertinoColors.tertiarySystemGroupedBackground.resolveFrom(context),
      child: ListView(
        padding: EdgeInsets.only(
          left: Platform.isIOS && !_isIpad ? 64 : 32,
          top: Platform.isMacOS || _isIpad ? 32 : 0,
        ),
        children: [
          if (MediaQuery.of(context).size.height > 500)
            _buildLeading(context, user),
          if (Platform.isMacOS || _isIpad) ...[
            const SizedBox(height: 32),
            const Text(
              "Navigation",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
          ],
          row(
            'Home',
            _appleIcon(_homeIcon),
            widget.onNavigateToHome,
          ),
          row(
            'Settings',
            _appleIcon(_settingsIcon),
            widget.onNavigateToSettings,
          ),
          row(
            'Exit Nodes',
            _appleIcon(_exitNodeIcon),
            widget.onNavigateToExitNodes,
          ),
          row(
            'Health',
            _buildHeathIcon(health),
            widget.onNavigateToHealth,
          ),
          row(
            isDarkMode ? 'Light Mode' : 'Dark Mode',
            _appleIcon(isDarkMode ? _lightModeIcon : _darkModeIcon),
            () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
          row(
            'About Cylonix',
            _appleIcon(_infoIcon),
            widget.onNavigateToAbout,
          ),
        ],
      ),
    );
  }

  Widget _railIcon(Widget icon, String? tooltip) {
    return _extended
        ? icon
        : Tooltip(
            message: tooltip,
            child: icon,
          );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    final health = ref.watch(healthProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex = ref.watch(navigationRailIndexProvider);

    if (isApple()) {
      return _buildAppleRail(context);
    }

    return NavigationRail(
      extended: _extended,
      minExtendedWidth: isApple() ? 320 : 200,
      backgroundColor: isApple()
          ? CupertinoColors.secondarySystemFill
          : Theme.of(context).navigationRailTheme.backgroundColor,
      leading: (MediaQuery.of(context).size.height > 500)
          ? _buildLeading(context, user)
          : null,
      useIndicator: !isApple(), // Material 3 indicator style
      indicatorColor: isApple()
          ? CupertinoColors.activeBlue.withOpacity(0.1)
          : Theme.of(context).colorScheme.secondaryContainer,
      selectedIconTheme: IconThemeData(
        color: isApple()
            ? CupertinoColors.activeBlue
            : Theme.of(context).colorScheme.primary,
      ),
      destinations: [
        NavigationRailDestination(
          icon: _railIcon(Icon(_homeIcon), "Home"),
          label: Text(
            'Home',
            style: _labelStyle,
          ),
        ),
        NavigationRailDestination(
          icon: _railIcon(Icon(_settingsIcon), "Settings"),
          label: Text(
            'Settings',
            style: _labelStyle,
          ),
        ),
        NavigationRailDestination(
          icon: _railIcon(Icon(_exitNodeIcon), "Exit Nodes"),
          label: Text(
            'Exit Nodes',
            style: _labelStyle,
          ),
        ),
        if (!isAndroidTV)
          NavigationRailDestination(
            icon:
                _railIcon(const Icon(Icons.upload_file_outlined), "Send Files"),
            label: Text(
              'Send Files',
              style: _labelStyle,
            ),
          ),
        NavigationRailDestination(
          icon: _railIcon(_buildHeathIcon(health), "Health"),
          label: Text(
            'Health',
            style: _labelStyle,
          ),
        ),
        if (!isAndroidTV)
          NavigationRailDestination(
            icon: _railIcon(
              Icon(isDarkMode ? _lightModeIcon : _darkModeIcon),
              isDarkMode ? "Light Mode" : "Dark Mode",
            ),
            label: Text(
              isDarkMode ? "Light Mode" : "Dark Mode",
              style: _labelStyle,
            ),
          ),
        NavigationRailDestination(
          icon: _railIcon(Icon(_infoIcon), "About Cylonix"),
          label: Text(
            "About Cylonix",
            style: _labelStyle,
          ),
        ),
      ],
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        ref.read(navigationRailIndexProvider.notifier).setState(index);
        _handleNavigation(index);
      },
    );
  }

  Widget _buildHeathIcon(HealthState? health) {
    return Stack(
      children: [
        isApple() ? _appleIcon(_healthIcon) : Icon(_healthIcon),
        if (health?.warnings?.isNotEmpty == true)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _getHealthColor(health),
                shape: BoxShape.circle,
              ),
              constraints: BoxConstraints(
                maxWidth: _isIpad ? 12 : 8,
                maxHeight: _isIpad ? 12 : 8,
              ),
            ),
          ),
      ],
    );
  }

  void _handleNavigation(int index) {
    if (isAndroidTV) {
      _handleAndroidTVNavigation(index);
      return;
    }
    switch (index) {
      case 0:
        widget.onNavigateToHome();
      case 1:
        widget.onNavigateToSettings();
        break;
      case 2:
        widget.onNavigateToExitNodes();
        break;
      case 3:
        widget.onNavigateToSendFiles();
        break;
      case 4:
        widget.onNavigateToHealth();
        break;
      case 5:
        ref.read(themeProvider.notifier).toggleTheme();
        break;
      case 6:
        widget.onNavigateToAbout();
        break;
    }
  }

  void _handleAndroidTVNavigation(int index) {
    switch (index) {
      case 0:
        widget.onNavigateToHome();
      case 1:
        widget.onNavigateToSettings();
        break;
      case 2:
        widget.onNavigateToExitNodes();
        break;
      case 3:
        widget.onNavigateToHealth();
        break;
      case 4:
        widget.onNavigateToAbout();
        break;
    }
  }

  Widget get _toggleButton {
    // Toggle button for extension
    return _isExtended
        ? IconButton(
            icon: const Icon(
              Icons.keyboard_double_arrow_left,
            ),
            onPressed: () => setState(() => _isExtended = false),
          )
        : IconButton(
            icon: Icon(
              isApple()
                  ? CupertinoIcons.sidebar_left
                  : Icons.keyboard_double_arrow_right,
            ),
            onPressed: () => setState(() => _isExtended = true),
          );
  }

  Widget _buildLeading(BuildContext context, UserProfile? user) {
    final profiles = ref.watch(loginProfilesProvider);
    return Column(
      crossAxisAlignment:
          isApple() ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(height: Platform.isIOS && !_isIpad ? 16 : 32),
        // Avatar and name
        GestureDetector(
          onTap: () {
            if (profiles.isNotEmpty) {
              widget.onNavigateToUserSwitcher();
            } else {
              widget.onNavigateToHome();
            }
          },
          onDoubleTap: () => setState(() => _isExtended = !_isExtended),
          child: Column(
            children: [
              AdaptiveAvatar(radius: _extended ? 48 : 24, user: user),
              if (_extended && user != null) ...[
                const SizedBox(height: 8),
                Text(
                  user.displayName,
                  style: isApple()
                      ? const TextStyle(
                          fontSize: 14,
                        )
                      : Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
        if (!isApple() && !isAndroidTV) _toggleButton,
      ],
    );
  }

  Color _getHealthColor(HealthState? health) {
    if (health?.warnings == null) return Colors.transparent;

    final hasCritical = health!.warnings!.values
        .any((warning) => warning?.severity == Severity.high);

    return isApple()
        ? (hasCritical
            ? CupertinoColors.systemRed
            : CupertinoColors.systemOrange)
        : (hasCritical ? Colors.red : Colors.orange);
  }
}
