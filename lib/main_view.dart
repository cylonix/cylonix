import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'widgets/main_drawer.dart';
import 'widgets/peer_list.dart';

class MainView extends ConsumerStatefulWidget {
  final Function(String) onLoginAtUrl;
  final Function() onNavigateToSettings;
  final Function() onNavigateToUserSwitcher;
  final Function(Node) onNavigateToPeerDetails;
  final Function() onNavigateToExitNodes;
  final Function() onNavigateToHealth;
  final Function() onNavigateToAbout;

  const MainView({
    Key? key,
    required this.onLoginAtUrl,
    required this.onNavigateToSettings,
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
  String? _urlLaunched;
  bool _waitingForURL = false;

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
    return Scaffold(
      appBar: _buildMaterialHeader(context, ref),
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
      endDrawer: useNavigationRail(context)
          ? null
          : MainDrawer(
              onNavigateToSettings: widget.onNavigateToSettings,
              onNavigateToUserSwitch: widget.onNavigateToUserSwitcher,
              onNavigateToExitNodes: widget.onNavigateToExitNodes,
              onNavigateToHealth: widget.onNavigateToHealth,
              onNavigateToAbout: widget.onNavigateToAbout,
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

  Widget _buildSwitch(BuildContext context, WidgetRef ref) {
    final ipnState = ref.watch(ipnStateNotifierProvider);
    final mdmState = ref.watch(mdmForceEnabledProvider);
    final isVPNPrepared = ref.watch(vpnPermissionStateProvider);

    if (!isVPNPrepared) {
      return const SizedBox.shrink();
    }

    return ipnState.when(
      loading: () => const AdaptiveLoadingWidget(),
      error: (error, _) => AdaptiveSwitch(
        value: false,
        onChanged: (v) => _toggleVPN(context, ref, v),
      ),
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
            return AdaptiveSwitch(
              value: value,
              onChanged: (v) => _toggleVPN(context, ref, v),
            );
          },
          loading: () => const AdaptiveLoadingWidget(),
          error: (_, __) => AdaptiveSwitch(
            value: value,
            onChanged: (v) => _toggleVPN(context, ref, v),
          ),
        );
      },
    );
  }

  Widget _buildLeading(BuildContext context, WidgetRef ref) {
    final child = _buildSwitch(context, ref);
    if (Platform.isMacOS && !useNavigationRail(context)) {
      return Padding(
        padding: const EdgeInsets.only(left: 60),
        child: child,
      );
    }
    return child;
  }

  Widget _buildTitle(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    final profiles = ref.watch(loginProfilesProvider);
    final title = Text(
      user?.tailnetTitle ??
          (profiles.isNotEmpty ? "Select Profile" : "Needs Login"),
      style: useNavigationRail(context)
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
      BuildContext context, WidgetRef ref) {
    return AppBar(
      title: _buildTitle(context, ref),
      leading: _buildLeading(context, ref),
      actions: useNavigationRail(context)
          ? null
          : [
              _buildMaterialProfileButton(context, ref),
            ],
    );
  }

  Widget _buildMaterialProfileButton(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    if (user == null) {
      return IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () => Scaffold.of(context).openDrawer(),
      );
    }

    return InkWell(
      onTap: () => Scaffold.of(context).openDrawer(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          radius: 20,
          backgroundImage: user.profilePicURL.isNotEmpty
              ? NetworkImage(user.profilePicURL)
              : null,
          child: user.profilePicURL.isEmpty
              ? Text(user.displayName[0].toUpperCase())
              : null,
        ),
      ),
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

  Widget _buildMaterialExpiryNotification(
      BuildContext context, NetworkMap? netmap, WidgetRef ref) {
    if (netmap == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.amber.shade50,
      child: ListTile(
        title: Text(netmap.selfNode.expiryLabel()),
        subtitle: const Text("Reauthenticate to remain connected"),
        onTap: () => _login(context, ref),
      ),
    );
  }

  Widget _buildToggleDeviceViewButton(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backendStateProvider) ?? BackendState.noState;
    if (state != BackendState.running) {
      return const SizedBox.shrink();
    }

    final showDevices = ref.watch(showDevicesProvider);
    return AdaptiveButton(
      onPressed: () {
        ref.read(showDevicesProvider.notifier).setValue(!showDevices);
      },
      child: Text(showDevices ? "Hide Devices" : "Show Devices"),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final netmap = ref.watch(netmapProvider);
    final state = ref.watch(backendStateProvider) ?? BackendState.noState;
    final showDevices = ref.watch(showDevicesProvider);
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

    final child = !showDevices
        ? Column(
            spacing: 16,
            children: [
              ExitNodeStatusWidget(onNavigate: widget.onNavigateToExitNodes),
              if (!useNavigationRail(context)) ...[
                _buildToggleDeviceViewButton(context, ref),
              ],
              Expanded(
                child: _buildCenteredWidget(const HealthStateWidget()),
              ),
            ],
          )
        : Column(
            children: [
              if (isApple())
                _buildExpiryNotification(context, netmap, ref)
              else
                _buildMaterialExpiryNotification(context, netmap, ref),
              ExitNodeStatusWidget(onNavigate: widget.onNavigateToExitNodes),
              if (!useNavigationRail(context)) ...[
                _buildToggleDeviceViewButton(context, ref),
              ],
              Expanded(
                child: PeerList(
                  onPeerTap: widget.onNavigateToPeerDetails,
                ),
              ),
            ],
          );
    return Container(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: child,
      ),
    );
  }

  Widget _buildCupertinoScaffold(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor:
          CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
        context,
      ),
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
          ],
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
              ],
            )
          : null,
      middle: showLeading
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Cylonix"),
                _buildHealthButton(context, ref),
              ],
            ),
      trailing: _buildCupertinoProfileButton(context, ref, user),
    );
  }

  Widget _buildCupertinoProfileButton(
      BuildContext context, WidgetRef ref, UserProfile? user) {
    if (useNavigationRail(context)) return const SizedBox.shrink();

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _showCupertinoMenu(context, ref),
      child: user == null
          ? const Icon(CupertinoIcons.ellipsis_circle)
          : CircleAvatar(
              radius: 18,
              backgroundColor: CupertinoColors.systemGrey5,
              backgroundImage: user.profilePicURL.isNotEmpty
                  ? NetworkImage(user.profilePicURL)
                  : null,
              child: user.profilePicURL.isEmpty
                  ? Text(
                      user.displayName[0].toUpperCase(),
                      style: const TextStyle(
                        color: CupertinoColors.label,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
    );
  }

  void _showCupertinoMenu(BuildContext context, WidgetRef ref) {
    final healthSeverity = ref.watch(healthSeverityProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: <CupertinoActionSheetAction>[
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
          isDestructiveAction: true,
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
          onTap: () => _login(context, ref),
        ),
      ],
    );
  }

  Widget _buildConnectView(BuildContext context, WidgetRef ref) {
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

  void _launchUrl(String url, {bool force = false}) {
    if (!force &&
        ref.read(ipnStateNotifierProvider.notifier).urlBrowsed == url) {
      _logger.d("URL already launched: $url");
      return;
    }
    if (mounted) {
      setState(() {
        _urlLaunched = url;
      });
      ref.read(ipnStateNotifierProvider.notifier).urlBrowsed = url;
      _cancelAutoLaunchTimer();
      widget.onLoginAtUrl(url);
    }
  }

  void _setAutoLaunchUrl(String url) {
    if (_urlLaunched != url) {
      _cancelAutoLaunchTimer();
      _autoLaunchTimer = Timer(const Duration(seconds: 10), () {
        _launchUrl(url);
      });
    }
  }

  Widget _buildVPNPreparedConnectView(BuildContext context, WidgetRef ref) {
    final ipnState = ref.watch(ipnStateNotifierProvider);
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
          _setAutoLaunchUrl(state.browseToURL!);
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
          child: _buildNotStoppedAndNotRunningView(
            context,
            ref,
            state,
          ),
        );
      },
    );
  }

  Widget _buildConnectingView(BuildContext context, bool turningOn) {
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
            _cancelAndRetryButton,
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

  Widget _buildNotStoppedAndNotRunningView(
      BuildContext context, WidgetRef ref, IpnState state) {
    _logger.d(
      "Building not stopped and not running view: state="
      "${state.backendState.name} ${state.vpnState.name}",
    );

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
    if (state.backendState == BackendState.noState &&
        state.vpnState == VpnState.disconnected) {
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

  Widget get _cancelAndRetryButton {
    return AdaptiveButton(
      onPressed: () => _resetIpnStateNotifier(),
      child: const Text('Cancel and Retry'),
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
    return Column(
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
    return Column(
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
    );
  }

  Widget _buildAuthRequiredView(BuildContext context, String? adminURL) {
    return Column(
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
            onPressed: () => widget.onLoginAtUrl(adminURL),
            child: const Text('Open Admin Console'),
          ),
      ],
    );
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
    return Column(
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
    );
  }

  void _login(BuildContext context, WidgetRef ref) async {
    setState(() {
      _waitingForURL = true;
    });
    try {
      await ref
          .read(ipnStateNotifierProvider.notifier)
          .login(controlURL: ref.read(controlURLProvider));
    } catch (e) {
      _logger.e("Failed to login: $e");
      await showAlertDialog(context, "Error", "Failed to start login: $e");
    }
  }

  Widget _buildLoginRequiredView(
      BuildContext context, WidgetRef ref, String? loginURL) {
    final profiles = ref.watch(loginProfilesProvider);
    return Column(
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
              filled: true,
              onPressed: () => _login(context, ref),
              child: const Text('Sign In'),
            ),
          if (_waitingForURL) ...[
            const SizedBox(height: 16),
            Text(
              'Waiting for backend to send the login URL...',
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
        if (loginURL != null) ...[
          if (_urlLaunched == loginURL) ...[
            const AdaptiveLoadingWidget(),
          ],
          Text(
            _urlLaunched != loginURL
                ? "Please press the button below to be redirected to the "
                    "following web page to login. Or you will be redirected in "
                    "10 seconds."
                : "Waiting for login to complete on the following web page. ",
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
            child: const Text('Go to Login Page'),
          ),
        ],
        if (profiles.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            "Or select a profile to login.",
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
    );
  }

  Widget _buildCenteredWidget(Widget child) {
    if (MediaQuery.of(context).size.height < 500) {
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
    return AdaptiveErrorWidget(error: error, onRetry: onRetry);
  }
}
