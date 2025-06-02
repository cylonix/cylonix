// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ping_view.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PingState {
  bool get isPinging => throw _privateConstructorUsedError;
  Node? get peer => throw _privateConstructorUsedError;
  String get connectionMode => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  String get lastLatencyValue => throw _privateConstructorUsedError;
  List<double> get latencyValues => throw _privateConstructorUsedError;

  /// Create a copy of PingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PingStateCopyWith<PingState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PingStateCopyWith<$Res> {
  factory $PingStateCopyWith(PingState value, $Res Function(PingState) then) =
      _$PingStateCopyWithImpl<$Res, PingState>;
  @useResult
  $Res call(
      {bool isPinging,
      Node? peer,
      String connectionMode,
      String? errorMessage,
      String lastLatencyValue,
      List<double> latencyValues});

  $NodeCopyWith<$Res>? get peer;
}

/// @nodoc
class _$PingStateCopyWithImpl<$Res, $Val extends PingState>
    implements $PingStateCopyWith<$Res> {
  _$PingStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isPinging = null,
    Object? peer = freezed,
    Object? connectionMode = null,
    Object? errorMessage = freezed,
    Object? lastLatencyValue = null,
    Object? latencyValues = null,
  }) {
    return _then(_value.copyWith(
      isPinging: null == isPinging
          ? _value.isPinging
          : isPinging // ignore: cast_nullable_to_non_nullable
              as bool,
      peer: freezed == peer
          ? _value.peer
          : peer // ignore: cast_nullable_to_non_nullable
              as Node?,
      connectionMode: null == connectionMode
          ? _value.connectionMode
          : connectionMode // ignore: cast_nullable_to_non_nullable
              as String,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      lastLatencyValue: null == lastLatencyValue
          ? _value.lastLatencyValue
          : lastLatencyValue // ignore: cast_nullable_to_non_nullable
              as String,
      latencyValues: null == latencyValues
          ? _value.latencyValues
          : latencyValues // ignore: cast_nullable_to_non_nullable
              as List<double>,
    ) as $Val);
  }

  /// Create a copy of PingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NodeCopyWith<$Res>? get peer {
    if (_value.peer == null) {
      return null;
    }

    return $NodeCopyWith<$Res>(_value.peer!, (value) {
      return _then(_value.copyWith(peer: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PingStateImplCopyWith<$Res>
    implements $PingStateCopyWith<$Res> {
  factory _$$PingStateImplCopyWith(
          _$PingStateImpl value, $Res Function(_$PingStateImpl) then) =
      __$$PingStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isPinging,
      Node? peer,
      String connectionMode,
      String? errorMessage,
      String lastLatencyValue,
      List<double> latencyValues});

  @override
  $NodeCopyWith<$Res>? get peer;
}

/// @nodoc
class __$$PingStateImplCopyWithImpl<$Res>
    extends _$PingStateCopyWithImpl<$Res, _$PingStateImpl>
    implements _$$PingStateImplCopyWith<$Res> {
  __$$PingStateImplCopyWithImpl(
      _$PingStateImpl _value, $Res Function(_$PingStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of PingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isPinging = null,
    Object? peer = freezed,
    Object? connectionMode = null,
    Object? errorMessage = freezed,
    Object? lastLatencyValue = null,
    Object? latencyValues = null,
  }) {
    return _then(_$PingStateImpl(
      isPinging: null == isPinging
          ? _value.isPinging
          : isPinging // ignore: cast_nullable_to_non_nullable
              as bool,
      peer: freezed == peer
          ? _value.peer
          : peer // ignore: cast_nullable_to_non_nullable
              as Node?,
      connectionMode: null == connectionMode
          ? _value.connectionMode
          : connectionMode // ignore: cast_nullable_to_non_nullable
              as String,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      lastLatencyValue: null == lastLatencyValue
          ? _value.lastLatencyValue
          : lastLatencyValue // ignore: cast_nullable_to_non_nullable
              as String,
      latencyValues: null == latencyValues
          ? _value._latencyValues
          : latencyValues // ignore: cast_nullable_to_non_nullable
              as List<double>,
    ));
  }
}

/// @nodoc

class _$PingStateImpl implements _PingState {
  const _$PingStateImpl(
      {this.isPinging = false,
      this.peer = null,
      this.connectionMode = "Not Connected",
      this.errorMessage = null,
      this.lastLatencyValue = "",
      final List<double> latencyValues = const []})
      : _latencyValues = latencyValues;

  @override
  @JsonKey()
  final bool isPinging;
  @override
  @JsonKey()
  final Node? peer;
  @override
  @JsonKey()
  final String connectionMode;
  @override
  @JsonKey()
  final String? errorMessage;
  @override
  @JsonKey()
  final String lastLatencyValue;
  final List<double> _latencyValues;
  @override
  @JsonKey()
  List<double> get latencyValues {
    if (_latencyValues is EqualUnmodifiableListView) return _latencyValues;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_latencyValues);
  }

  @override
  String toString() {
    return 'PingState(isPinging: $isPinging, peer: $peer, connectionMode: $connectionMode, errorMessage: $errorMessage, lastLatencyValue: $lastLatencyValue, latencyValues: $latencyValues)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PingStateImpl &&
            (identical(other.isPinging, isPinging) ||
                other.isPinging == isPinging) &&
            (identical(other.peer, peer) || other.peer == peer) &&
            (identical(other.connectionMode, connectionMode) ||
                other.connectionMode == connectionMode) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.lastLatencyValue, lastLatencyValue) ||
                other.lastLatencyValue == lastLatencyValue) &&
            const DeepCollectionEquality()
                .equals(other._latencyValues, _latencyValues));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isPinging,
      peer,
      connectionMode,
      errorMessage,
      lastLatencyValue,
      const DeepCollectionEquality().hash(_latencyValues));

  /// Create a copy of PingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PingStateImplCopyWith<_$PingStateImpl> get copyWith =>
      __$$PingStateImplCopyWithImpl<_$PingStateImpl>(this, _$identity);
}

abstract class _PingState implements PingState {
  const factory _PingState(
      {final bool isPinging,
      final Node? peer,
      final String connectionMode,
      final String? errorMessage,
      final String lastLatencyValue,
      final List<double> latencyValues}) = _$PingStateImpl;

  @override
  bool get isPinging;
  @override
  Node? get peer;
  @override
  String get connectionMode;
  @override
  String? get errorMessage;
  @override
  String get lastLatencyValue;
  @override
  List<double> get latencyValues;

  /// Create a copy of PingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PingStateImplCopyWith<_$PingStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
