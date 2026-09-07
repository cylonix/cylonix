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
import '../providers/peer_messaging.dart';
import '../providers/theme.dart';
import '../utils/utils.dart';
import '../viewmodels/state_notifier.dart';

/// Sidebar entries that can be shown as the current selection. The home
/// shell maps the page it is displaying onto one of these.
enum MainRailItem {
  account,
  home,
  settings,
  exitNodes,
  health,
  peerMessages,
  about,
}

class MainNavigationRail extends ConsumerStatefulWidget {
  /// Entry highlighted as the current page (Apple sidebar only).
  final MainRailItem? selected;
  final Function() onNavigateToUserSwitcher;
  final Function() onNavigateToSettings;
  final Function() onNavigateToExitNodes;
  final Function() onNavigateToSendFiles;
  final Function() onNavigateToHealth;
  final Function() onNavigateToHome;
  final Function() onNavigateToPeerMessaging;
  final Function() onNavigateToAbout;

  const MainNavigationRail({
    super.key,
    this.selected,
    required this.onNavigateToUserSwitcher,
    required this.onNavigateToSettings,
    required this.onNavigateToExitNodes,
    required this.onNavigateToSendFiles,
    required this.onNavigateToHealth,
    required this.onNavigateToHome,
    required this.onNavigateToPeerMessaging,
    required this.onNavigateToAbout,
  });

  @override
  ConsumerState<MainNavigationRail> createState() => _MainNavigationRailState();
}

class _MainNavigationRailState extends ConsumerState<MainNavigationRail> {
  bool get _extended {
    if (isNativeAndroidTV) return true;
    if (Platform.isIOS) return true;
    if (Platform.isMacOS) return _isExtendedApple;
    return _isExtended;
  }

  bool _isExtended = false;
  bool _isExtendedApple = true;
  bool _macAutoCollapseDone = false;

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
  IconData get _peerMessagingIcon => isApple()
      ? CupertinoIcons.chat_bubble_2
      : Icons.mark_chat_unread_outlined;

  TextStyle? get _labelStyle {
    return isApple() ? const TextStyle(fontSize: 13) : null;
  }

  bool get _isIpad {
    return Platform.isIOS && (MediaQuery.of(context).size.shortestSide >= 600);
  }

  // Sidebar metrics. macOS follows the AppKit source-list look: 28pt rows,
  // 13pt labels, 18pt accent-coloured symbols and a rounded selection
  // highlight inset from the sidebar edges. iPad keeps its roomier sizing.
  double get _railWidth => Platform.isMacOS ? 240 : 300;
  static const double _collapsedRailWidth = 80;
  static const double _rowRadius = 6;
  double get _rowHeight => _isIpad ? 44 : 28;
  double get _iconSize => !_extended ? 20 : (_isIpad ? 24 : 18);
  double get _labelFontSize => _isIpad ? 17 : 13;
  double get _detailFontSize => _isIpad ? 13 : 11;

  /// Gap between the sidebar edges and the rows. iPhone keeps the notch
  /// clearance it always had.
  EdgeInsets get _railInset {
    if (!_extended) return EdgeInsets.zero;
    if (Platform.isMacOS) return const EdgeInsets.symmetric(horizontal: 10);
    if (Platform.isIOS && !_isIpad) {
      return const EdgeInsets.only(left: 64, right: 16);
    }
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  Color? _highlight(bool selected) =>
      selected ? CupertinoColors.systemFill.resolveFrom(context) : null;

  Widget _appleIcon(IconData icon) {
    return Icon(icon, color: CupertinoColors.activeBlue, size: _iconSize);
  }

  Widget _buildPeerMessagingIcon(int unread) {
    final icon = _appleIcon(_peerMessagingIcon);
    // Extended rows show the count next to the label; the collapsed rail
    // only has room for a dot.
    if (unread == 0 || _extended) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed.resolveFrom(context),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  void _handleAppleNavigateToPeerMessaging() {
    if (Platform.isMacOS && !_macAutoCollapseDone) {
      setState(() {
        _macAutoCollapseDone = true;
        _isExtendedApple = false;
      });
    }
    widget.onNavigateToPeerMessaging();
  }

  /// One sidebar row. Extended: icon cell, label and an optional trailing
  /// detail (the unread count), on a rounded highlight when selected.
  /// Collapsed: just the icon, with the label as a tooltip.
  Widget _appleRow({
    required String title,
    required Widget icon,
    required VoidCallback onTap,
    bool selected = false,
    String? detail,
  }) {
    final radius = BorderRadius.circular(_rowRadius);
    if (!_extended) {
      return Tooltip(
        message: detail == null ? title : '$title ($detail)',
        child: CupertinoButton(
          onPressed: onTap,
          padding: const EdgeInsets.symmetric(vertical: 2),
          minimumSize: Size.zero,
          child: Container(
            width: 40,
            height: 32,
            decoration: BoxDecoration(
              color: _highlight(selected),
              borderRadius: radius,
            ),
            child: Center(child: icon),
          ),
        ),
      );
    }
    return CupertinoButton(
      onPressed: onTap,
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      child: Container(
        width: double.infinity,
        height: _rowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: _highlight(selected),
          borderRadius: radius,
        ),
        child: Row(
          children: [
            // Fixed cell so labels line up regardless of glyph width.
            SizedBox(
              width: _iconSize + 4,
              child: Center(child: icon),
            ),
            SizedBox(width: _isIpad ? 12 : 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _labelFontSize,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),
            if (detail != null)
              Text(
                detail,
                style: TextStyle(
                  fontSize: _detailFontSize + 1,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppleSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: _detailFontSize,
          fontWeight: FontWeight.w700,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }

  /// Account header: avatar plus name and login, styled like the account row
  /// at the top of System Settings. Opens the profile switcher.
  Widget _buildAppleAccount(BuildContext context, UserProfile? user) {
    final profiles = ref.watch(loginProfilesProvider);
    final isApplePrivateRelay =
        user?.displayName.toLowerCase().endsWith('@privaterelay.appleid.com') ??
            false;
    void onTap() {
      if (profiles.isNotEmpty) {
        widget.onNavigateToUserSwitcher();
      } else {
        widget.onNavigateToHome();
      }
    }

    if (!_extended) {
      return Tooltip(
        message: user?.displayName ?? 'Account',
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 8),
          minimumSize: Size.zero,
          onPressed: onTap,
          child: AdaptiveAvatar(radius: 20, user: user),
        ),
      );
    }

    final name = user == null
        ? (profiles.isNotEmpty ? 'Select Profile' : 'Not signed in')
        : isApplePrivateRelay
            ? 'Apple Private Relay'
            : user.displayName;
    final detail = user == null
        ? null
        : isApplePrivateRelay
            ? user.displayName.split('@').first
            : user.loginName != user.displayName
                ? user.loginName
                : null;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: _isIpad ? 10 : 6,
        ),
        decoration: BoxDecoration(
          color: _highlight(widget.selected == MainRailItem.account),
          borderRadius: BorderRadius.circular(_rowRadius),
        ),
        child: Row(
          children: [
            AdaptiveAvatar(radius: _isIpad ? 24 : 18, user: user),
            SizedBox(width: _isIpad ? 12 : 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _labelFontSize,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  if (detail != null)
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: _detailFontSize,
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// macOS sidebar toggle. Extended: sits at the trailing end of the
  /// sidebar's title-bar row, next to the divider, where Finder, Mail and
  /// Notes put it. Collapsed: the rail is only as wide as the traffic-light
  /// cluster, so it drops below them.
  Widget _buildAppleSidebarToggle() {
    final button = Tooltip(
      message: _extended ? 'Hide Sidebar' : 'Show Sidebar',
      child: CupertinoButton(
        padding: const EdgeInsets.all(4),
        minimumSize: Size.zero,
        onPressed: () {
          setState(() {
            _macAutoCollapseDone = true;
            _isExtendedApple = !_isExtendedApple;
          });
        },
        child: Icon(
          CupertinoIcons.sidebar_left,
          size: 20,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
    if (!_extended) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Center(child: button),
      );
    }
    // Measured on macOS 26: the traffic lights are 14pt circles centred at
    // y=15.5, so the title-bar row is 31pt. The sidebar symbol's glyph sits
    // about 1pt high in its 28pt button box; the 2pt top padding shifts the
    // box down so the glyph centres on the same line as the buttons.
    return SizedBox(
      height: 31,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: button,
        ),
      ),
    );
  }

  Widget _buildAppleRail(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    final health = ref.watch(healthProvider);
    final unread = ref.watch(peerMessagingUnreadCountProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final extended = _extended;
    final selected = widget.selected;
    final inset = _railInset;
    // The extended macOS sidebar starts at the very top so the toggle can
    // share the title-bar row with the traffic lights. Everything else keeps
    // a top clearance: the traffic lights when collapsed on macOS, the status
    // bar on iPad.
    final topPadding = Platform.isMacOS && extended
        ? 0.0
        : Platform.isMacOS || _isIpad
            ? 32.0
            : 0.0;

    return Container(
      // Collapsed width clears the macOS traffic-light cluster (the green
      // zoom button's right edge sits near x≈67); 64 used to slice it down
      // the middle since the window uses a transparent full-size-content
      // title bar and the rail renders beneath the controls.
      width: extended ? _railWidth : _collapsedRailWidth,
      color:
          CupertinoColors.tertiarySystemGroupedBackground.resolveFrom(context),
      child: ListView(
        padding: EdgeInsets.only(
          left: inset.left,
          right: inset.right,
          top: topPadding,
        ),
        children: [
          if (Platform.isMacOS) _buildAppleSidebarToggle(),
          if (MediaQuery.of(context).size.height > 500) ...[
            SizedBox(height: extended && !Platform.isMacOS ? 16 : 12),
            _buildAppleAccount(context, user),
          ],
          if (extended) ...[
            SizedBox(height: _isIpad ? 24 : 16),
            _buildAppleSectionHeader('Navigation'),
          ] else
            const SizedBox(height: 12),
          _appleRow(
            title: 'Home',
            icon: _appleIcon(_homeIcon),
            onTap: widget.onNavigateToHome,
            selected: selected == MainRailItem.home,
          ),
          _appleRow(
            title: 'Settings',
            icon: _appleIcon(_settingsIcon),
            onTap: widget.onNavigateToSettings,
            selected: selected == MainRailItem.settings,
          ),
          _appleRow(
            title: 'Exit Nodes',
            icon: _appleIcon(_exitNodeIcon),
            onTap: widget.onNavigateToExitNodes,
            selected: selected == MainRailItem.exitNodes,
          ),
          _appleRow(
            title: 'Health',
            icon: _buildHeathIcon(health),
            onTap: widget.onNavigateToHealth,
            selected: selected == MainRailItem.health,
          ),
          _appleRow(
            title: 'Peer Messages',
            icon: _buildPeerMessagingIcon(unread),
            detail: unread > 0 ? '$unread' : null,
            onTap: _handleAppleNavigateToPeerMessaging,
            selected: selected == MainRailItem.peerMessages,
          ),
          _appleRow(
            title: isDarkMode ? 'Light Mode' : 'Dark Mode',
            icon: _appleIcon(isDarkMode ? _lightModeIcon : _darkModeIcon),
            onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
          _appleRow(
            title: 'About Cylonix',
            icon: _appleIcon(_infoIcon),
            onTap: widget.onNavigateToAbout,
            selected: selected == MainRailItem.about,
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
    final unread = ref.watch(peerMessagingUnreadCountProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex = ref.watch(navigationRailIndexProvider);

    ref.listen<int>(peerMessagingInboxOpenedProvider, (previous, next) {
      if (Platform.isMacOS && !_macAutoCollapseDone) {
        setState(() {
          _macAutoCollapseDone = true;
          _isExtendedApple = false;
        });
      }
    });

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
          ? CupertinoColors.activeBlue.withValues(alpha: 0.1)
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
        if (!isNativeAndroidTV)
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
        NavigationRailDestination(
          icon: _railIcon(Icon(_peerMessagingIcon), "Peer Messages"),
          label: Text(
            unread > 0 ? 'Peer Messages ($unread)' : 'Peer Messages',
            style: _labelStyle,
          ),
        ),
        if (!isNativeAndroidTV)
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
    if (isNativeAndroidTV) {
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
        widget.onNavigateToPeerMessaging();
        break;
      case 6:
        ref.read(themeProvider.notifier).toggleTheme();
        break;
      case 7:
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
        widget.onNavigateToPeerMessaging();
        break;
      case 5:
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

  /// Avatar header of the Material rail; the Apple sidebar uses
  /// [_buildAppleAccount].
  Widget _buildLeading(BuildContext context, UserProfile? user) {
    final profiles = ref.watch(loginProfilesProvider);
    final isApplePrivateRelay =
        user?.displayName.toLowerCase().endsWith('@privaterelay.appleid.com') ??
            false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
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
                  isApplePrivateRelay
                      ? "Apple Private Relay"
                      : user.displayName,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                if (isApplePrivateRelay) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.displayName.split('@').first,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
        if (!isNativeAndroidTV) _toggleButton,
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
