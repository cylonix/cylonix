// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'peer_transfer_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PeerTransferStateImpl _$$PeerTransferStateImplFromJson(
        Map<String, dynamic> json) =>
    _$PeerTransferStateImpl(
      peerID: json['peerID'] as String,
      files: (json['files'] as List<dynamic>)
          .map((e) => OutgoingFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      status: $enumDecode(_$TransferStatusEnumMap, json['status']),
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$$PeerTransferStateImplToJson(
        _$PeerTransferStateImpl instance) =>
    <String, dynamic>{
      'peerID': instance.peerID,
      'files': instance.files,
      'progress': instance.progress,
      'status': _$TransferStatusEnumMap[instance.status]!,
      'errorMessage': instance.errorMessage,
    };

const _$TransferStatusEnumMap = {
  TransferStatus.sending: 'sending',
  TransferStatus.complete: 'complete',
  TransferStatus.failed: 'failed',
};
