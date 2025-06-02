import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsViewModel extends StateNotifier<AsyncValue<void>> {
  SettingsViewModel() : super(const AsyncValue.data(null));

  Future<void> toggleDNS(bool enabled) async {
    // Implementation
  }

  Future<void> toggleTailnetLock(bool enabled) async {
    // Implementation
  }

  // Add other settings-related methods
}

final settingsViewModelProvider = StateNotifierProvider<SettingsViewModel, AsyncValue<void>>((ref) {
  return SettingsViewModel();
});