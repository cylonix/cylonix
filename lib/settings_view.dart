import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/ipn.dart';
import 'providers/ipn.dart';
import 'providers/settings.dart';
import 'utils/logger.dart';
import 'utils/utils.dart';
import 'viewmodels/state_notifier.dart';
import 'widgets/adaptive_widgets.dart';
import 'widgets/alert_dialog_widget.dart';
import 'widgets/ipn_logs_widget.dart';
import 'widgets/ui_logs_widget.dart';

class SettingsView extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateBackHome;
  final VoidCallback? onNavigateBackToSettings;
  final VoidCallback onNavigateToCustomLogin;
  final VoidCallback onNavigateToCustomControlURL;
  final VoidCallback onNavigateToUserSwitcher;
  final VoidCallback onNavigateToDNSSettings;
  final VoidCallback onNavigateToSplitTunneling;
  final VoidCallback onNavigateToTailnetLock;
  final VoidCallback onNavigateToPermissions;
  final VoidCallback onNavigateToManagedBy;
  final VoidCallback onNavigateToBugReport;
  final VoidCallback onNavigateToAbout;
  final VoidCallback onNavigateToMDMSettings;
  final Function(Widget)? onPushNewPage;

  const SettingsView(
      {super.key,
      this.onNavigateBackHome,
      this.onNavigateBackToSettings,
      required this.onNavigateToCustomLogin,
      required this.onNavigateToCustomControlURL,
      required this.onNavigateToUserSwitcher,
      required this.onNavigateToDNSSettings,
      required this.onNavigateToSplitTunneling,
      required this.onNavigateToTailnetLock,
      required this.onNavigateToPermissions,
      required this.onNavigateToManagedBy,
      required this.onNavigateToBugReport,
      required this.onNavigateToAbout,
      required this.onNavigateToMDMSettings,
      this.onPushNewPage});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  static final _logger = Logger(tag: "SettingsView");
  bool _isTogglingTailchat = false;
  bool _isTogglingAlwaysUseDerp = false;
  static const bool _isNetworkFeaturesReady = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final managedByOrg = ref.watch(managedByOrgProvider);
    final tailnetLockEnabled = ref.watch(tailnetLockEnabledProvider);
    final corpDNSEnabled = ref.watch(corpDNSEnabledProvider);
    final isVPNPrepared = ref.watch(vpnPermissionStateProvider);
    final showTailnetLock = ref.watch(showTailnetLockProvider);

    return isApple()
        ? _buildCupertinoSettings(
            context,
            ref,
            user,
            isAdmin,
            managedByOrg,
            tailnetLockEnabled,
            corpDNSEnabled,
            isVPNPrepared,
            showTailnetLock,
          )
        : _buildMaterialSettings(
            context,
            ref,
            user,
            isAdmin,
            managedByOrg,
            tailnetLockEnabled,
            corpDNSEnabled,
            isVPNPrepared,
            showTailnetLock,
          );
  }

  Widget _buildMaterialSettings(
    BuildContext context,
    WidgetRef ref,
    UserProfile? user,
    bool isAdmin,
    String? managedByOrg,
    bool tailnetLockEnabled,
    bool corpDNSEnabled,
    bool isVPNPrepared,
    bool showTailnetLock,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: widget.onNavigateBackHome != null
            ? BackButton(onPressed: widget.onNavigateBackHome)
            : null,
      ),
      body: _buildSettingsContent(
        context,
        ref,
        user,
        isAdmin,
        managedByOrg,
        tailnetLockEnabled,
        corpDNSEnabled,
        isVPNPrepared,
        showTailnetLock,
      ),
    );
  }

  Future<void> _toggleTailchatService() async {
    setState(() {
      _isTogglingTailchat = true;
    });
    var isRunning = false;
    try {
      isRunning = ref.read(tailchatServiceStateProvider);
      if (isRunning) {
        await ref.read(ipnStateNotifierProvider.notifier).stopTailchat();
      } else {
        await ref.read(ipnStateNotifierProvider.notifier).startTailchat();
      }
    } catch (e) {
      if (mounted) {
        await showAlertDialog(
          context,
          "Error",
          "Failed to set tailchat service setting to ${!isRunning}: $e",
        );
      }
    } finally {
      _isTogglingTailchat = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _toggleAlwaysUseDerp(bool value) async {
    setState(() {
      _isTogglingAlwaysUseDerp = true;
    });
    try {
      await ref.read(ipnStateNotifierProvider.notifier).setAlwaysUseDerp(value);
      await ref.read(alwaysUseDerpProvider.notifier).setValue(value);
    } catch (e) {
      _logger.e("$e");
      if (mounted) {
        await showAlertDialog(
          context,
          "Error",
          "Failed to set 'Always Use Relay' setting to $value: $e",
        );
      }
    } finally {
      _isTogglingAlwaysUseDerp = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _launchBugReport() async {
    final uri = Uri.parse('https://github.com/cylonix/cylonix/issues/new');
    if (!await launchUrl(uri)) {
      debugPrint('Could not launch $uri');
    }
  }

  Widget _buildCupertinoSettings(
    BuildContext context,
    WidgetRef ref,
    UserProfile? user,
    bool isAdmin,
    String? managedByOrg,
    bool tailnetLockEnabled,
    bool corpDNSEnabled,
    bool isVPNPrepared,
    bool showTailnetLock,
  ) {
    return CupertinoPageScaffold(
      backgroundColor: appleScaffoldBackgroundColor(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        automaticBackgroundVisibility: false,
        transitionBetweenRoutes: false,
        heroTag: "Settings",
        middle: const Text('Settings'),
        leading: widget.onNavigateBackHome == null
            ? null
            : AppleBackButton(onPressed: widget.onNavigateBackHome),
      ),
      child: _buildSettingsContent(
        context,
        ref,
        user,
        isAdmin,
        managedByOrg,
        tailnetLockEnabled,
        corpDNSEnabled,
        isVPNPrepared,
        showTailnetLock,
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    WidgetRef ref,
    UserProfile? user,
    bool isAdmin,
    String? managedByOrg,
    bool tailnetLockEnabled,
    bool corpDNSEnabled,
    bool isVPNPrepared,
    bool showTailnetLock,
  ) {
    final tailchatAutoStart = ref.watch(tailchatAutoStartProvider);
    final tailchatRunning = ref.watch(tailchatServiceStateProvider);
    return Container(
      alignment: Alignment.topCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          children: [
            if (isVPNPrepared) _buildUserSection(context, ref, user),
            if (isAdmin) _buildAdminSection(context),
            if (_isNetworkFeaturesReady)
              AdaptiveListSection.insetGrouped(
                header: Text(
                  'NETWORK',
                  style:
                      isApple() ? null : Theme.of(context).textTheme.titleLarge,
                ),
                children: [
                  AdaptiveListTile(
                    title: const Text('DNS Settings'),
                    subtitle: Text(corpDNSEnabled
                        ? 'Using Cylonix DNS'
                        : 'Not using Cylonix DNS'),
                    trailing: _trailingIcon,
                    onTap: widget.onNavigateToDNSSettings,
                  ),
                  AdaptiveListTile.notched(
                    title: const Text('Split Tunneling'),
                    subtitle:
                        const Text('Exclude certain apps from using Cylonix'),
                    trailing: _trailingIcon,
                    onTap: widget.onNavigateToSplitTunneling,
                  ),
                  if (showTailnetLock)
                    AdaptiveListTile.notched(
                      title: const Text('Tailnet Lock'),
                      subtitle:
                          Text(tailnetLockEnabled ? 'Enabled' : 'Disabled'),
                      trailing: _trailingIcon,
                      onTap: widget.onNavigateToTailnetLock,
                    ),
                ],
              ),
            AdaptiveListSection.insetGrouped(
              children: [
                AdaptiveListTile.notched(
                  title: const Text('Permissions'),
                  trailing: _trailingIcon,
                  onTap: widget.onNavigateToPermissions,
                ),
                if (managedByOrg != null)
                  AdaptiveListTile.notched(
                    title: Text('Managed by $managedByOrg'),
                    trailing: _trailingIcon,
                    onTap: widget.onNavigateToManagedBy,
                  ),
              ],
            ),
            AdaptiveListSection.insetGrouped(
              children: [
                AdaptiveListTile.notched(
                  title: const Text('Report an Issue'),
                  subtitle: const Text('Open GitHub issue tracker'),
                  trailing: _trailingIcon,
                  onTap: _launchBugReport,
                ),
                AdaptiveListTile.notched(
                  title: const Text('About Cylonix'),
                  subtitle: FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final version = snapshot.data?.version ?? '';
                      return Text('Version $version');
                    },
                  ),
                  trailing: _trailingIcon,
                  onTap: widget.onNavigateToAbout,
                ),
              ],
            ),
            AdaptiveListSection.insetGrouped(
              header: const AdaptiveGroupedHeader(
                'Advanced Options',
              ),
              children: [
                UILogsWidget(
                  onNavigateBack: widget.onNavigateBackToSettings,
                  onNavigateToLogConsole: widget.onPushNewPage,
                ),
                IpnLogsWidget(
                  onNavigateBack: widget.onNavigateBackToSettings,
                  onNavigateToLogConsole: widget.onPushNewPage,
                ),
                AdaptiveListTile.notched(
                  title: const Text('Always Use Relay'),
                  subtitle: const Text('Force traffic through relay servers'),
                  trailing: _isTogglingAlwaysUseDerp
                      ? const CupertinoActivityIndicator()
                      : AdaptiveSwitch(
                          value: ref.watch(alwaysUseDerpProvider),
                          onChanged: _toggleAlwaysUseDerp,
                        ),
                ),
                if (Platform.isIOS) ...[
                  AdaptiveListTile.notched(
                    title: const Text('Start Tailchat on Launch'),
                    trailing: CupertinoSwitch(
                      value: tailchatAutoStart,
                      onChanged: (value) {
                        ref
                            .read(tailchatAutoStartProvider.notifier)
                            .setValue(value);
                      },
                    ),
                  ),
                  AdaptiveListTile.notched(
                    title: const Text('Tailchat Service'),
                    subtitle: Text(tailchatRunning ? 'Running' : 'Stopped'),
                    trailing: _isTogglingTailchat
                        ? const CupertinoActivityIndicator()
                        : AdaptiveButton(
                            padding: EdgeInsets.zero,
                            child: Text(tailchatRunning ? 'Stop' : 'Start'),
                            onPressed: _toggleTailchatService,
                          ),
                  ),
                ],
              ],
            ),
            if (const bool.fromEnvironment('DEBUG'))
              AdaptiveListSection.insetGrouped(
                header: const Text('INTERNAL DEBUG OPTIONS'),
                children: [
                  AdaptiveListTile.notched(
                    title: const Text('MDM Settings'),
                    trailing: _trailingIcon,
                    onTap: widget.onNavigateToMDMSettings,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection(
      BuildContext context, WidgetRef ref, UserProfile? user) {
    final profiles = ref.watch(loginProfilesProvider);
    return AdaptiveListSection.insetGrouped(
      header: const AdaptiveGroupedHeader(
        'ACCOUNT',
      ),
      children: [
        AdaptiveListTile.notched(
          leading: AdaptiveAvatar(
            radius: 20,
            user: user,
          ),
          title: Text(
            user?.displayName ??
                (profiles.isNotEmpty
                    ? "Select Profile or Login"
                    : "Please Login"),
          ),
          subtitle:
              user?.loginName != null && user?.loginName != user?.displayName
                  ? Text((user?.loginName)!)
                  : null,
          trailing: _trailingIcon,
          onTap: profiles.isEmpty
              ? widget.onNavigateBackHome
              : widget.onNavigateToUserSwitcher,
        ),
        AdaptiveListTile.notched(
          leading: const Icon(
            CupertinoIcons.person_badge_plus,
            color: CupertinoColors.activeBlue,
          ),
          title: const Text('Custom Login'),
          subtitle: const Text('Connect with auth key'),
          trailing: _trailingIcon,
          onTap: widget.onNavigateToCustomLogin,
        ),
        AdaptiveListTile.notched(
          leading: const Icon(
            CupertinoIcons.cloud,
            color: CupertinoColors.activeBlue,
          ),
          title: const Text('Custom Server'),
          subtitle: const Text('Set custom server URL'),
          trailing: _trailingIcon,
          onTap: widget.onNavigateToCustomControlURL,
        ),
      ],
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    return AdaptiveListSection.insetGrouped(
      header: const AdaptiveGroupedHeader(
        'ADMIN',
      ),
      children: [
        AdaptiveListTile.notched(
          leading: const Icon(
            CupertinoIcons.person_crop_circle_badge_checkmark,
            color: CupertinoColors.activeBlue,
          ),
          title: const Text('Admin Console'),
          subtitle: const Text('Manage your organization'),
          trailing: _trailingIcon,
          onTap: widget.onNavigateToManagedBy,
        ),
      ],
    );
  }

  Widget? get _trailingIcon {
    return const AdaptiveListTileChevron();
  }
}
