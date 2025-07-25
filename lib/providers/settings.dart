// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/backend_notify_event.dart';
import '../models/ipn.dart';
import '../services/ipn.dart';
import '../utils/logger.dart';
import 'ipn.dart';

final isAdminProvider = StateProvider<bool>((ref) => false);
final managedByOrgProvider = StateProvider<String?>((ref) => null);
final tailnetLockEnabledProvider = StateProvider<bool>((ref) => false);
final showTailnetLockProvider = StateProvider<bool>((ref) => false);

final corpDNSEnabledProvider = StateProvider<bool>((ref) {
  return ref.watch(ipnStateProvider)?.prefs?.corpDNS ?? false;
});

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
  return VpnPermissionNotifier(ref);
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
  static StreamSubscription<VpnPermissionEvent>? _eventSubscription;
  final Ref ref;

  VpnPermissionNotifier(this.ref) : super(const AsyncValue.loading()) {
    if (Platform.isAndroid) {
      // Re-check permission state on Android whenever ipn changes to
      // running state since it can be revoked (root cause unknown).
      final backendState = ref.watch(backendStateProvider);
      if (backendState == BackendState.running) {
        _logger.d("Backend is running, initializing VPN permission state");
        _initialize();
      }
    } else {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    _eventSubscription?.cancel();
    _eventSubscription =
        IpnService.eventBus.on<VpnPermissionEvent>().listen((event) {
      _logger.d("Received VpnPermissionEvent: $event");
      state = AsyncValue.data(VpnPermissionState(
        isGranted: event.isGranted,
        hasBeenAsked:
            event.isGranted ? true : state.value?.hasBeenAsked ?? false,
      ));
    });
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
