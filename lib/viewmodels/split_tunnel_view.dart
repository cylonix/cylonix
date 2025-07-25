import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/installed_apps.dart';
import '../providers/ipn.dart';

class InstalledApp {
  final String name;
  final String packageName;
  final Uint8List? icon;

  const InstalledApp({
    required this.name,
    required this.packageName,
    this.icon,
  });
}

class SplitTunnelState {
  final List<InstalledApp> installedApps;
  final Set<String> excludedPackageNames;
  final Set<String> builtInDisallowedPackageNames;
  final String? mdmIncludedPackages;
  final String? mdmExcludedPackages;
  final bool isLoading;

  const SplitTunnelState({
    this.installedApps = const [],
    this.excludedPackageNames = const {},
    this.builtInDisallowedPackageNames = const {},
    this.mdmIncludedPackages,
    this.mdmExcludedPackages,
    this.isLoading = false,
  });

  SplitTunnelState copyWith({
    List<InstalledApp>? installedApps,
    Set<String>? excludedPackageNames,
    Set<String>? builtInDisallowedPackageNames,
    String? mdmIncludedPackages,
    String? mdmExcludedPackages,
    bool? isLoading,
  }) {
    return SplitTunnelState(
      installedApps: installedApps ?? this.installedApps,
      excludedPackageNames: excludedPackageNames ?? this.excludedPackageNames,
      builtInDisallowedPackageNames:
          builtInDisallowedPackageNames ?? this.builtInDisallowedPackageNames,
      mdmIncludedPackages: mdmIncludedPackages ?? this.mdmIncludedPackages,
      mdmExcludedPackages: mdmExcludedPackages ?? this.mdmExcludedPackages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SplitTunnelNotifier extends StateNotifier<SplitTunnelState> {
  final Ref ref;
  SplitTunnelNotifier(this.ref) : super(const SplitTunnelState()) {
    _initializeApps();
  }

  Future<void> _initializeApps() async {
    try {
      state = state.copyWith(isLoading: true);
      // Fetch installed apps
      final apps = await InstalledApps.getInstalledApps(true, true);

      final installedApps = apps.map((app) {
        return InstalledApp(
          name: app.name,
          packageName: app.packageName,
          icon: app.icon,
        );
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      state = state.copyWith(installedApps: installedApps);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> exclude(String packageName) async {
    try {
      state = state.copyWith(isLoading: true);
      if (state.excludedPackageNames.contains(packageName)) return;

      await ref
          .read(ipnStateNotifierProvider.notifier)
          .excludeAppFromVPN(packageName, true);
      final newExcluded = Set<String>.from(state.excludedPackageNames)
        ..add(packageName);
      state = state.copyWith(excludedPackageNames: newExcluded);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> unexclude(String packageName) async {
    try {
      state = state.copyWith(isLoading: true);
      if (!state.excludedPackageNames.contains(packageName)) return;
      await ref
          .read(ipnStateNotifierProvider.notifier)
          .excludeAppFromVPN(packageName, false);
      final newExcluded = Set<String>.from(state.excludedPackageNames)
        ..remove(packageName);
      state = state.copyWith(excludedPackageNames: newExcluded);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final splitTunnelProvider =
    StateNotifierProvider<SplitTunnelNotifier, SplitTunnelState>((ref) {
  return SplitTunnelNotifier(ref);
});

final splitTunnelLoadingProvider = StateProvider<bool>((ref) {
  final state = ref.watch(splitTunnelProvider);
  return state.isLoading;
});
