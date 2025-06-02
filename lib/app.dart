import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'about_view.dart';
import 'custom_login_view.dart';
import 'exit_node_picker.dart';
import 'health_view.dart';
import 'home_page.dart';
import 'peer_details_view.dart';
import 'permissions_view.dart';
import 'providers/theme.dart';
import 'settings_view.dart';
import 'theme.dart';
import 'user_switcher_view.dart';
import 'utils/utils.dart';

class App extends ConsumerWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
      },
      child: isApple()
          ? _buildCupertinoApp(context, ref)
          : _buildMaterialApp(context, ref),
    );
  }

  Widget _buildMaterialApp(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      theme: ref.watch(lightThemeProvider),
      darkTheme: ref.watch(darkThemeProvider),
      themeMode: themeMode,
      onGenerateRoute: _onGenerateRoutes,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
      ],
    );
  }

  Widget _buildCupertinoApp(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            View.of(context).platformDispatcher.platformBrightness ==
                Brightness.dark);

    return CupertinoApp(
      theme: isDark ? darkCupertinoTheme : null,
      onGenerateRoute: _onGenerateRoutes,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
      ],
    );
  }

  Route<dynamic>? _onGenerateRoutes(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
        );
      case '/about':
        return MaterialPageRoute(
          builder: (_) => AboutView(
            onNavigateBack: () => Navigator.pop(_),
          ),
        );
      case '/custom-control':
        return MaterialPageRoute(
          builder: (_) => CustomLoginView(
            onNavigateToHome: () => Navigator.popUntil(_, (r) => r.isFirst),
            onNavigateBackToSettings: () => Navigator.pushNamed(_, "/settings"),
            isAuthKey: false,
          ),
        );
      case '/custom-login':
        return MaterialPageRoute(
          builder: (_) => CustomLoginView(
            onNavigateToHome: () => Navigator.popUntil(_, (r) => r.isFirst),
            onNavigateBackToSettings: () => Navigator.pushNamed(_, "/settings"),
            isAuthKey: true,
          ),
        );
      case '/exit-nodes':
        return MaterialPageRoute(
          builder: (_) => ExitNodePicker(
            onNavigateBackHome: () => Navigator.popUntil(_, (r) => r.isFirst),
            onNavigateToMullvad: () => Navigator.pushNamed(_, '/mullvad'),
            onNavigateToRunAsExitNode: () =>
                Navigator.pushNamed(_, '/run-as-exit-node'),
          ),
        );
      case '/health':
        return MaterialPageRoute(
          builder: (_) => HealthView(
            onNavigateBack: () => Navigator.pop(_),
          ),
        );

      case '/peer-details':
        final args = settings.arguments as Map<String, dynamic>;
        final nodeID = args['node'] as int;
        return MaterialPageRoute(
          builder: (_) => PeerDetailsView(
            node: nodeID,
            onNavigateBack: () => Navigator.pop(_),
          ),
        );

      case '/permissions':
        return MaterialPageRoute(
          builder: (_) => PermissionsView(
            onNavigateBack: () => Navigator.pop(_),
          ),
        );

      case '/settings':
        return MaterialPageRoute(
          builder: (context) => SettingsView(
            onNavigateBackHome: () =>
                Navigator.popUntil(context, (r) => r.isFirst),
            onNavigateToCustomLogin: () =>
                Navigator.pushNamed(context, '/custom-login'),
            onNavigateToCustomControlURL: () =>
                Navigator.pushNamed(context, '/custom-control'),
            onNavigateToUserSwitcher: () =>
                Navigator.pushNamed(context, '/user-switcher'),
            onNavigateToDNSSettings: () =>
                Navigator.pushNamed(context, '/dns-settings'),
            onNavigateToSplitTunneling: () =>
                Navigator.pushNamed(context, '/split-tunneling'),
            onNavigateToTailnetLock: () =>
                Navigator.pushNamed(context, '/tailnet-lock'),
            onNavigateToPermissions: () =>
                Navigator.pushNamed(context, '/permissions'),
            onNavigateToManagedBy: () =>
                Navigator.pushNamed(context, '/managed-by'),
            onNavigateToBugReport: () =>
                Navigator.pushNamed(context, '/bug-report'),
            onNavigateToAbout: () => Navigator.pushNamed(context, '/about'),
            onNavigateToMDMSettings: () =>
                Navigator.pushNamed(context, '/mdm-settings'),
          ),
        );
      case '/user-switcher':
        return MaterialPageRoute(
          builder: (context) => UserSwitcherView(
            onNavigateToHome: () =>
                Navigator.popUntil(context, (r) => r.isFirst),
            onNavigateBackToSettings: () => Navigator.pop(context),
            onNavigateToCustomControl: () =>
                Navigator.pushNamed(context, '/custom-control'),
            onNavigateToAuthKey: () =>
                Navigator.pushNamed(context, '/custom-login'),
          ),
        );
    }
    return null;
  }
}
