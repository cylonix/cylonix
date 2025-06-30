import 'package:event_bus/event_bus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ipn.dart';
import '../models/peer_transfer_state.dart';
import 'ipn.dart';

final shareFileEventBus = EventBus();

final transfersProvider =
    StateNotifierProvider<TransfersNotifier, Map<String, PeerTransferState>>(
  (ref) => TransfersNotifier(ref),
);

class TransfersNotifier extends StateNotifier<Map<String, PeerTransferState>> {
  TransfersNotifier(this.ref) : super({}) {
    // Listen to ipnStateProvider and update transfers automatically
    ref.listen<IpnState?>(ipnStateProvider, (previous, next) {
      if (next?.outgoingFiles?.isEmpty ?? true) {
        return;
      }
      final updates = <String, PeerTransferState>{};
      final filesMap = {for (var file in next!.outgoingFiles!) file.id: file};
      var anyUpdates = false;

      for (final p in state.keys) {
        print("Checking transfer for peer $p");
        final ps = state[p];
        if (ps == null) {
          continue;
        }
        var files = <OutgoingFile>[];
        var updated = false;
        for (final f in ps.files) {
          if (f.finished) {
            files.add(OutgoingFile(
              id: f.id,
              name: f.name,
              declaredSize: f.declaredSize,
              sent: f.sent,
              finished: f.finished,
              succeeded: f.succeeded,
            ));
            continue;
          }
          final file = filesMap[f.id];
          if (file == null) {
            files.add(OutgoingFile(
              id: f.id,
              name: f.name,
              declaredSize: f.declaredSize,
              sent: f.sent,
              finished: f.finished,
              succeeded: f.succeeded,
            ));
            continue;
          }
          files.add(OutgoingFile(
            id: file.id,
            name: file.name,
            declaredSize: file.declaredSize,
            sent: file.sent,
            finished: file.finished,
            succeeded: file.succeeded,
          ));
          updated = true;
          anyUpdates = true;
        }
        if (!updated) {
          updates[p] = PeerTransferState(
            peerID: p,
            files: files,
            progress: ps.progress,
            status: ps.status,
            errorMessage: ps.errorMessage,
          );
          continue;
        }
        print("Updating transfer for peer $p");
        final totalSent = files.fold<int>(0, (sum, file) => sum + file.sent);
        final totalSize =
            files.fold<int>(0, (sum, file) => sum + file.declaredSize);
        final progress = totalSize > 0 ? totalSent / totalSize : 0.0;

        final allFinished = files.every((f) => f.finished);
        final allSucceeded = files.every((f) => f.succeeded);
        final status = !allFinished
            ? TransferStatus.sending
            : (allSucceeded ? TransferStatus.complete : TransferStatus.failed);
        updates[p] = PeerTransferState(
          peerID: p,
          files: files,
          progress: progress,
          status: status,
          errorMessage: ps.errorMessage,
        );
      }
      if (!anyUpdates) return;
      state = updates;
    });
  }

  final Ref ref;

  void initializeTransfer(String peerId, List<OutgoingFile> files) {
    state = {
      ...state,
      peerId: PeerTransferState(
        peerID: peerId,
        files: files,
        progress: 0.0,
        status: TransferStatus.sending,
      ),
    };
  }

  void updateTransfer(String peerId, PeerTransferState transfer) {
    state = {...state, peerId: transfer};
  }

  void reset() {
    // Reset the state to an empty map
    state = {};
  }
}

// Helper function
Map<K, List<T>> groupBy<T, K>(Iterable<T> items, K Function(T) key) {
  final map = <K, List<T>>{};
  for (final item in items) {
    final k = key(item);
    (map[k] ??= []).add(item);
  }
  return map;
}

final filteredPeersProvider =
    Provider.family<List<Node>, ({bool onlineOnly, String searchQuery})>(
        (ref, filters) {
  final netmap = ref.watch(netmapProvider);
  var peers = netmap?.peers ?? [];

  if (filters.onlineOnly) {
    peers = peers.where((p) => p.online ?? false).toList();
  }

  if (filters.searchQuery.isNotEmpty) {
    final query = filters.searchQuery.toLowerCase();
    peers = peers
        .where((p) =>
            p.displayName.toLowerCase().contains(query) ||
            (p.hostinfo?.os?.toLowerCase().contains(query) ?? false))
        .toList();
  }

  return peers;
});
