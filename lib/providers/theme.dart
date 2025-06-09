import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

const _themePreferenceKey = 'theme_mode';
const _themeTimestampKey = 'theme_timestamp';

// Track system brightness changes
final systemBrightnessProvider =
    StateNotifierProvider<SystemBrightnessNotifier, (Brightness, DateTime)>(
        (ref) {
  return SystemBrightnessNotifier();
});

class SystemBrightnessNotifier extends StateNotifier<(Brightness, DateTime)> {
  SystemBrightnessNotifier()
      : super((
          WidgetsBinding.instance.platformDispatcher.platformBrightness,
          DateTime.now()
        ));

  void updateBrightness(Brightness brightness) {
    print("System brightness changed to: $brightness");
    state = (brightness, DateTime.now());
  }
}
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier(ref);
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final Ref ref;
  DateTime? _lastLocalChange;

  ThemeNotifier(this.ref) : super(ThemeMode.system) {
    _loadTheme();
    ref.listen(systemBrightnessProvider, (previous, current) {
      print("System brightness changed: $current");
      _handleSystemChange(current.$1, current.$2);
    });
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themePreferenceKey);
    final timestamp = prefs.getInt(_themeTimestampKey);

    if (savedTheme != null && timestamp != null) {
      _lastLocalChange = DateTime.fromMillisecondsSinceEpoch(timestamp);
      state = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedTheme,
        orElse: () => ThemeMode.system,
      );
    }
  }

  void _handleSystemChange(Brightness brightness, DateTime systemChangeTime) {
    // Only apply system change if it's more recent than local change
    print("Handling system change: $brightness at $systemChangeTime");
    if (_lastLocalChange == null ||
        systemChangeTime.isAfter(_lastLocalChange!)) {
      print("Applying system brightness change to theme");
      state = brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    if (mode == state) return;

    final prefs = await SharedPreferences.getInstance();
    _lastLocalChange = DateTime.now();

    // Save both theme and timestamp
    await prefs.setString(_themePreferenceKey, mode.toString());
    await prefs.setInt(
        _themeTimestampKey, _lastLocalChange!.millisecondsSinceEpoch);

    state = mode;
  }
  Future<void> toggleTheme() async {
    final newTheme =
        state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setTheme(newTheme);
  }
}

// Theme data providers
final lightThemeProvider = Provider<ThemeData>((ref) => themeList[0]);
final darkThemeProvider = Provider<ThemeData>((ref) => themeList[1]);