// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'about_view.dart';
import 'custom_login_view.dart';
import 'dns_settings_view.dart';
import 'exit_node_picker.dart';
import 'health_view.dart';
import 'intro_page.dart';
import 'main_view.dart';
import 'models/ipn.dart';
import 'models/shared_file.dart';
import 'peer_messaging_inbox_view.dart';
import 'peer_details_view.dart';
import 'permissions_view.dart';
import 'providers/ipn.dart';
import 'providers/peer_messaging.dart';
import 'providers/share_file.dart';
import 'providers/theme.dart';
import 'services/android_taildrop_notifications.dart';
import 'services/share_request_inbox.dart';
import 'services/system_tray_service.dart';
import 'run_exit_node_view.dart';
import 'settings_view.dart';
import 'share_view.dart';
import 'split_tunnel_view.dart';
import 'subnet_routing_view.dart';
import 'utils/applog.dart';
import 'utils/logger.dart';
import 'utils/utils.dart';
import 'user_switcher_view.dart';
import 'viewmodels/state_notifier.dart';
import 'widgets/adaptive_widgets.dart';
import 'widgets/alert_dialog_widget.dart';
import 'widgets/battery_optimization_dialog.dart';
import 'widgets/main_navigation_rail.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WindowListener, WidgetsBindingObserver {
  static final _logger = Logger(tag: "HomePage");
  Page _page = Page.mainView;
  int _previousPage = Page.mainView.value;
  int? _nodeID;
  Widget? _rightSide;
  StreamSubscription<void>? _shareRequestSub;
  bool _showingShareSheet = false;
  // Closing the window again while the minimize-to-tray prompt is open must
  // not stack a second prompt. The flag is set before the route is pushed
  // (a fast double-click on close beats the first frame); the context is
  // the prompt's own, recorded once its builder runs, for popping it.
  bool _minimizeDialogShowing = false;
  BuildContext? _minimizeDialogContext;

  @override
  void initState() {
    super.initState();
    _initLogger();
    WidgetsBinding.instance.addObserver(this);
    _shareRequestSub =
        ShareRequestInbox.updates.listen((_) => _drainShareRequests());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_pullPendingShareRequests());
    });
    if (Platform.isWindows || Platform.isMacOS) {
      windowManager.addListener(this);
      SystemTrayService.onShow = _dismissMinimizeToTrayDialog;
    }
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        () {
      _logger.i("Platform brightness changed");
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      ref.read(systemBrightnessProvider.notifier).updateBrightness(brightness);
    };
    if (Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_maybeShowBatteryOptimizationPrompt());
        unawaited(_maybeShowTaildropHeadsUpTip());
      });
    }
  }

  Future<void> _maybeShowBatteryOptimizationPrompt() async {
    // Same intro-flow gating as the taildrop tip below — but wait out app
    // startup first: introViewedProvider reads as its default (false)
    // until sharedPreferencesProvider resolves, so checking it at
    // first-frame time silently skips the prompt on every cold start.
    // The delay also keeps the dialog from landing mid launch animation.
    // Silent no-op once the exemption is granted; "Not Now" re-asks on
    // the next launch, and Settings > Background Running relaunches the
    // flow anytime.
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted || !ref.read(introViewedProvider)) {
      return;
    }
    await showBatteryOptimizationDialog(context, ref.read(ipnServiceProvider));
  }

  Future<void> _maybeShowTaildropHeadsUpTip() async {
    if (await AndroidTaildropNotifications.hasDismissedTip()) {
      return;
    }
    if (!await AndroidTaildropNotifications.isAffectedByHeadsUpSuppression()) {
      return;
    }
    if (!mounted) {
      return;
    }
    // Defer until the user is past the intro flow — showing this dialog
    // on top of IntroPage is jarring and the channel they're being asked
    // to configure does not exist in the system settings until the app
    // has gone through onCreate at least once.
    if (!ref.read(introViewedProvider)) {
      return;
    }
    await showAlertDialog(
      context,
      'Enable Cylonix File Transfer banners',
      'Your device hides heads-up notification banners by default, '
          'even for high-priority notifications. To get a pop-up banner '
          'each time a file arrives via Cylonix File Transfer, tap '
          '"Open Settings" and turn on "Floating notifications" / '
          '"Show as banner" for the "Cylonix File Transfer" channel.',
      okText: 'Open Settings',
      cancelText: "Don't show again",
      showCancel: true,
      onPressOK: () {
        unawaited(AndroidTaildropNotifications.openTaildropChannelSettings());
      },
    );
    await AndroidTaildropNotifications.markTipDismissed();
  }

  @override
  void dispose() {
    _shareRequestSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isWindows || Platform.isMacOS) {
      windowManager.removeListener(this);
      if (SystemTrayService.onShow == _dismissMinimizeToTrayDialog) {
        SystemTrayService.onShow = null;
      }
    }
    super.dispose();
  }

  /// Shares that reached the native side before this page was listening
  /// (cold launch from the share sheet) are pulled once on first frame; the
  /// native side pushes later ones through the method channel.
  Future<void> _pullPendingShareRequests() async {
    final requests =
        await ref.read(ipnServiceProvider).getPendingShareRequests();
    for (final request in requests) {
      ShareRequestInbox.push(request);
    }
    if (ShareRequestInbox.hasPending) {
      await _drainShareRequests();
    }
  }

  /// Presents the oldest queued share request. One sheet at a time: the
  /// sheet's close path drains again, so anything that arrives while a
  /// sheet is up waits its turn.
  Future<void> _drainShareRequests() async {
    if (_showingShareSheet || !mounted) {
      return;
    }
    final request = ShareRequestInbox.takeFirst();
    if (request == null) {
      return;
    }
    _logger.i("Presenting share request: $request");
    if (Platform.isMacOS || Platform.isWindows) {
      // The window may be hidden in the tray when the share extension
      // hands a share over.
      await SystemTrayService.show();
      await windowManager.show();
      await windowManager.focus();
    }
    // The manifest's names travel with the files: the extension stores its
    // temp copies under UUIDs without an extension, so the basename would
    // strip the name (and the receiver's thumbnails) from the attachment.
    await _showShareView(
      files: request.files,
      text: request.text,
      mode: request.mode,
      ephemeral: request.ephemeral,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    unawaited(
      ref.read(peerMessagingServiceProvider.notifier).replayPendingMessages(),
    );
  }

  @override
  void onWindowClose() async {
    final hideDialog = ref.read(hideMinimizeToTrayDialogProvider);

    if (hideDialog) {
      // User has chosen not to see the dialog, just minimize to tray
      await windowManager.hide();
      return;
    }

    // Show dialog
    if (!mounted) {
      await windowManager.hide();
      return;
    }

    // Closing again with the prompt still open: the window stays visible
    // (preventClose) so every extra close click lands here. Pushing another
    // prompt would stack them; each later OK then hides the window and the
    // next "Show" from the tray uncovers the next prompt. Treat the repeat
    // close as the user's answer instead.
    if (_minimizeDialogShowing) {
      _dismissMinimizeToTrayDialog();
      await windowManager.hide();
      return;
    }

    await _showMinimizeToTrayDialog();
  }

  /// Pops the minimize-to-tray prompt if it is still up (the user closed
  /// the window again, or the tray is bringing the window back).
  void _dismissMinimizeToTrayDialog() {
    final dialogContext = _minimizeDialogContext;
    if (dialogContext == null || !dialogContext.mounted) {
      return;
    }
    final route = ModalRoute.of(dialogContext);
    if (route == null || !route.isCurrent) {
      return;
    }
    Navigator.of(dialogContext).pop(false);
  }

  Future<void> _showMinimizeToTrayDialog() async {
    bool dontShowAgain = false;

    _minimizeDialogShowing = true;
    await showAlertDialog(
      context,
      'Minimizing to System Tray',
      '\nCylonix is being minimized to the system tray instead of closing the '
          'app.\n\nTo exit the app, '
          '${Platform.isWindows ? "right-click" : "click"} on the Cylonix icon '
          'in the system tray and select "Exit".',
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          _minimizeDialogContext = context;
          return Row(
            children: [
              Checkbox.adaptive(
                value: dontShowAgain,
                onChanged: (value) {
                  setDialogState(() {
                    dontShowAgain = value ?? false;
                  });
                },
              ),
              const SizedBox(width: 8),
              const Text("Don't show this again"),
            ],
          );
        },
      ),
      onPressOK: () async {
        if (dontShowAgain) {
          await ref
              .read(hideMinimizeToTrayDialogProvider.notifier)
              .setValue(true);
        }
        await windowManager.hide();
      },
    );
    _minimizeDialogShowing = false;
    _minimizeDialogContext = null;
  }

  void _initLogger() async {
    try {
      await AppLog.init();
      _logger.d("Logger initialized");
    } catch (e) {
      _logger.e("Failed to initialize logger: $e");
      if (mounted) {
        await showAlertDialog(
          context,
          "Error",
          "Failed to initialize logger: $e",
        );
      }
    }
  }

  Widget get _mainView {
    return MainView(
      onNavigateToSettings: () => Navigator.pushNamed(context, '/settings'),
      onNavigateToSendFiles: _sendFiles,
      onNavigateToUserSwitcher: () => Navigator.pushNamed(
        context,
        '/user-switcher',
      ),
      onNavigateToPeerDetails: (Node node) => Navigator.pushNamed(
        context,
        '/peer-details',
        arguments: {"node": node.id},
      ),
      onNavigateToExitNodes: () => Navigator.pushNamed(context, '/exit-nodes'),
      onNavigateToHealth: () => Navigator.pushNamed(context, '/health'),
      onNavigateToPeerMessaging: () =>
          Navigator.pushNamed(context, '/peer-messaging'),
      onNavigateToAbout: () => Navigator.pushNamed(context, '/about'),
    );
  }

  Widget get _mainViewWithRail {
    return MainView(
      onNavigateToSettings: () => _selectPage(Page.settings.value),
      onNavigateToSendFiles: _sendFiles,
      onNavigateToUserSwitcher: () => _selectPage(Page.userSwitcher.value),
      onNavigateToPeerDetails: (Node node) {
        _nodeID = node.id;
        _selectPage(Page.perDetails.value);
      },
      onNavigateToExitNodes: () => _selectPage(Page.exitNodes.value),
      onNavigateToHealth: () => _selectPage(Page.health.value),
      onNavigateToPeerMessaging: () => _selectPage(Page.peerMessaging.value),
      onNavigateToAbout: () => _selectPage(Page.about.value),
    );
  }

  Widget get _rightSidePage {
    switch (_page) {
      case Page.about:
        return _aboutView;
      case Page.customControl:
        return _customControlView;
      case Page.customLogin:
        return _customLoginView;
      case Page.exitNodes:
        return _exitNodesView;
      case Page.health:
        return _healthView;
      case Page.peerMessaging:
        return _peerMessagingView;
      case Page.settings:
        return _settingsView;
      case Page.userSwitcher:
        return _userSwitcherView;
      case Page.perDetails:
        return _peerDetailsView;
      case Page.permissions:
        return _permissionsView;
      case Page.runExitNodeView:
        return RunExitNodeView(
          onNavigateBackToExitNodes: () => _selectPage(Page.exitNodes.value),
        );
      case Page.dnsSettingsView:
        return DNSSettingsView(
          onBackToSettings: () => _selectPage(Page.settings.value),
        );
      case Page.subnetRouting:
        return SubnetRoutingView(
          onBackToSettings: () => _selectPage(Page.settings.value),
        );
      case Page.splitTunnel:
        return SplitTunnelAppPickerView(
          onBackToSettings: () => _selectPage(Page.settings.value),
        );
      default:
        return _mainViewWithRail;
    }
  }

  Widget get _customLoginView {
    return CustomLoginView(
      onNavigateToHome: () => _selectPage(Page.mainView.value),
      onNavigateBackToSettings: () => _selectPage(Page.settings.value),
      isAuthKey: true,
    );
  }

  Widget get _customControlView {
    return CustomLoginView(
      onNavigateToHome: () => _selectPage(Page.mainView.value),
      onNavigateBackToSettings: () => _selectPage(Page.settings.value),
      isAuthKey: false,
    );
  }

  Widget get _exitNodesView {
    return ExitNodePicker(
      onNavigateBackHome: () => _selectPage(Page.mainView.value),
      onNavigateToRunAsExitNode: () => _selectPage(Page.runExitNodeView.value),
    );
  }

  Widget get _userSwitcherView {
    return UserSwitcherView(
      onNavigateToHome: () => _selectPage(Page.mainView.value),
      onNavigateBackToSettings: () => _selectPage(Page.settings.value),
      onNavigateToCustomControl: () => _selectPage(Page.customControl.value),
      onNavigateToAuthKey: () => _selectPage(Page.customLogin.value),
    );
  }

  Widget get _permissionsView {
    return PermissionsView(
      onNavigateBack: _navigateBack,
    );
  }

  Widget get _peerDetailsView {
    return PeerDetailsView(
      node: _nodeID ?? 0,
      onNavigateBack: _navigateBack,
    );
  }

  Widget get _healthView {
    return HealthView(
      onNavigateBack: _navigateBack,
    );
  }

  Widget get _aboutView {
    return AboutView(
      onNavigateBack: _navigateBack,
    );
  }

  Widget get _peerMessagingView {
    return PeerMessagingInboxView(
      onNavigateBack: _navigateBack,
    );
  }

  Widget get _settingsView {
    return SettingsView(
      onNavigateBackHome: () => _selectPage(Page.mainView.value),
      onNavigateBackToSettings: () => _selectPage(Page.settings.value),
      onPushNewPage: (page) => _setRightSide(page),
      onNavigateToCustomLogin: () => _selectPage(Page.customLogin.value),
      onNavigateToCustomControlURL: () => _selectPage(Page.customControl.value),
      onNavigateToUserSwitcher: () => _selectPage(Page.userSwitcher.value),
      onNavigateToDNSSettings: () => _selectPage(Page.dnsSettingsView.value),
      onNavigateToSubnetRouting: () => _selectPage(Page.subnetRouting.value),
      onNavigateToSplitTunneling: () => _selectPage(Page.splitTunnel.value),
      onNavigateToTailnetLock: () =>
          Navigator.pushNamed(context, '/tailnet-lock'),
      onNavigateToPermissions: () => _selectPage(Page.permissions.value),
      onNavigateToManagedBy: () => Navigator.pushNamed(context, '/managed-by'),
      onNavigateToBugReport: () => Navigator.pushNamed(context, '/bug-report'),
      onNavigateToAbout: () => _selectPage(Page.about.value),
      onNavigateToMDMSettings: () =>
          Navigator.pushNamed(context, '/mdm-settings'),
    );
  }

  void _navigateBack() {
    if (_previousPage == _page.value) {
      _logger.d("Already on the previous page, no action taken.");
      return;
    }
    _logger.d("Navigating back to page $_previousPage");
    setState(() {
      _page = Page.fromInt(_previousPage);
      _rightSide = _rightSidePage;
    });
  }

  void _selectPage(int index) {
    if (index == Page.mainView.value) {
      ref.read(navigationRailIndexProvider.notifier).setState(0);
    }
    setState(() {
      _previousPage = _page.value;
      _page = Page.fromInt(index);
      _rightSide = _rightSidePage;
    });
  }

  void _setRightSide(Widget widget) {
    setState(() {
      _rightSide = widget;
    });
  }

  /// Sidebar entry to highlight for the page being shown. Sub-pages map to
  /// the entry they were reached from.
  MainRailItem get _railSelection {
    switch (_page) {
      case Page.mainView:
      case Page.perDetails:
        return MainRailItem.home;
      case Page.settings:
      case Page.customLogin:
      case Page.customControl:
      case Page.permissions:
      case Page.dnsSettingsView:
      case Page.subnetRouting:
      case Page.splitTunnel:
        return MainRailItem.settings;
      case Page.userSwitcher:
        return MainRailItem.account;
      case Page.exitNodes:
      case Page.runExitNodeView:
        return MainRailItem.exitNodes;
      case Page.health:
        return MainRailItem.health;
      case Page.peerMessaging:
        return MainRailItem.peerMessages;
      case Page.about:
        return MainRailItem.about;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.when(
      data: (prefs) {
        final introViewed = ref.watch(introViewedProvider);
        if (!introViewed) {
          return _makePage(const IntroPage());
        }
        return _mainPage;
      },
      loading: () {
        _logger.d("Waiting for SharedPreferences to be ready");
        return const Center(child: AdaptiveLoadingWidget());
      },
      error: (error, stack) {
        _logger.e("Error loading SharedPreferences: $error");
        return _makePage(
          Center(
            child: AdaptiveErrorWidget(
              error: error.toString(),
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _tvShowExitConfirmationDialog() async {
    return await showAlertDialog(
      context,
      "Exit Confirmation",
      "Do you want to exit the application or just go back to the launcher? ",
      showCancel: true,
      additionalAskTitle: "Exit App",
      okText: "Go Back to Launcher",
      destructiveButton: "Exit App",
      cancelText: "Stay Here",
      defaultButton: "Stay Here",
      child: const Text(
        "If you choose to exit, the application will terminate.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.red),
      ),
      onAdditionalAskedPressed: () {
        // Exit the app
        _logger.i("Exiting the application as per user request");
        exit(0);
      },
    );
  }

  Widget get _mainPage {
    final isAndroidTV = ref.watch(isAndroidTVProvider);
    if (!useNavigationRail(context) || isAndroidTV) {
      if (_rightSide != null) {
        return _rightSide!;
      }
      if (isAndroidTV) {
        return PopScope(
          canPop: false,
          child: _mainView,
          onPopInvokedWithResult: (didPop, _) async {
            if (!didPop) {
              final canPop = await _tvShowExitConfirmationDialog();
              if (canPop == true) {
                _logger.i("Going back to launcher");
                await SystemNavigator.pop();
              }
              return;
            }
          },
        );
      }
      return _mainView;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MainNavigationRail(
          selected: _railSelection,
          onNavigateToUserSwitcher: () => _selectPage(Page.userSwitcher.value),
          onNavigateToHome: () => _selectPage(Page.mainView.value),
          onNavigateToExitNodes: () => _selectPage(Page.exitNodes.value),
          onNavigateToSendFiles: _sendFiles,
          onNavigateToHealth: () => _selectPage(Page.health.value),
          onNavigateToPeerMessaging: () =>
              _selectPage(Page.peerMessaging.value),
          onNavigateToSettings: () => _selectPage(Page.settings.value),
          onNavigateToAbout: () => _selectPage(Page.about.value),
        ),
        VerticalDivider(
          thickness: 1,
          width: 1,
          color: isApple() ? CupertinoColors.separator : null,
        ),
        Expanded(
          child: SafeArea(
            top: false,
            bottom: false,
            left: false,
            child: _rightSide ?? _rightSidePage,
          ),
        ),
      ],
    );
  }

  void _sendFiles() async {
    _logger.d("Sending files initiated from HomePage");
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: "Select files to send",
      allowMultiple: true,
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty) {
      _logger.d("No files selected for sending.");
      return;
    }
    if (!mounted) {
      _logger.w("HomePage is not mounted, cannot send files.");
      return;
    }
    _logger.d("Files selected for sending: ${result.files.length}");
    await _showShareView(
      paths: result.files.map((file) => file.path).nonNulls.toList(),
    );
  }

  Future<void> _showShareView({
    List<String> paths = const [],
    List<SharedFile>? files,
    String text = '',
    ShareMode mode = ShareMode.fileDrop,
    bool ephemeral = false,
  }) async {
    if (!mounted) {
      return;
    }
    ref.read(transfersProvider.notifier).reset();
    final height = MediaQuery.of(context).size.height * 0.9;
    _showingShareSheet = true;
    try {
      await AdaptiveModalPopup(
        height: height,
        maxWidth: 800,
        child: ShareView(
          paths: paths,
          files: files,
          initialText: text,
          initialMode: mode,
          ephemeral: ephemeral,
          onCancel: () {
            _logger.d("ShareView cancelled");
            Navigator.of(context).pop();
          },
        ),
      ).show(context);
    } finally {
      _showingShareSheet = false;
    }
    if (ShareRequestInbox.hasPending) {
      unawaited(_drainShareRequests());
    }
  }

  Widget _makePage(Widget body) {
    if (isApple()) {
      return CupertinoPageScaffold(
        child: body,
      );
    }
    return Scaffold(
      body: body,
    );
  }
}

enum Page {
  mainView(0),
  settings(1),
  exitNodes(2),
  health(3),
  peerMessaging(4),
  userSwitcher(5),
  customLogin(6),
  customControl(7),
  about(8),
  perDetails(9),
  permissions(10),
  runExitNodeView(11),
  dnsSettingsView(12),
  subnetRouting(13),
  splitTunnel(14);

  const Page(this.value);
  final int value;

  static Page fromInt(int value) {
    return Page.values.firstWhere((state) => state.value == value,
        orElse: () => Page.mainView);
  }
}
