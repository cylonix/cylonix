import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'about_view.dart';
import 'custom_login_view.dart';
import 'exit_node_picker.dart';
import 'health_view.dart';
import 'main_view.dart';
import 'models/ipn.dart';
import 'peer_details_view.dart';
import 'permissions_view.dart';
import 'settings_view.dart';
import 'utils/applog.dart';
import 'utils/logger.dart';
import 'utils/utils.dart';
import 'user_switcher_view.dart';
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
  Widget? _rightSide;

  @override
  void initState() {
    super.initState();
    _initLogger();
  }

  void _initLogger() async {
    try {
      await AppLog.init();
      _logger.d("Logger initialized");
    } catch (e) {
      _logger.e("Failed to initialize logger: $e");
      if (mounted) {
        showAlertDialog(
          context,
          "Error",
          "Failed to initialize logger: $e",
        );
      }
    }
  }

  void _loginToURL(String url) async {
    _logger.d("Launching to URL $url");
    final launched = await launchUrl(Uri.parse(url));
    if (!launched) {
      throw Exception("Failed to launch login URL at '$url'");
    }
  }

  Widget get _mainView {
    return MainView(
      onLoginAtUrl: (url) => _loginToURL(url),
      onNavigateToSettings: () => Navigator.pushNamed(context, '/settings'),
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
      onLoginAtUrl: (url) => _loginToURL(url),
      onNavigateToSettings: () => _selectPage(Page.settings.value),
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
      onNavigateToRunAsExitNode: () =>
          Navigator.pushNamed(context, '/run-as-exit-node'),
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
      onNavigateToDNSSettings: () =>
          Navigator.pushNamed(context, '/dns-settings'),
      onNavigateToSplitTunneling: () =>
          Navigator.pushNamed(context, '/split-tunneling'),
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

  Widget get _body {
    if (!useNavigationRail(context)) {
      if (_page.value == Page.settings.value) {
        return _settingsView;
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

  @override
  Widget build(BuildContext context) {
    if (isApple()) {
      return CupertinoPageScaffold(
        child: _body,
      );
    }
    return Scaffold(
      body: _body,
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
  permissions(9);

  const Page(this.value);
  final int value;

  static Page fromInt(int value) {
    return Page.values.firstWhere((state) => state.value == value,
        orElse: () => Page.mainView);
  }
}
