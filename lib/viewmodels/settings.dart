// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dns_settings.dart';
import '../models/ipn.dart';
import '../providers/ipn.dart';
import 'state_notifier.dart';

final dnsSettingsProvider =
    StateNotifierProvider<DNSSettingsNotifier, DNSSettings>((ref) {
  return DNSSettingsNotifier(ref);
});

final dnsSettingsLoadingProvider =
    StateNotifierProvider<SimpleStateNotifier<bool>, bool>((ref) {
  return SimpleStateNotifier(false);
});

class DNSSettingsNotifier extends StateNotifier<DNSSettings> {
  final Ref ref;
  DNSSettingsNotifier(this.ref) : super(DNSSettings()) {
    _initialize();
  }

  void _initialize() {
    final ipnState = ref.watch(ipnStateProvider);
    if (ipnState?.backendState == BackendState.running) {
      state = DNSSettings(
        enablementState: ipnState?.prefs?.corpDNS ?? false
            ? DNSEnablementState.enabled
            : DNSEnablementState.disabled,
        dnsConfig: ipnState?.netmap?.dns,
        useCorpDNS: ipnState?.prefs?.corpDNS ?? false,
        isDNSSettingsHidden: state.isDNSSettingsHidden,
      );
    } else {
      state = DNSSettings(
        enablementState: DNSEnablementState.notRunning,
        useCorpDNS: false,
        isDNSSettingsHidden: state.isDNSSettingsHidden,
      );
    }
  }

  Future<void> toggleCorpDNS() async {
    try {
      ref.read(dnsSettingsLoadingProvider.notifier).setState(true);
      await ref.read(ipnStateNotifierProvider.notifier).toggleCorpDNS();
    } finally {
      ref.read(dnsSettingsLoadingProvider.notifier).setState(false);
    }
  }
}

class DNSSettings {
  final DNSEnablementState enablementState;
  final DNSConfig? dnsConfig;
  final bool useCorpDNS;
  final bool isDNSSettingsHidden;

  DNSSettings({
    this.enablementState = DNSEnablementState.disabled,
    this.dnsConfig,
    this.useCorpDNS = false,
    this.isDNSSettingsHidden = false,
  });
}

class SubnetRoutingState {
  final bool routeAll;
  final List<String> advertisedRoutes;
  final String editingRoute;
  final String dialogTextFieldValue;
  final bool isTextFieldValueValid;
  final String? currentError;

  const SubnetRoutingState({
    this.routeAll = false,
    this.advertisedRoutes = const [],
    this.editingRoute = '',
    this.dialogTextFieldValue = '',
    this.isTextFieldValueValid = true,
    this.currentError,
  });

  SubnetRoutingState copyWith({
    bool? routeAll,
    List<String>? advertisedRoutes,
    String? editingRoute,
    String? dialogTextFieldValue,
    bool? isTextFieldValueValid,
    String? currentError,
  }) {
    return SubnetRoutingState(
      routeAll: routeAll ?? this.routeAll,
      advertisedRoutes: advertisedRoutes ?? this.advertisedRoutes,
      editingRoute: editingRoute ?? this.editingRoute,
      dialogTextFieldValue: dialogTextFieldValue ?? this.dialogTextFieldValue,
      isTextFieldValueValid:
          isTextFieldValueValid ?? this.isTextFieldValueValid,
      currentError: currentError ?? this.currentError,
    );
  }
}

class SubnetRoutingNotifier extends StateNotifier<SubnetRoutingState> {
  final Ref ref;
  SubnetRoutingNotifier(this.ref) : super(const SubnetRoutingState()) {
    final prefs = ref.watch(prefsProvider);
    state = state.copyWith(
      routeAll: prefs?.routeAll ?? false,
      advertisedRoutes: prefs?.advertiseRoutes ?? [],
    );
  }

  static bool isValidCIDR(String route) {
    route = route.trim();
    if (route.isEmpty) return false;

    final cidrPattern = RegExp(
      r'^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])/(\d+)$',
    );

    final ipv6CidrPattern = RegExp(
      r'^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))/(\d+)$',
    );

    return cidrPattern.hasMatch(route) || ipv6CidrPattern.hasMatch(route);
  }

  void toggleUseSubnets() async {
    try {
      ref.read(subnetRoutingLoadingProvider.notifier).setState(true);
      final prefs = await ref.read(ipnStateNotifierProvider.notifier).editPrefs(
            MaskedPrefs(
              routeAll: !state.routeAll,
              routeAllSet: true,
            ),
          );
      state = state.copyWith(routeAll: prefs.routeAll);
    } finally {
      ref.read(subnetRoutingLoadingProvider.notifier).setState(false);
    }
  }

  void startEditingRoute(String route) {
    route = route.trim();
    state = state.copyWith(
      editingRoute: route,
      dialogTextFieldValue: route,
    );
  }

  void stopEditingRoute() {
    state = state.copyWith(
      dialogTextFieldValue: '',
      editingRoute: '',
    );
  }

  void updateDialogValue(String value) {
    value = value.trim();
    state = state.copyWith(
      dialogTextFieldValue: value,
      isTextFieldValueValid: isValidCIDR(value),
    );
  }

  Future<void> deleteRoute(String route) async {
    try {
      ref.read(subnetRoutingLoadingProvider.notifier).setState(true);
      final currentRoutes = List<String>.from(state.advertisedRoutes);
      if (!currentRoutes.contains(route)) return;

      currentRoutes.remove(route);
      final prefs = await ref.read(ipnStateNotifierProvider.notifier).editPrefs(
            MaskedPrefs(
              advertiseRoutes: currentRoutes,
              advertiseRoutesSet: true,
            ),
          );
      state = state.copyWith(advertisedRoutes: prefs.advertiseRoutes);
    } finally {
      ref.read(subnetRoutingLoadingProvider.notifier).setState(false);
    }
  }

  Future<void> saveRoute() async {
    try {
      ref.read(subnetRoutingLoadingProvider.notifier).setState(true);
      final routes = List<String>.from(state.advertisedRoutes);
      if (state.editingRoute.isNotEmpty) {
        routes.remove(state.editingRoute);
      }
      routes.add(state.dialogTextFieldValue);
      final prefs = await ref.read(ipnStateNotifierProvider.notifier).editPrefs(
            MaskedPrefs(
              advertiseRoutes: routes,
              advertiseRoutesSet: true,
            ),
          );
      state = state.copyWith(
        advertisedRoutes: prefs.advertiseRoutes,
      );
    } finally {
      ref.read(subnetRoutingLoadingProvider.notifier).setState(false);
    }
  }

  void dismissError() {
    state = state.copyWith(currentError: null);
  }
}

final subnetRoutingProvider =
    StateNotifierProvider<SubnetRoutingNotifier, SubnetRoutingState>((ref) {
  return SubnetRoutingNotifier(ref);
});

final subnetRoutingLoadingProvider =
    StateNotifierProvider<SimpleStateNotifier<bool>, bool>((ref) {
  return SimpleStateNotifier(false);
});

final autoStartOnBootProvider =
    StateNotifierProvider<SimpleStateNotifier<bool>, bool>((ref) {
  return SimpleStateNotifier<bool>(false);
});
