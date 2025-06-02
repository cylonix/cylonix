import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ipn.dart';
import '../utils/logger.dart';

// Basic state providers
final isAdminProvider = StateProvider<bool>((ref) => false);
final managedByOrgProvider = StateProvider<String?>((ref) => null);
final tailnetLockEnabledProvider = StateProvider<bool>((ref) => false);
final corpDNSEnabledProvider = StateProvider<bool>((ref) => false);
final showTailnetLockProvider = StateProvider<bool>((ref) => true);

class VpnPermissionState {
  final bool isGranted;
  final bool hasBeenAsked;

  const VpnPermissionState({
    this.isGranted = false,
    this.hasBeenAsked = false,
  });
}

final vpnPermissionNotifierProvider = StateNotifierProvider<
    VpnPermissionNotifier, AsyncValue<VpnPermissionState>>((ref) {
  return VpnPermissionNotifier();
});

// Simplified state providers for UI consumption
final vpnPermissionStateProvider = Provider<bool>((ref) {
  return ref.watch(vpnPermissionNotifierProvider).valueOrNull?.isGranted ??
      false;
});

final vpnPermissionAskedProvider = Provider<bool>((ref) {
  return ref.watch(vpnPermissionNotifierProvider).valueOrNull?.hasBeenAsked ??
      false;
});

class VpnPermissionNotifier
    extends StateNotifier<AsyncValue<VpnPermissionState>> {
  static final _logger = Logger(tag: "VpnPermissionNotifier");
  static const _kVpnPermissionAskedKey = 'vpn_permission_asked';
  static final _ipnService = IpnService();

  VpnPermissionNotifier() : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _logger.d("Checking initial VPN permission state");
      final prefs = await SharedPreferences.getInstance();
      final hasBeenAsked = prefs.getBool(_kVpnPermissionAskedKey) ?? false;
      final isPrepared = await _ipnService.checkVPNPermission();

      _logger.d("VPN permission state: $isPrepared asked: $hasBeenAsked");
      state = AsyncValue.data(VpnPermissionState(
        isGranted: isPrepared,
        hasBeenAsked: hasBeenAsked,
      ));
    } catch (error, stack) {
      _logger.e("Failed to check VPN permission: $error, stackTrace: $stack");
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> requestPermission() async {
    try {
      _logger.d("Requesting VPN permission");
      final granted = await _ipnService.requestVPNPermission();

      // Persist that we've asked for permission
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kVpnPermissionAskedKey, true);

      state = AsyncValue.data(VpnPermissionState(
        isGranted: granted,
        hasBeenAsked: true,
      ));
    } catch (error, stack) {
      _logger.e("Failed to request VPN permission: $error, stackTrace: $stack");
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> reset() async {
    state = const AsyncValue.data(VpnPermissionState());
    _logger.d("Resetting and re-initialize IpnStateNotifier");
    await _initialize();
  }
}
