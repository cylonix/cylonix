// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'peer_transfer_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PeerTransferState _$PeerTransferStateFromJson(Map<String, dynamic> json) {
  return _PeerTransferState.fromJson(json);
}

/// @nodoc
mixin _$PeerTransferState {
  String get peerID => throw _privateConstructorUsedError;
  List<OutgoingFile> get files => throw _privateConstructorUsedError;
  double get progress => throw _privateConstructorUsedError; // 0.0...1.0
  TransferStatus get status => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Serializes this PeerTransferState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PeerTransferState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PeerTransferStateCopyWith<PeerTransferState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PeerTransferStateCopyWith<$Res> {
  factory $PeerTransferStateCopyWith(
          PeerTransferState value, $Res Function(PeerTransferState) then) =
      _$PeerTransferStateCopyWithImpl<$Res, PeerTransferState>;
  @useResult
  $Res call(
      {String peerID,
      List<OutgoingFile> files,
      double progress,
      TransferStatus status,
      String? errorMessage});
}

/// @nodoc
class _$PeerTransferStateCopyWithImpl<$Res, $Val extends PeerTransferState>
    implements $PeerTransferStateCopyWith<$Res> {
  _$PeerTransferStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PeerTransferState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? peerID = null,
    Object? files = null,
    Object? progress = null,
    Object? status = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      peerID: null == peerID
          ? _value.peerID
          : peerID // ignore: cast_nullable_to_non_nullable
              as String,
      files: null == files
          ? _value.files
          : files // ignore: cast_nullable_to_non_nullable
              as List<OutgoingFile>,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TransferStatus,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PeerTransferStateImplCopyWith<$Res>
    implements $PeerTransferStateCopyWith<$Res> {
  factory _$$PeerTransferStateImplCopyWith(_$PeerTransferStateImpl value,
          $Res Function(_$PeerTransferStateImpl) then) =
      __$$PeerTransferStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String peerID,
      List<OutgoingFile> files,
      double progress,
      TransferStatus status,
      String? errorMessage});
}

/// @nodoc
class __$$PeerTransferStateImplCopyWithImpl<$Res>
    extends _$PeerTransferStateCopyWithImpl<$Res, _$PeerTransferStateImpl>
    implements _$$PeerTransferStateImplCopyWith<$Res> {
  __$$PeerTransferStateImplCopyWithImpl(_$PeerTransferStateImpl _value,
      $Res Function(_$PeerTransferStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of PeerTransferState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? peerID = null,
    Object? files = null,
    Object? progress = null,
    Object? status = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_$PeerTransferStateImpl(
      peerID: null == peerID
          ? _value.peerID
          : peerID // ignore: cast_nullable_to_non_nullable
              as String,
      files: null == files
          ? _value._files
          : files // ignore: cast_nullable_to_non_nullable
              as List<OutgoingFile>,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TransferStatus,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PeerTransferStateImpl extends _PeerTransferState {
  const _$PeerTransferStateImpl(
      {required this.peerID,
      required final List<OutgoingFile> files,
      this.progress = 0.0,
      required this.status,
      this.errorMessage})
      : _files = files,
        super._();

  factory _$PeerTransferStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$PeerTransferStateImplFromJson(json);

  @override
  final String peerID;
  final List<OutgoingFile> _files;
  @override
  List<OutgoingFile> get files {
    if (_files is EqualUnmodifiableListView) return _files;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_files);
  }

  @override
  @JsonKey()
  final double progress;
// 0.0...1.0
  @override
  final TransferStatus status;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'PeerTransferState(peerID: $peerID, files: $files, progress: $progress, status: $status, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PeerTransferStateImpl &&
            (identical(other.peerID, peerID) || other.peerID == peerID) &&
            const DeepCollectionEquality().equals(other._files, _files) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      peerID,
      const DeepCollectionEquality().hash(_files),
      progress,
      status,
      errorMessage);

  /// Create a copy of PeerTransferState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PeerTransferStateImplCopyWith<_$PeerTransferStateImpl> get copyWith =>
      __$$PeerTransferStateImplCopyWithImpl<_$PeerTransferStateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PeerTransferStateImplToJson(
      this,
    );
  }
}

abstract class _PeerTransferState extends PeerTransferState {
  const factory _PeerTransferState(
      {required final String peerID,
      required final List<OutgoingFile> files,
      final double progress,
      required final TransferStatus status,
      final String? errorMessage}) = _$PeerTransferStateImpl;
  const _PeerTransferState._() : super._();

  factory _PeerTransferState.fromJson(Map<String, dynamic> json) =
      _$PeerTransferStateImpl.fromJson;

  @override
  String get peerID;
  @override
  List<OutgoingFile> get files;
  @override
  double get progress; // 0.0...1.0
  @override
  TransferStatus get status;
  @override
  String? get errorMessage;

  /// Create a copy of PeerTransferState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PeerTransferStateImplCopyWith<_$PeerTransferStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
