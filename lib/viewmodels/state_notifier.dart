// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/const.dart';
import '../models/platform.dart';

//import 'package:sase_app_ui/utils/logger.dart';
//final _logger = Logger(tag: 'StateNotifier');

class PreferenceNotifier<T> extends StateNotifier<T> {
  final String key;
  final T defaultValue;
  final SharedPreferences? _prefs;

  PreferenceNotifier(this.key,
      {required this.defaultValue, SharedPreferences? prefs})
      : _prefs = prefs,
        super(defaultValue) {
    // Initialize state with saved value if available
    _loadInitialValue();
  }

  Future<void> setValue(T value) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    switch (T) {
      case String:
        await prefs.setString(key, value as String);
        break;
      case int:
        await prefs.setInt(key, value as int);
        break;
      case double:
        await prefs.setDouble(key, value as double);
        break;
      case bool:
        await prefs.setBool(key, value as bool);
        break;
      case const (List<String>):
        await prefs.setStringList(key, value as List<String>);
        break;
      default:
        throw Exception('Unsupported type: $T');
    }
    state = value;
  }

  void _loadInitialValue() {
    if (_prefs == null) return;

    switch (T) {
      case String:
        final saved = _prefs!.getString(key);
        if (saved != null) state = saved as T;
        break;
      case int:
        final saved = _prefs!.getInt(key);
        if (saved != null) state = saved as T;
        break;
      case double:
        final saved = _prefs!.getDouble(key);
        if (saved != null) state = saved as T;
        break;
      case bool:
        final saved = _prefs!.getBool(key);
        if (saved != null) state = saved as T;
        break;
      case const (List<String>):
        final saved = _prefs!.getStringList(key);
        if (saved != null) state = saved as T;
        break;
      default:
        throw Exception('Unsupported type: $T');
    }
  }
}

class SimpleStateNotifier<T> extends StateNotifier<T> {
  SimpleStateNotifier(T initialState) : super(initialState);

  void setState(T newState) {
    state = newState;
  }
}

final tailchatAutoStartProvider =
    StateNotifierProvider<PreferenceNotifier<bool>, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  return PreferenceNotifier(
    'tailchat_auto_start',
    defaultValue: false,
    prefs: prefs,
  );
});

final sharedPreferencesProvider = FutureProvider((ref) async {
  return await SharedPreferences.getInstance();
});

final tailchatServiceStateProvider =
    StateNotifierProvider<SimpleStateNotifier<bool>, bool>((ref) {
  return SimpleStateNotifier<bool>(false);
});

final controlURLProvider =
    StateNotifierProvider<PreferenceNotifier<String>, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  return PreferenceNotifier(
    'control_url',
    defaultValue: cylonixURL,
    prefs: prefs,
  );
});

final isCylonixControllerProvider = Provider<bool>((ref) {
  final controller = ref.watch(controlURLProvider);
  return controller == cylonixURL;
});

final alwaysUseDerpProvider =
    StateNotifierProvider<PreferenceNotifier<bool>, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  return PreferenceNotifier(
    'always_use_derp',
    defaultValue: false,
    prefs: prefs,
  );
});

final sendDNSToExitNodeInTunnelProvider =
    StateNotifierProvider<PreferenceNotifier<bool>, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  return PreferenceNotifier(
    'send_dns_to_exit_node_in_tunnel',
    defaultValue: false,
    prefs: prefs,
  );
});

final showDevicesProvider =
    StateNotifierProvider<PreferenceNotifier<bool>, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  return PreferenceNotifier(
    'show_devices',
    defaultValue: false,
    prefs: prefs,
  );
});

final introViewedProvider =
    StateNotifierProvider<PreferenceNotifier<bool>, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  return PreferenceNotifier(
    'intro_viewed',
    defaultValue: false,
    prefs: prefs,
  );
});

final navigationRailIndexProvider =
    StateNotifierProvider<SimpleStateNotifier<int>, int>((ref) {
  return SimpleStateNotifier<int>(0);
});

final isAndroidTVProvider =
    StateNotifierProvider<PreferenceNotifier<bool>, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  return PreferenceNotifier(
    'is_android_tv',
    defaultValue: isNativeAndroidTV,
    prefs: prefs,
  );
});

/// Provider for hiding the "minimize to tray" notification dialog on Windows
final hideMinimizeToTrayDialogProvider =
    StateNotifierProvider<PreferenceNotifier<bool>, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  return PreferenceNotifier(
    'hide_minimize_to_tray_dialog',
    defaultValue: false,
    prefs: prefs,
  );
});
