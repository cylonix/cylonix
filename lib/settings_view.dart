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
      body: ListView(
        children: [
          if (isVPNPrepared) ...[
            _buildUserTile(context, user),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.person_add,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Custom Login'),
              subtitle: const Text('Connect with auth key'),
              onTap: widget.onNavigateToCustomLogin,
            ),
            ListTile(
              leading: Icon(
                Icons.storage,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Custom Server'),
              subtitle: const Text('Set custom server URL'),
              onTap: widget.onNavigateToCustomControlURL,
            ),
          ],
          if (isAdmin) ...[
            const Divider(),
            _buildAdminTile(context),
          ],
          const Divider(height: 32, thickness: 8),
          ListTile(
            title: const Text('DNS Settings'),
            subtitle: Text(
                corpDNSEnabled ? 'Using Cylonix DNS' : 'Not using Cylonix DNS'),
            onTap: widget.onNavigateToDNSSettings,
          ),
          const Divider(),
          ListTile(
            title: const Text('Split Tunneling'),
            subtitle: const Text('Exclude certain apps from using Cylonix'),
            onTap: widget.onNavigateToSplitTunneling,
          ),
          if (showTailnetLock) ...[
            const Divider(),
            ListTile(
              title: const Text('Tailnet Lock'),
              subtitle: Text(tailnetLockEnabled ? 'Enabled' : 'Disabled'),
              onTap: widget.onNavigateToTailnetLock,
            ),
          ],
          const Divider(),
          ListTile(
            title: const Text('Permissions'),
            onTap: widget.onNavigateToPermissions,
          ),
          if (managedByOrg != null) ...[
            const Divider(),
            ListTile(
              title: Text('Managed by $managedByOrg'),
              onTap: widget.onNavigateToManagedBy,
            ),
          ],
          const Divider(height: 32, thickness: 8),
          ListTile(
            title: const Text('Bug Report'),
            onTap: widget.onNavigateToBugReport,
          ),
          const Divider(),
          ListTile(
            title: const Text('About Cylonix'),
            subtitle: const Text(
              'Version ${const String.fromEnvironment('VERSION')}',
            ),
            onTap: widget.onNavigateToAbout,
          ),
          if (const bool.fromEnvironment('DEBUG')) ...[
            const Divider(height: 32, thickness: 8),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Internal Debug Options',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ListTile(
              title: const Text('MDM Settings'),
              onTap: widget.onNavigateToMDMSettings,
            ),
          ],
        ],
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
        showAlertDialog(
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
    final tailchatAutoStart = ref.watch(tailchatAutoStartProvider);
    final tailchatRunning = ref.watch(tailchatServiceStateProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        automaticBackgroundVisibility: false,
        transitionBetweenRoutes: false,
        heroTag: "Settings",
        middle: const Text('Settings'),
        leading: widget.onNavigateBackHome == null
            ? null
            : AppleBackButton(onPressed: widget.onNavigateBackHome),
      ),
      child: Container(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            children: [
              if (isVPNPrepared) _buildCupertinoUserSection(context, ref, user),
              if (isAdmin) _buildCupertinoAdminSection(context),
              if (_isNetworkFeaturesReady)
                AdaptiveListSection(
                  header: const Text('NETWORK'),
                  children: [
                    AdaptiveListTile(
                      title: const Text('DNS Settings'),
                      subtitle: Text(corpDNSEnabled
                          ? 'Using Cylonix DNS'
                          : 'Not using Cylonix DNS'),
                      trailing: const CupertinoListTileChevron(),
                      onTap: widget.onNavigateToDNSSettings,
                    ),
                    AdaptiveListTile.notched(
                      title: const Text('Split Tunneling'),
                      subtitle:
                          const Text('Exclude certain apps from using Cylonix'),
                      trailing: const CupertinoListTileChevron(),
                      onTap: widget.onNavigateToSplitTunneling,
                    ),
                    if (showTailnetLock)
                      AdaptiveListTile.notched(
                        title: const Text('Tailnet Lock'),
                        subtitle:
                            Text(tailnetLockEnabled ? 'Enabled' : 'Disabled'),
                        trailing: const CupertinoListTileChevron(),
                        onTap: widget.onNavigateToTailnetLock,
                      ),
                  ],
                ),
              AdaptiveListSection.insetGrouped(
                children: [
                  AdaptiveListTile.notched(
                    title: const Text('Permissions'),
                    trailing: const CupertinoListTileChevron(),
                    onTap: widget.onNavigateToPermissions,
                  ),
                  if (managedByOrg != null)
                    AdaptiveListTile.notched(
                      title: Text('Managed by $managedByOrg'),
                      trailing: const CupertinoListTileChevron(),
                      onTap: widget.onNavigateToManagedBy,
                    ),
                ],
              ),
              AdaptiveListSection.insetGrouped(
                children: [
                  AdaptiveListTile.notched(
                    title: const Text('Report an Issue'),
                    subtitle: const Text('Open GitHub issue tracker'),
                    trailing: const CupertinoListTileChevron(),
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
                    trailing: const CupertinoListTileChevron(),
                    onTap: widget.onNavigateToAbout,
                  ),
                ],
              ),
              AdaptiveListSection.insetGrouped(
                header: const Text('Advanced Options'),
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
                        : CupertinoSwitch(
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
                          : CupertinoButton(
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
                      trailing: const CupertinoListTileChevron(),
                      onTap: widget.onNavigateToMDMSettings,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, UserProfile? user) {
    return ListTile(
      title: Text(user?.displayName ?? ''),
      subtitle: Text(user?.loginName ?? ''),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        backgroundImage: (user?.profilePicURL.isNotEmpty ?? false)
            ? NetworkImage(user!.profilePicURL)
            : null,
        child: !(user?.profilePicURL.isNotEmpty ?? false)
            ? Text(
                user?.displayName.characters.first.toUpperCase() ?? '',
                style: Theme.of(context).textTheme.titleMedium,
              )
            : null,
      ),
      onTap: widget.onNavigateToUserSwitcher,
    );
  }

  Widget _buildAdminTile(BuildContext context) {
    return ListTile(
      title: const Text('Admin Console'),
      subtitle: const Text('Manage your organization'),
      leading: Icon(
        Icons.admin_panel_settings,
        color: Theme.of(context).colorScheme.primary,
      ),
      onTap: widget.onNavigateToManagedBy,
    );
  }

  Widget _buildCupertinoUserSection(
      BuildContext context, WidgetRef ref, UserProfile? user) {
    final profiles = ref.watch(loginProfilesProvider);
    return AdaptiveListSection.insetGrouped(
      header: const Text('ACCOUNT'),
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
          subtitle: user?.loginName != null ? Text((user?.loginName)!) : null,
          trailing: const CupertinoListTileChevron(),
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
          trailing: const CupertinoListTileChevron(),
          onTap: widget.onNavigateToCustomLogin,
        ),
        AdaptiveListTile.notched(
          leading: const Icon(
            CupertinoIcons.cloud,
            color: CupertinoColors.activeBlue,
          ),
          title: const Text('Custom Server'),
          subtitle: const Text('Set custom server URL'),
          trailing: const CupertinoListTileChevron(),
          onTap: widget.onNavigateToCustomControlURL,
        ),
      ],
    );
  }

  Widget _buildCupertinoAdminSection(BuildContext context) {
    return AdaptiveListSection.insetGrouped(
      header: const Text('ADMIN'),
      children: [
        AdaptiveListTile.notched(
          leading: const Icon(
            CupertinoIcons.person_crop_circle_badge_checkmark,
            color: CupertinoColors.activeBlue,
          ),
          title: const Text('Admin Console'),
          subtitle: const Text('Manage your organization'),
          trailing: const CupertinoListTileChevron(),
          onTap: widget.onNavigateToManagedBy,
        ),
      ],
    );
  }
}
