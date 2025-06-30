import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ipn.dart';
import 'ipn.dart';

class ExitNodeState {
  final List<ExitNode> tailnetExitNodes;
  final Map<String, List<ExitNode>> mullvadExitNodesByCountryCode;
  final int mullvadExitNodeCount;
  final bool anyActive;
  final bool shouldShowMullvadInfo;
  final bool allowLANAccess;
  final bool showRunAsExitNode;
  final String? managedByOrganization;
  final String? forcedExitNodeID;
  final bool isRunningExitNode;
  final bool isLanAccessHidden;

  ExitNodeState({
    required this.tailnetExitNodes,
    required this.mullvadExitNodesByCountryCode,
    required this.mullvadExitNodeCount,
    required this.anyActive,
    required this.shouldShowMullvadInfo,
    required this.allowLANAccess,
    required this.showRunAsExitNode,
    this.managedByOrganization,
    this.forcedExitNodeID,
    this.isRunningExitNode = false,
    this.isLanAccessHidden = false,
  });
}

class ExitNodePickerNotifier extends StateNotifier<ExitNodeState> {
  final Ref ref;

  ExitNodePickerNotifier(this.ref)
      : super(ExitNodeState(
          tailnetExitNodes: [],
          mullvadExitNodesByCountryCode: {},
          mullvadExitNodeCount: 0,
          anyActive: false,
          shouldShowMullvadInfo: false,
          allowLANAccess: false,
          showRunAsExitNode: false,
        )) {
    // Watch for changes in netmap and prefs
    ref.listen(netmapProvider, (previous, next) => _updateState());
    ref.listen(prefsProvider, (previous, next) => _updateState());
  }

  void _updateState() {
    final netmap = ref.read(netmapProvider);
    final prefs = ref.read(prefsProvider);
    if (netmap == null) return;

    // Get current exit node ID
    final exitNodeId = prefs?.activeExitNodeID ?? prefs?.selectedExitNodeID;

    // Process all exit nodes
    final peers = netmap.peers ?? [];
    final allNodes = peers.where((peer) => peer.isExitNode).map((peer) {
      return ExitNode(
        id: peer.stableID,
        label: peer.displayName,
        online: peer.online ?? false,
        selected: peer.stableID == exitNodeId,
        mullvad: peer.name.endsWith('.mullvad.ts.net'),
        priority: peer.hostinfo?.location?.priority ?? 0,
        countryCode: peer.hostinfo?.location?.countryCode ?? '',
        country: peer.hostinfo?.location?.country ?? '',
        city: peer.hostinfo?.location?.city ?? '',
      );
    }).toList();

    // Filter tailnet nodes (non-Mullvad)
    final tailnetNodes = allNodes.where((node) => !node.mullvad).toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    // Process Mullvad nodes
    final mullvadNodes = allNodes
        .where((node) => node.mullvad && (node.selected || node.online))
        .toList();

    // Group Mullvad nodes by country code and city
    final mullvadByCountry = <String, List<ExitNode>>{};
    for (final node in mullvadNodes) {
      final countryNodes = mullvadByCountry[node.countryCode] ?? [];

      // Group by city and select best node per city
      final cityGroups = <String, List<ExitNode>>{};
      for (final cityNode in countryNodes) {
        final cityNodes = cityGroups[cityNode.city] ?? [];
        cityNodes.add(cityNode);
        cityGroups[cityNode.city] = cityNodes;
      }

      // Select best node per city
      final bestCityNodes = cityGroups.values.map((cityNodes) {
        return cityNodes.reduce((a, b) {
          if (a.selected && !b.selected) return a;
          if (b.selected && !a.selected) return b;
          return b.priority.compareTo(a.priority) > 0 ? b : a;
        });
      }).toList()
        ..sort((a, b) => a.city.toLowerCase().compareTo(b.city.toLowerCase()));

      mullvadByCountry[node.countryCode] = bestCityNodes;
    }

    // Check if any node is active
    final anyActive = allNodes.any((node) => node.selected);

    // Check if should show Mullvad info
    final shouldShowMullvadInfo = netmap.selfNode.isAdmin == true &&
        prefs?.controlURL.endsWith('.tailscale.com') == true;

    state = ExitNodeState(
      tailnetExitNodes: tailnetNodes,
      mullvadExitNodesByCountryCode: mullvadByCountry,
      mullvadExitNodeCount: mullvadNodes.length,
      anyActive: anyActive,
      shouldShowMullvadInfo: shouldShowMullvadInfo,
      allowLANAccess: prefs?.exitNodeAllowLANAccess ?? false,
      showRunAsExitNode: netmap.selfNode.isAdmin == true,
      isRunningExitNode: netmap.selfNode.isExitNode == true,
      isLanAccessHidden: prefs?.exitNodeAllowLANAccess == null,
    );
  }

  Future<void> setExitNode(ExitNode? node) async {
    ref.read(exitNodeLoadingProvider.notifier).state = true;
    try {
      final prefs = MaskedPrefs(
        exitNodeID: node?.id,
        exitNodeIDSet: true,
      );
      await ref.read(ipnStateNotifierProvider.notifier).editPrefs(prefs);
    } finally {
      ref.read(exitNodeLoadingProvider.notifier).state = false;
    }
  }

  Future<void> toggleAllowLANAccess() async {
    final prefs = MaskedPrefs(
      exitNodeAllowLANAccess: !state.allowLANAccess,
      exitNodeAllowLANAccessSet: true,
    );
    await ref.read(ipnStateNotifierProvider.notifier).editPrefs(prefs);
  }
}

// Update the provider to pass ref
final exitNodePickerProvider =
    StateNotifierProvider<ExitNodePickerNotifier, ExitNodeState>((ref) {
  return ExitNodePickerNotifier(ref);
});

final exitNodeLoadingProvider = StateProvider<bool>((ref) => false);
