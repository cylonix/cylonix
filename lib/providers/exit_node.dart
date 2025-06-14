import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ipn.dart';

class ExitNodeState {
  final List<ExitNode> tailnetExitNodes;
  final Map<String, List<ExitNode>> mullvadExitNodesByCountryCode;
  final int mullvadExitNodeCount;
  final bool anyActive;
  final bool shouldShowMullvadInfo;
  final bool allowLANAccess;
  final bool showRunAsExitNode;
  final String? managedByOrganization;
  final String? forcedExitNodeId;
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
    this.forcedExitNodeId,
    this.isRunningExitNode = false,
    this.isLanAccessHidden = false,
  });
}

class ExitNodePickerNotifier extends StateNotifier<ExitNodeState> {
  ExitNodePickerNotifier() : super(ExitNodeState(
    tailnetExitNodes: [],
    mullvadExitNodesByCountryCode: {},
    mullvadExitNodeCount: 0,
    anyActive: false,
    shouldShowMullvadInfo: false,
    allowLANAccess: false,
    showRunAsExitNode: false,
  ));

  Future<void> setExitNode(ExitNode? node) async {
    // TODO: Implement exit node selection logic
  }

  Future<void> toggleAllowLANAccess() async {
    // TODO: Implement LAN access toggle logic
  }
}

final exitNodePickerProvider = StateNotifierProvider<ExitNodePickerNotifier, ExitNodeState>((ref) {
  return ExitNodePickerNotifier();
});

final exitNodeLoadingProvider = StateProvider<bool>((ref) => false);