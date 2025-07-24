// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ipn.dart';
import '../providers/ipn.dart';
import 'ping_view.dart';

final peerProvider = Provider.family<Node?, int>((ref, nodeID) {
  final netmap = ref.watch(netmapProvider);
  if (nodeID == netmap?.selfNode.id) return netmap?.selfNode;
  return netmap?.peers?.firstWhereOrNull((p) => p.id == nodeID);
});

final isPingingProvider = StateProvider<bool>((ref) => false);

final peerDetailsViewModelProvider =
    StateNotifierProvider<PeerDetailsViewModel, AsyncValue<void>>((ref) {
  return PeerDetailsViewModel(ref);
});

class PeerDetailsViewModel extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  PeerDetailsViewModel(this._ref) : super(const AsyncValue.data(null));

  void startPing(Node peer) {
    _ref.read(isPingingProvider.notifier).state = true;
    _ref.read(pingStateProvider.notifier).startPing(peer);
  }

  void close() {
    _ref.read(isPingingProvider.notifier).state = false;
    _ref.read(pingStateProvider.notifier).handleDismissal();
  }
}
