import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      body: _buildUserList(context, users, loading: loading),
    );
  }

  Widget _buildCupertinoScaffold(BuildContext context, List<LoginProfile> users,
      {bool loading = false}) {
    return CupertinoPageScaffold(
      backgroundColor: appleScaffoldBackgroundColor(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        automaticBackgroundVisibility: false,
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
                if (users.length > 1)
                  _buildDontShowButtob(context, 'cylonix'),
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
                _buildDontShowButtob(context, 'tailscale'),
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
                _buildDontShowButtob(context, 'other'),
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
              onTap: _handleAddProfile,
            ),
            _buildActionTile(
              context,
              leading: const Icon(CupertinoIcons.arrow_right_circle),
              title: 'Reauthenticate',
              onTap: _handleReauthenticate,
            ),
            if (loginProfile != null) ...[
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
    var subtitle = u.loginName != u.displayName ? u.loginName : '';
    subtitle += showControlURL ? "\n(${user.controlURL})" : '';
    return AdaptiveListTile(
      title: Text(u.displayName),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      leading: CircleAvatar(
        backgroundColor: isApple() ? CupertinoColors.systemGrey5 : null,
        backgroundImage:
            u.profilePicURL.isNotEmpty ? NetworkImage(u.profilePicURL) : null,
        child: u.profilePicURL.isEmpty
            ? Text(
                u.displayName.characters.first.toUpperCase(),
                style: TextStyle(
                  color: isApple()
                      ? CupertinoColors.label.resolveFrom(context)
                      : null,
                ),
              )
            : null,
      ),
      trailing: isSwitching
          ? const AdaptiveLoadingWidget(maxWidth: 24)
          : isCurrentUser
              ? Icon(
                  isApple() ? CupertinoIcons.check_mark : Icons.check,
                  color: isApple()
                      ? CupertinoColors.activeBlue.resolveFrom(context)
                      : Theme.of(context).colorScheme.primary,
                )
              : const CupertinoListTileChevron(),
      onTap: isCurrentUser ? null : () => _handleSwitchProfile(user),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    Widget? leading,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
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
      trailing: title == 'Add Account' && _isAddingProfile
          ? const AdaptiveLoadingWidget(maxWidth: 24)
          : const AdaptiveListTileChevron(),
      onTap: _isAddingProfile ? null : onTap,
    );
  }

  Widget _buildDontShowButtob(BuildContext context, String section) {
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
          backgroundColor:
              CupertinoColors.systemBackground.resolveFrom(context),
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

  Future<void> _handleReauthenticate() async {
    await ref
        .read(ipnStateNotifierProvider.notifier)
        .login(controlURL: ref.read(controlURLProvider));
  }

  Future<void> _handleLogout() async {
    try {
      await ref.read(ipnStateNotifierProvider.notifier).logout();
      widget.onNavigateToHome();
    } catch (e) {
      _showError('Failed to sign out: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    if (isApple()) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
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

    if (isApple()) {
      await showCupertinoModalPopup(
        context: context,
        builder: (_) => AdaptiveModalPopup(
          child: Column(
            children: [
              CupertinoListTile(
                title: const Text('Profiles Data'),
                trailing: AdaptiveButton(
                  onPressed: () => Navigator.pop(_),
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
                          child:
                              Text(json, style: const TextStyle(fontSize: 14)),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Profiles Data'),
          content: SingleChildScrollView(
            child: Text(prettyJson.join('\n\n')),
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
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
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 600,
        ),
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
                      '"${profile.userProfile.displayName}". Please send a '
                      'request to contact@cylonix.io. After the request is '
                      'processed, you will receive an email with a link to '
                      'delete your account.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).show(context);
  }
}
