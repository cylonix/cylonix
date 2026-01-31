// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';
import 'dart:convert';
import 'package:cylonix/widgets/alert_dialog_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/ipn.dart';
import 'providers/ipn.dart';
import 'utils/logger.dart';
import 'utils/utils.dart';
import 'viewmodels/state_notifier.dart';
import 'widgets/adaptive_widgets.dart';

class PreferenceKeys {
  static const hiddenUserSections = 'hidden_user_sections';
}

class UserSectionPreferences {
  static final _prefs = SharedPreferences.getInstance();

  static Future<List<String>> getHiddenSections() async {
    final prefs = await _prefs;
    return prefs.getStringList(PreferenceKeys.hiddenUserSections) ?? [];
  }

  static Future<void> setHiddenSections(List<String> sections) async {
    final prefs = await _prefs;
    await prefs.setStringList(PreferenceKeys.hiddenUserSections, sections);
  }
}

class UserSwitcherView extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateBackToSettings;

  /// Callback to navigate to home screen
  final VoidCallback onNavigateToHome;

  /// Callback to navigate to custom control screen
  final VoidCallback onNavigateToCustomControl;

  /// Callback to navigate to auth key screen
  final VoidCallback onNavigateToAuthKey;

  const UserSwitcherView({
    super.key,
    this.onNavigateBackToSettings,
    required this.onNavigateToHome,
    required this.onNavigateToCustomControl,
    required this.onNavigateToAuthKey,
  });

  @override
  ConsumerState<UserSwitcherView> createState() => _UserSwitcherViewState();
}

class _UserSwitcherViewState extends ConsumerState<UserSwitcherView> {
  static final _logger = Logger(tag: "UserSwitcherView");
  final List<String> _hiddenSections = [];
  String? _switchingUserId;
  bool _isAddingProfile = false;
  String? _deletingProfileID;
  bool _isReauthenticating = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final hidden = await UserSectionPreferences.getHiddenSections();
    if (mounted) {
      setState(() {
        _hiddenSections.addAll(hidden);
        _loaded = true;
      });
    }
  }

  Future<void> _toggleSectionVisibility(String section) async {
    setState(() {
      if (_hiddenSections.contains(section)) {
        _hiddenSections.remove(section);
      } else {
        _hiddenSections.add(section);
      }
    });
    await UserSectionPreferences.setHiddenSections(_hiddenSections);
  }

  @override
  Widget build(BuildContext context) {
    final ipnState = ref.watch(ipnStateNotifierProvider);

    return ipnState.when(
      data: (state) => _buildContent(context, state.loginProfiles),
      loading: () => _buildContent(context, [], loading: true),
      error: (error, stack) => _buildErrorView(context, error),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<LoginProfile> users, {
    bool loading = false,
  }) {
    return isApple()
        ? _buildCupertinoScaffold(context, users, loading: loading)
        : _buildMaterialScaffold(context, users, loading: loading);
  }

  Widget _buildMaterialScaffold(BuildContext context, List<LoginProfile> users,
      {bool loading = false}) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        leading: widget.onNavigateBackToSettings == null
            ? null
            : BackButton(onPressed: widget.onNavigateBackToSettings),
        actions: [
          _buildHeaderMenu(),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _buildUserList(context, users, loading: loading),
        ),
      ),
    );
  }

  Widget _buildCupertinoScaffold(BuildContext context, List<LoginProfile> users,
      {bool loading = false}) {
    return CupertinoPageScaffold(
      backgroundColor: appleScaffoldBackgroundColor(context),
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        heroTag: "UserSwitcherView",
        middle: const Text('Accounts'),
        leading: widget.onNavigateBackToSettings == null
            ? null
            : AppleBackButton(
                onPressed: widget.onNavigateBackToSettings,
              ),
        trailing: _buildHeaderMenu(isCupertino: true),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _buildUserList(context, users, loading: loading),
        ),
      ),
    );
  }

  Widget _buildUserList(
    BuildContext context,
    List<LoginProfile> users, {
    bool loading = false,
  }) {
    if (loading) {
      return Center(
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 16,
                  children: [
                    const Text("Cylonix is starting..."),
                    const Text("Please log in if you haven't already."),
                    const SizedBox(height: 32),
                    AdaptiveButton(
                      onPressed: widget.onNavigateToHome,
                      child: const Text("OK"),
                    ),
                  ],
                ),
              ),
              Expanded(child: Container()),
            ],
          ),
        ),
      );
    }

    final loginProfile = ref.watch(currentLoginProfileProvider);
    final cylonixUsers =
        users.where((user) => user.controlURL.contains("cylonix")).toList();
    final tailscaleUsers =
        users.where((user) => user.controlURL.contains("tailscale")).toList();
    final otherUsers = users
        .where((user) =>
            !user.controlURL.contains("tailscale") &&
            !user.controlURL.contains("cylonix"))
        .toList();

    if (!_loaded) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    return ListView(
      children: [
        if (_hiddenSections.isNotEmpty) ...[
          AdaptiveButton(
            textButton: !isApple(),
            padding: const EdgeInsets.all(8),
            child: const Text('Show All'),
            onPressed: () async {
              setState(() => _hiddenSections.clear());
              await UserSectionPreferences.setHiddenSections([]);
            },
          ),
          const SizedBox(height: 8),
        ],
        if (cylonixUsers.isNotEmpty &&
            !_hiddenSections.contains('cylonix')) ...[
          AdaptiveListSection.insetGrouped(
            header: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AdaptiveGroupedHeader(
                  'Cylonix',
                ),
                if (users.length > 1) _buildDontShowButton(context, 'cylonix'),
              ],
            ),
            footer: Text(
              'Select a Cylonix user to access Cylonix services and features.',
              style: adaptiveGroupedFooterStyle(context),
            ),
            children: [
              ...cylonixUsers
                  .map((user) => _buildUserTile(context, user, loginProfile)),
            ],
          ),
        ],
        if (tailscaleUsers.isNotEmpty &&
            !_hiddenSections.contains('tailscale')) ...[
          AdaptiveListSection.insetGrouped(
            header: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AdaptiveGroupedHeader(
                  'Tailscale',
                ),
                _buildDontShowButton(context, 'tailscale'),
              ],
            ),
            footer: Text(
              'Select a Tailscale user to to switch to.',
              style: adaptiveGroupedFooterStyle(context),
            ),
            children: [
              ...tailscaleUsers
                  .map((user) => _buildUserTile(context, user, loginProfile)),
            ],
          ),
        ],
        if (otherUsers.isNotEmpty && !_hiddenSections.contains('others')) ...[
          AdaptiveListSection.insetGrouped(
            header: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Other', style: adaptiveGroupedHeaderStyle(context)),
                _buildDontShowButton(context, 'other'),
              ],
            ),
            footer: Text(
              'Select a user to switch to.',
              style: TextStyle(
                fontSize: 12,
                color: isApple()
                    ? CupertinoColors.secondaryLabel.resolveFrom(context)
                    : null,
              ),
            ),
            children: [
              ...otherUsers.map(
                (user) => _buildUserTile(
                  context,
                  user,
                  loginProfile,
                  showControlURL: true,
                ),
              ),
            ],
          ),
        ],
        AdaptiveListSection.insetGrouped(
          children: [
            _buildActionTile(
              context,
              leading: const Icon(CupertinoIcons.add),
              title: 'Add Account',
              isLoading: _isAddingProfile,
              onTap: _handleAddProfile,
            ),
            if (loginProfile != null) ...[
              _buildActionTile(
                context,
                leading: const Icon(CupertinoIcons.arrow_right_circle),
                title: 'Reauthenticate',
                isLoading: _isReauthenticating,
                onTap: _handleReauthenticate,
              ),
              _buildActionTile(
                context,
                leading: const Icon(CupertinoIcons.arrow_turn_up_left),
                title: 'Sign Out',
                isDestructive: true,
                onTap: _handleLogout,
              ),
            ],
          ],
        ),
        if (loginProfile != null) ...[
          const SizedBox(height: 32),
          AdaptiveListSection.insetGrouped(
            children: [
              _buildActionTile(
                context,
                leading: const Icon(CupertinoIcons.info_circle),
                title: 'Delete Account',
                isDestructive: true,
                onTap: () => _handleDeleteAccount(loginProfile),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildUserTile(
      BuildContext context, LoginProfile user, LoginProfile? currentUser,
      {showControlURL = false}) {
    final isCurrentUser = user.id == currentUser?.id;
    final isSwitching = user.id == _switchingUserId;
    final u = user.userProfile;
    final isApplePrivateRelay =
        u.displayName.toLowerCase().endsWith('@privaterelay.appleid.com');

    var subtitle = u.loginName != u.displayName ? u.loginName : '';
    if (isApplePrivateRelay) {
      subtitle = u.displayName.split('@').first;
    }
    subtitle += showControlURL
        ? subtitle.isEmpty
            ? "Server: ${user.controlURL}"
            : "\nServer: ${user.controlURL}"
        : '';
    return AdaptiveListTile(
      title: Text(isApplePrivateRelay ? 'Apple Private Relay' : u.displayName),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      leading: AdaptiveAvatar(user: u, radius: isApple() ? 20 : 12),
      trailing: isSwitching || _deletingProfileID == user.id
          ? const AdaptiveLoadingWidget(maxWidth: 18)
          : isCurrentUser
              ? Icon(
                  isApple() ? CupertinoIcons.check_mark : Icons.check,
                  color: isApple()
                      ? CupertinoColors.activeBlue.resolveFrom(context)
                      : Theme.of(context).colorScheme.primary,
                )
              : const CupertinoListTileChevron(),
      onTap: isCurrentUser ? null : () => _showSwitchOrDeleteProfileModal(user),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    Widget? leading,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isLoading = false,
  }) {
    return AdaptiveListTile(
      leading: leading,
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive
              ? isApple()
                  ? CupertinoColors.destructiveRed.resolveFrom(context)
                  : Colors.red
              : null,
        ),
      ),
      trailing: isLoading
          ? const AdaptiveLoadingWidget(maxWidth: 24)
          : const AdaptiveListTileChevron(),
      onTap: isLoading ? null : onTap,
    );
  }

  Widget _buildDontShowButton(BuildContext context, String section) {
    return AdaptiveButton(
      textButton: !isApple(),
      child: const Text("Don't Show"),
      onPressed: () => _toggleSectionVisibility(section),
    );
  }

  Widget _buildErrorView(BuildContext context, Object error) {
    final errorMessage = 'Failed to load profiles: ${error.toString()}';

    if (isApple()) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar.large(
          largeTitle: const Text('Accounts'),
          leading: widget.onNavigateBackToSettings == null
              ? null
              : CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: widget.onNavigateBackToSettings,
                  child: const Text("Back"),
                ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              errorMessage,
              style: const TextStyle(color: CupertinoColors.destructiveRed),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        leading: widget.onNavigateBackToSettings == null
            ? null
            : BackButton(onPressed: widget.onNavigateBackToSettings),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            errorMessage,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _showSwitchOrDeleteProfileModal(LoginProfile profile) async {
    await AdaptiveModalPopup(
      maxWidth: 800,
      child: Column(mainAxisSize: MainAxisSize.min, spacing: 16, children: [
        AdaptiveListTile(
          backgroundColor: Colors.transparent,
          title: Text('Profile: ${profile.name}'),
          trailing: AdaptiveButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ),
        const SizedBox(height: 16),
        AdaptiveButton(
            filled: true,
            child: Row(mainAxisSize: MainAxisSize.min, spacing: 8, children: [
              Icon(
                isApple()
                    ? CupertinoIcons.person_crop_circle_badge_checkmark
                    : Icons.person,
              ),
              const Text('Switch to this Profile')
            ]),
            onPressed: () {
              Navigator.pop(context);
              _handleSwitchProfile(profile);
            }),
        const SizedBox(height: 32),
        AdaptiveListSection.insetGrouped(
          header: const AdaptiveGroupedHeader("Delete Profile"),
          footer: const AdaptiveGroupedFooter(
            'Deleting a profile removes it from this device.'
            'This is not permanently deleting the account.'
            'You can re-add the profile later if needed.',
          ),
          children: [
            _buildActionTile(
              context,
              leading: AdaptiveDeleteIcon(),
              title: 'Delete this Profile',
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _handleDeleteProfile(profile);
              },
            ),
          ],
        ),
      ]),
    ).show(context);
  }

  Future<void> _handleSwitchProfile(LoginProfile profile) async {
    setState(() => _switchingUserId = profile.id);
    try {
      await ref
          .read(ipnStateNotifierProvider.notifier)
          .switchProfile(profile.id);
      widget.onNavigateToHome();
    } catch (e) {
      _logger.e("Failed to switch profile $e");
      _showError('Failed to switch profile: $e');
    } finally {
      setState(() => _switchingUserId = null);
    }
  }

  Widget _buildHeaderMenu({bool isCupertino = false}) {
    if (isCupertino) {
      return PullDownButton(
        buttonBuilder: (context, showMenu) => CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.ellipsis),
          onPressed: showMenu,
        ),
        itemBuilder: (_) => [
          PullDownMenuItem(
            onTap: widget.onNavigateToCustomControl,
            title: 'Custom Control',
          ),
          PullDownMenuItem(
            onTap: widget.onNavigateToAuthKey,
            title: 'Auth Key',
          ),
          PullDownMenuItem(
            onTap: () => _showProfilesData(),
            title: 'Show Profiles Data',
          ),
        ],
      );
    }

    return PopupMenuButton<String>(
      child: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'custom') {
          widget.onNavigateToCustomControl();
        } else if (value == 'auth') {
          widget.onNavigateToAuthKey();
        } else if (value == 'data') {
          _showProfilesData();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'custom',
          child: Text('Custom Control'),
        ),
        const PopupMenuItem(
          value: 'auth',
          child: Text('Auth Key'),
        ),
        const PopupMenuItem(
          value: 'data',
          child: Text('Profiles Data'),
        ),
      ],
    );
  }

  Future<void> _handleAddProfile() async {
    if (_isAddingProfile) return;
    setState(() => _isAddingProfile = true);

    try {
      // Start add profile process
      await ref.read(ipnStateNotifierProvider.notifier).addProfile(
            ref.read(controlURLProvider),
          );
      // Navigate to home after adding profile
      widget.onNavigateToHome();
    } catch (e) {
      _logger.e("Failed to add profile: $e");
      _showError('Failed to add profile: $e');
    } finally {
      _isAddingProfile = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _handleDeleteProfile(LoginProfile profile) async {
    if (_deletingProfileID != null) return;
    setState(() => _deletingProfileID = profile.id);

    try {
      final ok = await showAlertDialog(
        context,
        "Delete Profile",
        "Are you sure you want to delete this profile for ${profile.name}?",
        showCancel: true,
        okText: "Delete",
        destructiveButton: "Delete",
        defaultButton: "Cancel",
      );
      if (ok != true) return;
      await ref.read(ipnStateNotifierProvider.notifier).deleteProfile(
            profile.id,
          );
      await showAlertDialog(
        context,
        "Profile Deleted",
        "Profile for ${profile.name} has been deleted.",
      );
    } catch (e) {
      _logger.e("Failed to delete profile: $e");
      _showError('Failed to delete profile: $e');
    } finally {
      _deletingProfileID = null;
      if (mounted) setState(() {});
    }
  }

  Future<void> _handleReauthenticate() async {
    if (_isReauthenticating) return;
    setState(() => _isReauthenticating = true);
    final loginProfile = ref.read(currentLoginProfileProvider);

    try {
      // Start re-authentication process. Basically login and generate a new
      // node key for the current profile.
      await ref
          .read(ipnStateNotifierProvider.notifier)
          .login(controlURL: loginProfile?.controlURL);

      // Wait for login to rotate a new node key and then restart the VPN.
      // Note re-authentication does not ask user to re-enter credentials.
      // It uses existing session to generate a new node key.
      //
      // To completely re-authenticate, user may need to sign out and then
      // sign in again.
      //
      // Since there is no state change on getting a new node key, we wait
      // for a short duration before restarting the VPN.
      await Future.delayed(const Duration(seconds: 2));

      await ref.read(ipnStateNotifierProvider.notifier).startVpn();
      final completer = Completer<void>();
      final sub = ref.listenManual(
        ipnStateNotifierProvider,
        (previous, next) {
          final p = previous?.valueOrNull?.backendState;
          final n = next.valueOrNull?.backendState;
          _logger.d("Backend state changed from $p to $n");
          if (n == BackendState.running && !completer.isCompleted) {
            _logger.d("Backend reached running state");
            completer.complete();
          }
        },
      );

      try {
        await completer.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            _logger.w("Timeout waiting for backend to be running");
            throw TimeoutException(
              'Backend did not reach running state within 5 seconds',
            );
          },
        );
      } finally {
        sub.close();
      }
      if (!mounted) return;
      await showAlertDialog(
        context,
        'Re-authentication Successful',
        'Your account has been re-authenticated successfully.',
      );
      // Navigate to home after re-authentication
      widget.onNavigateToHome();
    } catch (e) {
      _logger.e("Failed to re-authenticate: $e");
      _showError('Failed to re-authenticate: $e');
    } finally {
      _isReauthenticating = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _handleLogout() async {
    try {
      await ref.read(ipnStateNotifierProvider.notifier).logout();
      widget.onNavigateToHome();
    } catch (e) {
      _showError('Failed to sign out: $e');
    }
  }

  void _showError(String message) async {
    if (!mounted) return;
    await showAlertDialog(context, 'Error', message);
  }

  void _showProfilesData() async {
    final profiles =
        ref.read(ipnStateNotifierProvider).valueOrNull?.loginProfiles;
    if (profiles == null || profiles.isEmpty) {
      _showError('No profiles available');
      return;
    }

    const encoder = JsonEncoder.withIndent('  ');
    final prettyJson =
        profiles.map((p) => encoder.convert(p.toJson())).toList();

    await AdaptiveModalPopup(
      child: Column(
        children: [
          CupertinoListTile(
            title: const Text('Profiles Data'),
            trailing: AdaptiveButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: prettyJson
                  .map(
                    (json) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(json, style: const TextStyle(fontSize: 14)),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    ).show(context);
  }

  void _handleDeleteAccount(LoginProfile profile) async {
    Widget text(String t) {
      return Text(
        t,
        textAlign: TextAlign.justify,
        style: TextStyle(
          fontSize: 16,
          color: isApple() ? CupertinoColors.label.resolveFrom(context) : null,
        ),
      );
    }

    var height = MediaQuery.of(context).size.height * 0.7;
    if (height < 380) {
      height = 380;
    }

    await AdaptiveModalPopup(
      height: height,
      maxWidth: 600,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          AdaptiveListTile(
            leading: Icon(
              isApple() ? CupertinoIcons.info_circle : Icons.info_outline,
            ),
            title: const Text(
              'Delete Account',
              textAlign: TextAlign.center,
            ),
            trailing: AdaptiveButton(
              textButton: !isApple(),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                spacing: 16,
                children: [
                  text(
                    'Delete Account will delete all the data associated with '
                    'this account including the user profile and devices. If '
                    'the account is an admin account, it will also delete all '
                    'the users associated with the organization and its '
                    'security settings.',
                  ),
                  text(
                    'If you still want to proceed to delete '
                    '"${profile.userProfile.displayName}". Please click the '
                    'button below that will open a web page to sign in your '
                    'account and delete it from there.',
                  ),
                  AdaptiveButton(
                    onPressed: () async {
                      final url =
                          '${profile.controlURL}/delete-account-with-login';
                      try {
                        if (await launchUrl(Uri.parse(url))) {
                          Navigator.pop(context);
                          widget.onNavigateToHome();
                        } else {
                          _showError('Could not launch $url');
                        }
                      } catch (e) {
                        _showError('Could not launch $url: $e');
                      }
                    },
                    child: Text('Delete Account',
                        style: TextStyle(
                          color: isApple()
                              ? CupertinoColors.destructiveRed
                                  .resolveFrom(context)
                              : Colors.red,
                        )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).show(context);
  }
}
