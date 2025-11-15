// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'about_view.dart';
import 'custom_login_view.dart';
import 'dns_settings_view.dart';
import 'exit_node_picker.dart';
import 'health_view.dart';
import 'intro_page.dart';
import 'main_view.dart';
import 'models/ipn.dart';
import 'peer_details_view.dart';
import 'permissions_view.dart';
import 'providers/share_file.dart';
import 'providers/theme.dart';
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
import 'widgets/main_navigation_rail.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static final _logger = Logger(tag: "HomePage");
  Page _page = Page.mainView;
  int _previousPage = Page.mainView.value;
  int? _nodeID;
  bool _canPop = false;
  Widget? _rightSide;

  @override
  void initState() {
    super.initState();
    _initLogger();
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        () {
      _logger.i("Platform brightness changed");
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      ref.read(systemBrightnessProvider.notifier).updateBrightness(brightness);
    };
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
    });
  }

  void _selectPage(int index) {
    if (index == Page.mainView.value) {
      ref.read(navigationRailIndexProvider.notifier).setState(0);
    }
    setState(() {
      _rightSide = null; // Clear the right side widget
      _previousPage = _page.value;
      _page = Page.fromInt(index);
    });
  }

  void _setRightSide(Widget widget) {
    setState(() {
      _rightSide = widget;
    });
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
      if (_page.value == Page.settings.value) {
        return _settingsView;
      }
      if (isAndroidTV) {
        return PopScope(
          canPop: _canPop,
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
          onNavigateToUserSwitcher: () => _selectPage(Page.userSwitcher.value),
          onNavigateToHome: () => _selectPage(Page.mainView.value),
          onNavigateToExitNodes: () => _selectPage(Page.exitNodes.value),
          onNavigateToSendFiles: _sendFiles,
          onNavigateToHealth: () => _selectPage(Page.health.value),
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
    ref.read(transfersProvider.notifier).reset();
    _logger.d("Files selected for sending: ${result.files.length}");
    final height = MediaQuery.of(context).size.height * 0.9;
    await AdaptiveModalPopup(
      height: height,
      maxWidth: 800,
      child: ShareView(
        paths: result.files.map((file) => file.path).nonNulls.toList(),
        onCancel: () {
          _logger.d("ShareView cancelled");
          Navigator.of(context).pop();
        },
      ),
    ).show(context);
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
  userSwitcher(4),
  customLogin(5),
  customControl(6),
  about(7),
  perDetails(8),
  permissions(9),
  runExitNodeView(10),
  dnsSettingsView(11),
  subnetRouting(12),
  splitTunnel(13);

  const Page(this.value);
  final int value;

  static Page fromInt(int value) {
    return Page.values.firstWhere((state) => state.value == value,
        orElse: () => Page.mainView);
  }
}
