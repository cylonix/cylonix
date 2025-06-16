import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ipn.dart';
import '../services/ipn.dart';
import '../services/mdm.dart';
import '../viewmodels/ipn_state_notifier.dart';

// Service providers
final ipnServiceProvider = Provider<IpnService>((ref) => IpnService());
final mdmSettingsProvider =
    Provider<MDMSettingsService>((ref) => MDMSettingsService());

// Base provider that handles initialization
final ipnStateNotifierProvider =
    StateNotifierProvider<IpnStateNotifier, AsyncValue<IpnState>>((ref) {
  return IpnStateNotifier(
      ref.watch(ipnServiceProvider), ref.watch(mdmSettingsProvider), ref);
});

// Derived providers with error handling
final ipnStateProvider = Provider<IpnState?>((ref) {
  final state = ref.watch(ipnStateNotifierProvider);
  return state.when(
    data: (data) => data,
    loading: () => null,
    error: (_, __) => null,
  );
});

final ipnErrMessageProvider = Provider<String?>((ref) {
  final ipnState = ref.watch(ipnStateProvider);
  return ipnState?.errMessage;
});

final vpnStateProvider = Provider<VpnState>((ref) {
  final ipnState = ref.watch(ipnStateProvider);
  return ipnState?.vpnState ?? VpnState.disconnected;
});

final netmapProvider = Provider<NetworkMap?>((ref) {
  final ipnState = ref.watch(ipnStateProvider);
  return ipnState?.netmap;
});

final peersProvider = Provider<List<Node>>((ref) {
  final netmap = ref.watch(netmapProvider);
  return netmap?.peers ?? [];
});

final searchTermProvider = StateProvider<String>((ref) => '');

final filteredPeersProvider = Provider<List<Node>>((ref) {
  final peers = ref.watch(peersProvider);
  final searchTerm = ref.watch(searchTermProvider).toLowerCase();

  if (searchTerm.isEmpty) return peers;

  return peers.where((peer) {
    return peer.name.toLowerCase().contains(searchTerm) ||
        peer.addresses.any((addr) => addr.contains(searchTerm));
  }).toList();
});

final mdmForceEnabledProvider = FutureProvider<bool>((ref) async {
  final mdmSettings = ref.watch(mdmSettingsProvider);
  return await mdmSettings.forceEnabled;
});

final healthProvider = Provider<HealthState?>((ref) {
  final ipnState = ref.watch(ipnStateProvider);
  return ipnState?.health;
});

// Node and exit node related providers
final nodeStateProvider = Provider<NodeState>((ref) {
  final ipnState = ref.watch(ipnStateProvider);
  if (ipnState == null) return NodeState.none;

  final netmap = ipnState.netmap;
  final prefs = ipnState.prefs;

  if ((prefs?.exitNodeID ?? "").isNotEmpty) {
    final exitNode = netmap?.peers?.firstWhereOrNull(
      (peer) => peer.stableID == prefs?.exitNodeID,
    );

    if (exitNode?.online == true) {
      return NodeState.activeAndRunning;
    }
    return NodeState.activeNotRunning;
  }

  return NodeState.none;
});

final exitNodeProvider = Provider<Node?>((ref) {
  final ipnState = ref.watch(ipnStateProvider);
  final exitNodeId = ipnState?.prefs?.exitNodeID ?? "";
  if (exitNodeId.isEmpty) return null;

  return ipnState?.netmap?.peers?.firstWhereOrNull(
    (peer) => peer.stableID == exitNodeId,
  );
});

// User profile related providers
final userProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(ipnStateProvider)?.loggedInUser;
});

final currentLoginProfileProvider = Provider<LoginProfile?>((ref) {
  return ref.watch(ipnStateProvider)?.currentProfile;
});

final loginProfilesProvider = Provider<List<LoginProfile>>((ref) {
  return ref.watch(ipnStateProvider)?.loginProfiles ?? [];
});

// Device and connection status providers
final pingDeviceProvider = StateProvider<Node?>((ref) => null);

final stateTextProvider = Provider<String>((ref) {
  final ipnState = ref.watch(ipnStateProvider);
  if (ipnState == null) return 'Disconnected';

  switch (ipnState.vpnState) {
    case VpnState.connected:
      return 'Connected';
    case VpnState.connecting:
      return 'Connecting...';
    case VpnState.error:
      if (ipnState.backendState == BackendState.inUseOtherUser) {
        return 'Error: In use by another user';
      }
      return 'Error';
    case VpnState.disconnecting:
      return 'Disconnecting...';
    case VpnState.disconnected:
      return 'Disconnected';
  }
});

final backendStateProvider = Provider<BackendState?>(
  (ref) => ref.watch(ipnStateProvider)?.backendState,
);

final healthWarningsProvider = Provider<HealthState?>((ref) {
  return ref.watch(ipnStateProvider)?.health;
});

// Health and warning indicators
final healthSeverityProvider = Provider<Severity?>((ref) {
  final health = ref.watch(ipnStateProvider)?.health;
  if (health == null) return null;

  final hasWarnings = health.warnings?.isNotEmpty ?? false;
  if (hasWarnings) {
    // Check severity of warnings
    final high = health.warnings?.values
            .any((warning) => warning?.severity == Severity.high) ??
        false;
    final medium = health.warnings?.values
            .any((warning) => warning?.severity == Severity.medium) ??
        false;
    return high
        ? Severity.high
        : medium
            ? Severity.medium
            : Severity.low;
  }

  return null;
});

final managedByOrganizationProvider = Provider<bool>((ref) {
  final mdmSettings = ref.watch(mdmSettingsProvider);
  return mdmSettings.isManaged;
});

final peerCategorizerProvider = Provider<PeerCategorizer>((ref) {
  ref.watch(ipnStateProvider)?.netmap;
  return ref.read(ipnStateNotifierProvider.notifier).peerCategorizer;
});

// Enum for node states
enum NodeState {
  none,
  activeAndRunning,
  activeNotRunning,
  offlineMdm,
}
