// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ipn.dart';
import '../models/peer_messaging.dart';
import '../utils/utils.dart';
import 'ipn.dart';
import 'peer_messaging.dart';

/// The netmap node a peer-messaging conversation id refers to, or null when
/// the peer is not in the current netmap (stranded profile, removed device,
/// tunnel down). Keyed on the raw reference; re-resolves when the netmap
/// changes.
final peerForRefProvider = Provider.family<Node?, String>((ref, peerRef) {
  return ref.watch(netmapProvider)?.resolvePeerRef(peerRef);
});

/// One vocabulary for a peer's status dot, shared by the inbox avatar badge
/// and the thread header so the same peer never shows two different colours.
///
/// Presence (control's Online flag) takes precedence over reachability (the
/// daemon's warm probe): an offline peer is grey everywhere, because being
/// offline is expected and not an error. Red is reserved for the one state
/// the user could not have guessed and can act on: control sees the peer
/// online but we cannot reach it.
enum PeerStatusKind {
  /// Our own tunnel is down; nothing can be said about the peer.
  disconnected,

  /// The peer is not in the current netmap at all.
  unavailable,

  /// Control reports the peer offline.
  offline,

  /// Peer online; no reachability probe is running (inbox, presence only).
  online,

  /// Peer online and the daemon's probe confirmed the path.
  ready,

  /// Peer online; the daemon is still probing, or a single probe failed.
  connecting,

  /// Peer online per control but the daemon's probes keep failing.
  unreachable,
}

class PeerStatusInfo {
  final PeerStatusKind kind;

  /// Short human label for tooltips and accessibility.
  final String label;

  const PeerStatusInfo(this.kind, this.label);

  // Value equality so providers only notify when the rendered state changes,
  // not on every netmap tick that re-resolves the same node.
  @override
  bool operator ==(Object other) =>
      other is PeerStatusInfo && other.kind == kind && other.label == label;

  @override
  int get hashCode => Object.hash(kind, label);
}

PeerStatusInfo resolvePeerStatus({
  required bool vpnConnected,
  required Node? node,
  PeerMessagingWarmStatus? warm,
}) {
  if (!vpnConnected) {
    return const PeerStatusInfo(PeerStatusKind.disconnected, 'Disconnected');
  }
  if (node == null) {
    return const PeerStatusInfo(PeerStatusKind.unavailable, 'Not in your network');
  }
  if (node.online != true) {
    final lastSeen = DateTime.tryParse(node.lastSeen ?? '');
    return PeerStatusInfo(
      PeerStatusKind.offline,
      lastSeen == null
          ? 'Offline'
          : 'Offline · last seen ${formatConversationTimestamp(lastSeen)}',
    );
  }
  switch (warm) {
    case null:
      return const PeerStatusInfo(PeerStatusKind.online, 'Online');
    case PeerMessagingWarmStatus.warm:
      return const PeerStatusInfo(
        PeerStatusKind.ready,
        'Online · connection ready',
      );
    case PeerMessagingWarmStatus.error:
      return const PeerStatusInfo(
        PeerStatusKind.unreachable,
        'Online but unreachable',
      );
    case PeerMessagingWarmStatus.cold:
    case PeerMessagingWarmStatus.warming:
    case PeerMessagingWarmStatus.offline:
      // `offline` here means the daemon's netmap view lags control's; treat
      // it as the path still forming rather than contradicting presence.
      return const PeerStatusInfo(
        PeerStatusKind.connecting,
        'Online · connecting…',
      );
  }
}

/// Presence-only status for a peer (inbox list, avatars).
final peerPresenceStatusProvider =
    Provider.family<PeerStatusInfo, String>((ref, peerRef) {
  return resolvePeerStatus(
    vpnConnected: ref.watch(vpnStateProvider) == VpnState.connected,
    node: ref.watch(peerForRefProvider(peerRef)),
  );
});

/// Presence plus reachability for the open thread, where the daemon keeps
/// the path to this peer warm and reports how that is going.
final peerThreadStatusProvider =
    Provider.family<PeerStatusInfo, String>((ref, peerRef) {
  return resolvePeerStatus(
    vpnConnected: ref.watch(vpnStateProvider) == VpnState.connected,
    node: ref.watch(peerForRefProvider(peerRef)),
    warm: ref.watch(peerMessagingWarmStatusForProvider(peerRef)),
  );
});
