// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../viewmodels/state_notifier.dart';
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
      _handleSystemChange(current.$1, current.$2);
    });
    // Listen to Android TV mode changes and update theme accordingly
    ref.listen(isAndroidTVProvider, (previous, current) {
      if (current) {
        state = ThemeMode.dark;
      } else if (previous == true && current == false) {
        // When disabling Android TV mode, revert to system theme
        state = ThemeMode.system;
      }
    });
  }

  Future<void> _loadTheme() async {
    // For android TV, we default to dark mode
    final isAndroidTV = ref.read(isAndroidTVProvider);
    if (isAndroidTV) {
      state = ThemeMode.dark;
      return;
    }

    // On loading up, use system theme as priority.
    state = ThemeMode.system;
  }

  void _handleSystemChange(Brightness brightness, DateTime systemChangeTime) {
    // Only apply system change if it's more recent than local change
    if (_lastLocalChange == null ||
        systemChangeTime.isAfter(_lastLocalChange!)) {
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
    final currentBrightness = ref.read(systemBrightnessProvider).$1;
    final effectiveTheme = state == ThemeMode.system
        ? (currentBrightness == Brightness.light
            ? ThemeMode.light
            : ThemeMode.dark)
        : state;

    final newTheme =
        effectiveTheme == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setTheme(newTheme);
  }
}

// Theme data providers
final lightThemeProvider = Provider<ThemeData>((ref) => themeList[0]);
final darkThemeProvider = Provider<ThemeData>((ref) => themeList[1]);
