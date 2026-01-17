// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:freezed_annotation/freezed_annotation.dart';
import 'ipn.dart';

part 'peer_transfer_state.freezed.dart';

/// Status of a file transfer
enum TransferStatus {
  sending,
  complete,
  failed,
}

/// State of a file transfer to a peer
@freezed
class PeerTransferState with _$PeerTransferState {
  const factory PeerTransferState({
    required String peerID,
    required List<OutgoingFile> files,
    @Default(0.0) double progress, // 0.0...1.0
    required TransferStatus status,
    String? errorMessage,
  }) = _PeerTransferState;

  const PeerTransferState._();

  /// Returns true if all files were sent but the transfer failed during processing
  /// This can happen if the file is successfully sent but failed to be
  /// processed by the receiving peer. e.g. filename is malformed.
  bool get allSuccessButWithFailedStatus =>
      files.every((f) => f.finished && f.succeeded) &&
      status == TransferStatus.failed;
}
