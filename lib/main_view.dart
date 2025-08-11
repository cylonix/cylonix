// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import 'files_waiting_view.dart';
import 'health_view.dart';
import 'models/ipn.dart';
import 'providers/ipn.dart';
import 'providers/settings.dart';
import 'providers/theme.dart';
import 'utils/logger.dart';
import 'utils/utils.dart';
import 'viewmodels/state_notifier.dart';
import 'widgets/adaptive_widgets.dart';
import 'widgets/alert_dialog_widget.dart';
import 'widgets/exit_node_status.dart';
import 'widgets/peer_list.dart';
import 'widgets/qr_code_image.dart';
import 'widgets/tv_widgets.dart';

class MainView extends ConsumerStatefulWidget {
  final Function() onNavigateToSettings;
  final Function() onNavigateToSendFiles;
  final Function() onNavigateToUserSwitcher;
  final Function(Node) onNavigateToPeerDetails;
  final Function() onNavigateToExitNodes;
  final Function() onNavigateToHealth;
  final Function() onNavigateToAbout;

  const MainView({
    Key? key,
    required this.onNavigateToSettings,
    required this.onNavigateToSendFiles,
    required this.onNavigateToUserSwitcher,
    required this.onNavigateToPeerDetails,
    required this.onNavigateToExitNodes,
    required this.onNavigateToHealth,
    required this.onNavigateToAbout,
  }) : super(key: key);

  @override
  ConsumerState<MainView> createState() => _MainViewState();
}

class _MainViewState extends ConsumerState<MainView> {
  static final _logger = Logger(tag: "MainView");
  Timer? _autoLaunchTimer;
  String? _urlToLaunch;
  bool _waitingForURL = false;
  int _launchCountDown = 10;
  bool _signingInWithApple = false;
  bool _signInWithAppSuccess = false;
  bool _showingSigninQRCode = false;

  @override
  void dispose() {
    _cancelAutoLaunchTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isApple()
        ? _buildCupertinoScaffold(context, ref)
        : _buildMaterialScaffold(context, ref);
  }

  Widget _buildMaterialScaffold(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    return Scaffold(
      appBar: _buildMaterialHeader(context, ref, user),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildContent(context, ref),
            ),
            if (ref.watch(pingDeviceProvider) != null)
              _buildMaterialPingSheet(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthButton(BuildContext context, WidgetRef ref) {
    final healthSeverity = ref.watch(healthSeverityProvider);
    return (healthSeverity != null)
        ? Container(
            constraints: const BoxConstraints(maxWidth: 24, maxHeight: 18),
            child: IconButton(
              iconSize: 16,
              //visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.only(left: 4, right: 4),
              constraints: const BoxConstraints(),
              icon: healthSeverity == Severity.high
                  ? AdaptiveErrorIcon()
                  : AdaptiveWarningIcon(),
              onPressed: widget.onNavigateToHealth,
            ),
          )
        : const SizedBox.shrink();
  }

  Widget _buildState(BuildContext context, WidgetRef ref) {
    final stateText = ref.watch(stateTextProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stateText,
          style: isApple()
              ? const TextStyle(fontSize: 14)
              : Theme.of(context).textTheme.bodyMedium,
        ),
        _buildHealthButton(context, ref),
      ],
    );
  }

  void _toggleVPN(BuildContext context, WidgetRef ref, bool toOn) async {
    try {
      await ref.read(ipnStateNotifierProvider.notifier).toggleVpn();
    } catch (e) {
      if (context.mounted) {
        showAlertDialog(context, "Error", "$e");
      }
    }
  }

  Widget? _buildSwitch(BuildContext context, WidgetRef ref) {
    final ipnState = ref.watch(ipnStateNotifierProvider);
    final mdmState = ref.watch(mdmForceEnabledProvider);
    final vpnState = ref.watch(vpnStateProvider);
    final isVPNPrepared = ref.watch(vpnPermissionStateProvider);
    final connectingOrDisconnecting =
        vpnState == VpnState.connecting || vpnState == VpnState.disconnecting;

    if (!isVPNPrepared) {
      return null;
    }

    return ipnState.when(
      loading: () => null,
      error: (error, _) => null,
      data: (state) {
        final value = state.vpnState == VpnState.connected;
        return mdmState.when(
          data: (isDisabled) {
            if (isDisabled) {
              return AdaptiveSwitch(
                value: value,
                onChanged: null,
              );
            }
            if (connectingOrDisconnecting) {
              return null;
            }
            return AdaptiveSwitch(
              value: value,
              onChanged: (v) => _toggleVPN(context, ref, v),
            );
          },
          loading: () => null,
          error: (_, __) => AdaptiveSwitch(
            value: value,
            onChanged: (v) => _toggleVPN(context, ref, v),
          ),
        );
      },
    );
  }

  Widget? _buildLeading(BuildContext context, WidgetRef ref) {
    final child = _buildSwitch(context, ref);
    if (child != null) {
      return Padding(
        padding: EdgeInsets.only(
          left: Platform.isMacOS && !useNavigationRail(context) ? 60 : 24,
        ),
        child: child,
      );
    }
    return child;
  }

  Widget _buildTitle(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    final profiles = ref.watch(loginProfilesProvider);
    final isAndroidTV = ref.watch(isAndroidTVProvider);
    final title = Text(
      user?.tailnetTitle ??
          (profiles.isNotEmpty ? "Select Profile" : "Needs Signin"),
      style: useNavigationRail(context) && !isAndroidTV
          ? null
          : isApple()
              ? CupertinoTheme.of(context).textTheme.navTitleTextStyle
              : Theme.of(context).textTheme.titleMedium,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [title, _buildState(context, ref)],
    );
  }

  PreferredSizeWidget _buildMaterialHeader(
      BuildContext context, WidgetRef ref, UserProfile? user) {
    final isAndroidTV = ref.watch(isAndroidTVProvider);
    return AppBar(
      title: _buildTitle(context, ref),
      titleSpacing: 24,
      leading: _buildLeading(context, ref),
      actions: [
        _buildToggleDeviceViewButton(context, ref),
        if (!useNavigationRail(context) || isAndroidTV)
          _buildProfileButton(context, ref, user),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildMaterialPingSheet(BuildContext context, WidgetRef ref) {
    final pingDevice = ref.watch(pingDeviceProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: ListTile(
        title: Text(pingDevice?.name ?? ''),
        subtitle: const Text('Pinging...'),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () =>
              ref.read(ipnStateNotifierProvider.notifier).stopPing(),
        ),
      ),
    );
  }

  Widget _buildToggleDeviceViewButton(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vpnStateProvider);
    if (state != VpnState.connected) {
      return const SizedBox.shrink();
    }

    final showDevices = ref.watch(showDevicesProvider);
    return AdaptiveButton(
      padding: useNavigationRail(context) ? null : EdgeInsets.zero,
      textButton: !useNavigationRail(context),
      onPressed: () {
        ref.read(showDevicesProvider.notifier).setValue(!showDevices);
      },
      child: Text(
        showDevices ? "Hide Devices" : "Show Devices",
        style:
            useNavigationRail(context) ? null : const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final netmap = ref.watch(netmapProvider);
    final state = ref.watch(backendStateProvider) ?? BackendState.noState;
    final showDevices = ref.watch(showDevicesProvider);
    final vpnState = ref.watch(vpnStateProvider);
    final errMessage = ref.watch(ipnErrMessageProvider);
    final isAndroidTV = ref.watch(isAndroidTVProvider);
    if (errMessage != null) {
      return _buildCenteredWidget(
        _buildErrorWidget(
          context,
          ref,
          errMessage,
          _resetIpnStateNotifier,
        ),
      );
    }

    if (vpnState == VpnState.connecting || vpnState == VpnState.disconnecting) {
      return _buildCenteredWidget(
        _buildConnectingView(context, vpnState == VpnState.connecting),
      );
    }
    switch (state) {
      case BackendState.running:
        break;
      case BackendState.starting:
        return _buildCenteredWidget(_buildConnectingView(context, true));
      default:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: _buildCenteredWidget(_buildConnectView(context, ref)),
        );
    }

    // Running state.
    if (_showingSigninQRCode) {
      _showingSigninQRCode = false;
      Navigator.pop(context);
    }

    // For android, we need to make sure vpn is prepared.
    if (Platform.isAndroid) {
      final vpnPreparedState = ref.watch(vpnPermissionNotifierProvider);
      final ret = vpnPreparedState.when<Widget?>(
        data: (state) {
          if (state.isGranted) {
            return null;
          }
          if (!state.hasBeenAsked) {
            return _buildPermissionRequest(context, ref);
          }
          return _buildErrorWidget(
            context,
            ref,
            "VPN permission not granted",
            _resetVPNPermissionNotifier,
          );
        },
        loading: () => _buildLoadingWithLogoView(context, ref),
        error: (error, stack) => _buildErrorWidget(
          context,
          ref,
          '$error',
          _resetVPNPermissionNotifier,
        ),
      );
      if (ret != null) {
        return _buildCenteredWidget(ret);
      }
    }

    final common = [
      _buildExpiryNotification(context, netmap, ref),
      _buildFilesWaitingSummary(context, ref),
      ExitNodeStatusWidget(onNavigate: widget.onNavigateToExitNodes),
    ];

    final child = !showDevices
        ? Column(
            spacing: 16,
            children: <Widget>[
              ...common,
              if (isAndroidTV) ...[
                const HealthStateWidget(),
              ],
              if (!isAndroidTV)
                Expanded(
                  child: _buildCenteredWidget(const HealthStateWidget()),
                ),
            ],
          )
        : Column(
            children: [
              ...common,
              Expanded(
                child: PeerList(
                  onPeerTap: widget.onNavigateToPeerDetails,
                ),
              ),
            ],
          );

    final container = Container(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: child,
      ),
    );

    if (isAndroidTV && !showDevices) {
      return Column(
        spacing: 32,
        children: [
          container,
          Expanded(
            child: Image.asset(
              'lib/assets/images/landing-banner.webp',
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.fill,
            ),
          ),
        ],
      );
    }
    return container;
  }

  Widget _buildCupertinoScaffold(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: appleScaffoldBackgroundColor(context),
      appBar: _buildCupertinoHeader(context, ref),
      body: _buildContent(context, ref),
    );
  }

  PreferredSizeWidget? _buildCupertinoHeader(
      BuildContext context, WidgetRef ref) {
    final backendState = ref.watch(backendStateProvider);
    final showLeading =
        (backendState?.value ?? 0) > BackendState.needsLogin.index;

    final user = ref.watch(userProfileProvider);
    if (useNavigationRail(context)) {
      if (!showLeading) return null;
      return CupertinoLargeNavigationBar(
        backgroundColor: Colors.transparent,
        automaticBackgroundVisibility: false,
        transitionBetweenRoutes: false,
        heroTag: "MainView",
        largeTitle: Row(
          spacing: 16,
          children: [
            _buildLeading(context, ref),
            Expanded(child: _buildTitle(context, ref)),
            _buildToggleDeviceViewButton(context, ref),
            const SizedBox(width: 16),
          ].nonNulls.toList(),
        ),
      );
    }
    return CupertinoNavigationBar(
      automaticBackgroundVisibility: false,
      transitionBetweenRoutes: false,
      heroTag: "MainView",
      leading: showLeading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                _buildLeading(context, ref),
                _buildTitle(context, ref),
              ].nonNulls.toList(),
            )
          : null,
      middle: showLeading
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Cylonix"),
                _buildHealthButton(context, ref),
                _buildToggleDeviceViewButton(context, ref),
              ],
            ),
      trailing: _buildProfileButton(context, ref, user),
    );
  }

  Widget _buildProfileButton(
      BuildContext context, WidgetRef ref, UserProfile? user) {
    final isAndroidTV = ref.watch(isAndroidTVProvider);
    if (useNavigationRail(context) && !isAndroidTV) {
      return const SizedBox.shrink();
    }
    final icon = user == null
        ? const Icon(CupertinoIcons.ellipsis_circle)
        : AdaptiveAvatar(radius: 18, user: user);

    if (isAndroidTV) {
      return TVButton(
        iconButton: true,
        onPressed: () => _showMaterialMenu(context, ref, user),
        child: icon,
      );
    }

    return IconButton(
      padding: const EdgeInsets.all(0),
      onPressed: () => isApple()
          ? _showCupertinoMenu(context, ref, user)
          : _showMaterialMenu(context, ref, user),
      icon: icon,
    );
  }

  Widget _buildFilesWaitingSummary(BuildContext context, WidgetRef ref) {
    final files = ref.watch(filesWaitingProvider);
    if (files.isEmpty) return const SizedBox.shrink();
    final totalSize = files.fold<int>(0, (sum, f) => sum + f.size);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: const EdgeInsets.all(16),
      child: AdaptiveListTile(
          backgroundColor: isApple()
              ? CupertinoColors.systemBrown
                  .resolveFrom(context)
                  .withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.primaryContainer,
          leading: const Icon(Icons.folder),
          title: Text("Files Waiting: ${files.length}"),
          subtitle: Text("Total Size: ${formatBytes(totalSize)}"),
          onTap: () {
            var height = MediaQuery.of(context).size.height * 0.9;
            if (height > 900) {
              height = height * 0.7;
            }

            AdaptiveModalPopup(
              maxWidth: 800,
              height: height,
              child: const FilesWaitingView(),
            ).show(context, minHeight: height);
          },
          trailing: const AdaptiveListTileChevron()),
    );
  }

  void _showMaterialMenu(
      BuildContext context, WidgetRef ref, UserProfile? user) {
    final healthSeverity = ref.watch(healthSeverityProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: AdaptiveAvatar(radius: 12, user: user),
                title: const Text('Account'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onNavigateToUserSwitcher();
                },
              ),
              ListTile(
                leading: AdaptiveSettingsIcon(size: 24),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onNavigateToSettings();
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined, size: 24),
                title: const Text('Send Files'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onNavigateToSendFiles();
                },
              ),
              ListTile(
                leading: (healthSeverity == null)
                    ? AdaptiveHealthyIcon(size: 24)
                    : healthSeverity == Severity.high
                        ? AdaptiveErrorIcon(size: 24)
                        : AdaptiveWarningIcon(size: 24),
                title: const Text('Health'),
                textColor: healthSeverity == Severity.high ? Colors.red : null,
                onTap: () {
                  Navigator.pop(context);
                  widget.onNavigateToHealth();
                },
              ),
              ListTile(
                leading: Icon(
                  isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  size: 24,
                ),
                title: Text(isDarkMode ? 'Light Mode' : 'Dark Mode'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(themeProvider.notifier).toggleTheme();
                },
              ),
            ],
          ),
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  void _showCupertinoMenu(
      BuildContext context, WidgetRef ref, UserProfile? user) {
    final healthSeverity = ref.watch(healthSeverityProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              widget.onNavigateToUserSwitcher();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                const Text('Account'),
                AdaptiveAvatar(radius: 8, user: user),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              widget.onNavigateToSettings();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                const Text('Settings'),
                AdaptiveSettingsIcon(size: 16),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: healthSeverity == Severity.high,
            onPressed: () {
              Navigator.pop(context);
              widget.onNavigateToHealth();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                const Text('Health'),
                (healthSeverity == null)
                    ? AdaptiveHealthyIcon(size: 16)
                    : healthSeverity == Severity.high
                        ? AdaptiveErrorIcon(size: 16)
                        : AdaptiveWarningIcon(size: 16),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              ref.read(themeProvider.notifier).toggleTheme();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                Text(isDarkMode ? 'Light Mode' : 'Dark Mode'),
                Icon(
                  isDarkMode
                      ? CupertinoIcons.sun_max_fill
                      : CupertinoIcons.moon_fill,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Widget _buildExpiryNotification(
      BuildContext context, NetworkMap? netmap, WidgetRef ref) {
    if (netmap == null) return const SizedBox.shrink();
    final expiryNotificationWindowMDM = MDMSettings.keyExpirationNotice;
    final window = (expiryNotificationWindowMDM != null
            ? GoTimeUtil.duration(expiryNotificationWindowMDM)
            : null) ??
        const Duration(hours: 64);
    if (!GoTimeUtil.isWithinExpiryNotificationWindow(
        window, netmap.selfNode.keyExpiry)) {
      return const SizedBox.shrink();
    }

    return AdaptiveListSection.insetGrouped(
      children: [
        AdaptiveListTile(
          title: Text(netmap.selfNode.expiryLabel()),
          subtitle: const Text("Reauthenticate to remain connected"),
          backgroundColor: CupertinoColors.systemYellow.withOpacity(0.2),
          onTap: () => _startSignin(context, ref),
        ),
      ],
    );
  }

  Widget _buildConnectView(BuildContext context, WidgetRef ref) {
    if (!isApple()) {
      // Android asks for VPN permission ONLY after backend is running.
      // We don't need to check for vpn permission first.
      return _buildVPNPreparedConnectView(context, ref);
    }

    return ref.watch(vpnPermissionNotifierProvider).when(
          data: (state) {
            if (!state.hasBeenAsked && !state.isGranted) {
              return _buildWelcomeView(context, ref);
            } else if (!state.isGranted) {
              return _buildPermissionRequest(context, ref);
            }
            return _buildVPNPreparedConnectView(context, ref);
          },
          loading: () => _buildLoadingWithLogoView(context, ref),
          error: (error, stack) => _buildErrorWidget(
            context,
            ref,
            '$error',
            _resetVPNPermissionNotifier,
          ),
        );
  }

  Future<void> _resetIpnStateNotifier() async {
    await ref.read(ipnStateNotifierProvider.notifier).reset();
  }

  Future<void> _resetVPNPermissionNotifier() async {
    await ref.read(vpnPermissionNotifierProvider.notifier).reset();
  }

  void _cancelAutoLaunchTimer() {
    _autoLaunchTimer?.cancel();
    _autoLaunchTimer = null;
  }

  void _launchUrl(String url, {bool force = false}) async {
    if (!force &&
        ref.read(ipnStateNotifierProvider.notifier).urlBrowsed == url) {
      _logger.d("URL already launched: $url");
      return;
    }
    _cancelAutoLaunchTimer();
    if (mounted) {
      setState(() {
        // Reset the state to trigger UI update
      });
    }
    if (mounted) {
      try {
        await ref.read(ipnStateNotifierProvider.notifier).startWebAuth(url);
      } catch (e) {
        _logger.e("Failed to sign in with '$url': $e");
        if (mounted) {
          await showAlertDialog(
            context,
            "Error",
            "Failed to sign in with '$url': $e",
          );
        }
      } finally {
        _urlToLaunch = null;
        _launchCountDown = 10;
      }
    }
  }

  void _setAutoLaunchUrl(String url) {
    final urlLaunched = ref.read(ipnStateNotifierProvider.notifier).urlBrowsed;
    if (urlLaunched != url && _urlToLaunch != url) {
      _logger.d("Setting auto-launch URL: $url");
      _urlToLaunch = url;
      _cancelAutoLaunchTimer();
      _launchCountDown = 10;
      _autoLaunchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _launchCountDown--;
        if (_launchCountDown <= 0) {
          _cancelAutoLaunchTimer();
          _urlToLaunch = null;
          _launchUrl(url);
        }
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  Widget _buildVPNPreparedConnectView(BuildContext context, WidgetRef ref) {
    final ipnState = ref.watch(ipnStateNotifierProvider);
    final isAndroidTV = ref.watch(isAndroidTVProvider);
    return ipnState.when(
      loading: () => _buildConnectingView(context, true),
      error: (error, stack) => _buildErrorWidget(
        context,
        ref,
        "$error",
        _resetIpnStateNotifier,
      ),
      data: (state) {
        if (state.browseToURL != null) {
          // Apple user to choose manually open the URL or sign in with apple.
          // AndroidTV shows a login QR code instead.
          if (!isApple() && !isAndroidTV) _setAutoLaunchUrl(state.browseToURL!);
          _waitingForURL = false;
        }
        if (state.vpnState == VpnState.connecting ||
            state.vpnState == VpnState.disconnecting) {
          return _buildConnectingView(
            context,
            state.vpnState == VpnState.connecting,
          );
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _buildNotRunningView(
            context,
            ref,
            state,
          ),
        );
      },
    );
  }

  Widget _buildConnectingView(BuildContext context, bool turningOn) {
    final health = ref.watch(healthProvider);
    if (health != null && health.warnings?['login-state'] != null) {
      return _buildLoginRequiredView(context, ref, null);
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: SingleChildScrollView(
        child: Column(
          spacing: MediaQuery.of(context).size.height > 600 ? 32 : 16,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 32),
            Text(
              turningOn ? "Starting..." : "Stopping...",
              style: Theme.of(context).textTheme.titleLarge?.apply(
                    fontWeightDelta: 2,
                    color: isApple()
                        ? CupertinoColors.label.resolveFrom(context)
                        : Theme.of(context).colorScheme.primary,
                  ),
            ),
            const AdaptiveLoadingWidget(),
            AdaptiveButton(
              width: 250,
              onPressed: () => _resetIpnStateNotifier(),
              child: const Text('Cancel and Retry'),
            ),
            AdaptiveButton(
              width: 250,
              onPressed: () => _startSignin(context, ref),
              child: const Text('Start Signin'),
            ),
            const HealthWarningList(color: CupertinoColors.systemBackground),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWithLogoView(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SizedBox(height: 32),
        const Flexible(child: Center(child: AdaptiveLoadingWidget())),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Image.asset(
              'lib/assets/images/cylonix_128.png',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotRunningView(
      BuildContext context, WidgetRef ref, IpnState state) {
    if (state.backendState == BackendState.needsMachineAuth) {
      return _buildAuthRequiredView(
        context,
        state.netmap?.selfNode.nodeAdminUrl,
      );
    }
    if (state.browseToURL != null ||
        state.backendState == BackendState.needsLogin) {
      return _buildLoginRequiredView(context, ref, state.browseToURL);
    }
    if (state.loggedInUser != null) {
      return _buildNotConnectedView(
        context,
        ref,
        state.loggedInUser!.loginName,
      );
    }
    if (state.vpnState == VpnState.disconnected) {
      return _buildStartView(context, ref);
    }
    if (state.backendState == BackendState.inUseOtherUser) {
      return _buildErrorWidget(
        context,
        ref,
        "In use by another user",
        null,
      );
    }
    return _buildConnectingView(
      context,
      state.vpnState != VpnState.disconnecting,
    );
  }

  Widget _buildStartView(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.vpn_key,
          size: 50,
          color: CupertinoColors.systemGrey,
        ),
        const SizedBox(height: 32),
        Text(
          'Cylonix Disconnected',
          style: Theme.of(context).textTheme.titleLarge?.apply(
                fontWeightDelta: 2,
                color: isApple()
                    ? CupertinoColors.label.resolveFrom(context)
                    : Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          'Start to connect to your network',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.apply(
                color: isApple()
                    ? CupertinoColors.secondaryLabel.resolveFrom(context)
                    : null,
              ),
        ),
        const SizedBox(height: 48),
        AdaptiveButton(
          filled: true,
          width: 200,
          onPressed: () => _onConnect(context, ref),
          child: const Text('Start'),
        ),
      ],
    );
  }

  Widget _buildPermissionRequest(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.vpn_key, size: 50),
          const SizedBox(height: 16),
          Text(
            'VPN Permission Required',
            style: Theme.of(context).textTheme.titleLarge?.apply(
                  fontWeightDelta: 2,
                  color: isApple()
                      ? CupertinoColors.label.resolveFrom(context)
                      : Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cylonix needs VPN permission to secure your connection. '
            'Please grant permission when prompted.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.apply(
                  color: isApple()
                      ? CupertinoColors.secondaryLabel.resolveFrom(context)
                      : null,
                ),
          ),
          const SizedBox(height: 48),
          AdaptiveButton(
            filled: true,
            onPressed: () => _requestPermission(context, ref),
            child: const Text('Continue to Grant Permission'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermission(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(vpnPermissionNotifierProvider.notifier)
          .requestPermission();
    } catch (e) {
      if (context.mounted) {
        await showAlertDialog(
          context,
          "Error",
          "Failed to request VPN permission: $e",
        );
      }
    }
  }

  Widget get _welcomeTitle {
    return Text(
      'Welcome to Cylonix',
      style: Theme.of(context).textTheme.titleLarge?.apply(
            fontWeightDelta: 2,
            color: isApple()
                ? CupertinoColors.label.resolveFrom(context)
                : Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Widget _buildWelcomeView(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 16,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.vpn_key, size: 50),
          const SizedBox(height: 16),
          _welcomeTitle,
          const SizedBox(height: 8),
          Text(
            'Approve VPN permissions to get started',
            style: Theme.of(context).textTheme.titleMedium?.apply(
                  color: isApple()
                      ? CupertinoColors.secondaryLabel.resolveFrom(context)
                      : null,
                ),
          ),
          const SizedBox(height: 16),
          AdaptiveButton(
            filled: true,
            width: 200,
            onPressed: () => _requestPermission(context, ref),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthRequiredView(BuildContext context, String? adminURL) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 40),
          const SizedBox(height: 16),
          Text(
            'Device Authentication Required',
            style: Theme.of(context).textTheme.titleLarge?.apply(
                  fontWeightDelta: 2,
                  color: isApple()
                      ? CupertinoColors.label.resolveFrom(context)
                      : Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text('This device needs to be authenticated by an admin',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.apply(
                    color: isApple()
                        ? CupertinoColors.secondaryLabel.resolveFrom(context)
                        : null,
                  )),
          const SizedBox(height: 16),
          if (adminURL != null)
            AdaptiveButton(
              onPressed: () => _loginToAdminURL(adminURL),
              child: const Text('Open Admin Console'),
            ),
        ],
      ),
    );
  }

  void _loginToAdminURL(String url) async {
    _logger.d("Launching to URL $url");
    final launched = await launchUrl(
      Uri.parse(url),
    );
    if (!launched) {
      throw Exception("Failed to launch admin URL at '$url'");
    }
  }

  Future<void> _onConnect(BuildContext context, ref) async {
    try {
      final backendState = ref.read(backendStateProvider);
      if (backendState == BackendState.stopped) {
        // Just toggle the VPN state.
        ref.read(ipnStateNotifierProvider.notifier).startVpn();
      } else {
        // Start the IPN service from scratch.
        ref.read(ipnStateNotifierProvider.notifier).start();
      }
    } catch (e) {
      showAlertDialog(context, "Error", 'Failed to start: $e');
    }
  }

  Widget _buildNotConnectedView(
      BuildContext context, WidgetRef ref, String username) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          Icon(
            Icons.power_settings_new,
            size: 40,
            color: isApple()
                ? CupertinoColors.systemGrey.resolveFrom(context)
                : Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Not Connected',
            style: isApple()
                ? TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.label.resolveFrom(context),
                  )
                : Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 32),
          Text(
            'Connect to your network as $username',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.apply(
                  color: isApple()
                      ? CupertinoColors.systemGrey.resolveFrom(context)
                      : null,
                ),
          ),
          const SizedBox(height: 16),
          AdaptiveButton(
            filled: true,
            width: 200,
            onPressed: () => _onConnect(context, ref),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _startSignin(BuildContext context, WidgetRef ref) async {
    setState(() {
      _waitingForURL = true;
    });
    try {
      await ref
          .read(ipnStateNotifierProvider.notifier)
          .login(controlURL: ref.read(controlURLProvider));
    } catch (e) {
      _logger.e("Failed to start signin: $e");
      await showAlertDialog(context, "Error", "Failed to start signin: $e");
    }
  }

  void _signinWithApple(String loginURL) async {
    _logger.d("Signing in with Apple: $loginURL");
    try {
      setState(() {
        _signingInWithApple = true;
        _signInWithAppSuccess = false;
      });
      final uri = Uri.parse(loginURL);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isEmpty || pathSegments.length < 2) {
        throw Exception("Invalid URL: missing state in path");
      }
      final state = pathSegments[1];
      final resp = await ref
          .read(ipnStateNotifierProvider.notifier)
          .signinWithApple(loginURL);
      setState(() {
        _signInWithAppSuccess = true;
      });
      if (resp == null) {
        return;
      }
      // Need to further process the response.
      if (resp.statusCode == 302) {
        Map<Object, Object?> details = {};
        try {
          final v = jsonDecode(resp.body) as Map<Object, Object?>;
          details = v['confirm_session'] as Map<Object, Object?>? ?? {};
          if (details.isEmpty) {
            _logger
                .d("Apple signin response is empty, no confirmation needed.");
            throw "No confirmation details.";
          }
        } catch (e) {
          _logger.e("Failed to parse Apple signin response: $e");
          throw "Failed to handle signin result: $e";
        }
        _logger.d(
          "Successfully signed in with Apple but needs user confirmation.",
        );
        final confirmed = await confirmDeviceConnection(resp, state, details);
        if (confirmed != true) {
          _logger.d(
              "User didn't confirmed Apple signin, proceeding to disconnect.");
          ref.read(ipnStateNotifierProvider.notifier).clearBrowseToURL();
          await ref.read(ipnStateNotifierProvider.notifier).logout();
          if (mounted) {
            showTopSnackBar(
              context,
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                height: 50,
                color: CupertinoColors.secondarySystemBackground
                    .resolveFrom(context),
                child: const Text(
                  "Apple signin was cancelled.",
                  textAlign: TextAlign.center,
                ),
              ),
              additionalTopPadding: 0,
              leftPadding: 0,
              rightPadding: 0,
            );
          }
        } else {
          _logger.d("User confirmed device connection.");
        }
      }
    } catch (e) {
      _logger.e("Failed to sign in with Apple: $e");
      if (mounted) {
        await showAlertDialog(
          context,
          "Error",
          "Failed to sign in with Apple: $e",
        );
      }
    } finally {
      _urlToLaunch = null;
      _signingInWithApple = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  List<Widget> _buildConnectionDetails(Map<Object, Object?> details) {
    return details.entries
        .map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 160, // Fixed width for keys
                  child: Text(
                    "${e.key}:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text("${e.value}"),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  Future<bool?> confirmDeviceConnection(
    http.Response resp,
    String state,
    Map<Object, Object?> details,
  ) async {
    return await showCupertinoModalPopup(
      context: context,
      builder: (c) => AdaptiveModalPopup(
        height: MediaQuery.of(c).size.height * 0.9,
        child: Container(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              spacing: 16,
              children: [
                CupertinoListTile(
                  leading: Icon(
                    CupertinoIcons.check_mark_circled,
                    color: CupertinoColors.systemGreen.resolveFrom(c),
                  ),
                  title: const Text('Apple Signin Success'),
                  trailing: AdaptiveButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Cancel'),
                  ),
                ),
                Text(
                  "Please confirm to connect this device to the network.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.secondaryLabel.resolveFrom(c),
                  ),
                ),
                AdaptiveButton(
                  filled: true,
                  onPressed: () async {
                    try {
                      ref
                          .read(ipnStateNotifierProvider.notifier)
                          .confirmDeviceConnection(resp, state);
                    } catch (e) {
                      _logger.e("Failed to confirm Apple signin: $e");
                      await showAlertDialog(
                        context,
                        "Error",
                        "Failed to confirm Apple signin: $e",
                      );
                    }
                    Navigator.pop(c, true);
                  },
                  child: const Text('Connect Device'),
                ),
                const Text(
                  "Device Details",
                ),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      const SizedBox(height: 8),
                      ..._buildConnectionDetails(details),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _canSignInWithAppleInApp {
    final isCylonixController = ref.watch(isCylonixControllerProvider);
    return isApple() && isCylonixController;
  }

  Widget _buildLoginRequiredView(
      BuildContext context, WidgetRef ref, String? loginURL) {
    final profiles = ref.watch(loginProfilesProvider);
    final urlLaunched = ref.watch(ipnStateNotifierProvider.notifier).urlBrowsed;
    final isAndroidTV = ref.watch(isAndroidTVProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 16,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          _welcomeTitle,
          const SizedBox(height: 8),
          if (loginURL == null) ...[
            Text(
              'Sign in to join your network',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.apply(
                    color: isApple()
                        ? CupertinoColors.secondaryLabel.resolveFrom(context)
                        : null,
                  ),
            ),
            const SizedBox(height: 16),
            if (!_waitingForURL)
              AdaptiveButton(
                autofocus: true,
                filled: true,
                onPressed: () => _startSignin(context, ref),
                child: const Text('Start Signin'),
              ),
            if (_waitingForURL) ...[
              const SizedBox(height: 16),
              Text(
                'Waiting for backend to start the signin process...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.apply(
                      color: isApple()
                          ? CupertinoColors.secondaryLabel.resolveFrom(context)
                          : null,
                    ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator.adaptive(),
            ],
          ],
          if (loginURL != null && _canSignInWithAppleInApp) ...[
            if (_signingInWithApple || urlLaunched == loginURL) ...[
              const AdaptiveLoadingWidget(),
              _signInWithAppSuccess
                  ? const Text(
                      "Signed in with Apple. Starting cylonix network. "
                      "Please wait...",
                      textAlign: TextAlign.center,
                    )
                  : const Text(
                      "Signing in with Apple. Please wait...",
                      textAlign: TextAlign.center,
                    ),
            ],
            if (!_signingInWithApple && urlLaunched != loginURL) ...[
              SizedBox(
                width: 300,
                child: SignInWithAppleButton(
                  height: 40,
                  style: isDarkMode(context)
                      ? SignInWithAppleButtonStyle.whiteOutlined
                      : SignInWithAppleButtonStyle.black,
                  onPressed: () => _signinWithApple(loginURL),
                ),
              ),
              AdaptiveButton(
                width: 300,
                height: 40,
                onPressed: () => _launchUrl(loginURL, force: true),
                child: const Text('Sign in with more methods'),
              ),
            ],
          ],
          if (loginURL != null && isAndroidTV) ...[
            const SizedBox(height: 16),
            Text(
              "Please scan the QR code with your phone to sign in.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.apply(
                    color: isApple()
                        ? CupertinoColors.secondaryLabel.resolveFrom(context)
                        : null,
                  ),
            ),
            const SizedBox(height: 16),
            AdaptiveButton(
                autofocus: true,
                filled: true,
                onPressed: () async {
                  _showingSigninQRCode = true;
                  await showDialog(
                    context: context,
                    builder: (c) {
                      return AlertDialog(
                        title: const Text("Sign in with QR Code"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 16,
                          children: [
                            Text(
                              "Scan this QR code with your phone to sign in "
                              "at $loginURL.",
                            ),
                            QrCodeImage(loginURL),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c),
                            child: const Text("Close"),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text("Show Signin QR Code")),
          ],
          if (loginURL != null &&
              !isAndroidTV &&
              !_canSignInWithAppleInApp) ...[
            urlLaunched == loginURL
                ? const AdaptiveLoadingWidget()
                : Text("$_launchCountDown seconds until auto-launch"),
            Text(
              urlLaunched != loginURL
                  ? "Please press the button below to be redirected to the "
                      "following web page to signin. Or you will be redirected "
                      "in a few seconds automatically."
                  : "Waiting for signin to complete on the following web page. ",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.apply(
                    color: isApple()
                        ? CupertinoColors.secondaryLabel.resolveFrom(context)
                        : null,
                  ),
            ),
            TextButton(
              onPressed: () => _launchUrl(loginURL, force: true),
              child: Text(
                loginURL,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            AdaptiveButton(
              filled: true,
              onPressed: () => _launchUrl(loginURL, force: true),
              child: const Text('Go to Signin Page'),
            ),
          ],
          if (profiles.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              "Or select a profile to sign in.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.apply(
                    color: isApple()
                        ? CupertinoColors.secondaryLabel.resolveFrom(context)
                        : null,
                  ),
            ),
            AdaptiveButton(
              textButton: true,
              onPressed: widget.onNavigateToUserSwitcher,
              child: const Text('Select Profile'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCenteredWidget(Widget child) {
    final height = MediaQuery.of(context).size.height;
    if (height <= 400) {
      return SingleChildScrollView(
        child: Center(child: child),
      );
    }
    if (height <= 800) {
      return Center(child: child);
    }
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Center(
            child: child,
          ),
        ),
        Expanded(flex: 1, child: Container()),
      ],
    );
  }

  Widget _buildErrorWidget(BuildContext context, WidgetRef ref, String error,
      Future<void> Function()? onRetry) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AdaptiveErrorWidget(error: error, onRetry: onRetry),
    );
  }
}
