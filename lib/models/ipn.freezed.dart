// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ipn.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

IpnState _$IpnStateFromJson(Map<String, dynamic> json) {
  return _IpnState.fromJson(json);
}

/// @nodoc
mixin _$IpnState {
  BackendState get backendState => throw _privateConstructorUsedError;
  VpnState get vpnState => throw _privateConstructorUsedError;
  UserProfile? get loggedInUser => throw _privateConstructorUsedError;
  Node? get selfNode => throw _privateConstructorUsedError;
  NetworkMap? get netmap => throw _privateConstructorUsedError;
  IpnPrefs? get prefs => throw _privateConstructorUsedError;
  HealthState? get health => throw _privateConstructorUsedError;
  String? get browseToURL => throw _privateConstructorUsedError;
  String? get errMessage => throw _privateConstructorUsedError;
  List<OutgoingFile>? get outgoingFiles => throw _privateConstructorUsedError;
  LoginProfile? get currentProfile => throw _privateConstructorUsedError;
  List<LoginProfile> get loginProfiles => throw _privateConstructorUsedError;
  bool get isRunningExitNode => throw _privateConstructorUsedError;

  /// Serializes this IpnState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IpnState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IpnStateCopyWith<IpnState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IpnStateCopyWith<$Res> {
  factory $IpnStateCopyWith(IpnState value, $Res Function(IpnState) then) =
      _$IpnStateCopyWithImpl<$Res, IpnState>;
  @useResult
  $Res call(
      {BackendState backendState,
      VpnState vpnState,
      UserProfile? loggedInUser,
      Node? selfNode,
      NetworkMap? netmap,
      IpnPrefs? prefs,
      HealthState? health,
      String? browseToURL,
      String? errMessage,
      List<OutgoingFile>? outgoingFiles,
      LoginProfile? currentProfile,
      List<LoginProfile> loginProfiles,
      bool isRunningExitNode});

  $UserProfileCopyWith<$Res>? get loggedInUser;
  $NodeCopyWith<$Res>? get selfNode;
  $NetworkMapCopyWith<$Res>? get netmap;
  $IpnPrefsCopyWith<$Res>? get prefs;
  $HealthStateCopyWith<$Res>? get health;
  $LoginProfileCopyWith<$Res>? get currentProfile;
}

/// @nodoc
class _$IpnStateCopyWithImpl<$Res, $Val extends IpnState>
    implements $IpnStateCopyWith<$Res> {
  _$IpnStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IpnState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? backendState = null,
    Object? vpnState = null,
    Object? loggedInUser = freezed,
    Object? selfNode = freezed,
    Object? netmap = freezed,
    Object? prefs = freezed,
    Object? health = freezed,
    Object? browseToURL = freezed,
    Object? errMessage = freezed,
    Object? outgoingFiles = freezed,
    Object? currentProfile = freezed,
    Object? loginProfiles = null,
    Object? isRunningExitNode = null,
  }) {
    return _then(_value.copyWith(
      backendState: null == backendState
          ? _value.backendState
          : backendState // ignore: cast_nullable_to_non_nullable
              as BackendState,
      vpnState: null == vpnState
          ? _value.vpnState
          : vpnState // ignore: cast_nullable_to_non_nullable
              as VpnState,
      loggedInUser: freezed == loggedInUser
          ? _value.loggedInUser
          : loggedInUser // ignore: cast_nullable_to_non_nullable
              as UserProfile?,
      selfNode: freezed == selfNode
          ? _value.selfNode
          : selfNode // ignore: cast_nullable_to_non_nullable
              as Node?,
      netmap: freezed == netmap
          ? _value.netmap
          : netmap // ignore: cast_nullable_to_non_nullable
              as NetworkMap?,
      prefs: freezed == prefs
          ? _value.prefs
          : prefs // ignore: cast_nullable_to_non_nullable
              as IpnPrefs?,
      health: freezed == health
          ? _value.health
          : health // ignore: cast_nullable_to_non_nullable
              as HealthState?,
      browseToURL: freezed == browseToURL
          ? _value.browseToURL
          : browseToURL // ignore: cast_nullable_to_non_nullable
              as String?,
      errMessage: freezed == errMessage
          ? _value.errMessage
          : errMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      outgoingFiles: freezed == outgoingFiles
          ? _value.outgoingFiles
          : outgoingFiles // ignore: cast_nullable_to_non_nullable
              as List<OutgoingFile>?,
      currentProfile: freezed == currentProfile
          ? _value.currentProfile
          : currentProfile // ignore: cast_nullable_to_non_nullable
              as LoginProfile?,
      loginProfiles: null == loginProfiles
          ? _value.loginProfiles
          : loginProfiles // ignore: cast_nullable_to_non_nullable
              as List<LoginProfile>,
      isRunningExitNode: null == isRunningExitNode
          ? _value.isRunningExitNode
          : isRunningExitNode // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  /// Create a copy of IpnState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserProfileCopyWith<$Res>? get loggedInUser {
    if (_value.loggedInUser == null) {
      return null;
    }

    return $UserProfileCopyWith<$Res>(_value.loggedInUser!, (value) {
      return _then(_value.copyWith(loggedInUser: value) as $Val);
    });
  }

  /// Create a copy of IpnState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NodeCopyWith<$Res>? get selfNode {
    if (_value.selfNode == null) {
      return null;
    }

    return $NodeCopyWith<$Res>(_value.selfNode!, (value) {
      return _then(_value.copyWith(selfNode: value) as $Val);
    });
  }

  /// Create a copy of IpnState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NetworkMapCopyWith<$Res>? get netmap {
    if (_value.netmap == null) {
      return null;
    }

    return $NetworkMapCopyWith<$Res>(_value.netmap!, (value) {
      return _then(_value.copyWith(netmap: value) as $Val);
    });
  }

  /// Create a copy of IpnState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $IpnPrefsCopyWith<$Res>? get prefs {
    if (_value.prefs == null) {
      return null;
    }

    return $IpnPrefsCopyWith<$Res>(_value.prefs!, (value) {
      return _then(_value.copyWith(prefs: value) as $Val);
    });
  }

  /// Create a copy of IpnState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HealthStateCopyWith<$Res>? get health {
    if (_value.health == null) {
      return null;
    }

    return $HealthStateCopyWith<$Res>(_value.health!, (value) {
      return _then(_value.copyWith(health: value) as $Val);
    });
  }

  /// Create a copy of IpnState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LoginProfileCopyWith<$Res>? get currentProfile {
    if (_value.currentProfile == null) {
      return null;
    }

    return $LoginProfileCopyWith<$Res>(_value.currentProfile!, (value) {
      return _then(_value.copyWith(currentProfile: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$IpnStateImplCopyWith<$Res>
    implements $IpnStateCopyWith<$Res> {
  factory _$$IpnStateImplCopyWith(
          _$IpnStateImpl value, $Res Function(_$IpnStateImpl) then) =
      __$$IpnStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {BackendState backendState,
      VpnState vpnState,
      UserProfile? loggedInUser,
      Node? selfNode,
      NetworkMap? netmap,
      IpnPrefs? prefs,
      HealthState? health,
      String? browseToURL,
      String? errMessage,
      List<OutgoingFile>? outgoingFiles,
      LoginProfile? currentProfile,
      List<LoginProfile> loginProfiles,
      bool isRunningExitNode});

  @override
  $UserProfileCopyWith<$Res>? get loggedInUser;
  @override
  $NodeCopyWith<$Res>? get selfNode;
  @override
  $NetworkMapCopyWith<$Res>? get netmap;
  @override
  $IpnPrefsCopyWith<$Res>? get prefs;
  @override
  $HealthStateCopyWith<$Res>? get health;
  @override
  $LoginProfileCopyWith<$Res>? get currentProfile;
}

/// @nodoc
class __$$IpnStateImplCopyWithImpl<$Res>
    extends _$IpnStateCopyWithImpl<$Res, _$IpnStateImpl>
    implements _$$IpnStateImplCopyWith<$Res> {
  __$$IpnStateImplCopyWithImpl(
      _$IpnStateImpl _value, $Res Function(_$IpnStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of IpnState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? backendState = null,
    Object? vpnState = null,
    Object? loggedInUser = freezed,
    Object? selfNode = freezed,
    Object? netmap = freezed,
    Object? prefs = freezed,
    Object? health = freezed,
    Object? browseToURL = freezed,
    Object? errMessage = freezed,
    Object? outgoingFiles = freezed,
    Object? currentProfile = freezed,
    Object? loginProfiles = null,
    Object? isRunningExitNode = null,
  }) {
    return _then(_$IpnStateImpl(
      backendState: null == backendState
          ? _value.backendState
          : backendState // ignore: cast_nullable_to_non_nullable
              as BackendState,
      vpnState: null == vpnState
          ? _value.vpnState
          : vpnState // ignore: cast_nullable_to_non_nullable
              as VpnState,
      loggedInUser: freezed == loggedInUser
          ? _value.loggedInUser
          : loggedInUser // ignore: cast_nullable_to_non_nullable
              as UserProfile?,
      selfNode: freezed == selfNode
          ? _value.selfNode
          : selfNode // ignore: cast_nullable_to_non_nullable
              as Node?,
      netmap: freezed == netmap
          ? _value.netmap
          : netmap // ignore: cast_nullable_to_non_nullable
              as NetworkMap?,
      prefs: freezed == prefs
          ? _value.prefs
          : prefs // ignore: cast_nullable_to_non_nullable
              as IpnPrefs?,
      health: freezed == health
          ? _value.health
          : health // ignore: cast_nullable_to_non_nullable
              as HealthState?,
      browseToURL: freezed == browseToURL
          ? _value.browseToURL
          : browseToURL // ignore: cast_nullable_to_non_nullable
              as String?,
      errMessage: freezed == errMessage
          ? _value.errMessage
          : errMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      outgoingFiles: freezed == outgoingFiles
          ? _value._outgoingFiles
          : outgoingFiles // ignore: cast_nullable_to_non_nullable
              as List<OutgoingFile>?,
      currentProfile: freezed == currentProfile
          ? _value.currentProfile
          : currentProfile // ignore: cast_nullable_to_non_nullable
              as LoginProfile?,
      loginProfiles: null == loginProfiles
          ? _value._loginProfiles
          : loginProfiles // ignore: cast_nullable_to_non_nullable
              as List<LoginProfile>,
      isRunningExitNode: null == isRunningExitNode
          ? _value.isRunningExitNode
          : isRunningExitNode // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$IpnStateImpl implements _IpnState {
  const _$IpnStateImpl(
      {this.backendState = BackendState.noState,
      this.vpnState = VpnState.disconnected,
      this.loggedInUser,
      this.selfNode,
      this.netmap,
      this.prefs,
      this.health,
      this.browseToURL,
      this.errMessage,
      final List<OutgoingFile>? outgoingFiles,
      this.currentProfile,
      final List<LoginProfile> loginProfiles = const [],
      this.isRunningExitNode = false})
      : _outgoingFiles = outgoingFiles,
        _loginProfiles = loginProfiles;

  factory _$IpnStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$IpnStateImplFromJson(json);

  @override
  @JsonKey()
  final BackendState backendState;
  @override
  @JsonKey()
  final VpnState vpnState;
  @override
  final UserProfile? loggedInUser;
  @override
  final Node? selfNode;
  @override
  final NetworkMap? netmap;
  @override
  final IpnPrefs? prefs;
  @override
  final HealthState? health;
  @override
  final String? browseToURL;
  @override
  final String? errMessage;
  final List<OutgoingFile>? _outgoingFiles;
  @override
  List<OutgoingFile>? get outgoingFiles {
    final value = _outgoingFiles;
    if (value == null) return null;
    if (_outgoingFiles is EqualUnmodifiableListView) return _outgoingFiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final LoginProfile? currentProfile;
  final List<LoginProfile> _loginProfiles;
  @override
  @JsonKey()
  List<LoginProfile> get loginProfiles {
    if (_loginProfiles is EqualUnmodifiableListView) return _loginProfiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_loginProfiles);
  }

  @override
  @JsonKey()
  final bool isRunningExitNode;

  @override
  String toString() {
    return 'IpnState(backendState: $backendState, vpnState: $vpnState, loggedInUser: $loggedInUser, selfNode: $selfNode, netmap: $netmap, prefs: $prefs, health: $health, browseToURL: $browseToURL, errMessage: $errMessage, outgoingFiles: $outgoingFiles, currentProfile: $currentProfile, loginProfiles: $loginProfiles, isRunningExitNode: $isRunningExitNode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IpnStateImpl &&
            (identical(other.backendState, backendState) ||
                other.backendState == backendState) &&
            (identical(other.vpnState, vpnState) ||
                other.vpnState == vpnState) &&
            (identical(other.loggedInUser, loggedInUser) ||
                other.loggedInUser == loggedInUser) &&
            (identical(other.selfNode, selfNode) ||
                other.selfNode == selfNode) &&
            (identical(other.netmap, netmap) || other.netmap == netmap) &&
            (identical(other.prefs, prefs) || other.prefs == prefs) &&
            (identical(other.health, health) || other.health == health) &&
            (identical(other.browseToURL, browseToURL) ||
                other.browseToURL == browseToURL) &&
            (identical(other.errMessage, errMessage) ||
                other.errMessage == errMessage) &&
            const DeepCollectionEquality()
                .equals(other._outgoingFiles, _outgoingFiles) &&
            (identical(other.currentProfile, currentProfile) ||
                other.currentProfile == currentProfile) &&
            const DeepCollectionEquality()
                .equals(other._loginProfiles, _loginProfiles) &&
            (identical(other.isRunningExitNode, isRunningExitNode) ||
                other.isRunningExitNode == isRunningExitNode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      backendState,
      vpnState,
      loggedInUser,
      selfNode,
      netmap,
      prefs,
      health,
      browseToURL,
      errMessage,
      const DeepCollectionEquality().hash(_outgoingFiles),
      currentProfile,
      const DeepCollectionEquality().hash(_loginProfiles),
      isRunningExitNode);

  /// Create a copy of IpnState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IpnStateImplCopyWith<_$IpnStateImpl> get copyWith =>
      __$$IpnStateImplCopyWithImpl<_$IpnStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IpnStateImplToJson(
      this,
    );
  }
}

abstract class _IpnState implements IpnState {
  const factory _IpnState(
      {final BackendState backendState,
      final VpnState vpnState,
      final UserProfile? loggedInUser,
      final Node? selfNode,
      final NetworkMap? netmap,
      final IpnPrefs? prefs,
      final HealthState? health,
      final String? browseToURL,
      final String? errMessage,
      final List<OutgoingFile>? outgoingFiles,
      final LoginProfile? currentProfile,
      final List<LoginProfile> loginProfiles,
      final bool isRunningExitNode}) = _$IpnStateImpl;

  factory _IpnState.fromJson(Map<String, dynamic> json) =
      _$IpnStateImpl.fromJson;

  @override
  BackendState get backendState;
  @override
  VpnState get vpnState;
  @override
  UserProfile? get loggedInUser;
  @override
  Node? get selfNode;
  @override
  NetworkMap? get netmap;
  @override
  IpnPrefs? get prefs;
  @override
  HealthState? get health;
  @override
  String? get browseToURL;
  @override
  String? get errMessage;
  @override
  List<OutgoingFile>? get outgoingFiles;
  @override
  LoginProfile? get currentProfile;
  @override
  List<LoginProfile> get loginProfiles;
  @override
  bool get isRunningExitNode;

  /// Create a copy of IpnState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IpnStateImplCopyWith<_$IpnStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

IpnNotification _$IpnNotificationFromJson(Map<String, dynamic> json) {
  return _IpnNotification.fromJson(json);
}

/// @nodoc
mixin _$IpnNotification {
  @JsonKey(name: 'Version')
  String? get version => throw _privateConstructorUsedError;
  @JsonKey(name: 'ErrMessage')
  String? get errMessage => throw _privateConstructorUsedError;
  @JsonKey(name: 'LoginFinished')
  Map<String, dynamic>? get loginFinished => throw _privateConstructorUsedError;
  @JsonKey(name: 'FilesWaiting')
  Map<String, dynamic>? get filesWaiting => throw _privateConstructorUsedError;
  @JsonKey(name: 'OutgoingFiles')
  List<OutgoingFile>? get outgoingFiles => throw _privateConstructorUsedError;
  @JsonKey(name: 'State')
  int? get state => throw _privateConstructorUsedError;
  @JsonKey(name: 'Prefs')
  IpnPrefs? get prefs => throw _privateConstructorUsedError;
  @JsonKey(name: 'NetMap')
  NetworkMap? get netMap => throw _privateConstructorUsedError;
  @JsonKey(name: 'Engine')
  EngineStatus? get engine => throw _privateConstructorUsedError;
  @JsonKey(name: 'BrowseToURL')
  String? get browseToURL => throw _privateConstructorUsedError;
  @JsonKey(name: 'BackendLogID')
  String? get backendLogId => throw _privateConstructorUsedError;
  @JsonKey(name: 'LocalTCPPort')
  int? get localTCPPort => throw _privateConstructorUsedError;
  @JsonKey(name: 'IncomingFiles')
  List<PartialFile>? get incomingFiles => throw _privateConstructorUsedError;
  @JsonKey(name: 'ClientVersion')
  ClientVersion? get clientVersion => throw _privateConstructorUsedError;
  @JsonKey(name: 'TailFSShares')
  List<String>? get tailFSShares => throw _privateConstructorUsedError;
  @JsonKey(name: 'Health')
  HealthState? get health => throw _privateConstructorUsedError;

  /// Serializes this IpnNotification to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IpnNotification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IpnNotificationCopyWith<IpnNotification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IpnNotificationCopyWith<$Res> {
  factory $IpnNotificationCopyWith(
          IpnNotification value, $Res Function(IpnNotification) then) =
      _$IpnNotificationCopyWithImpl<$Res, IpnNotification>;
  @useResult
  $Res call(
      {@JsonKey(name: 'Version') String? version,
      @JsonKey(name: 'ErrMessage') String? errMessage,
      @JsonKey(name: 'LoginFinished') Map<String, dynamic>? loginFinished,
      @JsonKey(name: 'FilesWaiting') Map<String, dynamic>? filesWaiting,
      @JsonKey(name: 'OutgoingFiles') List<OutgoingFile>? outgoingFiles,
      @JsonKey(name: 'State') int? state,
      @JsonKey(name: 'Prefs') IpnPrefs? prefs,
      @JsonKey(name: 'NetMap') NetworkMap? netMap,
      @JsonKey(name: 'Engine') EngineStatus? engine,
      @JsonKey(name: 'BrowseToURL') String? browseToURL,
      @JsonKey(name: 'BackendLogID') String? backendLogId,
      @JsonKey(name: 'LocalTCPPort') int? localTCPPort,
      @JsonKey(name: 'IncomingFiles') List<PartialFile>? incomingFiles,
      @JsonKey(name: 'ClientVersion') ClientVersion? clientVersion,
      @JsonKey(name: 'TailFSShares') List<String>? tailFSShares,
      @JsonKey(name: 'Health') HealthState? health});

  $IpnPrefsCopyWith<$Res>? get prefs;
  $NetworkMapCopyWith<$Res>? get netMap;
  $EngineStatusCopyWith<$Res>? get engine;
  $ClientVersionCopyWith<$Res>? get clientVersion;
  $HealthStateCopyWith<$Res>? get health;
}

/// @nodoc
class _$IpnNotificationCopyWithImpl<$Res, $Val extends IpnNotification>
    implements $IpnNotificationCopyWith<$Res> {
  _$IpnNotificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IpnNotification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = freezed,
    Object? errMessage = freezed,
    Object? loginFinished = freezed,
    Object? filesWaiting = freezed,
    Object? outgoingFiles = freezed,
    Object? state = freezed,
    Object? prefs = freezed,
    Object? netMap = freezed,
    Object? engine = freezed,
    Object? browseToURL = freezed,
    Object? backendLogId = freezed,
    Object? localTCPPort = freezed,
    Object? incomingFiles = freezed,
    Object? clientVersion = freezed,
    Object? tailFSShares = freezed,
    Object? health = freezed,
  }) {
    return _then(_value.copyWith(
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String?,
      errMessage: freezed == errMessage
          ? _value.errMessage
          : errMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      loginFinished: freezed == loginFinished
          ? _value.loginFinished
          : loginFinished // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      filesWaiting: freezed == filesWaiting
          ? _value.filesWaiting
          : filesWaiting // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      outgoingFiles: freezed == outgoingFiles
          ? _value.outgoingFiles
          : outgoingFiles // ignore: cast_nullable_to_non_nullable
              as List<OutgoingFile>?,
      state: freezed == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as int?,
      prefs: freezed == prefs
          ? _value.prefs
          : prefs // ignore: cast_nullable_to_non_nullable
              as IpnPrefs?,
      netMap: freezed == netMap
          ? _value.netMap
          : netMap // ignore: cast_nullable_to_non_nullable
              as NetworkMap?,
      engine: freezed == engine
          ? _value.engine
          : engine // ignore: cast_nullable_to_non_nullable
              as EngineStatus?,
      browseToURL: freezed == browseToURL
          ? _value.browseToURL
          : browseToURL // ignore: cast_nullable_to_non_nullable
              as String?,
      backendLogId: freezed == backendLogId
          ? _value.backendLogId
          : backendLogId // ignore: cast_nullable_to_non_nullable
              as String?,
      localTCPPort: freezed == localTCPPort
          ? _value.localTCPPort
          : localTCPPort // ignore: cast_nullable_to_non_nullable
              as int?,
      incomingFiles: freezed == incomingFiles
          ? _value.incomingFiles
          : incomingFiles // ignore: cast_nullable_to_non_nullable
              as List<PartialFile>?,
      clientVersion: freezed == clientVersion
          ? _value.clientVersion
          : clientVersion // ignore: cast_nullable_to_non_nullable
              as ClientVersion?,
      tailFSShares: freezed == tailFSShares
          ? _value.tailFSShares
          : tailFSShares // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      health: freezed == health
          ? _value.health
          : health // ignore: cast_nullable_to_non_nullable
              as HealthState?,
    ) as $Val);
  }

  /// Create a copy of IpnNotification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $IpnPrefsCopyWith<$Res>? get prefs {
    if (_value.prefs == null) {
      return null;
    }

    return $IpnPrefsCopyWith<$Res>(_value.prefs!, (value) {
      return _then(_value.copyWith(prefs: value) as $Val);
    });
  }

  /// Create a copy of IpnNotification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NetworkMapCopyWith<$Res>? get netMap {
    if (_value.netMap == null) {
      return null;
    }

    return $NetworkMapCopyWith<$Res>(_value.netMap!, (value) {
      return _then(_value.copyWith(netMap: value) as $Val);
    });
  }

  /// Create a copy of IpnNotification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EngineStatusCopyWith<$Res>? get engine {
    if (_value.engine == null) {
      return null;
    }

    return $EngineStatusCopyWith<$Res>(_value.engine!, (value) {
      return _then(_value.copyWith(engine: value) as $Val);
    });
  }

  /// Create a copy of IpnNotification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ClientVersionCopyWith<$Res>? get clientVersion {
    if (_value.clientVersion == null) {
      return null;
    }

    return $ClientVersionCopyWith<$Res>(_value.clientVersion!, (value) {
      return _then(_value.copyWith(clientVersion: value) as $Val);
    });
  }

  /// Create a copy of IpnNotification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HealthStateCopyWith<$Res>? get health {
    if (_value.health == null) {
      return null;
    }

    return $HealthStateCopyWith<$Res>(_value.health!, (value) {
      return _then(_value.copyWith(health: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$IpnNotificationImplCopyWith<$Res>
    implements $IpnNotificationCopyWith<$Res> {
  factory _$$IpnNotificationImplCopyWith(_$IpnNotificationImpl value,
          $Res Function(_$IpnNotificationImpl) then) =
      __$$IpnNotificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Version') String? version,
      @JsonKey(name: 'ErrMessage') String? errMessage,
      @JsonKey(name: 'LoginFinished') Map<String, dynamic>? loginFinished,
      @JsonKey(name: 'FilesWaiting') Map<String, dynamic>? filesWaiting,
      @JsonKey(name: 'OutgoingFiles') List<OutgoingFile>? outgoingFiles,
      @JsonKey(name: 'State') int? state,
      @JsonKey(name: 'Prefs') IpnPrefs? prefs,
      @JsonKey(name: 'NetMap') NetworkMap? netMap,
      @JsonKey(name: 'Engine') EngineStatus? engine,
      @JsonKey(name: 'BrowseToURL') String? browseToURL,
      @JsonKey(name: 'BackendLogID') String? backendLogId,
      @JsonKey(name: 'LocalTCPPort') int? localTCPPort,
      @JsonKey(name: 'IncomingFiles') List<PartialFile>? incomingFiles,
      @JsonKey(name: 'ClientVersion') ClientVersion? clientVersion,
      @JsonKey(name: 'TailFSShares') List<String>? tailFSShares,
      @JsonKey(name: 'Health') HealthState? health});

  @override
  $IpnPrefsCopyWith<$Res>? get prefs;
  @override
  $NetworkMapCopyWith<$Res>? get netMap;
  @override
  $EngineStatusCopyWith<$Res>? get engine;
  @override
  $ClientVersionCopyWith<$Res>? get clientVersion;
  @override
  $HealthStateCopyWith<$Res>? get health;
}

/// @nodoc
class __$$IpnNotificationImplCopyWithImpl<$Res>
    extends _$IpnNotificationCopyWithImpl<$Res, _$IpnNotificationImpl>
    implements _$$IpnNotificationImplCopyWith<$Res> {
  __$$IpnNotificationImplCopyWithImpl(
      _$IpnNotificationImpl _value, $Res Function(_$IpnNotificationImpl) _then)
      : super(_value, _then);

  /// Create a copy of IpnNotification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = freezed,
    Object? errMessage = freezed,
    Object? loginFinished = freezed,
    Object? filesWaiting = freezed,
    Object? outgoingFiles = freezed,
    Object? state = freezed,
    Object? prefs = freezed,
    Object? netMap = freezed,
    Object? engine = freezed,
    Object? browseToURL = freezed,
    Object? backendLogId = freezed,
    Object? localTCPPort = freezed,
    Object? incomingFiles = freezed,
    Object? clientVersion = freezed,
    Object? tailFSShares = freezed,
    Object? health = freezed,
  }) {
    return _then(_$IpnNotificationImpl(
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String?,
      errMessage: freezed == errMessage
          ? _value.errMessage
          : errMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      loginFinished: freezed == loginFinished
          ? _value._loginFinished
          : loginFinished // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      filesWaiting: freezed == filesWaiting
          ? _value._filesWaiting
          : filesWaiting // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      outgoingFiles: freezed == outgoingFiles
          ? _value._outgoingFiles
          : outgoingFiles // ignore: cast_nullable_to_non_nullable
              as List<OutgoingFile>?,
      state: freezed == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as int?,
      prefs: freezed == prefs
          ? _value.prefs
          : prefs // ignore: cast_nullable_to_non_nullable
              as IpnPrefs?,
      netMap: freezed == netMap
          ? _value.netMap
          : netMap // ignore: cast_nullable_to_non_nullable
              as NetworkMap?,
      engine: freezed == engine
          ? _value.engine
          : engine // ignore: cast_nullable_to_non_nullable
              as EngineStatus?,
      browseToURL: freezed == browseToURL
          ? _value.browseToURL
          : browseToURL // ignore: cast_nullable_to_non_nullable
              as String?,
      backendLogId: freezed == backendLogId
          ? _value.backendLogId
          : backendLogId // ignore: cast_nullable_to_non_nullable
              as String?,
      localTCPPort: freezed == localTCPPort
          ? _value.localTCPPort
          : localTCPPort // ignore: cast_nullable_to_non_nullable
              as int?,
      incomingFiles: freezed == incomingFiles
          ? _value._incomingFiles
          : incomingFiles // ignore: cast_nullable_to_non_nullable
              as List<PartialFile>?,
      clientVersion: freezed == clientVersion
          ? _value.clientVersion
          : clientVersion // ignore: cast_nullable_to_non_nullable
              as ClientVersion?,
      tailFSShares: freezed == tailFSShares
          ? _value._tailFSShares
          : tailFSShares // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      health: freezed == health
          ? _value.health
          : health // ignore: cast_nullable_to_non_nullable
              as HealthState?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$IpnNotificationImpl implements _IpnNotification {
  const _$IpnNotificationImpl(
      {@JsonKey(name: 'Version') this.version,
      @JsonKey(name: 'ErrMessage') this.errMessage,
      @JsonKey(name: 'LoginFinished') final Map<String, dynamic>? loginFinished,
      @JsonKey(name: 'FilesWaiting') final Map<String, dynamic>? filesWaiting,
      @JsonKey(name: 'OutgoingFiles') final List<OutgoingFile>? outgoingFiles,
      @JsonKey(name: 'State') this.state,
      @JsonKey(name: 'Prefs') this.prefs,
      @JsonKey(name: 'NetMap') this.netMap,
      @JsonKey(name: 'Engine') this.engine,
      @JsonKey(name: 'BrowseToURL') this.browseToURL,
      @JsonKey(name: 'BackendLogID') this.backendLogId,
      @JsonKey(name: 'LocalTCPPort') this.localTCPPort,
      @JsonKey(name: 'IncomingFiles') final List<PartialFile>? incomingFiles,
      @JsonKey(name: 'ClientVersion') this.clientVersion,
      @JsonKey(name: 'TailFSShares') final List<String>? tailFSShares,
      @JsonKey(name: 'Health') this.health})
      : _loginFinished = loginFinished,
        _filesWaiting = filesWaiting,
        _outgoingFiles = outgoingFiles,
        _incomingFiles = incomingFiles,
        _tailFSShares = tailFSShares;

  factory _$IpnNotificationImpl.fromJson(Map<String, dynamic> json) =>
      _$$IpnNotificationImplFromJson(json);

  @override
  @JsonKey(name: 'Version')
  final String? version;
  @override
  @JsonKey(name: 'ErrMessage')
  final String? errMessage;
  final Map<String, dynamic>? _loginFinished;
  @override
  @JsonKey(name: 'LoginFinished')
  Map<String, dynamic>? get loginFinished {
    final value = _loginFinished;
    if (value == null) return null;
    if (_loginFinished is EqualUnmodifiableMapView) return _loginFinished;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final Map<String, dynamic>? _filesWaiting;
  @override
  @JsonKey(name: 'FilesWaiting')
  Map<String, dynamic>? get filesWaiting {
    final value = _filesWaiting;
    if (value == null) return null;
    if (_filesWaiting is EqualUnmodifiableMapView) return _filesWaiting;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final List<OutgoingFile>? _outgoingFiles;
  @override
  @JsonKey(name: 'OutgoingFiles')
  List<OutgoingFile>? get outgoingFiles {
    final value = _outgoingFiles;
    if (value == null) return null;
    if (_outgoingFiles is EqualUnmodifiableListView) return _outgoingFiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'State')
  final int? state;
  @override
  @JsonKey(name: 'Prefs')
  final IpnPrefs? prefs;
  @override
  @JsonKey(name: 'NetMap')
  final NetworkMap? netMap;
  @override
  @JsonKey(name: 'Engine')
  final EngineStatus? engine;
  @override
  @JsonKey(name: 'BrowseToURL')
  final String? browseToURL;
  @override
  @JsonKey(name: 'BackendLogID')
  final String? backendLogId;
  @override
  @JsonKey(name: 'LocalTCPPort')
  final int? localTCPPort;
  final List<PartialFile>? _incomingFiles;
  @override
  @JsonKey(name: 'IncomingFiles')
  List<PartialFile>? get incomingFiles {
    final value = _incomingFiles;
    if (value == null) return null;
    if (_incomingFiles is EqualUnmodifiableListView) return _incomingFiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'ClientVersion')
  final ClientVersion? clientVersion;
  final List<String>? _tailFSShares;
  @override
  @JsonKey(name: 'TailFSShares')
  List<String>? get tailFSShares {
    final value = _tailFSShares;
    if (value == null) return null;
    if (_tailFSShares is EqualUnmodifiableListView) return _tailFSShares;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'Health')
  final HealthState? health;

  @override
  String toString() {
    return 'IpnNotification(version: $version, errMessage: $errMessage, loginFinished: $loginFinished, filesWaiting: $filesWaiting, outgoingFiles: $outgoingFiles, state: $state, prefs: $prefs, netMap: $netMap, engine: $engine, browseToURL: $browseToURL, backendLogId: $backendLogId, localTCPPort: $localTCPPort, incomingFiles: $incomingFiles, clientVersion: $clientVersion, tailFSShares: $tailFSShares, health: $health)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IpnNotificationImpl &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.errMessage, errMessage) ||
                other.errMessage == errMessage) &&
            const DeepCollectionEquality()
                .equals(other._loginFinished, _loginFinished) &&
            const DeepCollectionEquality()
                .equals(other._filesWaiting, _filesWaiting) &&
            const DeepCollectionEquality()
                .equals(other._outgoingFiles, _outgoingFiles) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.prefs, prefs) || other.prefs == prefs) &&
            (identical(other.netMap, netMap) || other.netMap == netMap) &&
            (identical(other.engine, engine) || other.engine == engine) &&
            (identical(other.browseToURL, browseToURL) ||
                other.browseToURL == browseToURL) &&
            (identical(other.backendLogId, backendLogId) ||
                other.backendLogId == backendLogId) &&
            (identical(other.localTCPPort, localTCPPort) ||
                other.localTCPPort == localTCPPort) &&
            const DeepCollectionEquality()
                .equals(other._incomingFiles, _incomingFiles) &&
            (identical(other.clientVersion, clientVersion) ||
                other.clientVersion == clientVersion) &&
            const DeepCollectionEquality()
                .equals(other._tailFSShares, _tailFSShares) &&
            (identical(other.health, health) || other.health == health));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      version,
      errMessage,
      const DeepCollectionEquality().hash(_loginFinished),
      const DeepCollectionEquality().hash(_filesWaiting),
      const DeepCollectionEquality().hash(_outgoingFiles),
      state,
      prefs,
      netMap,
      engine,
      browseToURL,
      backendLogId,
      localTCPPort,
      const DeepCollectionEquality().hash(_incomingFiles),
      clientVersion,
      const DeepCollectionEquality().hash(_tailFSShares),
      health);

  /// Create a copy of IpnNotification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IpnNotificationImplCopyWith<_$IpnNotificationImpl> get copyWith =>
      __$$IpnNotificationImplCopyWithImpl<_$IpnNotificationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IpnNotificationImplToJson(
      this,
    );
  }
}

abstract class _IpnNotification implements IpnNotification {
  const factory _IpnNotification(
      {@JsonKey(name: 'Version') final String? version,
      @JsonKey(name: 'ErrMessage') final String? errMessage,
      @JsonKey(name: 'LoginFinished') final Map<String, dynamic>? loginFinished,
      @JsonKey(name: 'FilesWaiting') final Map<String, dynamic>? filesWaiting,
      @JsonKey(name: 'OutgoingFiles') final List<OutgoingFile>? outgoingFiles,
      @JsonKey(name: 'State') final int? state,
      @JsonKey(name: 'Prefs') final IpnPrefs? prefs,
      @JsonKey(name: 'NetMap') final NetworkMap? netMap,
      @JsonKey(name: 'Engine') final EngineStatus? engine,
      @JsonKey(name: 'BrowseToURL') final String? browseToURL,
      @JsonKey(name: 'BackendLogID') final String? backendLogId,
      @JsonKey(name: 'LocalTCPPort') final int? localTCPPort,
      @JsonKey(name: 'IncomingFiles') final List<PartialFile>? incomingFiles,
      @JsonKey(name: 'ClientVersion') final ClientVersion? clientVersion,
      @JsonKey(name: 'TailFSShares') final List<String>? tailFSShares,
      @JsonKey(name: 'Health')
      final HealthState? health}) = _$IpnNotificationImpl;

  factory _IpnNotification.fromJson(Map<String, dynamic> json) =
      _$IpnNotificationImpl.fromJson;

  @override
  @JsonKey(name: 'Version')
  String? get version;
  @override
  @JsonKey(name: 'ErrMessage')
  String? get errMessage;
  @override
  @JsonKey(name: 'LoginFinished')
  Map<String, dynamic>? get loginFinished;
  @override
  @JsonKey(name: 'FilesWaiting')
  Map<String, dynamic>? get filesWaiting;
  @override
  @JsonKey(name: 'OutgoingFiles')
  List<OutgoingFile>? get outgoingFiles;
  @override
  @JsonKey(name: 'State')
  int? get state;
  @override
  @JsonKey(name: 'Prefs')
  IpnPrefs? get prefs;
  @override
  @JsonKey(name: 'NetMap')
  NetworkMap? get netMap;
  @override
  @JsonKey(name: 'Engine')
  EngineStatus? get engine;
  @override
  @JsonKey(name: 'BrowseToURL')
  String? get browseToURL;
  @override
  @JsonKey(name: 'BackendLogID')
  String? get backendLogId;
  @override
  @JsonKey(name: 'LocalTCPPort')
  int? get localTCPPort;
  @override
  @JsonKey(name: 'IncomingFiles')
  List<PartialFile>? get incomingFiles;
  @override
  @JsonKey(name: 'ClientVersion')
  ClientVersion? get clientVersion;
  @override
  @JsonKey(name: 'TailFSShares')
  List<String>? get tailFSShares;
  @override
  @JsonKey(name: 'Health')
  HealthState? get health;

  /// Create a copy of IpnNotification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IpnNotificationImplCopyWith<_$IpnNotificationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HealthState _$HealthStateFromJson(Map<String, dynamic> json) {
  return _HealthState.fromJson(json);
}

/// @nodoc
mixin _$HealthState {
  @JsonKey(name: 'Warnings')
  Map<String, UnhealthyState?>? get warnings =>
      throw _privateConstructorUsedError;

  /// Serializes this HealthState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HealthState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HealthStateCopyWith<HealthState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HealthStateCopyWith<$Res> {
  factory $HealthStateCopyWith(
          HealthState value, $Res Function(HealthState) then) =
      _$HealthStateCopyWithImpl<$Res, HealthState>;
  @useResult
  $Res call(
      {@JsonKey(name: 'Warnings') Map<String, UnhealthyState?>? warnings});
}

/// @nodoc
class _$HealthStateCopyWithImpl<$Res, $Val extends HealthState>
    implements $HealthStateCopyWith<$Res> {
  _$HealthStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HealthState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? warnings = freezed,
  }) {
    return _then(_value.copyWith(
      warnings: freezed == warnings
          ? _value.warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as Map<String, UnhealthyState?>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HealthStateImplCopyWith<$Res>
    implements $HealthStateCopyWith<$Res> {
  factory _$$HealthStateImplCopyWith(
          _$HealthStateImpl value, $Res Function(_$HealthStateImpl) then) =
      __$$HealthStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Warnings') Map<String, UnhealthyState?>? warnings});
}

/// @nodoc
class __$$HealthStateImplCopyWithImpl<$Res>
    extends _$HealthStateCopyWithImpl<$Res, _$HealthStateImpl>
    implements _$$HealthStateImplCopyWith<$Res> {
  __$$HealthStateImplCopyWithImpl(
      _$HealthStateImpl _value, $Res Function(_$HealthStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of HealthState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? warnings = freezed,
  }) {
    return _then(_$HealthStateImpl(
      warnings: freezed == warnings
          ? _value._warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as Map<String, UnhealthyState?>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HealthStateImpl implements _HealthState {
  const _$HealthStateImpl(
      {@JsonKey(name: 'Warnings') final Map<String, UnhealthyState?>? warnings})
      : _warnings = warnings;

  factory _$HealthStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$HealthStateImplFromJson(json);

  final Map<String, UnhealthyState?>? _warnings;
  @override
  @JsonKey(name: 'Warnings')
  Map<String, UnhealthyState?>? get warnings {
    final value = _warnings;
    if (value == null) return null;
    if (_warnings is EqualUnmodifiableMapView) return _warnings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'HealthState(warnings: $warnings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HealthStateImpl &&
            const DeepCollectionEquality().equals(other._warnings, _warnings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_warnings));

  /// Create a copy of HealthState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HealthStateImplCopyWith<_$HealthStateImpl> get copyWith =>
      __$$HealthStateImplCopyWithImpl<_$HealthStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HealthStateImplToJson(
      this,
    );
  }
}

abstract class _HealthState implements HealthState {
  const factory _HealthState(
      {@JsonKey(name: 'Warnings')
      final Map<String, UnhealthyState?>? warnings}) = _$HealthStateImpl;

  factory _HealthState.fromJson(Map<String, dynamic> json) =
      _$HealthStateImpl.fromJson;

  @override
  @JsonKey(name: 'Warnings')
  Map<String, UnhealthyState?>? get warnings;

  /// Create a copy of HealthState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HealthStateImplCopyWith<_$HealthStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UnhealthyState _$UnhealthyStateFromJson(Map<String, dynamic> json) {
  return _UnhealthyState.fromJson(json);
}

/// @nodoc
mixin _$UnhealthyState {
  @JsonKey(name: 'WarnableCode')
  String get warnableCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'Severity')
  Severity get severity => throw _privateConstructorUsedError;
  @JsonKey(name: 'Title')
  String get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'Text')
  String get text => throw _privateConstructorUsedError;
  @JsonKey(name: 'BrokenSince')
  String? get brokenSince => throw _privateConstructorUsedError;
  @JsonKey(name: 'Args')
  Map<String, String>? get args => throw _privateConstructorUsedError;
  @JsonKey(name: 'ImpactsConnectivity')
  bool? get impactsConnectivity => throw _privateConstructorUsedError;
  @JsonKey(name: 'DependsOn')
  List<String>? get dependsOn => throw _privateConstructorUsedError;

  /// Serializes this UnhealthyState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UnhealthyState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UnhealthyStateCopyWith<UnhealthyState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UnhealthyStateCopyWith<$Res> {
  factory $UnhealthyStateCopyWith(
          UnhealthyState value, $Res Function(UnhealthyState) then) =
      _$UnhealthyStateCopyWithImpl<$Res, UnhealthyState>;
  @useResult
  $Res call(
      {@JsonKey(name: 'WarnableCode') String warnableCode,
      @JsonKey(name: 'Severity') Severity severity,
      @JsonKey(name: 'Title') String title,
      @JsonKey(name: 'Text') String text,
      @JsonKey(name: 'BrokenSince') String? brokenSince,
      @JsonKey(name: 'Args') Map<String, String>? args,
      @JsonKey(name: 'ImpactsConnectivity') bool? impactsConnectivity,
      @JsonKey(name: 'DependsOn') List<String>? dependsOn});
}

/// @nodoc
class _$UnhealthyStateCopyWithImpl<$Res, $Val extends UnhealthyState>
    implements $UnhealthyStateCopyWith<$Res> {
  _$UnhealthyStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UnhealthyState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? warnableCode = null,
    Object? severity = null,
    Object? title = null,
    Object? text = null,
    Object? brokenSince = freezed,
    Object? args = freezed,
    Object? impactsConnectivity = freezed,
    Object? dependsOn = freezed,
  }) {
    return _then(_value.copyWith(
      warnableCode: null == warnableCode
          ? _value.warnableCode
          : warnableCode // ignore: cast_nullable_to_non_nullable
              as String,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as Severity,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      brokenSince: freezed == brokenSince
          ? _value.brokenSince
          : brokenSince // ignore: cast_nullable_to_non_nullable
              as String?,
      args: freezed == args
          ? _value.args
          : args // ignore: cast_nullable_to_non_nullable
              as Map<String, String>?,
      impactsConnectivity: freezed == impactsConnectivity
          ? _value.impactsConnectivity
          : impactsConnectivity // ignore: cast_nullable_to_non_nullable
              as bool?,
      dependsOn: freezed == dependsOn
          ? _value.dependsOn
          : dependsOn // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UnhealthyStateImplCopyWith<$Res>
    implements $UnhealthyStateCopyWith<$Res> {
  factory _$$UnhealthyStateImplCopyWith(_$UnhealthyStateImpl value,
          $Res Function(_$UnhealthyStateImpl) then) =
      __$$UnhealthyStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'WarnableCode') String warnableCode,
      @JsonKey(name: 'Severity') Severity severity,
      @JsonKey(name: 'Title') String title,
      @JsonKey(name: 'Text') String text,
      @JsonKey(name: 'BrokenSince') String? brokenSince,
      @JsonKey(name: 'Args') Map<String, String>? args,
      @JsonKey(name: 'ImpactsConnectivity') bool? impactsConnectivity,
      @JsonKey(name: 'DependsOn') List<String>? dependsOn});
}

/// @nodoc
class __$$UnhealthyStateImplCopyWithImpl<$Res>
    extends _$UnhealthyStateCopyWithImpl<$Res, _$UnhealthyStateImpl>
    implements _$$UnhealthyStateImplCopyWith<$Res> {
  __$$UnhealthyStateImplCopyWithImpl(
      _$UnhealthyStateImpl _value, $Res Function(_$UnhealthyStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of UnhealthyState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? warnableCode = null,
    Object? severity = null,
    Object? title = null,
    Object? text = null,
    Object? brokenSince = freezed,
    Object? args = freezed,
    Object? impactsConnectivity = freezed,
    Object? dependsOn = freezed,
  }) {
    return _then(_$UnhealthyStateImpl(
      warnableCode: null == warnableCode
          ? _value.warnableCode
          : warnableCode // ignore: cast_nullable_to_non_nullable
              as String,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as Severity,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      brokenSince: freezed == brokenSince
          ? _value.brokenSince
          : brokenSince // ignore: cast_nullable_to_non_nullable
              as String?,
      args: freezed == args
          ? _value._args
          : args // ignore: cast_nullable_to_non_nullable
              as Map<String, String>?,
      impactsConnectivity: freezed == impactsConnectivity
          ? _value.impactsConnectivity
          : impactsConnectivity // ignore: cast_nullable_to_non_nullable
              as bool?,
      dependsOn: freezed == dependsOn
          ? _value._dependsOn
          : dependsOn // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UnhealthyStateImpl extends _UnhealthyState {
  const _$UnhealthyStateImpl(
      {@JsonKey(name: 'WarnableCode') required this.warnableCode,
      @JsonKey(name: 'Severity') required this.severity,
      @JsonKey(name: 'Title') required this.title,
      @JsonKey(name: 'Text') required this.text,
      @JsonKey(name: 'BrokenSince') this.brokenSince,
      @JsonKey(name: 'Args') final Map<String, String>? args,
      @JsonKey(name: 'ImpactsConnectivity') this.impactsConnectivity,
      @JsonKey(name: 'DependsOn') final List<String>? dependsOn})
      : _args = args,
        _dependsOn = dependsOn,
        super._();

  factory _$UnhealthyStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$UnhealthyStateImplFromJson(json);

  @override
  @JsonKey(name: 'WarnableCode')
  final String warnableCode;
  @override
  @JsonKey(name: 'Severity')
  final Severity severity;
  @override
  @JsonKey(name: 'Title')
  final String title;
  @override
  @JsonKey(name: 'Text')
  final String text;
  @override
  @JsonKey(name: 'BrokenSince')
  final String? brokenSince;
  final Map<String, String>? _args;
  @override
  @JsonKey(name: 'Args')
  Map<String, String>? get args {
    final value = _args;
    if (value == null) return null;
    if (_args is EqualUnmodifiableMapView) return _args;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'ImpactsConnectivity')
  final bool? impactsConnectivity;
  final List<String>? _dependsOn;
  @override
  @JsonKey(name: 'DependsOn')
  List<String>? get dependsOn {
    final value = _dependsOn;
    if (value == null) return null;
    if (_dependsOn is EqualUnmodifiableListView) return _dependsOn;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'UnhealthyState(warnableCode: $warnableCode, severity: $severity, title: $title, text: $text, brokenSince: $brokenSince, args: $args, impactsConnectivity: $impactsConnectivity, dependsOn: $dependsOn)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnhealthyStateImpl &&
            (identical(other.warnableCode, warnableCode) ||
                other.warnableCode == warnableCode) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.brokenSince, brokenSince) ||
                other.brokenSince == brokenSince) &&
            const DeepCollectionEquality().equals(other._args, _args) &&
            (identical(other.impactsConnectivity, impactsConnectivity) ||
                other.impactsConnectivity == impactsConnectivity) &&
            const DeepCollectionEquality()
                .equals(other._dependsOn, _dependsOn));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      warnableCode,
      severity,
      title,
      text,
      brokenSince,
      const DeepCollectionEquality().hash(_args),
      impactsConnectivity,
      const DeepCollectionEquality().hash(_dependsOn));

  /// Create a copy of UnhealthyState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnhealthyStateImplCopyWith<_$UnhealthyStateImpl> get copyWith =>
      __$$UnhealthyStateImplCopyWithImpl<_$UnhealthyStateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UnhealthyStateImplToJson(
      this,
    );
  }
}

abstract class _UnhealthyState extends UnhealthyState {
  const factory _UnhealthyState(
          {@JsonKey(name: 'WarnableCode') required final String warnableCode,
          @JsonKey(name: 'Severity') required final Severity severity,
          @JsonKey(name: 'Title') required final String title,
          @JsonKey(name: 'Text') required final String text,
          @JsonKey(name: 'BrokenSince') final String? brokenSince,
          @JsonKey(name: 'Args') final Map<String, String>? args,
          @JsonKey(name: 'ImpactsConnectivity') final bool? impactsConnectivity,
          @JsonKey(name: 'DependsOn') final List<String>? dependsOn}) =
      _$UnhealthyStateImpl;
  const _UnhealthyState._() : super._();

  factory _UnhealthyState.fromJson(Map<String, dynamic> json) =
      _$UnhealthyStateImpl.fromJson;

  @override
  @JsonKey(name: 'WarnableCode')
  String get warnableCode;
  @override
  @JsonKey(name: 'Severity')
  Severity get severity;
  @override
  @JsonKey(name: 'Title')
  String get title;
  @override
  @JsonKey(name: 'Text')
  String get text;
  @override
  @JsonKey(name: 'BrokenSince')
  String? get brokenSince;
  @override
  @JsonKey(name: 'Args')
  Map<String, String>? get args;
  @override
  @JsonKey(name: 'ImpactsConnectivity')
  bool? get impactsConnectivity;
  @override
  @JsonKey(name: 'DependsOn')
  List<String>? get dependsOn;

  /// Create a copy of UnhealthyState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnhealthyStateImplCopyWith<_$UnhealthyStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

IpnPrefs _$IpnPrefsFromJson(Map<String, dynamic> json) {
  return _IpnPrefs.fromJson(json);
}

/// @nodoc
mixin _$IpnPrefs {
  @JsonKey(name: 'ControlURL')
  String get controlURL => throw _privateConstructorUsedError;
  @JsonKey(name: 'RouteAll')
  bool get routeAll => throw _privateConstructorUsedError;
  @JsonKey(name: 'AllowsSingleHosts')
  bool get allowsSingleHosts => throw _privateConstructorUsedError;
  @JsonKey(name: 'CorpDNS')
  bool get corpDNS => throw _privateConstructorUsedError;
  @JsonKey(name: 'WantRunning')
  bool get wantRunning => throw _privateConstructorUsedError;
  @JsonKey(name: 'LoggedOut')
  bool get loggedOut => throw _privateConstructorUsedError;
  @JsonKey(name: 'ShieldsUp')
  bool get shieldsUp => throw _privateConstructorUsedError;
  @JsonKey(name: 'AdvertiseRoutes')
  List<String>? get advertiseRoutes => throw _privateConstructorUsedError;
  @JsonKey(name: 'AdvertiseTags')
  List<String>? get advertiseTags => throw _privateConstructorUsedError;
  @JsonKey(name: 'ExitNodeID')
  String? get exitNodeID => throw _privateConstructorUsedError;
  @JsonKey(name: 'ExitNodeAllowLANAccess')
  bool get exitNodeAllowLANAccess => throw _privateConstructorUsedError;
  @JsonKey(name: 'Config')
  PersistConfig? get config => throw _privateConstructorUsedError;
  @JsonKey(name: 'ForceDaemon')
  bool get forceDaemon => throw _privateConstructorUsedError;
  @JsonKey(name: 'HostName')
  String get hostName => throw _privateConstructorUsedError;
  @JsonKey(name: 'AutoUpdate')
  AutoUpdatePrefs? get autoUpdate => throw _privateConstructorUsedError;
  @JsonKey(name: 'InternalExitNodePrior')
  String? get internalExitNodePrior => throw _privateConstructorUsedError;

  /// Serializes this IpnPrefs to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IpnPrefs
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IpnPrefsCopyWith<IpnPrefs> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IpnPrefsCopyWith<$Res> {
  factory $IpnPrefsCopyWith(IpnPrefs value, $Res Function(IpnPrefs) then) =
      _$IpnPrefsCopyWithImpl<$Res, IpnPrefs>;
  @useResult
  $Res call(
      {@JsonKey(name: 'ControlURL') String controlURL,
      @JsonKey(name: 'RouteAll') bool routeAll,
      @JsonKey(name: 'AllowsSingleHosts') bool allowsSingleHosts,
      @JsonKey(name: 'CorpDNS') bool corpDNS,
      @JsonKey(name: 'WantRunning') bool wantRunning,
      @JsonKey(name: 'LoggedOut') bool loggedOut,
      @JsonKey(name: 'ShieldsUp') bool shieldsUp,
      @JsonKey(name: 'AdvertiseRoutes') List<String>? advertiseRoutes,
      @JsonKey(name: 'AdvertiseTags') List<String>? advertiseTags,
      @JsonKey(name: 'ExitNodeID') String? exitNodeID,
      @JsonKey(name: 'ExitNodeAllowLANAccess') bool exitNodeAllowLANAccess,
      @JsonKey(name: 'Config') PersistConfig? config,
      @JsonKey(name: 'ForceDaemon') bool forceDaemon,
      @JsonKey(name: 'HostName') String hostName,
      @JsonKey(name: 'AutoUpdate') AutoUpdatePrefs? autoUpdate,
      @JsonKey(name: 'InternalExitNodePrior') String? internalExitNodePrior});

  $PersistConfigCopyWith<$Res>? get config;
  $AutoUpdatePrefsCopyWith<$Res>? get autoUpdate;
}

/// @nodoc
class _$IpnPrefsCopyWithImpl<$Res, $Val extends IpnPrefs>
    implements $IpnPrefsCopyWith<$Res> {
  _$IpnPrefsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IpnPrefs
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? controlURL = null,
    Object? routeAll = null,
    Object? allowsSingleHosts = null,
    Object? corpDNS = null,
    Object? wantRunning = null,
    Object? loggedOut = null,
    Object? shieldsUp = null,
    Object? advertiseRoutes = freezed,
    Object? advertiseTags = freezed,
    Object? exitNodeID = freezed,
    Object? exitNodeAllowLANAccess = null,
    Object? config = freezed,
    Object? forceDaemon = null,
    Object? hostName = null,
    Object? autoUpdate = freezed,
    Object? internalExitNodePrior = freezed,
  }) {
    return _then(_value.copyWith(
      controlURL: null == controlURL
          ? _value.controlURL
          : controlURL // ignore: cast_nullable_to_non_nullable
              as String,
      routeAll: null == routeAll
          ? _value.routeAll
          : routeAll // ignore: cast_nullable_to_non_nullable
              as bool,
      allowsSingleHosts: null == allowsSingleHosts
          ? _value.allowsSingleHosts
          : allowsSingleHosts // ignore: cast_nullable_to_non_nullable
              as bool,
      corpDNS: null == corpDNS
          ? _value.corpDNS
          : corpDNS // ignore: cast_nullable_to_non_nullable
              as bool,
      wantRunning: null == wantRunning
          ? _value.wantRunning
          : wantRunning // ignore: cast_nullable_to_non_nullable
              as bool,
      loggedOut: null == loggedOut
          ? _value.loggedOut
          : loggedOut // ignore: cast_nullable_to_non_nullable
              as bool,
      shieldsUp: null == shieldsUp
          ? _value.shieldsUp
          : shieldsUp // ignore: cast_nullable_to_non_nullable
              as bool,
      advertiseRoutes: freezed == advertiseRoutes
          ? _value.advertiseRoutes
          : advertiseRoutes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      advertiseTags: freezed == advertiseTags
          ? _value.advertiseTags
          : advertiseTags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      exitNodeID: freezed == exitNodeID
          ? _value.exitNodeID
          : exitNodeID // ignore: cast_nullable_to_non_nullable
              as String?,
      exitNodeAllowLANAccess: null == exitNodeAllowLANAccess
          ? _value.exitNodeAllowLANAccess
          : exitNodeAllowLANAccess // ignore: cast_nullable_to_non_nullable
              as bool,
      config: freezed == config
          ? _value.config
          : config // ignore: cast_nullable_to_non_nullable
              as PersistConfig?,
      forceDaemon: null == forceDaemon
          ? _value.forceDaemon
          : forceDaemon // ignore: cast_nullable_to_non_nullable
              as bool,
      hostName: null == hostName
          ? _value.hostName
          : hostName // ignore: cast_nullable_to_non_nullable
              as String,
      autoUpdate: freezed == autoUpdate
          ? _value.autoUpdate
          : autoUpdate // ignore: cast_nullable_to_non_nullable
              as AutoUpdatePrefs?,
      internalExitNodePrior: freezed == internalExitNodePrior
          ? _value.internalExitNodePrior
          : internalExitNodePrior // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of IpnPrefs
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PersistConfigCopyWith<$Res>? get config {
    if (_value.config == null) {
      return null;
    }

    return $PersistConfigCopyWith<$Res>(_value.config!, (value) {
      return _then(_value.copyWith(config: value) as $Val);
    });
  }

  /// Create a copy of IpnPrefs
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AutoUpdatePrefsCopyWith<$Res>? get autoUpdate {
    if (_value.autoUpdate == null) {
      return null;
    }

    return $AutoUpdatePrefsCopyWith<$Res>(_value.autoUpdate!, (value) {
      return _then(_value.copyWith(autoUpdate: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$IpnPrefsImplCopyWith<$Res>
    implements $IpnPrefsCopyWith<$Res> {
  factory _$$IpnPrefsImplCopyWith(
          _$IpnPrefsImpl value, $Res Function(_$IpnPrefsImpl) then) =
      __$$IpnPrefsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'ControlURL') String controlURL,
      @JsonKey(name: 'RouteAll') bool routeAll,
      @JsonKey(name: 'AllowsSingleHosts') bool allowsSingleHosts,
      @JsonKey(name: 'CorpDNS') bool corpDNS,
      @JsonKey(name: 'WantRunning') bool wantRunning,
      @JsonKey(name: 'LoggedOut') bool loggedOut,
      @JsonKey(name: 'ShieldsUp') bool shieldsUp,
      @JsonKey(name: 'AdvertiseRoutes') List<String>? advertiseRoutes,
      @JsonKey(name: 'AdvertiseTags') List<String>? advertiseTags,
      @JsonKey(name: 'ExitNodeID') String? exitNodeID,
      @JsonKey(name: 'ExitNodeAllowLANAccess') bool exitNodeAllowLANAccess,
      @JsonKey(name: 'Config') PersistConfig? config,
      @JsonKey(name: 'ForceDaemon') bool forceDaemon,
      @JsonKey(name: 'HostName') String hostName,
      @JsonKey(name: 'AutoUpdate') AutoUpdatePrefs? autoUpdate,
      @JsonKey(name: 'InternalExitNodePrior') String? internalExitNodePrior});

  @override
  $PersistConfigCopyWith<$Res>? get config;
  @override
  $AutoUpdatePrefsCopyWith<$Res>? get autoUpdate;
}

/// @nodoc
class __$$IpnPrefsImplCopyWithImpl<$Res>
    extends _$IpnPrefsCopyWithImpl<$Res, _$IpnPrefsImpl>
    implements _$$IpnPrefsImplCopyWith<$Res> {
  __$$IpnPrefsImplCopyWithImpl(
      _$IpnPrefsImpl _value, $Res Function(_$IpnPrefsImpl) _then)
      : super(_value, _then);

  /// Create a copy of IpnPrefs
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? controlURL = null,
    Object? routeAll = null,
    Object? allowsSingleHosts = null,
    Object? corpDNS = null,
    Object? wantRunning = null,
    Object? loggedOut = null,
    Object? shieldsUp = null,
    Object? advertiseRoutes = freezed,
    Object? advertiseTags = freezed,
    Object? exitNodeID = freezed,
    Object? exitNodeAllowLANAccess = null,
    Object? config = freezed,
    Object? forceDaemon = null,
    Object? hostName = null,
    Object? autoUpdate = freezed,
    Object? internalExitNodePrior = freezed,
  }) {
    return _then(_$IpnPrefsImpl(
      controlURL: null == controlURL
          ? _value.controlURL
          : controlURL // ignore: cast_nullable_to_non_nullable
              as String,
      routeAll: null == routeAll
          ? _value.routeAll
          : routeAll // ignore: cast_nullable_to_non_nullable
              as bool,
      allowsSingleHosts: null == allowsSingleHosts
          ? _value.allowsSingleHosts
          : allowsSingleHosts // ignore: cast_nullable_to_non_nullable
              as bool,
      corpDNS: null == corpDNS
          ? _value.corpDNS
          : corpDNS // ignore: cast_nullable_to_non_nullable
              as bool,
      wantRunning: null == wantRunning
          ? _value.wantRunning
          : wantRunning // ignore: cast_nullable_to_non_nullable
              as bool,
      loggedOut: null == loggedOut
          ? _value.loggedOut
          : loggedOut // ignore: cast_nullable_to_non_nullable
              as bool,
      shieldsUp: null == shieldsUp
          ? _value.shieldsUp
          : shieldsUp // ignore: cast_nullable_to_non_nullable
              as bool,
      advertiseRoutes: freezed == advertiseRoutes
          ? _value._advertiseRoutes
          : advertiseRoutes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      advertiseTags: freezed == advertiseTags
          ? _value._advertiseTags
          : advertiseTags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      exitNodeID: freezed == exitNodeID
          ? _value.exitNodeID
          : exitNodeID // ignore: cast_nullable_to_non_nullable
              as String?,
      exitNodeAllowLANAccess: null == exitNodeAllowLANAccess
          ? _value.exitNodeAllowLANAccess
          : exitNodeAllowLANAccess // ignore: cast_nullable_to_non_nullable
              as bool,
      config: freezed == config
          ? _value.config
          : config // ignore: cast_nullable_to_non_nullable
              as PersistConfig?,
      forceDaemon: null == forceDaemon
          ? _value.forceDaemon
          : forceDaemon // ignore: cast_nullable_to_non_nullable
              as bool,
      hostName: null == hostName
          ? _value.hostName
          : hostName // ignore: cast_nullable_to_non_nullable
              as String,
      autoUpdate: freezed == autoUpdate
          ? _value.autoUpdate
          : autoUpdate // ignore: cast_nullable_to_non_nullable
              as AutoUpdatePrefs?,
      internalExitNodePrior: freezed == internalExitNodePrior
          ? _value.internalExitNodePrior
          : internalExitNodePrior // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$IpnPrefsImpl extends _IpnPrefs {
  const _$IpnPrefsImpl(
      {@JsonKey(name: 'ControlURL') this.controlURL = '',
      @JsonKey(name: 'RouteAll') this.routeAll = false,
      @JsonKey(name: 'AllowsSingleHosts') this.allowsSingleHosts = false,
      @JsonKey(name: 'CorpDNS') this.corpDNS = false,
      @JsonKey(name: 'WantRunning') this.wantRunning = false,
      @JsonKey(name: 'LoggedOut') this.loggedOut = false,
      @JsonKey(name: 'ShieldsUp') this.shieldsUp = false,
      @JsonKey(name: 'AdvertiseRoutes') final List<String>? advertiseRoutes,
      @JsonKey(name: 'AdvertiseTags') final List<String>? advertiseTags,
      @JsonKey(name: 'ExitNodeID') this.exitNodeID,
      @JsonKey(name: 'ExitNodeAllowLANAccess')
      this.exitNodeAllowLANAccess = false,
      @JsonKey(name: 'Config') this.config,
      @JsonKey(name: 'ForceDaemon') this.forceDaemon = false,
      @JsonKey(name: 'HostName') this.hostName = '',
      @JsonKey(name: 'AutoUpdate') this.autoUpdate,
      @JsonKey(name: 'InternalExitNodePrior') this.internalExitNodePrior})
      : _advertiseRoutes = advertiseRoutes,
        _advertiseTags = advertiseTags,
        super._();

  factory _$IpnPrefsImpl.fromJson(Map<String, dynamic> json) =>
      _$$IpnPrefsImplFromJson(json);

  @override
  @JsonKey(name: 'ControlURL')
  final String controlURL;
  @override
  @JsonKey(name: 'RouteAll')
  final bool routeAll;
  @override
  @JsonKey(name: 'AllowsSingleHosts')
  final bool allowsSingleHosts;
  @override
  @JsonKey(name: 'CorpDNS')
  final bool corpDNS;
  @override
  @JsonKey(name: 'WantRunning')
  final bool wantRunning;
  @override
  @JsonKey(name: 'LoggedOut')
  final bool loggedOut;
  @override
  @JsonKey(name: 'ShieldsUp')
  final bool shieldsUp;
  final List<String>? _advertiseRoutes;
  @override
  @JsonKey(name: 'AdvertiseRoutes')
  List<String>? get advertiseRoutes {
    final value = _advertiseRoutes;
    if (value == null) return null;
    if (_advertiseRoutes is EqualUnmodifiableListView) return _advertiseRoutes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _advertiseTags;
  @override
  @JsonKey(name: 'AdvertiseTags')
  List<String>? get advertiseTags {
    final value = _advertiseTags;
    if (value == null) return null;
    if (_advertiseTags is EqualUnmodifiableListView) return _advertiseTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'ExitNodeID')
  final String? exitNodeID;
  @override
  @JsonKey(name: 'ExitNodeAllowLANAccess')
  final bool exitNodeAllowLANAccess;
  @override
  @JsonKey(name: 'Config')
  final PersistConfig? config;
  @override
  @JsonKey(name: 'ForceDaemon')
  final bool forceDaemon;
  @override
  @JsonKey(name: 'HostName')
  final String hostName;
  @override
  @JsonKey(name: 'AutoUpdate')
  final AutoUpdatePrefs? autoUpdate;
  @override
  @JsonKey(name: 'InternalExitNodePrior')
  final String? internalExitNodePrior;

  @override
  String toString() {
    return 'IpnPrefs(controlURL: $controlURL, routeAll: $routeAll, allowsSingleHosts: $allowsSingleHosts, corpDNS: $corpDNS, wantRunning: $wantRunning, loggedOut: $loggedOut, shieldsUp: $shieldsUp, advertiseRoutes: $advertiseRoutes, advertiseTags: $advertiseTags, exitNodeID: $exitNodeID, exitNodeAllowLANAccess: $exitNodeAllowLANAccess, config: $config, forceDaemon: $forceDaemon, hostName: $hostName, autoUpdate: $autoUpdate, internalExitNodePrior: $internalExitNodePrior)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IpnPrefsImpl &&
            (identical(other.controlURL, controlURL) ||
                other.controlURL == controlURL) &&
            (identical(other.routeAll, routeAll) ||
                other.routeAll == routeAll) &&
            (identical(other.allowsSingleHosts, allowsSingleHosts) ||
                other.allowsSingleHosts == allowsSingleHosts) &&
            (identical(other.corpDNS, corpDNS) || other.corpDNS == corpDNS) &&
            (identical(other.wantRunning, wantRunning) ||
                other.wantRunning == wantRunning) &&
            (identical(other.loggedOut, loggedOut) ||
                other.loggedOut == loggedOut) &&
            (identical(other.shieldsUp, shieldsUp) ||
                other.shieldsUp == shieldsUp) &&
            const DeepCollectionEquality()
                .equals(other._advertiseRoutes, _advertiseRoutes) &&
            const DeepCollectionEquality()
                .equals(other._advertiseTags, _advertiseTags) &&
            (identical(other.exitNodeID, exitNodeID) ||
                other.exitNodeID == exitNodeID) &&
            (identical(other.exitNodeAllowLANAccess, exitNodeAllowLANAccess) ||
                other.exitNodeAllowLANAccess == exitNodeAllowLANAccess) &&
            (identical(other.config, config) || other.config == config) &&
            (identical(other.forceDaemon, forceDaemon) ||
                other.forceDaemon == forceDaemon) &&
            (identical(other.hostName, hostName) ||
                other.hostName == hostName) &&
            (identical(other.autoUpdate, autoUpdate) ||
                other.autoUpdate == autoUpdate) &&
            (identical(other.internalExitNodePrior, internalExitNodePrior) ||
                other.internalExitNodePrior == internalExitNodePrior));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      controlURL,
      routeAll,
      allowsSingleHosts,
      corpDNS,
      wantRunning,
      loggedOut,
      shieldsUp,
      const DeepCollectionEquality().hash(_advertiseRoutes),
      const DeepCollectionEquality().hash(_advertiseTags),
      exitNodeID,
      exitNodeAllowLANAccess,
      config,
      forceDaemon,
      hostName,
      autoUpdate,
      internalExitNodePrior);

  /// Create a copy of IpnPrefs
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IpnPrefsImplCopyWith<_$IpnPrefsImpl> get copyWith =>
      __$$IpnPrefsImplCopyWithImpl<_$IpnPrefsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IpnPrefsImplToJson(
      this,
    );
  }
}

abstract class _IpnPrefs extends IpnPrefs {
  const factory _IpnPrefs(
      {@JsonKey(name: 'ControlURL') final String controlURL,
      @JsonKey(name: 'RouteAll') final bool routeAll,
      @JsonKey(name: 'AllowsSingleHosts') final bool allowsSingleHosts,
      @JsonKey(name: 'CorpDNS') final bool corpDNS,
      @JsonKey(name: 'WantRunning') final bool wantRunning,
      @JsonKey(name: 'LoggedOut') final bool loggedOut,
      @JsonKey(name: 'ShieldsUp') final bool shieldsUp,
      @JsonKey(name: 'AdvertiseRoutes') final List<String>? advertiseRoutes,
      @JsonKey(name: 'AdvertiseTags') final List<String>? advertiseTags,
      @JsonKey(name: 'ExitNodeID') final String? exitNodeID,
      @JsonKey(name: 'ExitNodeAllowLANAccess')
      final bool exitNodeAllowLANAccess,
      @JsonKey(name: 'Config') final PersistConfig? config,
      @JsonKey(name: 'ForceDaemon') final bool forceDaemon,
      @JsonKey(name: 'HostName') final String hostName,
      @JsonKey(name: 'AutoUpdate') final AutoUpdatePrefs? autoUpdate,
      @JsonKey(name: 'InternalExitNodePrior')
      final String? internalExitNodePrior}) = _$IpnPrefsImpl;
  const _IpnPrefs._() : super._();

  factory _IpnPrefs.fromJson(Map<String, dynamic> json) =
      _$IpnPrefsImpl.fromJson;

  @override
  @JsonKey(name: 'ControlURL')
  String get controlURL;
  @override
  @JsonKey(name: 'RouteAll')
  bool get routeAll;
  @override
  @JsonKey(name: 'AllowsSingleHosts')
  bool get allowsSingleHosts;
  @override
  @JsonKey(name: 'CorpDNS')
  bool get corpDNS;
  @override
  @JsonKey(name: 'WantRunning')
  bool get wantRunning;
  @override
  @JsonKey(name: 'LoggedOut')
  bool get loggedOut;
  @override
  @JsonKey(name: 'ShieldsUp')
  bool get shieldsUp;
  @override
  @JsonKey(name: 'AdvertiseRoutes')
  List<String>? get advertiseRoutes;
  @override
  @JsonKey(name: 'AdvertiseTags')
  List<String>? get advertiseTags;
  @override
  @JsonKey(name: 'ExitNodeID')
  String? get exitNodeID;
  @override
  @JsonKey(name: 'ExitNodeAllowLANAccess')
  bool get exitNodeAllowLANAccess;
  @override
  @JsonKey(name: 'Config')
  PersistConfig? get config;
  @override
  @JsonKey(name: 'ForceDaemon')
  bool get forceDaemon;
  @override
  @JsonKey(name: 'HostName')
  String get hostName;
  @override
  @JsonKey(name: 'AutoUpdate')
  AutoUpdatePrefs? get autoUpdate;
  @override
  @JsonKey(name: 'InternalExitNodePrior')
  String? get internalExitNodePrior;

  /// Create a copy of IpnPrefs
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IpnPrefsImplCopyWith<_$IpnPrefsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

IpnOptions _$IpnOptionsFromJson(Map<String, dynamic> json) {
  return _IpnOptions.fromJson(json);
}

/// @nodoc
mixin _$IpnOptions {
  @JsonKey(name: 'FrontendLogID')
  String? get frontendLogID => throw _privateConstructorUsedError;
  @JsonKey(name: 'UpdatePrefs')
  IpnPrefs? get updatePrefs => throw _privateConstructorUsedError;
  @JsonKey(name: 'AuthKey')
  String? get authKey => throw _privateConstructorUsedError;

  /// Serializes this IpnOptions to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IpnOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IpnOptionsCopyWith<IpnOptions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IpnOptionsCopyWith<$Res> {
  factory $IpnOptionsCopyWith(
          IpnOptions value, $Res Function(IpnOptions) then) =
      _$IpnOptionsCopyWithImpl<$Res, IpnOptions>;
  @useResult
  $Res call(
      {@JsonKey(name: 'FrontendLogID') String? frontendLogID,
      @JsonKey(name: 'UpdatePrefs') IpnPrefs? updatePrefs,
      @JsonKey(name: 'AuthKey') String? authKey});

  $IpnPrefsCopyWith<$Res>? get updatePrefs;
}

/// @nodoc
class _$IpnOptionsCopyWithImpl<$Res, $Val extends IpnOptions>
    implements $IpnOptionsCopyWith<$Res> {
  _$IpnOptionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IpnOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frontendLogID = freezed,
    Object? updatePrefs = freezed,
    Object? authKey = freezed,
  }) {
    return _then(_value.copyWith(
      frontendLogID: freezed == frontendLogID
          ? _value.frontendLogID
          : frontendLogID // ignore: cast_nullable_to_non_nullable
              as String?,
      updatePrefs: freezed == updatePrefs
          ? _value.updatePrefs
          : updatePrefs // ignore: cast_nullable_to_non_nullable
              as IpnPrefs?,
      authKey: freezed == authKey
          ? _value.authKey
          : authKey // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of IpnOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $IpnPrefsCopyWith<$Res>? get updatePrefs {
    if (_value.updatePrefs == null) {
      return null;
    }

    return $IpnPrefsCopyWith<$Res>(_value.updatePrefs!, (value) {
      return _then(_value.copyWith(updatePrefs: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$IpnOptionsImplCopyWith<$Res>
    implements $IpnOptionsCopyWith<$Res> {
  factory _$$IpnOptionsImplCopyWith(
          _$IpnOptionsImpl value, $Res Function(_$IpnOptionsImpl) then) =
      __$$IpnOptionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'FrontendLogID') String? frontendLogID,
      @JsonKey(name: 'UpdatePrefs') IpnPrefs? updatePrefs,
      @JsonKey(name: 'AuthKey') String? authKey});

  @override
  $IpnPrefsCopyWith<$Res>? get updatePrefs;
}

/// @nodoc
class __$$IpnOptionsImplCopyWithImpl<$Res>
    extends _$IpnOptionsCopyWithImpl<$Res, _$IpnOptionsImpl>
    implements _$$IpnOptionsImplCopyWith<$Res> {
  __$$IpnOptionsImplCopyWithImpl(
      _$IpnOptionsImpl _value, $Res Function(_$IpnOptionsImpl) _then)
      : super(_value, _then);

  /// Create a copy of IpnOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frontendLogID = freezed,
    Object? updatePrefs = freezed,
    Object? authKey = freezed,
  }) {
    return _then(_$IpnOptionsImpl(
      frontendLogID: freezed == frontendLogID
          ? _value.frontendLogID
          : frontendLogID // ignore: cast_nullable_to_non_nullable
              as String?,
      updatePrefs: freezed == updatePrefs
          ? _value.updatePrefs
          : updatePrefs // ignore: cast_nullable_to_non_nullable
              as IpnPrefs?,
      authKey: freezed == authKey
          ? _value.authKey
          : authKey // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$IpnOptionsImpl implements _IpnOptions {
  const _$IpnOptionsImpl(
      {@JsonKey(name: 'FrontendLogID') this.frontendLogID,
      @JsonKey(name: 'UpdatePrefs') this.updatePrefs,
      @JsonKey(name: 'AuthKey') this.authKey});

  factory _$IpnOptionsImpl.fromJson(Map<String, dynamic> json) =>
      _$$IpnOptionsImplFromJson(json);

  @override
  @JsonKey(name: 'FrontendLogID')
  final String? frontendLogID;
  @override
  @JsonKey(name: 'UpdatePrefs')
  final IpnPrefs? updatePrefs;
  @override
  @JsonKey(name: 'AuthKey')
  final String? authKey;

  @override
  String toString() {
    return 'IpnOptions(frontendLogID: $frontendLogID, updatePrefs: $updatePrefs, authKey: $authKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IpnOptionsImpl &&
            (identical(other.frontendLogID, frontendLogID) ||
                other.frontendLogID == frontendLogID) &&
            (identical(other.updatePrefs, updatePrefs) ||
                other.updatePrefs == updatePrefs) &&
            (identical(other.authKey, authKey) || other.authKey == authKey));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, frontendLogID, updatePrefs, authKey);

  /// Create a copy of IpnOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IpnOptionsImplCopyWith<_$IpnOptionsImpl> get copyWith =>
      __$$IpnOptionsImplCopyWithImpl<_$IpnOptionsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IpnOptionsImplToJson(
      this,
    );
  }
}

abstract class _IpnOptions implements IpnOptions {
  const factory _IpnOptions(
      {@JsonKey(name: 'FrontendLogID') final String? frontendLogID,
      @JsonKey(name: 'UpdatePrefs') final IpnPrefs? updatePrefs,
      @JsonKey(name: 'AuthKey') final String? authKey}) = _$IpnOptionsImpl;

  factory _IpnOptions.fromJson(Map<String, dynamic> json) =
      _$IpnOptionsImpl.fromJson;

  @override
  @JsonKey(name: 'FrontendLogID')
  String? get frontendLogID;
  @override
  @JsonKey(name: 'UpdatePrefs')
  IpnPrefs? get updatePrefs;
  @override
  @JsonKey(name: 'AuthKey')
  String? get authKey;

  /// Create a copy of IpnOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IpnOptionsImplCopyWith<_$IpnOptionsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MaskedPrefs _$MaskedPrefsFromJson(Map<String, dynamic> json) {
  return _MaskedPrefs.fromJson(json);
}

/// @nodoc
mixin _$MaskedPrefs {
  @JsonKey(name: 'ControlURLSet')
  bool? get controlURLSet => throw _privateConstructorUsedError;
  @JsonKey(name: 'RouteAllSet')
  bool? get routeAllSet => throw _privateConstructorUsedError;
  @JsonKey(name: 'CoprDNSSet')
  bool? get corpDNSSet => throw _privateConstructorUsedError;
  @JsonKey(name: 'ExitNodeIDSet')
  bool? get exitNodeIDSet => throw _privateConstructorUsedError;
  @JsonKey(name: 'ExitNodeAllowLANAccessSet')
  bool? get exitNodeAllowLANAccessSet => throw _privateConstructorUsedError;
  @JsonKey(name: 'WantRunningSet')
  bool? get wantRunningSet => throw _privateConstructorUsedError;
  @JsonKey(name: 'ShieldsUpSet')
  bool? get shieldsUpSet => throw _privateConstructorUsedError;
  @JsonKey(name: 'AdvertiseRoutesSet')
  bool? get advertiseRoutesSet => throw _privateConstructorUsedError;
  @JsonKey(name: 'ForceDaemonSet')
  bool? get forceDaemonSet => throw _privateConstructorUsedError;
  @JsonKey(name: 'HostnameSet')
  bool? get hostnameSet => throw _privateConstructorUsedError;
  @JsonKey(name: 'InternalExitNodePriorSet')
  bool? get internalExitNodePriorSet => throw _privateConstructorUsedError;
  @JsonKey(name: 'ControlURL')
  String? get controlURL => throw _privateConstructorUsedError;
  @JsonKey(name: 'RouteAll')
  bool? get routeAll => throw _privateConstructorUsedError;
  @JsonKey(name: 'CorpDNS')
  bool? get corpDNS => throw _privateConstructorUsedError;
  @JsonKey(name: 'ExitNodeID')
  String? get exitNodeID => throw _privateConstructorUsedError;
  @JsonKey(name: 'InternalExitNodePrior')
  String? get internalExitNodePrior => throw _privateConstructorUsedError;
  @JsonKey(name: 'ExitNodeAllowLANAccess')
  bool? get exitNodeAllowLANAccess => throw _privateConstructorUsedError;
  @JsonKey(name: 'WantRunning')
  bool? get wantRunning => throw _privateConstructorUsedError;
  @JsonKey(name: 'ShieldsUp')
  bool? get shieldsUp => throw _privateConstructorUsedError;
  @JsonKey(name: 'AdvertiseRoutes')
  List<String>? get advertiseRoutes => throw _privateConstructorUsedError;
  @JsonKey(name: 'ForceDaemon')
  bool? get forceDaemon => throw _privateConstructorUsedError;
  @JsonKey(name: 'Hostname')
  String? get hostname => throw _privateConstructorUsedError;

  /// Serializes this MaskedPrefs to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MaskedPrefs
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MaskedPrefsCopyWith<MaskedPrefs> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MaskedPrefsCopyWith<$Res> {
  factory $MaskedPrefsCopyWith(
          MaskedPrefs value, $Res Function(MaskedPrefs) then) =
      _$MaskedPrefsCopyWithImpl<$Res, MaskedPrefs>;
  @useResult
  $Res call(
      {@JsonKey(name: 'ControlURLSet') bool? controlURLSet,
      @JsonKey(name: 'RouteAllSet') bool? routeAllSet,
      @JsonKey(name: 'CoprDNSSet') bool? corpDNSSet,
      @JsonKey(name: 'ExitNodeIDSet') bool? exitNodeIDSet,
      @JsonKey(name: 'ExitNodeAllowLANAccessSet')
      bool? exitNodeAllowLANAccessSet,
      @JsonKey(name: 'WantRunningSet') bool? wantRunningSet,
      @JsonKey(name: 'ShieldsUpSet') bool? shieldsUpSet,
      @JsonKey(name: 'AdvertiseRoutesSet') bool? advertiseRoutesSet,
      @JsonKey(name: 'ForceDaemonSet') bool? forceDaemonSet,
      @JsonKey(name: 'HostnameSet') bool? hostnameSet,
      @JsonKey(name: 'InternalExitNodePriorSet') bool? internalExitNodePriorSet,
      @JsonKey(name: 'ControlURL') String? controlURL,
      @JsonKey(name: 'RouteAll') bool? routeAll,
      @JsonKey(name: 'CorpDNS') bool? corpDNS,
      @JsonKey(name: 'ExitNodeID') String? exitNodeID,
      @JsonKey(name: 'InternalExitNodePrior') String? internalExitNodePrior,
      @JsonKey(name: 'ExitNodeAllowLANAccess') bool? exitNodeAllowLANAccess,
      @JsonKey(name: 'WantRunning') bool? wantRunning,
      @JsonKey(name: 'ShieldsUp') bool? shieldsUp,
      @JsonKey(name: 'AdvertiseRoutes') List<String>? advertiseRoutes,
      @JsonKey(name: 'ForceDaemon') bool? forceDaemon,
      @JsonKey(name: 'Hostname') String? hostname});
}

/// @nodoc
class _$MaskedPrefsCopyWithImpl<$Res, $Val extends MaskedPrefs>
    implements $MaskedPrefsCopyWith<$Res> {
  _$MaskedPrefsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MaskedPrefs
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? controlURLSet = freezed,
    Object? routeAllSet = freezed,
    Object? corpDNSSet = freezed,
    Object? exitNodeIDSet = freezed,
    Object? exitNodeAllowLANAccessSet = freezed,
    Object? wantRunningSet = freezed,
    Object? shieldsUpSet = freezed,
    Object? advertiseRoutesSet = freezed,
    Object? forceDaemonSet = freezed,
    Object? hostnameSet = freezed,
    Object? internalExitNodePriorSet = freezed,
    Object? controlURL = freezed,
    Object? routeAll = freezed,
    Object? corpDNS = freezed,
    Object? exitNodeID = freezed,
    Object? internalExitNodePrior = freezed,
    Object? exitNodeAllowLANAccess = freezed,
    Object? wantRunning = freezed,
    Object? shieldsUp = freezed,
    Object? advertiseRoutes = freezed,
    Object? forceDaemon = freezed,
    Object? hostname = freezed,
  }) {
    return _then(_value.copyWith(
      controlURLSet: freezed == controlURLSet
          ? _value.controlURLSet
          : controlURLSet // ignore: cast_nullable_to_non_nullable
              as bool?,
      routeAllSet: freezed == routeAllSet
          ? _value.routeAllSet
          : routeAllSet // ignore: cast_nullable_to_non_nullable
              as bool?,
      corpDNSSet: freezed == corpDNSSet
          ? _value.corpDNSSet
          : corpDNSSet // ignore: cast_nullable_to_non_nullable
              as bool?,
      exitNodeIDSet: freezed == exitNodeIDSet
          ? _value.exitNodeIDSet
          : exitNodeIDSet // ignore: cast_nullable_to_non_nullable
              as bool?,
      exitNodeAllowLANAccessSet: freezed == exitNodeAllowLANAccessSet
          ? _value.exitNodeAllowLANAccessSet
          : exitNodeAllowLANAccessSet // ignore: cast_nullable_to_non_nullable
              as bool?,
      wantRunningSet: freezed == wantRunningSet
          ? _value.wantRunningSet
          : wantRunningSet // ignore: cast_nullable_to_non_nullable
              as bool?,
      shieldsUpSet: freezed == shieldsUpSet
          ? _value.shieldsUpSet
          : shieldsUpSet // ignore: cast_nullable_to_non_nullable
              as bool?,
      advertiseRoutesSet: freezed == advertiseRoutesSet
          ? _value.advertiseRoutesSet
          : advertiseRoutesSet // ignore: cast_nullable_to_non_nullable
              as bool?,
      forceDaemonSet: freezed == forceDaemonSet
          ? _value.forceDaemonSet
          : forceDaemonSet // ignore: cast_nullable_to_non_nullable
              as bool?,
      hostnameSet: freezed == hostnameSet
          ? _value.hostnameSet
          : hostnameSet // ignore: cast_nullable_to_non_nullable
              as bool?,
      internalExitNodePriorSet: freezed == internalExitNodePriorSet
          ? _value.internalExitNodePriorSet
          : internalExitNodePriorSet // ignore: cast_nullable_to_non_nullable
              as bool?,
      controlURL: freezed == controlURL
          ? _value.controlURL
          : controlURL // ignore: cast_nullable_to_non_nullable
              as String?,
      routeAll: freezed == routeAll
          ? _value.routeAll
          : routeAll // ignore: cast_nullable_to_non_nullable
              as bool?,
      corpDNS: freezed == corpDNS
          ? _value.corpDNS
          : corpDNS // ignore: cast_nullable_to_non_nullable
              as bool?,
      exitNodeID: freezed == exitNodeID
          ? _value.exitNodeID
          : exitNodeID // ignore: cast_nullable_to_non_nullable
              as String?,
      internalExitNodePrior: freezed == internalExitNodePrior
          ? _value.internalExitNodePrior
          : internalExitNodePrior // ignore: cast_nullable_to_non_nullable
              as String?,
      exitNodeAllowLANAccess: freezed == exitNodeAllowLANAccess
          ? _value.exitNodeAllowLANAccess
          : exitNodeAllowLANAccess // ignore: cast_nullable_to_non_nullable
              as bool?,
      wantRunning: freezed == wantRunning
          ? _value.wantRunning
          : wantRunning // ignore: cast_nullable_to_non_nullable
              as bool?,
      shieldsUp: freezed == shieldsUp
          ? _value.shieldsUp
          : shieldsUp // ignore: cast_nullable_to_non_nullable
              as bool?,
      advertiseRoutes: freezed == advertiseRoutes
          ? _value.advertiseRoutes
          : advertiseRoutes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      forceDaemon: freezed == forceDaemon
          ? _value.forceDaemon
          : forceDaemon // ignore: cast_nullable_to_non_nullable
              as bool?,
      hostname: freezed == hostname
          ? _value.hostname
          : hostname // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MaskedPrefsImplCopyWith<$Res>
    implements $MaskedPrefsCopyWith<$Res> {
  factory _$$MaskedPrefsImplCopyWith(
          _$MaskedPrefsImpl value, $Res Function(_$MaskedPrefsImpl) then) =
      __$$MaskedPrefsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'ControlURLSet') bool? controlURLSet,
      @JsonKey(name: 'RouteAllSet') bool? routeAllSet,
      @JsonKey(name: 'CoprDNSSet') bool? corpDNSSet,
      @JsonKey(name: 'ExitNodeIDSet') bool? exitNodeIDSet,
      @JsonKey(name: 'ExitNodeAllowLANAccessSet')
      bool? exitNodeAllowLANAccessSet,
      @JsonKey(name: 'WantRunningSet') bool? wantRunningSet,
      @JsonKey(name: 'ShieldsUpSet') bool? shieldsUpSet,
      @JsonKey(name: 'AdvertiseRoutesSet') bool? advertiseRoutesSet,
      @JsonKey(name: 'ForceDaemonSet') bool? forceDaemonSet,
      @JsonKey(name: 'HostnameSet') bool? hostnameSet,
      @JsonKey(name: 'InternalExitNodePriorSet') bool? internalExitNodePriorSet,
      @JsonKey(name: 'ControlURL') String? controlURL,
      @JsonKey(name: 'RouteAll') bool? routeAll,
      @JsonKey(name: 'CorpDNS') bool? corpDNS,
      @JsonKey(name: 'ExitNodeID') String? exitNodeID,
      @JsonKey(name: 'InternalExitNodePrior') String? internalExitNodePrior,
      @JsonKey(name: 'ExitNodeAllowLANAccess') bool? exitNodeAllowLANAccess,
      @JsonKey(name: 'WantRunning') bool? wantRunning,
      @JsonKey(name: 'ShieldsUp') bool? shieldsUp,
      @JsonKey(name: 'AdvertiseRoutes') List<String>? advertiseRoutes,
      @JsonKey(name: 'ForceDaemon') bool? forceDaemon,
      @JsonKey(name: 'Hostname') String? hostname});
}

/// @nodoc
class __$$MaskedPrefsImplCopyWithImpl<$Res>
    extends _$MaskedPrefsCopyWithImpl<$Res, _$MaskedPrefsImpl>
    implements _$$MaskedPrefsImplCopyWith<$Res> {
  __$$MaskedPrefsImplCopyWithImpl(
      _$MaskedPrefsImpl _value, $Res Function(_$MaskedPrefsImpl) _then)
      : super(_value, _then);

  /// Create a copy of MaskedPrefs
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? controlURLSet = freezed,
    Object? routeAllSet = freezed,
    Object? corpDNSSet = freezed,
    Object? exitNodeIDSet = freezed,
    Object? exitNodeAllowLANAccessSet = freezed,
    Object? wantRunningSet = freezed,
    Object? shieldsUpSet = freezed,
    Object? advertiseRoutesSet = freezed,
    Object? forceDaemonSet = freezed,
    Object? hostnameSet = freezed,
    Object? internalExitNodePriorSet = freezed,
    Object? controlURL = freezed,
    Object? routeAll = freezed,
    Object? corpDNS = freezed,
    Object? exitNodeID = freezed,
    Object? internalExitNodePrior = freezed,
    Object? exitNodeAllowLANAccess = freezed,
    Object? wantRunning = freezed,
    Object? shieldsUp = freezed,
    Object? advertiseRoutes = freezed,
    Object? forceDaemon = freezed,
    Object? hostname = freezed,
  }) {
    return _then(_$MaskedPrefsImpl(
      controlURLSet: freezed == controlURLSet
          ? _value.controlURLSet
          : controlURLSet // ignore: cast_nullable_to_non_nullable
              as bool?,
      routeAllSet: freezed == routeAllSet
          ? _value.routeAllSet
          : routeAllSet // ignore: cast_nullable_to_non_nullable
              as bool?,
      corpDNSSet: freezed == corpDNSSet
          ? _value.corpDNSSet
          : corpDNSSet // ignore: cast_nullable_to_non_nullable
              as bool?,
      exitNodeIDSet: freezed == exitNodeIDSet
          ? _value.exitNodeIDSet
          : exitNodeIDSet // ignore: cast_nullable_to_non_nullable
              as bool?,
      exitNodeAllowLANAccessSet: freezed == exitNodeAllowLANAccessSet
          ? _value.exitNodeAllowLANAccessSet
          : exitNodeAllowLANAccessSet // ignore: cast_nullable_to_non_nullable
              as bool?,
      wantRunningSet: freezed == wantRunningSet
          ? _value.wantRunningSet
          : wantRunningSet // ignore: cast_nullable_to_non_nullable
              as bool?,
      shieldsUpSet: freezed == shieldsUpSet
          ? _value.shieldsUpSet
          : shieldsUpSet // ignore: cast_nullable_to_non_nullable
              as bool?,
      advertiseRoutesSet: freezed == advertiseRoutesSet
          ? _value.advertiseRoutesSet
          : advertiseRoutesSet // ignore: cast_nullable_to_non_nullable
              as bool?,
      forceDaemonSet: freezed == forceDaemonSet
          ? _value.forceDaemonSet
          : forceDaemonSet // ignore: cast_nullable_to_non_nullable
              as bool?,
      hostnameSet: freezed == hostnameSet
          ? _value.hostnameSet
          : hostnameSet // ignore: cast_nullable_to_non_nullable
              as bool?,
      internalExitNodePriorSet: freezed == internalExitNodePriorSet
          ? _value.internalExitNodePriorSet
          : internalExitNodePriorSet // ignore: cast_nullable_to_non_nullable
              as bool?,
      controlURL: freezed == controlURL
          ? _value.controlURL
          : controlURL // ignore: cast_nullable_to_non_nullable
              as String?,
      routeAll: freezed == routeAll
          ? _value.routeAll
          : routeAll // ignore: cast_nullable_to_non_nullable
              as bool?,
      corpDNS: freezed == corpDNS
          ? _value.corpDNS
          : corpDNS // ignore: cast_nullable_to_non_nullable
              as bool?,
      exitNodeID: freezed == exitNodeID
          ? _value.exitNodeID
          : exitNodeID // ignore: cast_nullable_to_non_nullable
              as String?,
      internalExitNodePrior: freezed == internalExitNodePrior
          ? _value.internalExitNodePrior
          : internalExitNodePrior // ignore: cast_nullable_to_non_nullable
              as String?,
      exitNodeAllowLANAccess: freezed == exitNodeAllowLANAccess
          ? _value.exitNodeAllowLANAccess
          : exitNodeAllowLANAccess // ignore: cast_nullable_to_non_nullable
              as bool?,
      wantRunning: freezed == wantRunning
          ? _value.wantRunning
          : wantRunning // ignore: cast_nullable_to_non_nullable
              as bool?,
      shieldsUp: freezed == shieldsUp
          ? _value.shieldsUp
          : shieldsUp // ignore: cast_nullable_to_non_nullable
              as bool?,
      advertiseRoutes: freezed == advertiseRoutes
          ? _value._advertiseRoutes
          : advertiseRoutes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      forceDaemon: freezed == forceDaemon
          ? _value.forceDaemon
          : forceDaemon // ignore: cast_nullable_to_non_nullable
              as bool?,
      hostname: freezed == hostname
          ? _value.hostname
          : hostname // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MaskedPrefsImpl extends _MaskedPrefs {
  const _$MaskedPrefsImpl(
      {@JsonKey(name: 'ControlURLSet') this.controlURLSet,
      @JsonKey(name: 'RouteAllSet') this.routeAllSet,
      @JsonKey(name: 'CoprDNSSet') this.corpDNSSet,
      @JsonKey(name: 'ExitNodeIDSet') this.exitNodeIDSet,
      @JsonKey(name: 'ExitNodeAllowLANAccessSet')
      this.exitNodeAllowLANAccessSet,
      @JsonKey(name: 'WantRunningSet') this.wantRunningSet,
      @JsonKey(name: 'ShieldsUpSet') this.shieldsUpSet,
      @JsonKey(name: 'AdvertiseRoutesSet') this.advertiseRoutesSet,
      @JsonKey(name: 'ForceDaemonSet') this.forceDaemonSet,
      @JsonKey(name: 'HostnameSet') this.hostnameSet,
      @JsonKey(name: 'InternalExitNodePriorSet') this.internalExitNodePriorSet,
      @JsonKey(name: 'ControlURL') this.controlURL,
      @JsonKey(name: 'RouteAll') this.routeAll,
      @JsonKey(name: 'CorpDNS') this.corpDNS,
      @JsonKey(name: 'ExitNodeID') this.exitNodeID,
      @JsonKey(name: 'InternalExitNodePrior') this.internalExitNodePrior,
      @JsonKey(name: 'ExitNodeAllowLANAccess') this.exitNodeAllowLANAccess,
      @JsonKey(name: 'WantRunning') this.wantRunning,
      @JsonKey(name: 'ShieldsUp') this.shieldsUp,
      @JsonKey(name: 'AdvertiseRoutes') final List<String>? advertiseRoutes,
      @JsonKey(name: 'ForceDaemon') this.forceDaemon,
      @JsonKey(name: 'Hostname') this.hostname})
      : _advertiseRoutes = advertiseRoutes,
        super._();

  factory _$MaskedPrefsImpl.fromJson(Map<String, dynamic> json) =>
      _$$MaskedPrefsImplFromJson(json);

  @override
  @JsonKey(name: 'ControlURLSet')
  final bool? controlURLSet;
  @override
  @JsonKey(name: 'RouteAllSet')
  final bool? routeAllSet;
  @override
  @JsonKey(name: 'CoprDNSSet')
  final bool? corpDNSSet;
  @override
  @JsonKey(name: 'ExitNodeIDSet')
  final bool? exitNodeIDSet;
  @override
  @JsonKey(name: 'ExitNodeAllowLANAccessSet')
  final bool? exitNodeAllowLANAccessSet;
  @override
  @JsonKey(name: 'WantRunningSet')
  final bool? wantRunningSet;
  @override
  @JsonKey(name: 'ShieldsUpSet')
  final bool? shieldsUpSet;
  @override
  @JsonKey(name: 'AdvertiseRoutesSet')
  final bool? advertiseRoutesSet;
  @override
  @JsonKey(name: 'ForceDaemonSet')
  final bool? forceDaemonSet;
  @override
  @JsonKey(name: 'HostnameSet')
  final bool? hostnameSet;
  @override
  @JsonKey(name: 'InternalExitNodePriorSet')
  final bool? internalExitNodePriorSet;
  @override
  @JsonKey(name: 'ControlURL')
  final String? controlURL;
  @override
  @JsonKey(name: 'RouteAll')
  final bool? routeAll;
  @override
  @JsonKey(name: 'CorpDNS')
  final bool? corpDNS;
  @override
  @JsonKey(name: 'ExitNodeID')
  final String? exitNodeID;
  @override
  @JsonKey(name: 'InternalExitNodePrior')
  final String? internalExitNodePrior;
  @override
  @JsonKey(name: 'ExitNodeAllowLANAccess')
  final bool? exitNodeAllowLANAccess;
  @override
  @JsonKey(name: 'WantRunning')
  final bool? wantRunning;
  @override
  @JsonKey(name: 'ShieldsUp')
  final bool? shieldsUp;
  final List<String>? _advertiseRoutes;
  @override
  @JsonKey(name: 'AdvertiseRoutes')
  List<String>? get advertiseRoutes {
    final value = _advertiseRoutes;
    if (value == null) return null;
    if (_advertiseRoutes is EqualUnmodifiableListView) return _advertiseRoutes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'ForceDaemon')
  final bool? forceDaemon;
  @override
  @JsonKey(name: 'Hostname')
  final String? hostname;

  @override
  String toString() {
    return 'MaskedPrefs(controlURLSet: $controlURLSet, routeAllSet: $routeAllSet, corpDNSSet: $corpDNSSet, exitNodeIDSet: $exitNodeIDSet, exitNodeAllowLANAccessSet: $exitNodeAllowLANAccessSet, wantRunningSet: $wantRunningSet, shieldsUpSet: $shieldsUpSet, advertiseRoutesSet: $advertiseRoutesSet, forceDaemonSet: $forceDaemonSet, hostnameSet: $hostnameSet, internalExitNodePriorSet: $internalExitNodePriorSet, controlURL: $controlURL, routeAll: $routeAll, corpDNS: $corpDNS, exitNodeID: $exitNodeID, internalExitNodePrior: $internalExitNodePrior, exitNodeAllowLANAccess: $exitNodeAllowLANAccess, wantRunning: $wantRunning, shieldsUp: $shieldsUp, advertiseRoutes: $advertiseRoutes, forceDaemon: $forceDaemon, hostname: $hostname)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MaskedPrefsImpl &&
            (identical(other.controlURLSet, controlURLSet) ||
                other.controlURLSet == controlURLSet) &&
            (identical(other.routeAllSet, routeAllSet) ||
                other.routeAllSet == routeAllSet) &&
            (identical(other.corpDNSSet, corpDNSSet) ||
                other.corpDNSSet == corpDNSSet) &&
            (identical(other.exitNodeIDSet, exitNodeIDSet) ||
                other.exitNodeIDSet == exitNodeIDSet) &&
            (identical(other.exitNodeAllowLANAccessSet,
                    exitNodeAllowLANAccessSet) ||
                other.exitNodeAllowLANAccessSet == exitNodeAllowLANAccessSet) &&
            (identical(other.wantRunningSet, wantRunningSet) ||
                other.wantRunningSet == wantRunningSet) &&
            (identical(other.shieldsUpSet, shieldsUpSet) ||
                other.shieldsUpSet == shieldsUpSet) &&
            (identical(other.advertiseRoutesSet, advertiseRoutesSet) ||
                other.advertiseRoutesSet == advertiseRoutesSet) &&
            (identical(other.forceDaemonSet, forceDaemonSet) ||
                other.forceDaemonSet == forceDaemonSet) &&
            (identical(other.hostnameSet, hostnameSet) ||
                other.hostnameSet == hostnameSet) &&
            (identical(
                    other.internalExitNodePriorSet, internalExitNodePriorSet) ||
                other.internalExitNodePriorSet == internalExitNodePriorSet) &&
            (identical(other.controlURL, controlURL) ||
                other.controlURL == controlURL) &&
            (identical(other.routeAll, routeAll) ||
                other.routeAll == routeAll) &&
            (identical(other.corpDNS, corpDNS) || other.corpDNS == corpDNS) &&
            (identical(other.exitNodeID, exitNodeID) ||
                other.exitNodeID == exitNodeID) &&
            (identical(other.internalExitNodePrior, internalExitNodePrior) ||
                other.internalExitNodePrior == internalExitNodePrior) &&
            (identical(other.exitNodeAllowLANAccess, exitNodeAllowLANAccess) ||
                other.exitNodeAllowLANAccess == exitNodeAllowLANAccess) &&
            (identical(other.wantRunning, wantRunning) ||
                other.wantRunning == wantRunning) &&
            (identical(other.shieldsUp, shieldsUp) ||
                other.shieldsUp == shieldsUp) &&
            const DeepCollectionEquality()
                .equals(other._advertiseRoutes, _advertiseRoutes) &&
            (identical(other.forceDaemon, forceDaemon) ||
                other.forceDaemon == forceDaemon) &&
            (identical(other.hostname, hostname) ||
                other.hostname == hostname));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        controlURLSet,
        routeAllSet,
        corpDNSSet,
        exitNodeIDSet,
        exitNodeAllowLANAccessSet,
        wantRunningSet,
        shieldsUpSet,
        advertiseRoutesSet,
        forceDaemonSet,
        hostnameSet,
        internalExitNodePriorSet,
        controlURL,
        routeAll,
        corpDNS,
        exitNodeID,
        internalExitNodePrior,
        exitNodeAllowLANAccess,
        wantRunning,
        shieldsUp,
        const DeepCollectionEquality().hash(_advertiseRoutes),
        forceDaemon,
        hostname
      ]);

  /// Create a copy of MaskedPrefs
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MaskedPrefsImplCopyWith<_$MaskedPrefsImpl> get copyWith =>
      __$$MaskedPrefsImplCopyWithImpl<_$MaskedPrefsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MaskedPrefsImplToJson(
      this,
    );
  }
}

abstract class _MaskedPrefs extends MaskedPrefs {
  const factory _MaskedPrefs(
      {@JsonKey(name: 'ControlURLSet') final bool? controlURLSet,
      @JsonKey(name: 'RouteAllSet') final bool? routeAllSet,
      @JsonKey(name: 'CoprDNSSet') final bool? corpDNSSet,
      @JsonKey(name: 'ExitNodeIDSet') final bool? exitNodeIDSet,
      @JsonKey(name: 'ExitNodeAllowLANAccessSet')
      final bool? exitNodeAllowLANAccessSet,
      @JsonKey(name: 'WantRunningSet') final bool? wantRunningSet,
      @JsonKey(name: 'ShieldsUpSet') final bool? shieldsUpSet,
      @JsonKey(name: 'AdvertiseRoutesSet') final bool? advertiseRoutesSet,
      @JsonKey(name: 'ForceDaemonSet') final bool? forceDaemonSet,
      @JsonKey(name: 'HostnameSet') final bool? hostnameSet,
      @JsonKey(name: 'InternalExitNodePriorSet')
      final bool? internalExitNodePriorSet,
      @JsonKey(name: 'ControlURL') final String? controlURL,
      @JsonKey(name: 'RouteAll') final bool? routeAll,
      @JsonKey(name: 'CorpDNS') final bool? corpDNS,
      @JsonKey(name: 'ExitNodeID') final String? exitNodeID,
      @JsonKey(name: 'InternalExitNodePrior')
      final String? internalExitNodePrior,
      @JsonKey(name: 'ExitNodeAllowLANAccess')
      final bool? exitNodeAllowLANAccess,
      @JsonKey(name: 'WantRunning') final bool? wantRunning,
      @JsonKey(name: 'ShieldsUp') final bool? shieldsUp,
      @JsonKey(name: 'AdvertiseRoutes') final List<String>? advertiseRoutes,
      @JsonKey(name: 'ForceDaemon') final bool? forceDaemon,
      @JsonKey(name: 'Hostname') final String? hostname}) = _$MaskedPrefsImpl;
  const _MaskedPrefs._() : super._();

  factory _MaskedPrefs.fromJson(Map<String, dynamic> json) =
      _$MaskedPrefsImpl.fromJson;

  @override
  @JsonKey(name: 'ControlURLSet')
  bool? get controlURLSet;
  @override
  @JsonKey(name: 'RouteAllSet')
  bool? get routeAllSet;
  @override
  @JsonKey(name: 'CoprDNSSet')
  bool? get corpDNSSet;
  @override
  @JsonKey(name: 'ExitNodeIDSet')
  bool? get exitNodeIDSet;
  @override
  @JsonKey(name: 'ExitNodeAllowLANAccessSet')
  bool? get exitNodeAllowLANAccessSet;
  @override
  @JsonKey(name: 'WantRunningSet')
  bool? get wantRunningSet;
  @override
  @JsonKey(name: 'ShieldsUpSet')
  bool? get shieldsUpSet;
  @override
  @JsonKey(name: 'AdvertiseRoutesSet')
  bool? get advertiseRoutesSet;
  @override
  @JsonKey(name: 'ForceDaemonSet')
  bool? get forceDaemonSet;
  @override
  @JsonKey(name: 'HostnameSet')
  bool? get hostnameSet;
  @override
  @JsonKey(name: 'InternalExitNodePriorSet')
  bool? get internalExitNodePriorSet;
  @override
  @JsonKey(name: 'ControlURL')
  String? get controlURL;
  @override
  @JsonKey(name: 'RouteAll')
  bool? get routeAll;
  @override
  @JsonKey(name: 'CorpDNS')
  bool? get corpDNS;
  @override
  @JsonKey(name: 'ExitNodeID')
  String? get exitNodeID;
  @override
  @JsonKey(name: 'InternalExitNodePrior')
  String? get internalExitNodePrior;
  @override
  @JsonKey(name: 'ExitNodeAllowLANAccess')
  bool? get exitNodeAllowLANAccess;
  @override
  @JsonKey(name: 'WantRunning')
  bool? get wantRunning;
  @override
  @JsonKey(name: 'ShieldsUp')
  bool? get shieldsUp;
  @override
  @JsonKey(name: 'AdvertiseRoutes')
  List<String>? get advertiseRoutes;
  @override
  @JsonKey(name: 'ForceDaemon')
  bool? get forceDaemon;
  @override
  @JsonKey(name: 'Hostname')
  String? get hostname;

  /// Create a copy of MaskedPrefs
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MaskedPrefsImplCopyWith<_$MaskedPrefsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PersistConfig _$PersistConfigFromJson(Map<String, dynamic> json) {
  return _PersistConfig.fromJson(json);
}

/// @nodoc
mixin _$PersistConfig {
  @JsonKey(name: 'PrivateMachineKey')
  String get privateMachineKey => throw _privateConstructorUsedError;
  @JsonKey(name: 'PrivateNodeKey')
  String get privateNodeKey => throw _privateConstructorUsedError;
  @JsonKey(name: 'OldPrivateNodeKey')
  String get oldPrivateNodeKey => throw _privateConstructorUsedError;
  @JsonKey(name: 'Provider')
  String get provider => throw _privateConstructorUsedError;

  /// Serializes this PersistConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PersistConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PersistConfigCopyWith<PersistConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PersistConfigCopyWith<$Res> {
  factory $PersistConfigCopyWith(
          PersistConfig value, $Res Function(PersistConfig) then) =
      _$PersistConfigCopyWithImpl<$Res, PersistConfig>;
  @useResult
  $Res call(
      {@JsonKey(name: 'PrivateMachineKey') String privateMachineKey,
      @JsonKey(name: 'PrivateNodeKey') String privateNodeKey,
      @JsonKey(name: 'OldPrivateNodeKey') String oldPrivateNodeKey,
      @JsonKey(name: 'Provider') String provider});
}

/// @nodoc
class _$PersistConfigCopyWithImpl<$Res, $Val extends PersistConfig>
    implements $PersistConfigCopyWith<$Res> {
  _$PersistConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PersistConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? privateMachineKey = null,
    Object? privateNodeKey = null,
    Object? oldPrivateNodeKey = null,
    Object? provider = null,
  }) {
    return _then(_value.copyWith(
      privateMachineKey: null == privateMachineKey
          ? _value.privateMachineKey
          : privateMachineKey // ignore: cast_nullable_to_non_nullable
              as String,
      privateNodeKey: null == privateNodeKey
          ? _value.privateNodeKey
          : privateNodeKey // ignore: cast_nullable_to_non_nullable
              as String,
      oldPrivateNodeKey: null == oldPrivateNodeKey
          ? _value.oldPrivateNodeKey
          : oldPrivateNodeKey // ignore: cast_nullable_to_non_nullable
              as String,
      provider: null == provider
          ? _value.provider
          : provider // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PersistConfigImplCopyWith<$Res>
    implements $PersistConfigCopyWith<$Res> {
  factory _$$PersistConfigImplCopyWith(
          _$PersistConfigImpl value, $Res Function(_$PersistConfigImpl) then) =
      __$$PersistConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'PrivateMachineKey') String privateMachineKey,
      @JsonKey(name: 'PrivateNodeKey') String privateNodeKey,
      @JsonKey(name: 'OldPrivateNodeKey') String oldPrivateNodeKey,
      @JsonKey(name: 'Provider') String provider});
}

/// @nodoc
class __$$PersistConfigImplCopyWithImpl<$Res>
    extends _$PersistConfigCopyWithImpl<$Res, _$PersistConfigImpl>
    implements _$$PersistConfigImplCopyWith<$Res> {
  __$$PersistConfigImplCopyWithImpl(
      _$PersistConfigImpl _value, $Res Function(_$PersistConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of PersistConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? privateMachineKey = null,
    Object? privateNodeKey = null,
    Object? oldPrivateNodeKey = null,
    Object? provider = null,
  }) {
    return _then(_$PersistConfigImpl(
      privateMachineKey: null == privateMachineKey
          ? _value.privateMachineKey
          : privateMachineKey // ignore: cast_nullable_to_non_nullable
              as String,
      privateNodeKey: null == privateNodeKey
          ? _value.privateNodeKey
          : privateNodeKey // ignore: cast_nullable_to_non_nullable
              as String,
      oldPrivateNodeKey: null == oldPrivateNodeKey
          ? _value.oldPrivateNodeKey
          : oldPrivateNodeKey // ignore: cast_nullable_to_non_nullable
              as String,
      provider: null == provider
          ? _value.provider
          : provider // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PersistConfigImpl implements _PersistConfig {
  const _$PersistConfigImpl(
      {@JsonKey(name: 'PrivateMachineKey')
      this.privateMachineKey = _zeroPrivateKey,
      @JsonKey(name: 'PrivateNodeKey') this.privateNodeKey = _zeroPrivateKey,
      @JsonKey(name: 'OldPrivateNodeKey')
      this.oldPrivateNodeKey = _zeroPrivateKey,
      @JsonKey(name: 'Provider') this.provider = ''});

  factory _$PersistConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$PersistConfigImplFromJson(json);

  @override
  @JsonKey(name: 'PrivateMachineKey')
  final String privateMachineKey;
  @override
  @JsonKey(name: 'PrivateNodeKey')
  final String privateNodeKey;
  @override
  @JsonKey(name: 'OldPrivateNodeKey')
  final String oldPrivateNodeKey;
  @override
  @JsonKey(name: 'Provider')
  final String provider;

  @override
  String toString() {
    return 'PersistConfig(privateMachineKey: $privateMachineKey, privateNodeKey: $privateNodeKey, oldPrivateNodeKey: $oldPrivateNodeKey, provider: $provider)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PersistConfigImpl &&
            (identical(other.privateMachineKey, privateMachineKey) ||
                other.privateMachineKey == privateMachineKey) &&
            (identical(other.privateNodeKey, privateNodeKey) ||
                other.privateNodeKey == privateNodeKey) &&
            (identical(other.oldPrivateNodeKey, oldPrivateNodeKey) ||
                other.oldPrivateNodeKey == oldPrivateNodeKey) &&
            (identical(other.provider, provider) ||
                other.provider == provider));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, privateMachineKey,
      privateNodeKey, oldPrivateNodeKey, provider);

  /// Create a copy of PersistConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PersistConfigImplCopyWith<_$PersistConfigImpl> get copyWith =>
      __$$PersistConfigImplCopyWithImpl<_$PersistConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PersistConfigImplToJson(
      this,
    );
  }
}

abstract class _PersistConfig implements PersistConfig {
  const factory _PersistConfig(
      {@JsonKey(name: 'PrivateMachineKey') final String privateMachineKey,
      @JsonKey(name: 'PrivateNodeKey') final String privateNodeKey,
      @JsonKey(name: 'OldPrivateNodeKey') final String oldPrivateNodeKey,
      @JsonKey(name: 'Provider') final String provider}) = _$PersistConfigImpl;

  factory _PersistConfig.fromJson(Map<String, dynamic> json) =
      _$PersistConfigImpl.fromJson;

  @override
  @JsonKey(name: 'PrivateMachineKey')
  String get privateMachineKey;
  @override
  @JsonKey(name: 'PrivateNodeKey')
  String get privateNodeKey;
  @override
  @JsonKey(name: 'OldPrivateNodeKey')
  String get oldPrivateNodeKey;
  @override
  @JsonKey(name: 'Provider')
  String get provider;

  /// Create a copy of PersistConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PersistConfigImplCopyWith<_$PersistConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NetworkMap _$NetworkMapFromJson(Map<String, dynamic> json) {
  return _NetworkMap.fromJson(json);
}

/// @nodoc
mixin _$NetworkMap {
  @JsonKey(name: 'SelfNode')
  Node get selfNode => throw _privateConstructorUsedError;
  @JsonKey(name: 'NodeKey')
  String get nodeKey => throw _privateConstructorUsedError;
  @JsonKey(name: 'Peers')
  List<Node>? get peers => throw _privateConstructorUsedError;
  @JsonKey(name: 'Expiry')
  DateTime get expiry => throw _privateConstructorUsedError;
  @JsonKey(name: 'Domain')
  String get domain => throw _privateConstructorUsedError;
  @JsonKey(name: 'UserProfiles')
  Map<String, UserProfile> get userProfiles =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'TKAEnabled')
  bool get tkaEnabled => throw _privateConstructorUsedError;
  @JsonKey(name: 'DNS')
  DNSConfig? get dns => throw _privateConstructorUsedError;

  /// Serializes this NetworkMap to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NetworkMap
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NetworkMapCopyWith<NetworkMap> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NetworkMapCopyWith<$Res> {
  factory $NetworkMapCopyWith(
          NetworkMap value, $Res Function(NetworkMap) then) =
      _$NetworkMapCopyWithImpl<$Res, NetworkMap>;
  @useResult
  $Res call(
      {@JsonKey(name: 'SelfNode') Node selfNode,
      @JsonKey(name: 'NodeKey') String nodeKey,
      @JsonKey(name: 'Peers') List<Node>? peers,
      @JsonKey(name: 'Expiry') DateTime expiry,
      @JsonKey(name: 'Domain') String domain,
      @JsonKey(name: 'UserProfiles') Map<String, UserProfile> userProfiles,
      @JsonKey(name: 'TKAEnabled') bool tkaEnabled,
      @JsonKey(name: 'DNS') DNSConfig? dns});

  $NodeCopyWith<$Res> get selfNode;
  $DNSConfigCopyWith<$Res>? get dns;
}

/// @nodoc
class _$NetworkMapCopyWithImpl<$Res, $Val extends NetworkMap>
    implements $NetworkMapCopyWith<$Res> {
  _$NetworkMapCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NetworkMap
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selfNode = null,
    Object? nodeKey = null,
    Object? peers = freezed,
    Object? expiry = null,
    Object? domain = null,
    Object? userProfiles = null,
    Object? tkaEnabled = null,
    Object? dns = freezed,
  }) {
    return _then(_value.copyWith(
      selfNode: null == selfNode
          ? _value.selfNode
          : selfNode // ignore: cast_nullable_to_non_nullable
              as Node,
      nodeKey: null == nodeKey
          ? _value.nodeKey
          : nodeKey // ignore: cast_nullable_to_non_nullable
              as String,
      peers: freezed == peers
          ? _value.peers
          : peers // ignore: cast_nullable_to_non_nullable
              as List<Node>?,
      expiry: null == expiry
          ? _value.expiry
          : expiry // ignore: cast_nullable_to_non_nullable
              as DateTime,
      domain: null == domain
          ? _value.domain
          : domain // ignore: cast_nullable_to_non_nullable
              as String,
      userProfiles: null == userProfiles
          ? _value.userProfiles
          : userProfiles // ignore: cast_nullable_to_non_nullable
              as Map<String, UserProfile>,
      tkaEnabled: null == tkaEnabled
          ? _value.tkaEnabled
          : tkaEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      dns: freezed == dns
          ? _value.dns
          : dns // ignore: cast_nullable_to_non_nullable
              as DNSConfig?,
    ) as $Val);
  }

  /// Create a copy of NetworkMap
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NodeCopyWith<$Res> get selfNode {
    return $NodeCopyWith<$Res>(_value.selfNode, (value) {
      return _then(_value.copyWith(selfNode: value) as $Val);
    });
  }

  /// Create a copy of NetworkMap
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DNSConfigCopyWith<$Res>? get dns {
    if (_value.dns == null) {
      return null;
    }

    return $DNSConfigCopyWith<$Res>(_value.dns!, (value) {
      return _then(_value.copyWith(dns: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$NetworkMapImplCopyWith<$Res>
    implements $NetworkMapCopyWith<$Res> {
  factory _$$NetworkMapImplCopyWith(
          _$NetworkMapImpl value, $Res Function(_$NetworkMapImpl) then) =
      __$$NetworkMapImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'SelfNode') Node selfNode,
      @JsonKey(name: 'NodeKey') String nodeKey,
      @JsonKey(name: 'Peers') List<Node>? peers,
      @JsonKey(name: 'Expiry') DateTime expiry,
      @JsonKey(name: 'Domain') String domain,
      @JsonKey(name: 'UserProfiles') Map<String, UserProfile> userProfiles,
      @JsonKey(name: 'TKAEnabled') bool tkaEnabled,
      @JsonKey(name: 'DNS') DNSConfig? dns});

  @override
  $NodeCopyWith<$Res> get selfNode;
  @override
  $DNSConfigCopyWith<$Res>? get dns;
}

/// @nodoc
class __$$NetworkMapImplCopyWithImpl<$Res>
    extends _$NetworkMapCopyWithImpl<$Res, _$NetworkMapImpl>
    implements _$$NetworkMapImplCopyWith<$Res> {
  __$$NetworkMapImplCopyWithImpl(
      _$NetworkMapImpl _value, $Res Function(_$NetworkMapImpl) _then)
      : super(_value, _then);

  /// Create a copy of NetworkMap
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selfNode = null,
    Object? nodeKey = null,
    Object? peers = freezed,
    Object? expiry = null,
    Object? domain = null,
    Object? userProfiles = null,
    Object? tkaEnabled = null,
    Object? dns = freezed,
  }) {
    return _then(_$NetworkMapImpl(
      selfNode: null == selfNode
          ? _value.selfNode
          : selfNode // ignore: cast_nullable_to_non_nullable
              as Node,
      nodeKey: null == nodeKey
          ? _value.nodeKey
          : nodeKey // ignore: cast_nullable_to_non_nullable
              as String,
      peers: freezed == peers
          ? _value._peers
          : peers // ignore: cast_nullable_to_non_nullable
              as List<Node>?,
      expiry: null == expiry
          ? _value.expiry
          : expiry // ignore: cast_nullable_to_non_nullable
              as DateTime,
      domain: null == domain
          ? _value.domain
          : domain // ignore: cast_nullable_to_non_nullable
              as String,
      userProfiles: null == userProfiles
          ? _value._userProfiles
          : userProfiles // ignore: cast_nullable_to_non_nullable
              as Map<String, UserProfile>,
      tkaEnabled: null == tkaEnabled
          ? _value.tkaEnabled
          : tkaEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      dns: freezed == dns
          ? _value.dns
          : dns // ignore: cast_nullable_to_non_nullable
              as DNSConfig?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NetworkMapImpl extends _NetworkMap {
  const _$NetworkMapImpl(
      {@JsonKey(name: 'SelfNode') required this.selfNode,
      @JsonKey(name: 'NodeKey') required this.nodeKey,
      @JsonKey(name: 'Peers') final List<Node>? peers,
      @JsonKey(name: 'Expiry') required this.expiry,
      @JsonKey(name: 'Domain') required this.domain,
      @JsonKey(name: 'UserProfiles')
      required final Map<String, UserProfile> userProfiles,
      @JsonKey(name: 'TKAEnabled') required this.tkaEnabled,
      @JsonKey(name: 'DNS') this.dns})
      : _peers = peers,
        _userProfiles = userProfiles,
        super._();

  factory _$NetworkMapImpl.fromJson(Map<String, dynamic> json) =>
      _$$NetworkMapImplFromJson(json);

  @override
  @JsonKey(name: 'SelfNode')
  final Node selfNode;
  @override
  @JsonKey(name: 'NodeKey')
  final String nodeKey;
  final List<Node>? _peers;
  @override
  @JsonKey(name: 'Peers')
  List<Node>? get peers {
    final value = _peers;
    if (value == null) return null;
    if (_peers is EqualUnmodifiableListView) return _peers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'Expiry')
  final DateTime expiry;
  @override
  @JsonKey(name: 'Domain')
  final String domain;
  final Map<String, UserProfile> _userProfiles;
  @override
  @JsonKey(name: 'UserProfiles')
  Map<String, UserProfile> get userProfiles {
    if (_userProfiles is EqualUnmodifiableMapView) return _userProfiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_userProfiles);
  }

  @override
  @JsonKey(name: 'TKAEnabled')
  final bool tkaEnabled;
  @override
  @JsonKey(name: 'DNS')
  final DNSConfig? dns;

  @override
  String toString() {
    return 'NetworkMap(selfNode: $selfNode, nodeKey: $nodeKey, peers: $peers, expiry: $expiry, domain: $domain, userProfiles: $userProfiles, tkaEnabled: $tkaEnabled, dns: $dns)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NetworkMapImpl &&
            (identical(other.selfNode, selfNode) ||
                other.selfNode == selfNode) &&
            (identical(other.nodeKey, nodeKey) || other.nodeKey == nodeKey) &&
            const DeepCollectionEquality().equals(other._peers, _peers) &&
            (identical(other.expiry, expiry) || other.expiry == expiry) &&
            (identical(other.domain, domain) || other.domain == domain) &&
            const DeepCollectionEquality()
                .equals(other._userProfiles, _userProfiles) &&
            (identical(other.tkaEnabled, tkaEnabled) ||
                other.tkaEnabled == tkaEnabled) &&
            (identical(other.dns, dns) || other.dns == dns));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      selfNode,
      nodeKey,
      const DeepCollectionEquality().hash(_peers),
      expiry,
      domain,
      const DeepCollectionEquality().hash(_userProfiles),
      tkaEnabled,
      dns);

  /// Create a copy of NetworkMap
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NetworkMapImplCopyWith<_$NetworkMapImpl> get copyWith =>
      __$$NetworkMapImplCopyWithImpl<_$NetworkMapImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NetworkMapImplToJson(
      this,
    );
  }
}

abstract class _NetworkMap extends NetworkMap {
  const factory _NetworkMap(
      {@JsonKey(name: 'SelfNode') required final Node selfNode,
      @JsonKey(name: 'NodeKey') required final String nodeKey,
      @JsonKey(name: 'Peers') final List<Node>? peers,
      @JsonKey(name: 'Expiry') required final DateTime expiry,
      @JsonKey(name: 'Domain') required final String domain,
      @JsonKey(name: 'UserProfiles')
      required final Map<String, UserProfile> userProfiles,
      @JsonKey(name: 'TKAEnabled') required final bool tkaEnabled,
      @JsonKey(name: 'DNS') final DNSConfig? dns}) = _$NetworkMapImpl;
  const _NetworkMap._() : super._();

  factory _NetworkMap.fromJson(Map<String, dynamic> json) =
      _$NetworkMapImpl.fromJson;

  @override
  @JsonKey(name: 'SelfNode')
  Node get selfNode;
  @override
  @JsonKey(name: 'NodeKey')
  String get nodeKey;
  @override
  @JsonKey(name: 'Peers')
  List<Node>? get peers;
  @override
  @JsonKey(name: 'Expiry')
  DateTime get expiry;
  @override
  @JsonKey(name: 'Domain')
  String get domain;
  @override
  @JsonKey(name: 'UserProfiles')
  Map<String, UserProfile> get userProfiles;
  @override
  @JsonKey(name: 'TKAEnabled')
  bool get tkaEnabled;
  @override
  @JsonKey(name: 'DNS')
  DNSConfig? get dns;

  /// Create a copy of NetworkMap
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NetworkMapImplCopyWith<_$NetworkMapImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Node _$NodeFromJson(Map<String, dynamic> json) {
  return _Node.fromJson(json);
}

/// @nodoc
mixin _$Node {
  @JsonKey(name: 'ID')
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'StableID')
  String get stableID => throw _privateConstructorUsedError;
  @JsonKey(name: 'Name')
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'User')
  int get userID => throw _privateConstructorUsedError;
  @JsonKey(name: 'Sharer')
  int? get sharer => throw _privateConstructorUsedError;
  @JsonKey(name: 'Key')
  String get key => throw _privateConstructorUsedError;
  @JsonKey(name: 'KeyExpiry')
  String get keyExpiry => throw _privateConstructorUsedError;
  @JsonKey(name: 'Machine')
  String get machine => throw _privateConstructorUsedError;
  @JsonKey(name: 'Addresses')
  List<String> get addresses => throw _privateConstructorUsedError;
  @JsonKey(name: 'AllowedIPs')
  List<String> get allowedIPs => throw _privateConstructorUsedError;
  @JsonKey(name: 'Endpoints')
  List<String>? get endpoints => throw _privateConstructorUsedError;
  @JsonKey(name: 'Hostinfo')
  Hostinfo? get hostinfo => throw _privateConstructorUsedError;
  @JsonKey(name: 'Created')
  String? get created => throw _privateConstructorUsedError;
  @JsonKey(name: 'LastSeen')
  String? get lastSeen => throw _privateConstructorUsedError;
  @JsonKey(name: 'Online')
  bool? get online => throw _privateConstructorUsedError;
  @JsonKey(name: 'Capabilities')
  List<String>? get capabilities => throw _privateConstructorUsedError;
  @JsonKey(name: 'CapMap')
  Map<String, dynamic>? get capMap => throw _privateConstructorUsedError;
  @JsonKey(name: 'ComputedName')
  String? get computedName => throw _privateConstructorUsedError;
  @JsonKey(name: 'ComputedNameWithHost')
  String? get computedNameWithHost => throw _privateConstructorUsedError;

  /// Serializes this Node to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Node
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NodeCopyWith<Node> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NodeCopyWith<$Res> {
  factory $NodeCopyWith(Node value, $Res Function(Node) then) =
      _$NodeCopyWithImpl<$Res, Node>;
  @useResult
  $Res call(
      {@JsonKey(name: 'ID') int id,
      @JsonKey(name: 'StableID') String stableID,
      @JsonKey(name: 'Name') String name,
      @JsonKey(name: 'User') int userID,
      @JsonKey(name: 'Sharer') int? sharer,
      @JsonKey(name: 'Key') String key,
      @JsonKey(name: 'KeyExpiry') String keyExpiry,
      @JsonKey(name: 'Machine') String machine,
      @JsonKey(name: 'Addresses') List<String> addresses,
      @JsonKey(name: 'AllowedIPs') List<String> allowedIPs,
      @JsonKey(name: 'Endpoints') List<String>? endpoints,
      @JsonKey(name: 'Hostinfo') Hostinfo? hostinfo,
      @JsonKey(name: 'Created') String? created,
      @JsonKey(name: 'LastSeen') String? lastSeen,
      @JsonKey(name: 'Online') bool? online,
      @JsonKey(name: 'Capabilities') List<String>? capabilities,
      @JsonKey(name: 'CapMap') Map<String, dynamic>? capMap,
      @JsonKey(name: 'ComputedName') String? computedName,
      @JsonKey(name: 'ComputedNameWithHost') String? computedNameWithHost});

  $HostinfoCopyWith<$Res>? get hostinfo;
}

/// @nodoc
class _$NodeCopyWithImpl<$Res, $Val extends Node>
    implements $NodeCopyWith<$Res> {
  _$NodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Node
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? stableID = null,
    Object? name = null,
    Object? userID = null,
    Object? sharer = freezed,
    Object? key = null,
    Object? keyExpiry = null,
    Object? machine = null,
    Object? addresses = null,
    Object? allowedIPs = null,
    Object? endpoints = freezed,
    Object? hostinfo = freezed,
    Object? created = freezed,
    Object? lastSeen = freezed,
    Object? online = freezed,
    Object? capabilities = freezed,
    Object? capMap = freezed,
    Object? computedName = freezed,
    Object? computedNameWithHost = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      stableID: null == stableID
          ? _value.stableID
          : stableID // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      userID: null == userID
          ? _value.userID
          : userID // ignore: cast_nullable_to_non_nullable
              as int,
      sharer: freezed == sharer
          ? _value.sharer
          : sharer // ignore: cast_nullable_to_non_nullable
              as int?,
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      keyExpiry: null == keyExpiry
          ? _value.keyExpiry
          : keyExpiry // ignore: cast_nullable_to_non_nullable
              as String,
      machine: null == machine
          ? _value.machine
          : machine // ignore: cast_nullable_to_non_nullable
              as String,
      addresses: null == addresses
          ? _value.addresses
          : addresses // ignore: cast_nullable_to_non_nullable
              as List<String>,
      allowedIPs: null == allowedIPs
          ? _value.allowedIPs
          : allowedIPs // ignore: cast_nullable_to_non_nullable
              as List<String>,
      endpoints: freezed == endpoints
          ? _value.endpoints
          : endpoints // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      hostinfo: freezed == hostinfo
          ? _value.hostinfo
          : hostinfo // ignore: cast_nullable_to_non_nullable
              as Hostinfo?,
      created: freezed == created
          ? _value.created
          : created // ignore: cast_nullable_to_non_nullable
              as String?,
      lastSeen: freezed == lastSeen
          ? _value.lastSeen
          : lastSeen // ignore: cast_nullable_to_non_nullable
              as String?,
      online: freezed == online
          ? _value.online
          : online // ignore: cast_nullable_to_non_nullable
              as bool?,
      capabilities: freezed == capabilities
          ? _value.capabilities
          : capabilities // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      capMap: freezed == capMap
          ? _value.capMap
          : capMap // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      computedName: freezed == computedName
          ? _value.computedName
          : computedName // ignore: cast_nullable_to_non_nullable
              as String?,
      computedNameWithHost: freezed == computedNameWithHost
          ? _value.computedNameWithHost
          : computedNameWithHost // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of Node
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HostinfoCopyWith<$Res>? get hostinfo {
    if (_value.hostinfo == null) {
      return null;
    }

    return $HostinfoCopyWith<$Res>(_value.hostinfo!, (value) {
      return _then(_value.copyWith(hostinfo: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$NodeImplCopyWith<$Res> implements $NodeCopyWith<$Res> {
  factory _$$NodeImplCopyWith(
          _$NodeImpl value, $Res Function(_$NodeImpl) then) =
      __$$NodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'ID') int id,
      @JsonKey(name: 'StableID') String stableID,
      @JsonKey(name: 'Name') String name,
      @JsonKey(name: 'User') int userID,
      @JsonKey(name: 'Sharer') int? sharer,
      @JsonKey(name: 'Key') String key,
      @JsonKey(name: 'KeyExpiry') String keyExpiry,
      @JsonKey(name: 'Machine') String machine,
      @JsonKey(name: 'Addresses') List<String> addresses,
      @JsonKey(name: 'AllowedIPs') List<String> allowedIPs,
      @JsonKey(name: 'Endpoints') List<String>? endpoints,
      @JsonKey(name: 'Hostinfo') Hostinfo? hostinfo,
      @JsonKey(name: 'Created') String? created,
      @JsonKey(name: 'LastSeen') String? lastSeen,
      @JsonKey(name: 'Online') bool? online,
      @JsonKey(name: 'Capabilities') List<String>? capabilities,
      @JsonKey(name: 'CapMap') Map<String, dynamic>? capMap,
      @JsonKey(name: 'ComputedName') String? computedName,
      @JsonKey(name: 'ComputedNameWithHost') String? computedNameWithHost});

  @override
  $HostinfoCopyWith<$Res>? get hostinfo;
}

/// @nodoc
class __$$NodeImplCopyWithImpl<$Res>
    extends _$NodeCopyWithImpl<$Res, _$NodeImpl>
    implements _$$NodeImplCopyWith<$Res> {
  __$$NodeImplCopyWithImpl(_$NodeImpl _value, $Res Function(_$NodeImpl) _then)
      : super(_value, _then);

  /// Create a copy of Node
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? stableID = null,
    Object? name = null,
    Object? userID = null,
    Object? sharer = freezed,
    Object? key = null,
    Object? keyExpiry = null,
    Object? machine = null,
    Object? addresses = null,
    Object? allowedIPs = null,
    Object? endpoints = freezed,
    Object? hostinfo = freezed,
    Object? created = freezed,
    Object? lastSeen = freezed,
    Object? online = freezed,
    Object? capabilities = freezed,
    Object? capMap = freezed,
    Object? computedName = freezed,
    Object? computedNameWithHost = freezed,
  }) {
    return _then(_$NodeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      stableID: null == stableID
          ? _value.stableID
          : stableID // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      userID: null == userID
          ? _value.userID
          : userID // ignore: cast_nullable_to_non_nullable
              as int,
      sharer: freezed == sharer
          ? _value.sharer
          : sharer // ignore: cast_nullable_to_non_nullable
              as int?,
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      keyExpiry: null == keyExpiry
          ? _value.keyExpiry
          : keyExpiry // ignore: cast_nullable_to_non_nullable
              as String,
      machine: null == machine
          ? _value.machine
          : machine // ignore: cast_nullable_to_non_nullable
              as String,
      addresses: null == addresses
          ? _value._addresses
          : addresses // ignore: cast_nullable_to_non_nullable
              as List<String>,
      allowedIPs: null == allowedIPs
          ? _value._allowedIPs
          : allowedIPs // ignore: cast_nullable_to_non_nullable
              as List<String>,
      endpoints: freezed == endpoints
          ? _value._endpoints
          : endpoints // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      hostinfo: freezed == hostinfo
          ? _value.hostinfo
          : hostinfo // ignore: cast_nullable_to_non_nullable
              as Hostinfo?,
      created: freezed == created
          ? _value.created
          : created // ignore: cast_nullable_to_non_nullable
              as String?,
      lastSeen: freezed == lastSeen
          ? _value.lastSeen
          : lastSeen // ignore: cast_nullable_to_non_nullable
              as String?,
      online: freezed == online
          ? _value.online
          : online // ignore: cast_nullable_to_non_nullable
              as bool?,
      capabilities: freezed == capabilities
          ? _value._capabilities
          : capabilities // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      capMap: freezed == capMap
          ? _value._capMap
          : capMap // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      computedName: freezed == computedName
          ? _value.computedName
          : computedName // ignore: cast_nullable_to_non_nullable
              as String?,
      computedNameWithHost: freezed == computedNameWithHost
          ? _value.computedNameWithHost
          : computedNameWithHost // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NodeImpl extends _Node {
  const _$NodeImpl(
      {@JsonKey(name: 'ID') required this.id,
      @JsonKey(name: 'StableID') required this.stableID,
      @JsonKey(name: 'Name') required this.name,
      @JsonKey(name: 'User') required this.userID,
      @JsonKey(name: 'Sharer') this.sharer,
      @JsonKey(name: 'Key') required this.key,
      @JsonKey(name: 'KeyExpiry') required this.keyExpiry,
      @JsonKey(name: 'Machine') required this.machine,
      @JsonKey(name: 'Addresses') required final List<String> addresses,
      @JsonKey(name: 'AllowedIPs') required final List<String> allowedIPs,
      @JsonKey(name: 'Endpoints') final List<String>? endpoints,
      @JsonKey(name: 'Hostinfo') this.hostinfo,
      @JsonKey(name: 'Created') this.created,
      @JsonKey(name: 'LastSeen') this.lastSeen,
      @JsonKey(name: 'Online') this.online,
      @JsonKey(name: 'Capabilities') final List<String>? capabilities,
      @JsonKey(name: 'CapMap') final Map<String, dynamic>? capMap,
      @JsonKey(name: 'ComputedName') this.computedName,
      @JsonKey(name: 'ComputedNameWithHost') this.computedNameWithHost})
      : _addresses = addresses,
        _allowedIPs = allowedIPs,
        _endpoints = endpoints,
        _capabilities = capabilities,
        _capMap = capMap,
        super._();

  factory _$NodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$NodeImplFromJson(json);

  @override
  @JsonKey(name: 'ID')
  final int id;
  @override
  @JsonKey(name: 'StableID')
  final String stableID;
  @override
  @JsonKey(name: 'Name')
  final String name;
  @override
  @JsonKey(name: 'User')
  final int userID;
  @override
  @JsonKey(name: 'Sharer')
  final int? sharer;
  @override
  @JsonKey(name: 'Key')
  final String key;
  @override
  @JsonKey(name: 'KeyExpiry')
  final String keyExpiry;
  @override
  @JsonKey(name: 'Machine')
  final String machine;
  final List<String> _addresses;
  @override
  @JsonKey(name: 'Addresses')
  List<String> get addresses {
    if (_addresses is EqualUnmodifiableListView) return _addresses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_addresses);
  }

  final List<String> _allowedIPs;
  @override
  @JsonKey(name: 'AllowedIPs')
  List<String> get allowedIPs {
    if (_allowedIPs is EqualUnmodifiableListView) return _allowedIPs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allowedIPs);
  }

  final List<String>? _endpoints;
  @override
  @JsonKey(name: 'Endpoints')
  List<String>? get endpoints {
    final value = _endpoints;
    if (value == null) return null;
    if (_endpoints is EqualUnmodifiableListView) return _endpoints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'Hostinfo')
  final Hostinfo? hostinfo;
  @override
  @JsonKey(name: 'Created')
  final String? created;
  @override
  @JsonKey(name: 'LastSeen')
  final String? lastSeen;
  @override
  @JsonKey(name: 'Online')
  final bool? online;
  final List<String>? _capabilities;
  @override
  @JsonKey(name: 'Capabilities')
  List<String>? get capabilities {
    final value = _capabilities;
    if (value == null) return null;
    if (_capabilities is EqualUnmodifiableListView) return _capabilities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, dynamic>? _capMap;
  @override
  @JsonKey(name: 'CapMap')
  Map<String, dynamic>? get capMap {
    final value = _capMap;
    if (value == null) return null;
    if (_capMap is EqualUnmodifiableMapView) return _capMap;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'ComputedName')
  final String? computedName;
  @override
  @JsonKey(name: 'ComputedNameWithHost')
  final String? computedNameWithHost;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NodeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.stableID, stableID) ||
                other.stableID == stableID) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.userID, userID) || other.userID == userID) &&
            (identical(other.sharer, sharer) || other.sharer == sharer) &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.keyExpiry, keyExpiry) ||
                other.keyExpiry == keyExpiry) &&
            (identical(other.machine, machine) || other.machine == machine) &&
            const DeepCollectionEquality()
                .equals(other._addresses, _addresses) &&
            const DeepCollectionEquality()
                .equals(other._allowedIPs, _allowedIPs) &&
            const DeepCollectionEquality()
                .equals(other._endpoints, _endpoints) &&
            (identical(other.hostinfo, hostinfo) ||
                other.hostinfo == hostinfo) &&
            (identical(other.created, created) || other.created == created) &&
            (identical(other.lastSeen, lastSeen) ||
                other.lastSeen == lastSeen) &&
            (identical(other.online, online) || other.online == online) &&
            const DeepCollectionEquality()
                .equals(other._capabilities, _capabilities) &&
            const DeepCollectionEquality().equals(other._capMap, _capMap) &&
            (identical(other.computedName, computedName) ||
                other.computedName == computedName) &&
            (identical(other.computedNameWithHost, computedNameWithHost) ||
                other.computedNameWithHost == computedNameWithHost));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        stableID,
        name,
        userID,
        sharer,
        key,
        keyExpiry,
        machine,
        const DeepCollectionEquality().hash(_addresses),
        const DeepCollectionEquality().hash(_allowedIPs),
        const DeepCollectionEquality().hash(_endpoints),
        hostinfo,
        created,
        lastSeen,
        online,
        const DeepCollectionEquality().hash(_capabilities),
        const DeepCollectionEquality().hash(_capMap),
        computedName,
        computedNameWithHost
      ]);

  /// Create a copy of Node
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NodeImplCopyWith<_$NodeImpl> get copyWith =>
      __$$NodeImplCopyWithImpl<_$NodeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NodeImplToJson(
      this,
    );
  }
}

abstract class _Node extends Node {
  const factory _Node(
      {@JsonKey(name: 'ID') required final int id,
      @JsonKey(name: 'StableID') required final String stableID,
      @JsonKey(name: 'Name') required final String name,
      @JsonKey(name: 'User') required final int userID,
      @JsonKey(name: 'Sharer') final int? sharer,
      @JsonKey(name: 'Key') required final String key,
      @JsonKey(name: 'KeyExpiry') required final String keyExpiry,
      @JsonKey(name: 'Machine') required final String machine,
      @JsonKey(name: 'Addresses') required final List<String> addresses,
      @JsonKey(name: 'AllowedIPs') required final List<String> allowedIPs,
      @JsonKey(name: 'Endpoints') final List<String>? endpoints,
      @JsonKey(name: 'Hostinfo') final Hostinfo? hostinfo,
      @JsonKey(name: 'Created') final String? created,
      @JsonKey(name: 'LastSeen') final String? lastSeen,
      @JsonKey(name: 'Online') final bool? online,
      @JsonKey(name: 'Capabilities') final List<String>? capabilities,
      @JsonKey(name: 'CapMap') final Map<String, dynamic>? capMap,
      @JsonKey(name: 'ComputedName') final String? computedName,
      @JsonKey(name: 'ComputedNameWithHost')
      final String? computedNameWithHost}) = _$NodeImpl;
  const _Node._() : super._();

  factory _Node.fromJson(Map<String, dynamic> json) = _$NodeImpl.fromJson;

  @override
  @JsonKey(name: 'ID')
  int get id;
  @override
  @JsonKey(name: 'StableID')
  String get stableID;
  @override
  @JsonKey(name: 'Name')
  String get name;
  @override
  @JsonKey(name: 'User')
  int get userID;
  @override
  @JsonKey(name: 'Sharer')
  int? get sharer;
  @override
  @JsonKey(name: 'Key')
  String get key;
  @override
  @JsonKey(name: 'KeyExpiry')
  String get keyExpiry;
  @override
  @JsonKey(name: 'Machine')
  String get machine;
  @override
  @JsonKey(name: 'Addresses')
  List<String> get addresses;
  @override
  @JsonKey(name: 'AllowedIPs')
  List<String> get allowedIPs;
  @override
  @JsonKey(name: 'Endpoints')
  List<String>? get endpoints;
  @override
  @JsonKey(name: 'Hostinfo')
  Hostinfo? get hostinfo;
  @override
  @JsonKey(name: 'Created')
  String? get created;
  @override
  @JsonKey(name: 'LastSeen')
  String? get lastSeen;
  @override
  @JsonKey(name: 'Online')
  bool? get online;
  @override
  @JsonKey(name: 'Capabilities')
  List<String>? get capabilities;
  @override
  @JsonKey(name: 'CapMap')
  Map<String, dynamic>? get capMap;
  @override
  @JsonKey(name: 'ComputedName')
  String? get computedName;
  @override
  @JsonKey(name: 'ComputedNameWithHost')
  String? get computedNameWithHost;

  /// Create a copy of Node
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NodeImplCopyWith<_$NodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) {
  return _UserProfile.fromJson(json);
}

/// @nodoc
mixin _$UserProfile {
  @JsonKey(name: 'ID')
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'DisplayName')
  String get displayName => throw _privateConstructorUsedError;
  @JsonKey(name: 'LoginName')
  String get loginName => throw _privateConstructorUsedError;
  @JsonKey(name: 'ProfilePicURL')
  String get profilePicURL => throw _privateConstructorUsedError;

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProfileCopyWith<UserProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileCopyWith<$Res> {
  factory $UserProfileCopyWith(
          UserProfile value, $Res Function(UserProfile) then) =
      _$UserProfileCopyWithImpl<$Res, UserProfile>;
  @useResult
  $Res call(
      {@JsonKey(name: 'ID') int id,
      @JsonKey(name: 'DisplayName') String displayName,
      @JsonKey(name: 'LoginName') String loginName,
      @JsonKey(name: 'ProfilePicURL') String profilePicURL});
}

/// @nodoc
class _$UserProfileCopyWithImpl<$Res, $Val extends UserProfile>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? loginName = null,
    Object? profilePicURL = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      loginName: null == loginName
          ? _value.loginName
          : loginName // ignore: cast_nullable_to_non_nullable
              as String,
      profilePicURL: null == profilePicURL
          ? _value.profilePicURL
          : profilePicURL // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserProfileImplCopyWith<$Res>
    implements $UserProfileCopyWith<$Res> {
  factory _$$UserProfileImplCopyWith(
          _$UserProfileImpl value, $Res Function(_$UserProfileImpl) then) =
      __$$UserProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'ID') int id,
      @JsonKey(name: 'DisplayName') String displayName,
      @JsonKey(name: 'LoginName') String loginName,
      @JsonKey(name: 'ProfilePicURL') String profilePicURL});
}

/// @nodoc
class __$$UserProfileImplCopyWithImpl<$Res>
    extends _$UserProfileCopyWithImpl<$Res, _$UserProfileImpl>
    implements _$$UserProfileImplCopyWith<$Res> {
  __$$UserProfileImplCopyWithImpl(
      _$UserProfileImpl _value, $Res Function(_$UserProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? loginName = null,
    Object? profilePicURL = null,
  }) {
    return _then(_$UserProfileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      loginName: null == loginName
          ? _value.loginName
          : loginName // ignore: cast_nullable_to_non_nullable
              as String,
      profilePicURL: null == profilePicURL
          ? _value.profilePicURL
          : profilePicURL // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserProfileImpl extends _UserProfile {
  const _$UserProfileImpl(
      {@JsonKey(name: 'ID') required this.id,
      @JsonKey(name: 'DisplayName') required this.displayName,
      @JsonKey(name: 'LoginName') required this.loginName,
      @JsonKey(name: 'ProfilePicURL') this.profilePicURL = ''})
      : super._();

  factory _$UserProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProfileImplFromJson(json);

  @override
  @JsonKey(name: 'ID')
  final int id;
  @override
  @JsonKey(name: 'DisplayName')
  final String displayName;
  @override
  @JsonKey(name: 'LoginName')
  final String loginName;
  @override
  @JsonKey(name: 'ProfilePicURL')
  final String profilePicURL;

  @override
  String toString() {
    return 'UserProfile(id: $id, displayName: $displayName, loginName: $loginName, profilePicURL: $profilePicURL)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.loginName, loginName) ||
                other.loginName == loginName) &&
            (identical(other.profilePicURL, profilePicURL) ||
                other.profilePicURL == profilePicURL));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, displayName, loginName, profilePicURL);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      __$$UserProfileImplCopyWithImpl<_$UserProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserProfileImplToJson(
      this,
    );
  }
}

abstract class _UserProfile extends UserProfile {
  const factory _UserProfile(
          {@JsonKey(name: 'ID') required final int id,
          @JsonKey(name: 'DisplayName') required final String displayName,
          @JsonKey(name: 'LoginName') required final String loginName,
          @JsonKey(name: 'ProfilePicURL') final String profilePicURL}) =
      _$UserProfileImpl;
  const _UserProfile._() : super._();

  factory _UserProfile.fromJson(Map<String, dynamic> json) =
      _$UserProfileImpl.fromJson;

  @override
  @JsonKey(name: 'ID')
  int get id;
  @override
  @JsonKey(name: 'DisplayName')
  String get displayName;
  @override
  @JsonKey(name: 'LoginName')
  String get loginName;
  @override
  @JsonKey(name: 'ProfilePicURL')
  String get profilePicURL;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LoginProfile _$LoginProfileFromJson(Map<String, dynamic> json) {
  return _LoginProfile.fromJson(json);
}

/// @nodoc
mixin _$LoginProfile {
  @JsonKey(name: 'ID')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'Name')
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'Key')
  String get key => throw _privateConstructorUsedError;
  @JsonKey(name: 'UserProfile')
  UserProfile get userProfile => throw _privateConstructorUsedError;
  @JsonKey(name: 'NetworkProfile')
  NetworkProfile? get networkProfile => throw _privateConstructorUsedError;
  @JsonKey(name: 'LocalUserID')
  String get localUserId => throw _privateConstructorUsedError;
  @JsonKey(name: 'ControlURL')
  String get controlURL => throw _privateConstructorUsedError;

  /// Serializes this LoginProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LoginProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LoginProfileCopyWith<LoginProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoginProfileCopyWith<$Res> {
  factory $LoginProfileCopyWith(
          LoginProfile value, $Res Function(LoginProfile) then) =
      _$LoginProfileCopyWithImpl<$Res, LoginProfile>;
  @useResult
  $Res call(
      {@JsonKey(name: 'ID') String id,
      @JsonKey(name: 'Name') String name,
      @JsonKey(name: 'Key') String key,
      @JsonKey(name: 'UserProfile') UserProfile userProfile,
      @JsonKey(name: 'NetworkProfile') NetworkProfile? networkProfile,
      @JsonKey(name: 'LocalUserID') String localUserId,
      @JsonKey(name: 'ControlURL') String controlURL});

  $UserProfileCopyWith<$Res> get userProfile;
  $NetworkProfileCopyWith<$Res>? get networkProfile;
}

/// @nodoc
class _$LoginProfileCopyWithImpl<$Res, $Val extends LoginProfile>
    implements $LoginProfileCopyWith<$Res> {
  _$LoginProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LoginProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? key = null,
    Object? userProfile = null,
    Object? networkProfile = freezed,
    Object? localUserId = null,
    Object? controlURL = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      userProfile: null == userProfile
          ? _value.userProfile
          : userProfile // ignore: cast_nullable_to_non_nullable
              as UserProfile,
      networkProfile: freezed == networkProfile
          ? _value.networkProfile
          : networkProfile // ignore: cast_nullable_to_non_nullable
              as NetworkProfile?,
      localUserId: null == localUserId
          ? _value.localUserId
          : localUserId // ignore: cast_nullable_to_non_nullable
              as String,
      controlURL: null == controlURL
          ? _value.controlURL
          : controlURL // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }

  /// Create a copy of LoginProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserProfileCopyWith<$Res> get userProfile {
    return $UserProfileCopyWith<$Res>(_value.userProfile, (value) {
      return _then(_value.copyWith(userProfile: value) as $Val);
    });
  }

  /// Create a copy of LoginProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NetworkProfileCopyWith<$Res>? get networkProfile {
    if (_value.networkProfile == null) {
      return null;
    }

    return $NetworkProfileCopyWith<$Res>(_value.networkProfile!, (value) {
      return _then(_value.copyWith(networkProfile: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$LoginProfileImplCopyWith<$Res>
    implements $LoginProfileCopyWith<$Res> {
  factory _$$LoginProfileImplCopyWith(
          _$LoginProfileImpl value, $Res Function(_$LoginProfileImpl) then) =
      __$$LoginProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'ID') String id,
      @JsonKey(name: 'Name') String name,
      @JsonKey(name: 'Key') String key,
      @JsonKey(name: 'UserProfile') UserProfile userProfile,
      @JsonKey(name: 'NetworkProfile') NetworkProfile? networkProfile,
      @JsonKey(name: 'LocalUserID') String localUserId,
      @JsonKey(name: 'ControlURL') String controlURL});

  @override
  $UserProfileCopyWith<$Res> get userProfile;
  @override
  $NetworkProfileCopyWith<$Res>? get networkProfile;
}

/// @nodoc
class __$$LoginProfileImplCopyWithImpl<$Res>
    extends _$LoginProfileCopyWithImpl<$Res, _$LoginProfileImpl>
    implements _$$LoginProfileImplCopyWith<$Res> {
  __$$LoginProfileImplCopyWithImpl(
      _$LoginProfileImpl _value, $Res Function(_$LoginProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of LoginProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? key = null,
    Object? userProfile = null,
    Object? networkProfile = freezed,
    Object? localUserId = null,
    Object? controlURL = null,
  }) {
    return _then(_$LoginProfileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      userProfile: null == userProfile
          ? _value.userProfile
          : userProfile // ignore: cast_nullable_to_non_nullable
              as UserProfile,
      networkProfile: freezed == networkProfile
          ? _value.networkProfile
          : networkProfile // ignore: cast_nullable_to_non_nullable
              as NetworkProfile?,
      localUserId: null == localUserId
          ? _value.localUserId
          : localUserId // ignore: cast_nullable_to_non_nullable
              as String,
      controlURL: null == controlURL
          ? _value.controlURL
          : controlURL // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LoginProfileImpl extends _LoginProfile {
  const _$LoginProfileImpl(
      {@JsonKey(name: 'ID') required this.id,
      @JsonKey(name: 'Name') required this.name,
      @JsonKey(name: 'Key') required this.key,
      @JsonKey(name: 'UserProfile') required this.userProfile,
      @JsonKey(name: 'NetworkProfile') this.networkProfile,
      @JsonKey(name: 'LocalUserID') required this.localUserId,
      @JsonKey(name: 'ControlURL') required this.controlURL})
      : super._();

  factory _$LoginProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$LoginProfileImplFromJson(json);

  @override
  @JsonKey(name: 'ID')
  final String id;
  @override
  @JsonKey(name: 'Name')
  final String name;
  @override
  @JsonKey(name: 'Key')
  final String key;
  @override
  @JsonKey(name: 'UserProfile')
  final UserProfile userProfile;
  @override
  @JsonKey(name: 'NetworkProfile')
  final NetworkProfile? networkProfile;
  @override
  @JsonKey(name: 'LocalUserID')
  final String localUserId;
  @override
  @JsonKey(name: 'ControlURL')
  final String controlURL;

  @override
  String toString() {
    return 'LoginProfile(id: $id, name: $name, key: $key, userProfile: $userProfile, networkProfile: $networkProfile, localUserId: $localUserId, controlURL: $controlURL)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoginProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.userProfile, userProfile) ||
                other.userProfile == userProfile) &&
            (identical(other.networkProfile, networkProfile) ||
                other.networkProfile == networkProfile) &&
            (identical(other.localUserId, localUserId) ||
                other.localUserId == localUserId) &&
            (identical(other.controlURL, controlURL) ||
                other.controlURL == controlURL));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, key, userProfile,
      networkProfile, localUserId, controlURL);

  /// Create a copy of LoginProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoginProfileImplCopyWith<_$LoginProfileImpl> get copyWith =>
      __$$LoginProfileImplCopyWithImpl<_$LoginProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LoginProfileImplToJson(
      this,
    );
  }
}

abstract class _LoginProfile extends LoginProfile {
  const factory _LoginProfile(
          {@JsonKey(name: 'ID') required final String id,
          @JsonKey(name: 'Name') required final String name,
          @JsonKey(name: 'Key') required final String key,
          @JsonKey(name: 'UserProfile') required final UserProfile userProfile,
          @JsonKey(name: 'NetworkProfile') final NetworkProfile? networkProfile,
          @JsonKey(name: 'LocalUserID') required final String localUserId,
          @JsonKey(name: 'ControlURL') required final String controlURL}) =
      _$LoginProfileImpl;
  const _LoginProfile._() : super._();

  factory _LoginProfile.fromJson(Map<String, dynamic> json) =
      _$LoginProfileImpl.fromJson;

  @override
  @JsonKey(name: 'ID')
  String get id;
  @override
  @JsonKey(name: 'Name')
  String get name;
  @override
  @JsonKey(name: 'Key')
  String get key;
  @override
  @JsonKey(name: 'UserProfile')
  UserProfile get userProfile;
  @override
  @JsonKey(name: 'NetworkProfile')
  NetworkProfile? get networkProfile;
  @override
  @JsonKey(name: 'LocalUserID')
  String get localUserId;
  @override
  @JsonKey(name: 'ControlURL')
  String get controlURL;

  /// Create a copy of LoginProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoginProfileImplCopyWith<_$LoginProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NetworkProfile _$NetworkProfileFromJson(Map<String, dynamic> json) {
  return _NetworkProfile.fromJson(json);
}

/// @nodoc
mixin _$NetworkProfile {
  @JsonKey(name: 'MagicDNSName')
  String? get magicDNSName => throw _privateConstructorUsedError;
  @JsonKey(name: 'DomainName')
  String? get domainName => throw _privateConstructorUsedError;

  /// Serializes this NetworkProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NetworkProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NetworkProfileCopyWith<NetworkProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NetworkProfileCopyWith<$Res> {
  factory $NetworkProfileCopyWith(
          NetworkProfile value, $Res Function(NetworkProfile) then) =
      _$NetworkProfileCopyWithImpl<$Res, NetworkProfile>;
  @useResult
  $Res call(
      {@JsonKey(name: 'MagicDNSName') String? magicDNSName,
      @JsonKey(name: 'DomainName') String? domainName});
}

/// @nodoc
class _$NetworkProfileCopyWithImpl<$Res, $Val extends NetworkProfile>
    implements $NetworkProfileCopyWith<$Res> {
  _$NetworkProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NetworkProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? magicDNSName = freezed,
    Object? domainName = freezed,
  }) {
    return _then(_value.copyWith(
      magicDNSName: freezed == magicDNSName
          ? _value.magicDNSName
          : magicDNSName // ignore: cast_nullable_to_non_nullable
              as String?,
      domainName: freezed == domainName
          ? _value.domainName
          : domainName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NetworkProfileImplCopyWith<$Res>
    implements $NetworkProfileCopyWith<$Res> {
  factory _$$NetworkProfileImplCopyWith(_$NetworkProfileImpl value,
          $Res Function(_$NetworkProfileImpl) then) =
      __$$NetworkProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'MagicDNSName') String? magicDNSName,
      @JsonKey(name: 'DomainName') String? domainName});
}

/// @nodoc
class __$$NetworkProfileImplCopyWithImpl<$Res>
    extends _$NetworkProfileCopyWithImpl<$Res, _$NetworkProfileImpl>
    implements _$$NetworkProfileImplCopyWith<$Res> {
  __$$NetworkProfileImplCopyWithImpl(
      _$NetworkProfileImpl _value, $Res Function(_$NetworkProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of NetworkProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? magicDNSName = freezed,
    Object? domainName = freezed,
  }) {
    return _then(_$NetworkProfileImpl(
      magicDNSName: freezed == magicDNSName
          ? _value.magicDNSName
          : magicDNSName // ignore: cast_nullable_to_non_nullable
              as String?,
      domainName: freezed == domainName
          ? _value.domainName
          : domainName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NetworkProfileImpl extends _NetworkProfile {
  const _$NetworkProfileImpl(
      {@JsonKey(name: 'MagicDNSName') this.magicDNSName,
      @JsonKey(name: 'DomainName') this.domainName})
      : super._();

  factory _$NetworkProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$NetworkProfileImplFromJson(json);

  @override
  @JsonKey(name: 'MagicDNSName')
  final String? magicDNSName;
  @override
  @JsonKey(name: 'DomainName')
  final String? domainName;

  @override
  String toString() {
    return 'NetworkProfile(magicDNSName: $magicDNSName, domainName: $domainName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NetworkProfileImpl &&
            (identical(other.magicDNSName, magicDNSName) ||
                other.magicDNSName == magicDNSName) &&
            (identical(other.domainName, domainName) ||
                other.domainName == domainName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, magicDNSName, domainName);

  /// Create a copy of NetworkProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NetworkProfileImplCopyWith<_$NetworkProfileImpl> get copyWith =>
      __$$NetworkProfileImplCopyWithImpl<_$NetworkProfileImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NetworkProfileImplToJson(
      this,
    );
  }
}

abstract class _NetworkProfile extends NetworkProfile {
  const factory _NetworkProfile(
          {@JsonKey(name: 'MagicDNSName') final String? magicDNSName,
          @JsonKey(name: 'DomainName') final String? domainName}) =
      _$NetworkProfileImpl;
  const _NetworkProfile._() : super._();

  factory _NetworkProfile.fromJson(Map<String, dynamic> json) =
      _$NetworkProfileImpl.fromJson;

  @override
  @JsonKey(name: 'MagicDNSName')
  String? get magicDNSName;
  @override
  @JsonKey(name: 'DomainName')
  String? get domainName;

  /// Create a copy of NetworkProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NetworkProfileImplCopyWith<_$NetworkProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DNSHostEntry _$DNSHostEntryFromJson(Map<String, dynamic> json) {
  return _DNSHostEntry.fromJson(json);
}

/// @nodoc
mixin _$DNSHostEntry {
  @JsonKey(name: 'Addr')
  String? get addr => throw _privateConstructorUsedError;
  @JsonKey(name: 'Hosts')
  List<String>? get hosts => throw _privateConstructorUsedError;

  /// Serializes this DNSHostEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DNSHostEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DNSHostEntryCopyWith<DNSHostEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DNSHostEntryCopyWith<$Res> {
  factory $DNSHostEntryCopyWith(
          DNSHostEntry value, $Res Function(DNSHostEntry) then) =
      _$DNSHostEntryCopyWithImpl<$Res, DNSHostEntry>;
  @useResult
  $Res call(
      {@JsonKey(name: 'Addr') String? addr,
      @JsonKey(name: 'Hosts') List<String>? hosts});
}

/// @nodoc
class _$DNSHostEntryCopyWithImpl<$Res, $Val extends DNSHostEntry>
    implements $DNSHostEntryCopyWith<$Res> {
  _$DNSHostEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DNSHostEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? addr = freezed,
    Object? hosts = freezed,
  }) {
    return _then(_value.copyWith(
      addr: freezed == addr
          ? _value.addr
          : addr // ignore: cast_nullable_to_non_nullable
              as String?,
      hosts: freezed == hosts
          ? _value.hosts
          : hosts // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DNSHostEntryImplCopyWith<$Res>
    implements $DNSHostEntryCopyWith<$Res> {
  factory _$$DNSHostEntryImplCopyWith(
          _$DNSHostEntryImpl value, $Res Function(_$DNSHostEntryImpl) then) =
      __$$DNSHostEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Addr') String? addr,
      @JsonKey(name: 'Hosts') List<String>? hosts});
}

/// @nodoc
class __$$DNSHostEntryImplCopyWithImpl<$Res>
    extends _$DNSHostEntryCopyWithImpl<$Res, _$DNSHostEntryImpl>
    implements _$$DNSHostEntryImplCopyWith<$Res> {
  __$$DNSHostEntryImplCopyWithImpl(
      _$DNSHostEntryImpl _value, $Res Function(_$DNSHostEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of DNSHostEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? addr = freezed,
    Object? hosts = freezed,
  }) {
    return _then(_$DNSHostEntryImpl(
      addr: freezed == addr
          ? _value.addr
          : addr // ignore: cast_nullable_to_non_nullable
              as String?,
      hosts: freezed == hosts
          ? _value._hosts
          : hosts // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DNSHostEntryImpl implements _DNSHostEntry {
  const _$DNSHostEntryImpl(
      {@JsonKey(name: 'Addr') this.addr,
      @JsonKey(name: 'Hosts') final List<String>? hosts})
      : _hosts = hosts;

  factory _$DNSHostEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$DNSHostEntryImplFromJson(json);

  @override
  @JsonKey(name: 'Addr')
  final String? addr;
  final List<String>? _hosts;
  @override
  @JsonKey(name: 'Hosts')
  List<String>? get hosts {
    final value = _hosts;
    if (value == null) return null;
    if (_hosts is EqualUnmodifiableListView) return _hosts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'DNSHostEntry(addr: $addr, hosts: $hosts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DNSHostEntryImpl &&
            (identical(other.addr, addr) || other.addr == addr) &&
            const DeepCollectionEquality().equals(other._hosts, _hosts));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, addr, const DeepCollectionEquality().hash(_hosts));

  /// Create a copy of DNSHostEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DNSHostEntryImplCopyWith<_$DNSHostEntryImpl> get copyWith =>
      __$$DNSHostEntryImplCopyWithImpl<_$DNSHostEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DNSHostEntryImplToJson(
      this,
    );
  }
}

abstract class _DNSHostEntry implements DNSHostEntry {
  const factory _DNSHostEntry(
      {@JsonKey(name: 'Addr') final String? addr,
      @JsonKey(name: 'Hosts') final List<String>? hosts}) = _$DNSHostEntryImpl;

  factory _DNSHostEntry.fromJson(Map<String, dynamic> json) =
      _$DNSHostEntryImpl.fromJson;

  @override
  @JsonKey(name: 'Addr')
  String? get addr;
  @override
  @JsonKey(name: 'Hosts')
  List<String>? get hosts;

  /// Create a copy of DNSHostEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DNSHostEntryImplCopyWith<_$DNSHostEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OSConfig _$OSConfigFromJson(Map<String, dynamic> json) {
  return _OSConfig.fromJson(json);
}

/// @nodoc
mixin _$OSConfig {
  @JsonKey(name: 'Hosts')
  List<DNSHostEntry>? get hosts => throw _privateConstructorUsedError;
  @JsonKey(name: 'Nameservers')
  List<String>? get nameservers => throw _privateConstructorUsedError;
  @JsonKey(name: 'SearchDomains')
  List<String>? get searchDomains => throw _privateConstructorUsedError;
  @JsonKey(name: 'MatchDomains')
  List<String>? get matchDomains => throw _privateConstructorUsedError;

  /// Serializes this OSConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OSConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OSConfigCopyWith<OSConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OSConfigCopyWith<$Res> {
  factory $OSConfigCopyWith(OSConfig value, $Res Function(OSConfig) then) =
      _$OSConfigCopyWithImpl<$Res, OSConfig>;
  @useResult
  $Res call(
      {@JsonKey(name: 'Hosts') List<DNSHostEntry>? hosts,
      @JsonKey(name: 'Nameservers') List<String>? nameservers,
      @JsonKey(name: 'SearchDomains') List<String>? searchDomains,
      @JsonKey(name: 'MatchDomains') List<String>? matchDomains});
}

/// @nodoc
class _$OSConfigCopyWithImpl<$Res, $Val extends OSConfig>
    implements $OSConfigCopyWith<$Res> {
  _$OSConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OSConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hosts = freezed,
    Object? nameservers = freezed,
    Object? searchDomains = freezed,
    Object? matchDomains = freezed,
  }) {
    return _then(_value.copyWith(
      hosts: freezed == hosts
          ? _value.hosts
          : hosts // ignore: cast_nullable_to_non_nullable
              as List<DNSHostEntry>?,
      nameservers: freezed == nameservers
          ? _value.nameservers
          : nameservers // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      searchDomains: freezed == searchDomains
          ? _value.searchDomains
          : searchDomains // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      matchDomains: freezed == matchDomains
          ? _value.matchDomains
          : matchDomains // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OSConfigImplCopyWith<$Res>
    implements $OSConfigCopyWith<$Res> {
  factory _$$OSConfigImplCopyWith(
          _$OSConfigImpl value, $Res Function(_$OSConfigImpl) then) =
      __$$OSConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Hosts') List<DNSHostEntry>? hosts,
      @JsonKey(name: 'Nameservers') List<String>? nameservers,
      @JsonKey(name: 'SearchDomains') List<String>? searchDomains,
      @JsonKey(name: 'MatchDomains') List<String>? matchDomains});
}

/// @nodoc
class __$$OSConfigImplCopyWithImpl<$Res>
    extends _$OSConfigCopyWithImpl<$Res, _$OSConfigImpl>
    implements _$$OSConfigImplCopyWith<$Res> {
  __$$OSConfigImplCopyWithImpl(
      _$OSConfigImpl _value, $Res Function(_$OSConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of OSConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hosts = freezed,
    Object? nameservers = freezed,
    Object? searchDomains = freezed,
    Object? matchDomains = freezed,
  }) {
    return _then(_$OSConfigImpl(
      hosts: freezed == hosts
          ? _value._hosts
          : hosts // ignore: cast_nullable_to_non_nullable
              as List<DNSHostEntry>?,
      nameservers: freezed == nameservers
          ? _value._nameservers
          : nameservers // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      searchDomains: freezed == searchDomains
          ? _value._searchDomains
          : searchDomains // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      matchDomains: freezed == matchDomains
          ? _value._matchDomains
          : matchDomains // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OSConfigImpl extends _OSConfig {
  const _$OSConfigImpl(
      {@JsonKey(name: 'Hosts') final List<DNSHostEntry>? hosts,
      @JsonKey(name: 'Nameservers') final List<String>? nameservers,
      @JsonKey(name: 'SearchDomains') final List<String>? searchDomains,
      @JsonKey(name: 'MatchDomains') final List<String>? matchDomains})
      : _hosts = hosts,
        _nameservers = nameservers,
        _searchDomains = searchDomains,
        _matchDomains = matchDomains,
        super._();

  factory _$OSConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$OSConfigImplFromJson(json);

  final List<DNSHostEntry>? _hosts;
  @override
  @JsonKey(name: 'Hosts')
  List<DNSHostEntry>? get hosts {
    final value = _hosts;
    if (value == null) return null;
    if (_hosts is EqualUnmodifiableListView) return _hosts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _nameservers;
  @override
  @JsonKey(name: 'Nameservers')
  List<String>? get nameservers {
    final value = _nameservers;
    if (value == null) return null;
    if (_nameservers is EqualUnmodifiableListView) return _nameservers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _searchDomains;
  @override
  @JsonKey(name: 'SearchDomains')
  List<String>? get searchDomains {
    final value = _searchDomains;
    if (value == null) return null;
    if (_searchDomains is EqualUnmodifiableListView) return _searchDomains;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _matchDomains;
  @override
  @JsonKey(name: 'MatchDomains')
  List<String>? get matchDomains {
    final value = _matchDomains;
    if (value == null) return null;
    if (_matchDomains is EqualUnmodifiableListView) return _matchDomains;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'OSConfig(hosts: $hosts, nameservers: $nameservers, searchDomains: $searchDomains, matchDomains: $matchDomains)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OSConfigImpl &&
            const DeepCollectionEquality().equals(other._hosts, _hosts) &&
            const DeepCollectionEquality()
                .equals(other._nameservers, _nameservers) &&
            const DeepCollectionEquality()
                .equals(other._searchDomains, _searchDomains) &&
            const DeepCollectionEquality()
                .equals(other._matchDomains, _matchDomains));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_hosts),
      const DeepCollectionEquality().hash(_nameservers),
      const DeepCollectionEquality().hash(_searchDomains),
      const DeepCollectionEquality().hash(_matchDomains));

  /// Create a copy of OSConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OSConfigImplCopyWith<_$OSConfigImpl> get copyWith =>
      __$$OSConfigImplCopyWithImpl<_$OSConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OSConfigImplToJson(
      this,
    );
  }
}

abstract class _OSConfig extends OSConfig {
  const factory _OSConfig(
          {@JsonKey(name: 'Hosts') final List<DNSHostEntry>? hosts,
          @JsonKey(name: 'Nameservers') final List<String>? nameservers,
          @JsonKey(name: 'SearchDomains') final List<String>? searchDomains,
          @JsonKey(name: 'MatchDomains') final List<String>? matchDomains}) =
      _$OSConfigImpl;
  const _OSConfig._() : super._();

  factory _OSConfig.fromJson(Map<String, dynamic> json) =
      _$OSConfigImpl.fromJson;

  @override
  @JsonKey(name: 'Hosts')
  List<DNSHostEntry>? get hosts;
  @override
  @JsonKey(name: 'Nameservers')
  List<String>? get nameservers;
  @override
  @JsonKey(name: 'SearchDomains')
  List<String>? get searchDomains;
  @override
  @JsonKey(name: 'MatchDomains')
  List<String>? get matchDomains;

  /// Create a copy of OSConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OSConfigImplCopyWith<_$OSConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Resolver _$ResolverFromJson(Map<String, dynamic> json) {
  return _Resolver.fromJson(json);
}

/// @nodoc
mixin _$Resolver {
  @JsonKey(name: 'Addr')
  String? get addr => throw _privateConstructorUsedError;
  @JsonKey(name: 'BootstrapResolution')
  List<String>? get bootstrapResolution => throw _privateConstructorUsedError;

  /// Serializes this Resolver to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Resolver
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ResolverCopyWith<Resolver> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ResolverCopyWith<$Res> {
  factory $ResolverCopyWith(Resolver value, $Res Function(Resolver) then) =
      _$ResolverCopyWithImpl<$Res, Resolver>;
  @useResult
  $Res call(
      {@JsonKey(name: 'Addr') String? addr,
      @JsonKey(name: 'BootstrapResolution') List<String>? bootstrapResolution});
}

/// @nodoc
class _$ResolverCopyWithImpl<$Res, $Val extends Resolver>
    implements $ResolverCopyWith<$Res> {
  _$ResolverCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Resolver
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? addr = freezed,
    Object? bootstrapResolution = freezed,
  }) {
    return _then(_value.copyWith(
      addr: freezed == addr
          ? _value.addr
          : addr // ignore: cast_nullable_to_non_nullable
              as String?,
      bootstrapResolution: freezed == bootstrapResolution
          ? _value.bootstrapResolution
          : bootstrapResolution // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ResolverImplCopyWith<$Res>
    implements $ResolverCopyWith<$Res> {
  factory _$$ResolverImplCopyWith(
          _$ResolverImpl value, $Res Function(_$ResolverImpl) then) =
      __$$ResolverImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Addr') String? addr,
      @JsonKey(name: 'BootstrapResolution') List<String>? bootstrapResolution});
}

/// @nodoc
class __$$ResolverImplCopyWithImpl<$Res>
    extends _$ResolverCopyWithImpl<$Res, _$ResolverImpl>
    implements _$$ResolverImplCopyWith<$Res> {
  __$$ResolverImplCopyWithImpl(
      _$ResolverImpl _value, $Res Function(_$ResolverImpl) _then)
      : super(_value, _then);

  /// Create a copy of Resolver
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? addr = freezed,
    Object? bootstrapResolution = freezed,
  }) {
    return _then(_$ResolverImpl(
      addr: freezed == addr
          ? _value.addr
          : addr // ignore: cast_nullable_to_non_nullable
              as String?,
      bootstrapResolution: freezed == bootstrapResolution
          ? _value._bootstrapResolution
          : bootstrapResolution // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ResolverImpl implements _Resolver {
  const _$ResolverImpl(
      {@JsonKey(name: 'Addr') this.addr,
      @JsonKey(name: 'BootstrapResolution')
      final List<String>? bootstrapResolution})
      : _bootstrapResolution = bootstrapResolution;

  factory _$ResolverImpl.fromJson(Map<String, dynamic> json) =>
      _$$ResolverImplFromJson(json);

  @override
  @JsonKey(name: 'Addr')
  final String? addr;
  final List<String>? _bootstrapResolution;
  @override
  @JsonKey(name: 'BootstrapResolution')
  List<String>? get bootstrapResolution {
    final value = _bootstrapResolution;
    if (value == null) return null;
    if (_bootstrapResolution is EqualUnmodifiableListView)
      return _bootstrapResolution;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'Resolver(addr: $addr, bootstrapResolution: $bootstrapResolution)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ResolverImpl &&
            (identical(other.addr, addr) || other.addr == addr) &&
            const DeepCollectionEquality()
                .equals(other._bootstrapResolution, _bootstrapResolution));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, addr,
      const DeepCollectionEquality().hash(_bootstrapResolution));

  /// Create a copy of Resolver
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ResolverImplCopyWith<_$ResolverImpl> get copyWith =>
      __$$ResolverImplCopyWithImpl<_$ResolverImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ResolverImplToJson(
      this,
    );
  }
}

abstract class _Resolver implements Resolver {
  const factory _Resolver(
      {@JsonKey(name: 'Addr') final String? addr,
      @JsonKey(name: 'BootstrapResolution')
      final List<String>? bootstrapResolution}) = _$ResolverImpl;

  factory _Resolver.fromJson(Map<String, dynamic> json) =
      _$ResolverImpl.fromJson;

  @override
  @JsonKey(name: 'Addr')
  String? get addr;
  @override
  @JsonKey(name: 'BootstrapResolution')
  List<String>? get bootstrapResolution;

  /// Create a copy of Resolver
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ResolverImplCopyWith<_$ResolverImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DNSConfig _$DNSConfigFromJson(Map<String, dynamic> json) {
  return _DNSConfig.fromJson(json);
}

/// @nodoc
mixin _$DNSConfig {
  @JsonKey(name: 'Resolvers')
  List<Resolver>? get resolvers => throw _privateConstructorUsedError;
  @JsonKey(name: 'Routes')
  Map<String, List<Resolver>?>? get routes =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'FallbackResolvers')
  List<Resolver>? get fallbackResolvers => throw _privateConstructorUsedError;
  @JsonKey(name: 'Domains')
  List<String>? get domains => throw _privateConstructorUsedError;
  @JsonKey(name: 'Nameservers')
  List<String>? get nameservers => throw _privateConstructorUsedError;

  /// Serializes this DNSConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DNSConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DNSConfigCopyWith<DNSConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DNSConfigCopyWith<$Res> {
  factory $DNSConfigCopyWith(DNSConfig value, $Res Function(DNSConfig) then) =
      _$DNSConfigCopyWithImpl<$Res, DNSConfig>;
  @useResult
  $Res call(
      {@JsonKey(name: 'Resolvers') List<Resolver>? resolvers,
      @JsonKey(name: 'Routes') Map<String, List<Resolver>?>? routes,
      @JsonKey(name: 'FallbackResolvers') List<Resolver>? fallbackResolvers,
      @JsonKey(name: 'Domains') List<String>? domains,
      @JsonKey(name: 'Nameservers') List<String>? nameservers});
}

/// @nodoc
class _$DNSConfigCopyWithImpl<$Res, $Val extends DNSConfig>
    implements $DNSConfigCopyWith<$Res> {
  _$DNSConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DNSConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? resolvers = freezed,
    Object? routes = freezed,
    Object? fallbackResolvers = freezed,
    Object? domains = freezed,
    Object? nameservers = freezed,
  }) {
    return _then(_value.copyWith(
      resolvers: freezed == resolvers
          ? _value.resolvers
          : resolvers // ignore: cast_nullable_to_non_nullable
              as List<Resolver>?,
      routes: freezed == routes
          ? _value.routes
          : routes // ignore: cast_nullable_to_non_nullable
              as Map<String, List<Resolver>?>?,
      fallbackResolvers: freezed == fallbackResolvers
          ? _value.fallbackResolvers
          : fallbackResolvers // ignore: cast_nullable_to_non_nullable
              as List<Resolver>?,
      domains: freezed == domains
          ? _value.domains
          : domains // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      nameservers: freezed == nameservers
          ? _value.nameservers
          : nameservers // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DNSConfigImplCopyWith<$Res>
    implements $DNSConfigCopyWith<$Res> {
  factory _$$DNSConfigImplCopyWith(
          _$DNSConfigImpl value, $Res Function(_$DNSConfigImpl) then) =
      __$$DNSConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Resolvers') List<Resolver>? resolvers,
      @JsonKey(name: 'Routes') Map<String, List<Resolver>?>? routes,
      @JsonKey(name: 'FallbackResolvers') List<Resolver>? fallbackResolvers,
      @JsonKey(name: 'Domains') List<String>? domains,
      @JsonKey(name: 'Nameservers') List<String>? nameservers});
}

/// @nodoc
class __$$DNSConfigImplCopyWithImpl<$Res>
    extends _$DNSConfigCopyWithImpl<$Res, _$DNSConfigImpl>
    implements _$$DNSConfigImplCopyWith<$Res> {
  __$$DNSConfigImplCopyWithImpl(
      _$DNSConfigImpl _value, $Res Function(_$DNSConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of DNSConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? resolvers = freezed,
    Object? routes = freezed,
    Object? fallbackResolvers = freezed,
    Object? domains = freezed,
    Object? nameservers = freezed,
  }) {
    return _then(_$DNSConfigImpl(
      resolvers: freezed == resolvers
          ? _value._resolvers
          : resolvers // ignore: cast_nullable_to_non_nullable
              as List<Resolver>?,
      routes: freezed == routes
          ? _value._routes
          : routes // ignore: cast_nullable_to_non_nullable
              as Map<String, List<Resolver>?>?,
      fallbackResolvers: freezed == fallbackResolvers
          ? _value._fallbackResolvers
          : fallbackResolvers // ignore: cast_nullable_to_non_nullable
              as List<Resolver>?,
      domains: freezed == domains
          ? _value._domains
          : domains // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      nameservers: freezed == nameservers
          ? _value._nameservers
          : nameservers // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DNSConfigImpl implements _DNSConfig {
  const _$DNSConfigImpl(
      {@JsonKey(name: 'Resolvers') final List<Resolver>? resolvers,
      @JsonKey(name: 'Routes') final Map<String, List<Resolver>?>? routes,
      @JsonKey(name: 'FallbackResolvers')
      final List<Resolver>? fallbackResolvers,
      @JsonKey(name: 'Domains') final List<String>? domains,
      @JsonKey(name: 'Nameservers') final List<String>? nameservers})
      : _resolvers = resolvers,
        _routes = routes,
        _fallbackResolvers = fallbackResolvers,
        _domains = domains,
        _nameservers = nameservers;

  factory _$DNSConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$DNSConfigImplFromJson(json);

  final List<Resolver>? _resolvers;
  @override
  @JsonKey(name: 'Resolvers')
  List<Resolver>? get resolvers {
    final value = _resolvers;
    if (value == null) return null;
    if (_resolvers is EqualUnmodifiableListView) return _resolvers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, List<Resolver>?>? _routes;
  @override
  @JsonKey(name: 'Routes')
  Map<String, List<Resolver>?>? get routes {
    final value = _routes;
    if (value == null) return null;
    if (_routes is EqualUnmodifiableMapView) return _routes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final List<Resolver>? _fallbackResolvers;
  @override
  @JsonKey(name: 'FallbackResolvers')
  List<Resolver>? get fallbackResolvers {
    final value = _fallbackResolvers;
    if (value == null) return null;
    if (_fallbackResolvers is EqualUnmodifiableListView)
      return _fallbackResolvers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _domains;
  @override
  @JsonKey(name: 'Domains')
  List<String>? get domains {
    final value = _domains;
    if (value == null) return null;
    if (_domains is EqualUnmodifiableListView) return _domains;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _nameservers;
  @override
  @JsonKey(name: 'Nameservers')
  List<String>? get nameservers {
    final value = _nameservers;
    if (value == null) return null;
    if (_nameservers is EqualUnmodifiableListView) return _nameservers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'DNSConfig(resolvers: $resolvers, routes: $routes, fallbackResolvers: $fallbackResolvers, domains: $domains, nameservers: $nameservers)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DNSConfigImpl &&
            const DeepCollectionEquality()
                .equals(other._resolvers, _resolvers) &&
            const DeepCollectionEquality().equals(other._routes, _routes) &&
            const DeepCollectionEquality()
                .equals(other._fallbackResolvers, _fallbackResolvers) &&
            const DeepCollectionEquality().equals(other._domains, _domains) &&
            const DeepCollectionEquality()
                .equals(other._nameservers, _nameservers));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_resolvers),
      const DeepCollectionEquality().hash(_routes),
      const DeepCollectionEquality().hash(_fallbackResolvers),
      const DeepCollectionEquality().hash(_domains),
      const DeepCollectionEquality().hash(_nameservers));

  /// Create a copy of DNSConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DNSConfigImplCopyWith<_$DNSConfigImpl> get copyWith =>
      __$$DNSConfigImplCopyWithImpl<_$DNSConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DNSConfigImplToJson(
      this,
    );
  }
}

abstract class _DNSConfig implements DNSConfig {
  const factory _DNSConfig(
          {@JsonKey(name: 'Resolvers') final List<Resolver>? resolvers,
          @JsonKey(name: 'Routes') final Map<String, List<Resolver>?>? routes,
          @JsonKey(name: 'FallbackResolvers')
          final List<Resolver>? fallbackResolvers,
          @JsonKey(name: 'Domains') final List<String>? domains,
          @JsonKey(name: 'Nameservers') final List<String>? nameservers}) =
      _$DNSConfigImpl;

  factory _DNSConfig.fromJson(Map<String, dynamic> json) =
      _$DNSConfigImpl.fromJson;

  @override
  @JsonKey(name: 'Resolvers')
  List<Resolver>? get resolvers;
  @override
  @JsonKey(name: 'Routes')
  Map<String, List<Resolver>?>? get routes;
  @override
  @JsonKey(name: 'FallbackResolvers')
  List<Resolver>? get fallbackResolvers;
  @override
  @JsonKey(name: 'Domains')
  List<String>? get domains;
  @override
  @JsonKey(name: 'Nameservers')
  List<String>? get nameservers;

  /// Create a copy of DNSConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DNSConfigImplCopyWith<_$DNSConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Health _$HealthFromJson(Map<String, dynamic> json) {
  return _Health.fromJson(json);
}

/// @nodoc
mixin _$Health {
  @JsonKey(name: 'State')
  String? get state => throw _privateConstructorUsedError;
  @JsonKey(name: 'Code')
  int? get code => throw _privateConstructorUsedError;
  @JsonKey(name: 'Message')
  String? get message => throw _privateConstructorUsedError;

  /// Serializes this Health to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Health
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HealthCopyWith<Health> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HealthCopyWith<$Res> {
  factory $HealthCopyWith(Health value, $Res Function(Health) then) =
      _$HealthCopyWithImpl<$Res, Health>;
  @useResult
  $Res call(
      {@JsonKey(name: 'State') String? state,
      @JsonKey(name: 'Code') int? code,
      @JsonKey(name: 'Message') String? message});
}

/// @nodoc
class _$HealthCopyWithImpl<$Res, $Val extends Health>
    implements $HealthCopyWith<$Res> {
  _$HealthCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Health
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = freezed,
    Object? code = freezed,
    Object? message = freezed,
  }) {
    return _then(_value.copyWith(
      state: freezed == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String?,
      code: freezed == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as int?,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HealthImplCopyWith<$Res> implements $HealthCopyWith<$Res> {
  factory _$$HealthImplCopyWith(
          _$HealthImpl value, $Res Function(_$HealthImpl) then) =
      __$$HealthImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'State') String? state,
      @JsonKey(name: 'Code') int? code,
      @JsonKey(name: 'Message') String? message});
}

/// @nodoc
class __$$HealthImplCopyWithImpl<$Res>
    extends _$HealthCopyWithImpl<$Res, _$HealthImpl>
    implements _$$HealthImplCopyWith<$Res> {
  __$$HealthImplCopyWithImpl(
      _$HealthImpl _value, $Res Function(_$HealthImpl) _then)
      : super(_value, _then);

  /// Create a copy of Health
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = freezed,
    Object? code = freezed,
    Object? message = freezed,
  }) {
    return _then(_$HealthImpl(
      state: freezed == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String?,
      code: freezed == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as int?,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HealthImpl implements _Health {
  const _$HealthImpl(
      {@JsonKey(name: 'State') this.state,
      @JsonKey(name: 'Code') this.code,
      @JsonKey(name: 'Message') this.message});

  factory _$HealthImpl.fromJson(Map<String, dynamic> json) =>
      _$$HealthImplFromJson(json);

  @override
  @JsonKey(name: 'State')
  final String? state;
  @override
  @JsonKey(name: 'Code')
  final int? code;
  @override
  @JsonKey(name: 'Message')
  final String? message;

  @override
  String toString() {
    return 'Health(state: $state, code: $code, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HealthImpl &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, state, code, message);

  /// Create a copy of Health
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HealthImplCopyWith<_$HealthImpl> get copyWith =>
      __$$HealthImplCopyWithImpl<_$HealthImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HealthImplToJson(
      this,
    );
  }
}

abstract class _Health implements Health {
  const factory _Health(
      {@JsonKey(name: 'State') final String? state,
      @JsonKey(name: 'Code') final int? code,
      @JsonKey(name: 'Message') final String? message}) = _$HealthImpl;

  factory _Health.fromJson(Map<String, dynamic> json) = _$HealthImpl.fromJson;

  @override
  @JsonKey(name: 'State')
  String? get state;
  @override
  @JsonKey(name: 'Code')
  int? get code;
  @override
  @JsonKey(name: 'Message')
  String? get message;

  /// Create a copy of Health
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HealthImplCopyWith<_$HealthImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PartialFile _$PartialFileFromJson(Map<String, dynamic> json) {
  return _PartialFile.fromJson(json);
}

/// @nodoc
mixin _$PartialFile {
  @JsonKey(name: 'Name')
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'Started')
  String get started => throw _privateConstructorUsedError;
  @JsonKey(name: 'DeclaredSize')
  int get declaredSize => throw _privateConstructorUsedError;
  @JsonKey(name: 'Received')
  int get received => throw _privateConstructorUsedError;
  @JsonKey(name: 'PartialPath')
  String? get partialPath => throw _privateConstructorUsedError;
  @JsonKey(name: 'FinalPath')
  String? get finalPath => throw _privateConstructorUsedError;
  @JsonKey(name: 'Done')
  bool? get done => throw _privateConstructorUsedError;

  /// Serializes this PartialFile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PartialFile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PartialFileCopyWith<PartialFile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PartialFileCopyWith<$Res> {
  factory $PartialFileCopyWith(
          PartialFile value, $Res Function(PartialFile) then) =
      _$PartialFileCopyWithImpl<$Res, PartialFile>;
  @useResult
  $Res call(
      {@JsonKey(name: 'Name') String name,
      @JsonKey(name: 'Started') String started,
      @JsonKey(name: 'DeclaredSize') int declaredSize,
      @JsonKey(name: 'Received') int received,
      @JsonKey(name: 'PartialPath') String? partialPath,
      @JsonKey(name: 'FinalPath') String? finalPath,
      @JsonKey(name: 'Done') bool? done});
}

/// @nodoc
class _$PartialFileCopyWithImpl<$Res, $Val extends PartialFile>
    implements $PartialFileCopyWith<$Res> {
  _$PartialFileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PartialFile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? started = null,
    Object? declaredSize = null,
    Object? received = null,
    Object? partialPath = freezed,
    Object? finalPath = freezed,
    Object? done = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      started: null == started
          ? _value.started
          : started // ignore: cast_nullable_to_non_nullable
              as String,
      declaredSize: null == declaredSize
          ? _value.declaredSize
          : declaredSize // ignore: cast_nullable_to_non_nullable
              as int,
      received: null == received
          ? _value.received
          : received // ignore: cast_nullable_to_non_nullable
              as int,
      partialPath: freezed == partialPath
          ? _value.partialPath
          : partialPath // ignore: cast_nullable_to_non_nullable
              as String?,
      finalPath: freezed == finalPath
          ? _value.finalPath
          : finalPath // ignore: cast_nullable_to_non_nullable
              as String?,
      done: freezed == done
          ? _value.done
          : done // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PartialFileImplCopyWith<$Res>
    implements $PartialFileCopyWith<$Res> {
  factory _$$PartialFileImplCopyWith(
          _$PartialFileImpl value, $Res Function(_$PartialFileImpl) then) =
      __$$PartialFileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Name') String name,
      @JsonKey(name: 'Started') String started,
      @JsonKey(name: 'DeclaredSize') int declaredSize,
      @JsonKey(name: 'Received') int received,
      @JsonKey(name: 'PartialPath') String? partialPath,
      @JsonKey(name: 'FinalPath') String? finalPath,
      @JsonKey(name: 'Done') bool? done});
}

/// @nodoc
class __$$PartialFileImplCopyWithImpl<$Res>
    extends _$PartialFileCopyWithImpl<$Res, _$PartialFileImpl>
    implements _$$PartialFileImplCopyWith<$Res> {
  __$$PartialFileImplCopyWithImpl(
      _$PartialFileImpl _value, $Res Function(_$PartialFileImpl) _then)
      : super(_value, _then);

  /// Create a copy of PartialFile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? started = null,
    Object? declaredSize = null,
    Object? received = null,
    Object? partialPath = freezed,
    Object? finalPath = freezed,
    Object? done = freezed,
  }) {
    return _then(_$PartialFileImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      started: null == started
          ? _value.started
          : started // ignore: cast_nullable_to_non_nullable
              as String,
      declaredSize: null == declaredSize
          ? _value.declaredSize
          : declaredSize // ignore: cast_nullable_to_non_nullable
              as int,
      received: null == received
          ? _value.received
          : received // ignore: cast_nullable_to_non_nullable
              as int,
      partialPath: freezed == partialPath
          ? _value.partialPath
          : partialPath // ignore: cast_nullable_to_non_nullable
              as String?,
      finalPath: freezed == finalPath
          ? _value.finalPath
          : finalPath // ignore: cast_nullable_to_non_nullable
              as String?,
      done: freezed == done
          ? _value.done
          : done // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PartialFileImpl implements _PartialFile {
  const _$PartialFileImpl(
      {@JsonKey(name: 'Name') required this.name,
      @JsonKey(name: 'Started') required this.started,
      @JsonKey(name: 'DeclaredSize') required this.declaredSize,
      @JsonKey(name: 'Received') required this.received,
      @JsonKey(name: 'PartialPath') this.partialPath,
      @JsonKey(name: 'FinalPath') this.finalPath,
      @JsonKey(name: 'Done') this.done});

  factory _$PartialFileImpl.fromJson(Map<String, dynamic> json) =>
      _$$PartialFileImplFromJson(json);

  @override
  @JsonKey(name: 'Name')
  final String name;
  @override
  @JsonKey(name: 'Started')
  final String started;
  @override
  @JsonKey(name: 'DeclaredSize')
  final int declaredSize;
  @override
  @JsonKey(name: 'Received')
  final int received;
  @override
  @JsonKey(name: 'PartialPath')
  final String? partialPath;
  @override
  @JsonKey(name: 'FinalPath')
  final String? finalPath;
  @override
  @JsonKey(name: 'Done')
  final bool? done;

  @override
  String toString() {
    return 'PartialFile(name: $name, started: $started, declaredSize: $declaredSize, received: $received, partialPath: $partialPath, finalPath: $finalPath, done: $done)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PartialFileImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.started, started) || other.started == started) &&
            (identical(other.declaredSize, declaredSize) ||
                other.declaredSize == declaredSize) &&
            (identical(other.received, received) ||
                other.received == received) &&
            (identical(other.partialPath, partialPath) ||
                other.partialPath == partialPath) &&
            (identical(other.finalPath, finalPath) ||
                other.finalPath == finalPath) &&
            (identical(other.done, done) || other.done == done));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, started, declaredSize,
      received, partialPath, finalPath, done);

  /// Create a copy of PartialFile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PartialFileImplCopyWith<_$PartialFileImpl> get copyWith =>
      __$$PartialFileImplCopyWithImpl<_$PartialFileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PartialFileImplToJson(
      this,
    );
  }
}

abstract class _PartialFile implements PartialFile {
  const factory _PartialFile(
      {@JsonKey(name: 'Name') required final String name,
      @JsonKey(name: 'Started') required final String started,
      @JsonKey(name: 'DeclaredSize') required final int declaredSize,
      @JsonKey(name: 'Received') required final int received,
      @JsonKey(name: 'PartialPath') final String? partialPath,
      @JsonKey(name: 'FinalPath') final String? finalPath,
      @JsonKey(name: 'Done') final bool? done}) = _$PartialFileImpl;

  factory _PartialFile.fromJson(Map<String, dynamic> json) =
      _$PartialFileImpl.fromJson;

  @override
  @JsonKey(name: 'Name')
  String get name;
  @override
  @JsonKey(name: 'Started')
  String get started;
  @override
  @JsonKey(name: 'DeclaredSize')
  int get declaredSize;
  @override
  @JsonKey(name: 'Received')
  int get received;
  @override
  @JsonKey(name: 'PartialPath')
  String? get partialPath;
  @override
  @JsonKey(name: 'FinalPath')
  String? get finalPath;
  @override
  @JsonKey(name: 'Done')
  bool? get done;

  /// Create a copy of PartialFile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PartialFileImplCopyWith<_$PartialFileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EngineStatus _$EngineStatusFromJson(Map<String, dynamic> json) {
  return _EngineStatus.fromJson(json);
}

/// @nodoc
mixin _$EngineStatus {
  @JsonKey(name: 'RBytes')
  int get rBytes => throw _privateConstructorUsedError;
  @JsonKey(name: 'WBytes')
  int get wBytes => throw _privateConstructorUsedError;
  @JsonKey(name: 'NumLive')
  int get numLive => throw _privateConstructorUsedError;
  @JsonKey(name: 'LivePeers')
  Map<String, PeerStatusLite> get livePeers =>
      throw _privateConstructorUsedError;

  /// Serializes this EngineStatus to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EngineStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EngineStatusCopyWith<EngineStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EngineStatusCopyWith<$Res> {
  factory $EngineStatusCopyWith(
          EngineStatus value, $Res Function(EngineStatus) then) =
      _$EngineStatusCopyWithImpl<$Res, EngineStatus>;
  @useResult
  $Res call(
      {@JsonKey(name: 'RBytes') int rBytes,
      @JsonKey(name: 'WBytes') int wBytes,
      @JsonKey(name: 'NumLive') int numLive,
      @JsonKey(name: 'LivePeers') Map<String, PeerStatusLite> livePeers});
}

/// @nodoc
class _$EngineStatusCopyWithImpl<$Res, $Val extends EngineStatus>
    implements $EngineStatusCopyWith<$Res> {
  _$EngineStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EngineStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rBytes = null,
    Object? wBytes = null,
    Object? numLive = null,
    Object? livePeers = null,
  }) {
    return _then(_value.copyWith(
      rBytes: null == rBytes
          ? _value.rBytes
          : rBytes // ignore: cast_nullable_to_non_nullable
              as int,
      wBytes: null == wBytes
          ? _value.wBytes
          : wBytes // ignore: cast_nullable_to_non_nullable
              as int,
      numLive: null == numLive
          ? _value.numLive
          : numLive // ignore: cast_nullable_to_non_nullable
              as int,
      livePeers: null == livePeers
          ? _value.livePeers
          : livePeers // ignore: cast_nullable_to_non_nullable
              as Map<String, PeerStatusLite>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EngineStatusImplCopyWith<$Res>
    implements $EngineStatusCopyWith<$Res> {
  factory _$$EngineStatusImplCopyWith(
          _$EngineStatusImpl value, $Res Function(_$EngineStatusImpl) then) =
      __$$EngineStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'RBytes') int rBytes,
      @JsonKey(name: 'WBytes') int wBytes,
      @JsonKey(name: 'NumLive') int numLive,
      @JsonKey(name: 'LivePeers') Map<String, PeerStatusLite> livePeers});
}

/// @nodoc
class __$$EngineStatusImplCopyWithImpl<$Res>
    extends _$EngineStatusCopyWithImpl<$Res, _$EngineStatusImpl>
    implements _$$EngineStatusImplCopyWith<$Res> {
  __$$EngineStatusImplCopyWithImpl(
      _$EngineStatusImpl _value, $Res Function(_$EngineStatusImpl) _then)
      : super(_value, _then);

  /// Create a copy of EngineStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rBytes = null,
    Object? wBytes = null,
    Object? numLive = null,
    Object? livePeers = null,
  }) {
    return _then(_$EngineStatusImpl(
      rBytes: null == rBytes
          ? _value.rBytes
          : rBytes // ignore: cast_nullable_to_non_nullable
              as int,
      wBytes: null == wBytes
          ? _value.wBytes
          : wBytes // ignore: cast_nullable_to_non_nullable
              as int,
      numLive: null == numLive
          ? _value.numLive
          : numLive // ignore: cast_nullable_to_non_nullable
              as int,
      livePeers: null == livePeers
          ? _value._livePeers
          : livePeers // ignore: cast_nullable_to_non_nullable
              as Map<String, PeerStatusLite>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EngineStatusImpl implements _EngineStatus {
  const _$EngineStatusImpl(
      {@JsonKey(name: 'RBytes') required this.rBytes,
      @JsonKey(name: 'WBytes') required this.wBytes,
      @JsonKey(name: 'NumLive') required this.numLive,
      @JsonKey(name: 'LivePeers')
      required final Map<String, PeerStatusLite> livePeers})
      : _livePeers = livePeers;

  factory _$EngineStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$EngineStatusImplFromJson(json);

  @override
  @JsonKey(name: 'RBytes')
  final int rBytes;
  @override
  @JsonKey(name: 'WBytes')
  final int wBytes;
  @override
  @JsonKey(name: 'NumLive')
  final int numLive;
  final Map<String, PeerStatusLite> _livePeers;
  @override
  @JsonKey(name: 'LivePeers')
  Map<String, PeerStatusLite> get livePeers {
    if (_livePeers is EqualUnmodifiableMapView) return _livePeers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_livePeers);
  }

  @override
  String toString() {
    return 'EngineStatus(rBytes: $rBytes, wBytes: $wBytes, numLive: $numLive, livePeers: $livePeers)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EngineStatusImpl &&
            (identical(other.rBytes, rBytes) || other.rBytes == rBytes) &&
            (identical(other.wBytes, wBytes) || other.wBytes == wBytes) &&
            (identical(other.numLive, numLive) || other.numLive == numLive) &&
            const DeepCollectionEquality()
                .equals(other._livePeers, _livePeers));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, rBytes, wBytes, numLive,
      const DeepCollectionEquality().hash(_livePeers));

  /// Create a copy of EngineStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EngineStatusImplCopyWith<_$EngineStatusImpl> get copyWith =>
      __$$EngineStatusImplCopyWithImpl<_$EngineStatusImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EngineStatusImplToJson(
      this,
    );
  }
}

abstract class _EngineStatus implements EngineStatus {
  const factory _EngineStatus(
          {@JsonKey(name: 'RBytes') required final int rBytes,
          @JsonKey(name: 'WBytes') required final int wBytes,
          @JsonKey(name: 'NumLive') required final int numLive,
          @JsonKey(name: 'LivePeers')
          required final Map<String, PeerStatusLite> livePeers}) =
      _$EngineStatusImpl;

  factory _EngineStatus.fromJson(Map<String, dynamic> json) =
      _$EngineStatusImpl.fromJson;

  @override
  @JsonKey(name: 'RBytes')
  int get rBytes;
  @override
  @JsonKey(name: 'WBytes')
  int get wBytes;
  @override
  @JsonKey(name: 'NumLive')
  int get numLive;
  @override
  @JsonKey(name: 'LivePeers')
  Map<String, PeerStatusLite> get livePeers;

  /// Create a copy of EngineStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EngineStatusImplCopyWith<_$EngineStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OutgoingFile _$OutgoingFileFromJson(Map<String, dynamic> json) {
  return _OutgoingFile.fromJson(json);
}

/// @nodoc
mixin _$OutgoingFile {
  @JsonKey(name: 'ID')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'Name')
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'PeerID')
  String get peerID => throw _privateConstructorUsedError;
  @JsonKey(name: 'Started')
  String? get started => throw _privateConstructorUsedError;
  @JsonKey(name: 'DeclaredSize')
  int get declaredSize => throw _privateConstructorUsedError;
  @JsonKey(name: 'Sent')
  int get sent => throw _privateConstructorUsedError;
  @JsonKey(name: 'PartialPath')
  String? get partialPath => throw _privateConstructorUsedError;
  @JsonKey(name: 'FinalPath')
  String? get finalPath => throw _privateConstructorUsedError;
  @JsonKey(name: 'Finished')
  bool get finished => throw _privateConstructorUsedError;
  @JsonKey(name: 'Succeeded')
  bool get succeeded => throw _privateConstructorUsedError;
  @JsonKey(name: 'Path')
  String? get path => throw _privateConstructorUsedError;

  /// Serializes this OutgoingFile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OutgoingFile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OutgoingFileCopyWith<OutgoingFile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OutgoingFileCopyWith<$Res> {
  factory $OutgoingFileCopyWith(
          OutgoingFile value, $Res Function(OutgoingFile) then) =
      _$OutgoingFileCopyWithImpl<$Res, OutgoingFile>;
  @useResult
  $Res call(
      {@JsonKey(name: 'ID') String id,
      @JsonKey(name: 'Name') String name,
      @JsonKey(name: 'PeerID') String peerID,
      @JsonKey(name: 'Started') String? started,
      @JsonKey(name: 'DeclaredSize') int declaredSize,
      @JsonKey(name: 'Sent') int sent,
      @JsonKey(name: 'PartialPath') String? partialPath,
      @JsonKey(name: 'FinalPath') String? finalPath,
      @JsonKey(name: 'Finished') bool finished,
      @JsonKey(name: 'Succeeded') bool succeeded,
      @JsonKey(name: 'Path') String? path});
}

/// @nodoc
class _$OutgoingFileCopyWithImpl<$Res, $Val extends OutgoingFile>
    implements $OutgoingFileCopyWith<$Res> {
  _$OutgoingFileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OutgoingFile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? peerID = null,
    Object? started = freezed,
    Object? declaredSize = null,
    Object? sent = null,
    Object? partialPath = freezed,
    Object? finalPath = freezed,
    Object? finished = null,
    Object? succeeded = null,
    Object? path = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      peerID: null == peerID
          ? _value.peerID
          : peerID // ignore: cast_nullable_to_non_nullable
              as String,
      started: freezed == started
          ? _value.started
          : started // ignore: cast_nullable_to_non_nullable
              as String?,
      declaredSize: null == declaredSize
          ? _value.declaredSize
          : declaredSize // ignore: cast_nullable_to_non_nullable
              as int,
      sent: null == sent
          ? _value.sent
          : sent // ignore: cast_nullable_to_non_nullable
              as int,
      partialPath: freezed == partialPath
          ? _value.partialPath
          : partialPath // ignore: cast_nullable_to_non_nullable
              as String?,
      finalPath: freezed == finalPath
          ? _value.finalPath
          : finalPath // ignore: cast_nullable_to_non_nullable
              as String?,
      finished: null == finished
          ? _value.finished
          : finished // ignore: cast_nullable_to_non_nullable
              as bool,
      succeeded: null == succeeded
          ? _value.succeeded
          : succeeded // ignore: cast_nullable_to_non_nullable
              as bool,
      path: freezed == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OutgoingFileImplCopyWith<$Res>
    implements $OutgoingFileCopyWith<$Res> {
  factory _$$OutgoingFileImplCopyWith(
          _$OutgoingFileImpl value, $Res Function(_$OutgoingFileImpl) then) =
      __$$OutgoingFileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'ID') String id,
      @JsonKey(name: 'Name') String name,
      @JsonKey(name: 'PeerID') String peerID,
      @JsonKey(name: 'Started') String? started,
      @JsonKey(name: 'DeclaredSize') int declaredSize,
      @JsonKey(name: 'Sent') int sent,
      @JsonKey(name: 'PartialPath') String? partialPath,
      @JsonKey(name: 'FinalPath') String? finalPath,
      @JsonKey(name: 'Finished') bool finished,
      @JsonKey(name: 'Succeeded') bool succeeded,
      @JsonKey(name: 'Path') String? path});
}

/// @nodoc
class __$$OutgoingFileImplCopyWithImpl<$Res>
    extends _$OutgoingFileCopyWithImpl<$Res, _$OutgoingFileImpl>
    implements _$$OutgoingFileImplCopyWith<$Res> {
  __$$OutgoingFileImplCopyWithImpl(
      _$OutgoingFileImpl _value, $Res Function(_$OutgoingFileImpl) _then)
      : super(_value, _then);

  /// Create a copy of OutgoingFile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? peerID = null,
    Object? started = freezed,
    Object? declaredSize = null,
    Object? sent = null,
    Object? partialPath = freezed,
    Object? finalPath = freezed,
    Object? finished = null,
    Object? succeeded = null,
    Object? path = freezed,
  }) {
    return _then(_$OutgoingFileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      peerID: null == peerID
          ? _value.peerID
          : peerID // ignore: cast_nullable_to_non_nullable
              as String,
      started: freezed == started
          ? _value.started
          : started // ignore: cast_nullable_to_non_nullable
              as String?,
      declaredSize: null == declaredSize
          ? _value.declaredSize
          : declaredSize // ignore: cast_nullable_to_non_nullable
              as int,
      sent: null == sent
          ? _value.sent
          : sent // ignore: cast_nullable_to_non_nullable
              as int,
      partialPath: freezed == partialPath
          ? _value.partialPath
          : partialPath // ignore: cast_nullable_to_non_nullable
              as String?,
      finalPath: freezed == finalPath
          ? _value.finalPath
          : finalPath // ignore: cast_nullable_to_non_nullable
              as String?,
      finished: null == finished
          ? _value.finished
          : finished // ignore: cast_nullable_to_non_nullable
              as bool,
      succeeded: null == succeeded
          ? _value.succeeded
          : succeeded // ignore: cast_nullable_to_non_nullable
              as bool,
      path: freezed == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OutgoingFileImpl extends _OutgoingFile {
  const _$OutgoingFileImpl(
      {@JsonKey(name: 'ID') this.id = '',
      @JsonKey(name: 'Name') required this.name,
      @JsonKey(name: 'PeerID') this.peerID = '',
      @JsonKey(name: 'Started') this.started,
      @JsonKey(name: 'DeclaredSize') required this.declaredSize,
      @JsonKey(name: 'Sent') this.sent = 0,
      @JsonKey(name: 'PartialPath') this.partialPath,
      @JsonKey(name: 'FinalPath') this.finalPath,
      @JsonKey(name: 'Finished') this.finished = false,
      @JsonKey(name: 'Succeeded') this.succeeded = false,
      @JsonKey(name: 'Path') this.path})
      : super._();

  factory _$OutgoingFileImpl.fromJson(Map<String, dynamic> json) =>
      _$$OutgoingFileImplFromJson(json);

  @override
  @JsonKey(name: 'ID')
  final String id;
  @override
  @JsonKey(name: 'Name')
  final String name;
  @override
  @JsonKey(name: 'PeerID')
  final String peerID;
  @override
  @JsonKey(name: 'Started')
  final String? started;
  @override
  @JsonKey(name: 'DeclaredSize')
  final int declaredSize;
  @override
  @JsonKey(name: 'Sent')
  final int sent;
  @override
  @JsonKey(name: 'PartialPath')
  final String? partialPath;
  @override
  @JsonKey(name: 'FinalPath')
  final String? finalPath;
  @override
  @JsonKey(name: 'Finished')
  final bool finished;
  @override
  @JsonKey(name: 'Succeeded')
  final bool succeeded;
  @override
  @JsonKey(name: 'Path')
  final String? path;

  @override
  String toString() {
    return 'OutgoingFile(id: $id, name: $name, peerID: $peerID, started: $started, declaredSize: $declaredSize, sent: $sent, partialPath: $partialPath, finalPath: $finalPath, finished: $finished, succeeded: $succeeded, path: $path)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OutgoingFileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.peerID, peerID) || other.peerID == peerID) &&
            (identical(other.started, started) || other.started == started) &&
            (identical(other.declaredSize, declaredSize) ||
                other.declaredSize == declaredSize) &&
            (identical(other.sent, sent) || other.sent == sent) &&
            (identical(other.partialPath, partialPath) ||
                other.partialPath == partialPath) &&
            (identical(other.finalPath, finalPath) ||
                other.finalPath == finalPath) &&
            (identical(other.finished, finished) ||
                other.finished == finished) &&
            (identical(other.succeeded, succeeded) ||
                other.succeeded == succeeded) &&
            (identical(other.path, path) || other.path == path));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, peerID, started,
      declaredSize, sent, partialPath, finalPath, finished, succeeded, path);

  /// Create a copy of OutgoingFile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OutgoingFileImplCopyWith<_$OutgoingFileImpl> get copyWith =>
      __$$OutgoingFileImplCopyWithImpl<_$OutgoingFileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OutgoingFileImplToJson(
      this,
    );
  }
}

abstract class _OutgoingFile extends OutgoingFile {
  const factory _OutgoingFile(
      {@JsonKey(name: 'ID') final String id,
      @JsonKey(name: 'Name') required final String name,
      @JsonKey(name: 'PeerID') final String peerID,
      @JsonKey(name: 'Started') final String? started,
      @JsonKey(name: 'DeclaredSize') required final int declaredSize,
      @JsonKey(name: 'Sent') final int sent,
      @JsonKey(name: 'PartialPath') final String? partialPath,
      @JsonKey(name: 'FinalPath') final String? finalPath,
      @JsonKey(name: 'Finished') final bool finished,
      @JsonKey(name: 'Succeeded') final bool succeeded,
      @JsonKey(name: 'Path') final String? path}) = _$OutgoingFileImpl;
  const _OutgoingFile._() : super._();

  factory _OutgoingFile.fromJson(Map<String, dynamic> json) =
      _$OutgoingFileImpl.fromJson;

  @override
  @JsonKey(name: 'ID')
  String get id;
  @override
  @JsonKey(name: 'Name')
  String get name;
  @override
  @JsonKey(name: 'PeerID')
  String get peerID;
  @override
  @JsonKey(name: 'Started')
  String? get started;
  @override
  @JsonKey(name: 'DeclaredSize')
  int get declaredSize;
  @override
  @JsonKey(name: 'Sent')
  int get sent;
  @override
  @JsonKey(name: 'PartialPath')
  String? get partialPath;
  @override
  @JsonKey(name: 'FinalPath')
  String? get finalPath;
  @override
  @JsonKey(name: 'Finished')
  bool get finished;
  @override
  @JsonKey(name: 'Succeeded')
  bool get succeeded;
  @override
  @JsonKey(name: 'Path')
  String? get path;

  /// Create a copy of OutgoingFile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OutgoingFileImplCopyWith<_$OutgoingFileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AutoUpdatePrefs _$AutoUpdatePrefsFromJson(Map<String, dynamic> json) {
  return _AutoUpdatePrefs.fromJson(json);
}

/// @nodoc
mixin _$AutoUpdatePrefs {
  @JsonKey(name: 'Check')
  bool? get check => throw _privateConstructorUsedError;
  @JsonKey(name: 'Apply')
  bool? get apply => throw _privateConstructorUsedError;

  /// Serializes this AutoUpdatePrefs to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AutoUpdatePrefs
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AutoUpdatePrefsCopyWith<AutoUpdatePrefs> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AutoUpdatePrefsCopyWith<$Res> {
  factory $AutoUpdatePrefsCopyWith(
          AutoUpdatePrefs value, $Res Function(AutoUpdatePrefs) then) =
      _$AutoUpdatePrefsCopyWithImpl<$Res, AutoUpdatePrefs>;
  @useResult
  $Res call(
      {@JsonKey(name: 'Check') bool? check,
      @JsonKey(name: 'Apply') bool? apply});
}

/// @nodoc
class _$AutoUpdatePrefsCopyWithImpl<$Res, $Val extends AutoUpdatePrefs>
    implements $AutoUpdatePrefsCopyWith<$Res> {
  _$AutoUpdatePrefsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AutoUpdatePrefs
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? check = freezed,
    Object? apply = freezed,
  }) {
    return _then(_value.copyWith(
      check: freezed == check
          ? _value.check
          : check // ignore: cast_nullable_to_non_nullable
              as bool?,
      apply: freezed == apply
          ? _value.apply
          : apply // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AutoUpdatePrefsImplCopyWith<$Res>
    implements $AutoUpdatePrefsCopyWith<$Res> {
  factory _$$AutoUpdatePrefsImplCopyWith(_$AutoUpdatePrefsImpl value,
          $Res Function(_$AutoUpdatePrefsImpl) then) =
      __$$AutoUpdatePrefsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Check') bool? check,
      @JsonKey(name: 'Apply') bool? apply});
}

/// @nodoc
class __$$AutoUpdatePrefsImplCopyWithImpl<$Res>
    extends _$AutoUpdatePrefsCopyWithImpl<$Res, _$AutoUpdatePrefsImpl>
    implements _$$AutoUpdatePrefsImplCopyWith<$Res> {
  __$$AutoUpdatePrefsImplCopyWithImpl(
      _$AutoUpdatePrefsImpl _value, $Res Function(_$AutoUpdatePrefsImpl) _then)
      : super(_value, _then);

  /// Create a copy of AutoUpdatePrefs
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? check = freezed,
    Object? apply = freezed,
  }) {
    return _then(_$AutoUpdatePrefsImpl(
      check: freezed == check
          ? _value.check
          : check // ignore: cast_nullable_to_non_nullable
              as bool?,
      apply: freezed == apply
          ? _value.apply
          : apply // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AutoUpdatePrefsImpl implements _AutoUpdatePrefs {
  const _$AutoUpdatePrefsImpl(
      {@JsonKey(name: 'Check') this.check, @JsonKey(name: 'Apply') this.apply});

  factory _$AutoUpdatePrefsImpl.fromJson(Map<String, dynamic> json) =>
      _$$AutoUpdatePrefsImplFromJson(json);

  @override
  @JsonKey(name: 'Check')
  final bool? check;
  @override
  @JsonKey(name: 'Apply')
  final bool? apply;

  @override
  String toString() {
    return 'AutoUpdatePrefs(check: $check, apply: $apply)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AutoUpdatePrefsImpl &&
            (identical(other.check, check) || other.check == check) &&
            (identical(other.apply, apply) || other.apply == apply));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, check, apply);

  /// Create a copy of AutoUpdatePrefs
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AutoUpdatePrefsImplCopyWith<_$AutoUpdatePrefsImpl> get copyWith =>
      __$$AutoUpdatePrefsImplCopyWithImpl<_$AutoUpdatePrefsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AutoUpdatePrefsImplToJson(
      this,
    );
  }
}

abstract class _AutoUpdatePrefs implements AutoUpdatePrefs {
  const factory _AutoUpdatePrefs(
      {@JsonKey(name: 'Check') final bool? check,
      @JsonKey(name: 'Apply') final bool? apply}) = _$AutoUpdatePrefsImpl;

  factory _AutoUpdatePrefs.fromJson(Map<String, dynamic> json) =
      _$AutoUpdatePrefsImpl.fromJson;

  @override
  @JsonKey(name: 'Check')
  bool? get check;
  @override
  @JsonKey(name: 'Apply')
  bool? get apply;

  /// Create a copy of AutoUpdatePrefs
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AutoUpdatePrefsImplCopyWith<_$AutoUpdatePrefsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ClientVersion _$ClientVersionFromJson(Map<String, dynamic> json) {
  return _ClientVersion.fromJson(json);
}

/// @nodoc
mixin _$ClientVersion {
  @JsonKey(name: 'Major')
  String? get major => throw _privateConstructorUsedError;
  @JsonKey(name: 'Minor')
  String? get minor => throw _privateConstructorUsedError;
  @JsonKey(name: 'Patch')
  String? get patch => throw _privateConstructorUsedError;
  @JsonKey(name: 'Suffix')
  String? get suffix => throw _privateConstructorUsedError;
  @JsonKey(name: 'Candidate')
  bool? get candidate => throw _privateConstructorUsedError;

  /// Serializes this ClientVersion to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClientVersion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClientVersionCopyWith<ClientVersion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClientVersionCopyWith<$Res> {
  factory $ClientVersionCopyWith(
          ClientVersion value, $Res Function(ClientVersion) then) =
      _$ClientVersionCopyWithImpl<$Res, ClientVersion>;
  @useResult
  $Res call(
      {@JsonKey(name: 'Major') String? major,
      @JsonKey(name: 'Minor') String? minor,
      @JsonKey(name: 'Patch') String? patch,
      @JsonKey(name: 'Suffix') String? suffix,
      @JsonKey(name: 'Candidate') bool? candidate});
}

/// @nodoc
class _$ClientVersionCopyWithImpl<$Res, $Val extends ClientVersion>
    implements $ClientVersionCopyWith<$Res> {
  _$ClientVersionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClientVersion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? major = freezed,
    Object? minor = freezed,
    Object? patch = freezed,
    Object? suffix = freezed,
    Object? candidate = freezed,
  }) {
    return _then(_value.copyWith(
      major: freezed == major
          ? _value.major
          : major // ignore: cast_nullable_to_non_nullable
              as String?,
      minor: freezed == minor
          ? _value.minor
          : minor // ignore: cast_nullable_to_non_nullable
              as String?,
      patch: freezed == patch
          ? _value.patch
          : patch // ignore: cast_nullable_to_non_nullable
              as String?,
      suffix: freezed == suffix
          ? _value.suffix
          : suffix // ignore: cast_nullable_to_non_nullable
              as String?,
      candidate: freezed == candidate
          ? _value.candidate
          : candidate // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ClientVersionImplCopyWith<$Res>
    implements $ClientVersionCopyWith<$Res> {
  factory _$$ClientVersionImplCopyWith(
          _$ClientVersionImpl value, $Res Function(_$ClientVersionImpl) then) =
      __$$ClientVersionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Major') String? major,
      @JsonKey(name: 'Minor') String? minor,
      @JsonKey(name: 'Patch') String? patch,
      @JsonKey(name: 'Suffix') String? suffix,
      @JsonKey(name: 'Candidate') bool? candidate});
}

/// @nodoc
class __$$ClientVersionImplCopyWithImpl<$Res>
    extends _$ClientVersionCopyWithImpl<$Res, _$ClientVersionImpl>
    implements _$$ClientVersionImplCopyWith<$Res> {
  __$$ClientVersionImplCopyWithImpl(
      _$ClientVersionImpl _value, $Res Function(_$ClientVersionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClientVersion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? major = freezed,
    Object? minor = freezed,
    Object? patch = freezed,
    Object? suffix = freezed,
    Object? candidate = freezed,
  }) {
    return _then(_$ClientVersionImpl(
      major: freezed == major
          ? _value.major
          : major // ignore: cast_nullable_to_non_nullable
              as String?,
      minor: freezed == minor
          ? _value.minor
          : minor // ignore: cast_nullable_to_non_nullable
              as String?,
      patch: freezed == patch
          ? _value.patch
          : patch // ignore: cast_nullable_to_non_nullable
              as String?,
      suffix: freezed == suffix
          ? _value.suffix
          : suffix // ignore: cast_nullable_to_non_nullable
              as String?,
      candidate: freezed == candidate
          ? _value.candidate
          : candidate // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ClientVersionImpl implements _ClientVersion {
  const _$ClientVersionImpl(
      {@JsonKey(name: 'Major') this.major,
      @JsonKey(name: 'Minor') this.minor,
      @JsonKey(name: 'Patch') this.patch,
      @JsonKey(name: 'Suffix') this.suffix,
      @JsonKey(name: 'Candidate') this.candidate});

  factory _$ClientVersionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClientVersionImplFromJson(json);

  @override
  @JsonKey(name: 'Major')
  final String? major;
  @override
  @JsonKey(name: 'Minor')
  final String? minor;
  @override
  @JsonKey(name: 'Patch')
  final String? patch;
  @override
  @JsonKey(name: 'Suffix')
  final String? suffix;
  @override
  @JsonKey(name: 'Candidate')
  final bool? candidate;

  @override
  String toString() {
    return 'ClientVersion(major: $major, minor: $minor, patch: $patch, suffix: $suffix, candidate: $candidate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClientVersionImpl &&
            (identical(other.major, major) || other.major == major) &&
            (identical(other.minor, minor) || other.minor == minor) &&
            (identical(other.patch, patch) || other.patch == patch) &&
            (identical(other.suffix, suffix) || other.suffix == suffix) &&
            (identical(other.candidate, candidate) ||
                other.candidate == candidate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, major, minor, patch, suffix, candidate);

  /// Create a copy of ClientVersion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClientVersionImplCopyWith<_$ClientVersionImpl> get copyWith =>
      __$$ClientVersionImplCopyWithImpl<_$ClientVersionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClientVersionImplToJson(
      this,
    );
  }
}

abstract class _ClientVersion implements ClientVersion {
  const factory _ClientVersion(
      {@JsonKey(name: 'Major') final String? major,
      @JsonKey(name: 'Minor') final String? minor,
      @JsonKey(name: 'Patch') final String? patch,
      @JsonKey(name: 'Suffix') final String? suffix,
      @JsonKey(name: 'Candidate') final bool? candidate}) = _$ClientVersionImpl;

  factory _ClientVersion.fromJson(Map<String, dynamic> json) =
      _$ClientVersionImpl.fromJson;

  @override
  @JsonKey(name: 'Major')
  String? get major;
  @override
  @JsonKey(name: 'Minor')
  String? get minor;
  @override
  @JsonKey(name: 'Patch')
  String? get patch;
  @override
  @JsonKey(name: 'Suffix')
  String? get suffix;
  @override
  @JsonKey(name: 'Candidate')
  bool? get candidate;

  /// Create a copy of ClientVersion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClientVersionImplCopyWith<_$ClientVersionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PeerSet {
  UserProfile? get user => throw _privateConstructorUsedError;
  List<Node> get peers => throw _privateConstructorUsedError;

  /// Create a copy of PeerSet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PeerSetCopyWith<PeerSet> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PeerSetCopyWith<$Res> {
  factory $PeerSetCopyWith(PeerSet value, $Res Function(PeerSet) then) =
      _$PeerSetCopyWithImpl<$Res, PeerSet>;
  @useResult
  $Res call({UserProfile? user, List<Node> peers});

  $UserProfileCopyWith<$Res>? get user;
}

/// @nodoc
class _$PeerSetCopyWithImpl<$Res, $Val extends PeerSet>
    implements $PeerSetCopyWith<$Res> {
  _$PeerSetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PeerSet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? user = freezed,
    Object? peers = null,
  }) {
    return _then(_value.copyWith(
      user: freezed == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserProfile?,
      peers: null == peers
          ? _value.peers
          : peers // ignore: cast_nullable_to_non_nullable
              as List<Node>,
    ) as $Val);
  }

  /// Create a copy of PeerSet
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserProfileCopyWith<$Res>? get user {
    if (_value.user == null) {
      return null;
    }

    return $UserProfileCopyWith<$Res>(_value.user!, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PeerSetImplCopyWith<$Res> implements $PeerSetCopyWith<$Res> {
  factory _$$PeerSetImplCopyWith(
          _$PeerSetImpl value, $Res Function(_$PeerSetImpl) then) =
      __$$PeerSetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({UserProfile? user, List<Node> peers});

  @override
  $UserProfileCopyWith<$Res>? get user;
}

/// @nodoc
class __$$PeerSetImplCopyWithImpl<$Res>
    extends _$PeerSetCopyWithImpl<$Res, _$PeerSetImpl>
    implements _$$PeerSetImplCopyWith<$Res> {
  __$$PeerSetImplCopyWithImpl(
      _$PeerSetImpl _value, $Res Function(_$PeerSetImpl) _then)
      : super(_value, _then);

  /// Create a copy of PeerSet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? user = freezed,
    Object? peers = null,
  }) {
    return _then(_$PeerSetImpl(
      user: freezed == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserProfile?,
      peers: null == peers
          ? _value._peers
          : peers // ignore: cast_nullable_to_non_nullable
              as List<Node>,
    ));
  }
}

/// @nodoc

class _$PeerSetImpl implements _PeerSet {
  const _$PeerSetImpl({this.user, required final List<Node> peers})
      : _peers = peers;

  @override
  final UserProfile? user;
  final List<Node> _peers;
  @override
  List<Node> get peers {
    if (_peers is EqualUnmodifiableListView) return _peers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_peers);
  }

  @override
  String toString() {
    return 'PeerSet(user: $user, peers: $peers)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PeerSetImpl &&
            (identical(other.user, user) || other.user == user) &&
            const DeepCollectionEquality().equals(other._peers, _peers));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, user, const DeepCollectionEquality().hash(_peers));

  /// Create a copy of PeerSet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PeerSetImplCopyWith<_$PeerSetImpl> get copyWith =>
      __$$PeerSetImplCopyWithImpl<_$PeerSetImpl>(this, _$identity);
}

abstract class _PeerSet implements PeerSet {
  const factory _PeerSet(
      {final UserProfile? user,
      required final List<Node> peers}) = _$PeerSetImpl;

  @override
  UserProfile? get user;
  @override
  List<Node> get peers;

  /// Create a copy of PeerSet
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PeerSetImplCopyWith<_$PeerSetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Hostinfo _$HostinfoFromJson(Map<String, dynamic> json) {
  return _Hostinfo.fromJson(json);
}

/// @nodoc
mixin _$Hostinfo {
  @JsonKey(name: 'IPNVersion')
  String? get ipnVersion => throw _privateConstructorUsedError;
  @JsonKey(name: 'FrontendLogID')
  String? get frontendLogID => throw _privateConstructorUsedError;
  @JsonKey(name: 'BackendLogID')
  String? get backendLogID => throw _privateConstructorUsedError;
  @JsonKey(name: 'OS')
  String? get os => throw _privateConstructorUsedError;
  @JsonKey(name: 'OSVersion')
  String? get osVersion => throw _privateConstructorUsedError;
  @JsonKey(name: 'Env')
  String? get env => throw _privateConstructorUsedError;
  @JsonKey(name: 'Distro')
  String? get distro => throw _privateConstructorUsedError;
  @JsonKey(name: 'DistroVersion')
  String? get distroVersion => throw _privateConstructorUsedError;
  @JsonKey(name: 'DistroCodeName')
  String? get distroCodeName => throw _privateConstructorUsedError;
  @JsonKey(name: 'Desktop')
  bool? get desktop => throw _privateConstructorUsedError;
  @JsonKey(name: 'Package')
  String? get package => throw _privateConstructorUsedError;
  @JsonKey(name: 'DeviceModel')
  String? get deviceModel => throw _privateConstructorUsedError;
  @JsonKey(name: 'ShareeNode')
  bool? get shareeNode => throw _privateConstructorUsedError;
  @JsonKey(name: 'Hostname')
  String? get hostname => throw _privateConstructorUsedError;
  @JsonKey(name: 'ShieldsUp')
  bool? get shieldsUp => throw _privateConstructorUsedError;
  @JsonKey(name: 'NoLogsNoSupport')
  bool? get noLogsNoSupport => throw _privateConstructorUsedError;
  @JsonKey(name: 'Machine')
  String? get machine => throw _privateConstructorUsedError;
  @JsonKey(name: 'RoutableIPs')
  List<String>? get routableIPs => throw _privateConstructorUsedError;
  @JsonKey(name: 'Services')
  List<Service>? get services => throw _privateConstructorUsedError;
  @JsonKey(name: 'Location')
  Location? get location => throw _privateConstructorUsedError;

  /// Serializes this Hostinfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Hostinfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HostinfoCopyWith<Hostinfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HostinfoCopyWith<$Res> {
  factory $HostinfoCopyWith(Hostinfo value, $Res Function(Hostinfo) then) =
      _$HostinfoCopyWithImpl<$Res, Hostinfo>;
  @useResult
  $Res call(
      {@JsonKey(name: 'IPNVersion') String? ipnVersion,
      @JsonKey(name: 'FrontendLogID') String? frontendLogID,
      @JsonKey(name: 'BackendLogID') String? backendLogID,
      @JsonKey(name: 'OS') String? os,
      @JsonKey(name: 'OSVersion') String? osVersion,
      @JsonKey(name: 'Env') String? env,
      @JsonKey(name: 'Distro') String? distro,
      @JsonKey(name: 'DistroVersion') String? distroVersion,
      @JsonKey(name: 'DistroCodeName') String? distroCodeName,
      @JsonKey(name: 'Desktop') bool? desktop,
      @JsonKey(name: 'Package') String? package,
      @JsonKey(name: 'DeviceModel') String? deviceModel,
      @JsonKey(name: 'ShareeNode') bool? shareeNode,
      @JsonKey(name: 'Hostname') String? hostname,
      @JsonKey(name: 'ShieldsUp') bool? shieldsUp,
      @JsonKey(name: 'NoLogsNoSupport') bool? noLogsNoSupport,
      @JsonKey(name: 'Machine') String? machine,
      @JsonKey(name: 'RoutableIPs') List<String>? routableIPs,
      @JsonKey(name: 'Services') List<Service>? services,
      @JsonKey(name: 'Location') Location? location});

  $LocationCopyWith<$Res>? get location;
}

/// @nodoc
class _$HostinfoCopyWithImpl<$Res, $Val extends Hostinfo>
    implements $HostinfoCopyWith<$Res> {
  _$HostinfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Hostinfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ipnVersion = freezed,
    Object? frontendLogID = freezed,
    Object? backendLogID = freezed,
    Object? os = freezed,
    Object? osVersion = freezed,
    Object? env = freezed,
    Object? distro = freezed,
    Object? distroVersion = freezed,
    Object? distroCodeName = freezed,
    Object? desktop = freezed,
    Object? package = freezed,
    Object? deviceModel = freezed,
    Object? shareeNode = freezed,
    Object? hostname = freezed,
    Object? shieldsUp = freezed,
    Object? noLogsNoSupport = freezed,
    Object? machine = freezed,
    Object? routableIPs = freezed,
    Object? services = freezed,
    Object? location = freezed,
  }) {
    return _then(_value.copyWith(
      ipnVersion: freezed == ipnVersion
          ? _value.ipnVersion
          : ipnVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      frontendLogID: freezed == frontendLogID
          ? _value.frontendLogID
          : frontendLogID // ignore: cast_nullable_to_non_nullable
              as String?,
      backendLogID: freezed == backendLogID
          ? _value.backendLogID
          : backendLogID // ignore: cast_nullable_to_non_nullable
              as String?,
      os: freezed == os
          ? _value.os
          : os // ignore: cast_nullable_to_non_nullable
              as String?,
      osVersion: freezed == osVersion
          ? _value.osVersion
          : osVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      env: freezed == env
          ? _value.env
          : env // ignore: cast_nullable_to_non_nullable
              as String?,
      distro: freezed == distro
          ? _value.distro
          : distro // ignore: cast_nullable_to_non_nullable
              as String?,
      distroVersion: freezed == distroVersion
          ? _value.distroVersion
          : distroVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      distroCodeName: freezed == distroCodeName
          ? _value.distroCodeName
          : distroCodeName // ignore: cast_nullable_to_non_nullable
              as String?,
      desktop: freezed == desktop
          ? _value.desktop
          : desktop // ignore: cast_nullable_to_non_nullable
              as bool?,
      package: freezed == package
          ? _value.package
          : package // ignore: cast_nullable_to_non_nullable
              as String?,
      deviceModel: freezed == deviceModel
          ? _value.deviceModel
          : deviceModel // ignore: cast_nullable_to_non_nullable
              as String?,
      shareeNode: freezed == shareeNode
          ? _value.shareeNode
          : shareeNode // ignore: cast_nullable_to_non_nullable
              as bool?,
      hostname: freezed == hostname
          ? _value.hostname
          : hostname // ignore: cast_nullable_to_non_nullable
              as String?,
      shieldsUp: freezed == shieldsUp
          ? _value.shieldsUp
          : shieldsUp // ignore: cast_nullable_to_non_nullable
              as bool?,
      noLogsNoSupport: freezed == noLogsNoSupport
          ? _value.noLogsNoSupport
          : noLogsNoSupport // ignore: cast_nullable_to_non_nullable
              as bool?,
      machine: freezed == machine
          ? _value.machine
          : machine // ignore: cast_nullable_to_non_nullable
              as String?,
      routableIPs: freezed == routableIPs
          ? _value.routableIPs
          : routableIPs // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      services: freezed == services
          ? _value.services
          : services // ignore: cast_nullable_to_non_nullable
              as List<Service>?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as Location?,
    ) as $Val);
  }

  /// Create a copy of Hostinfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LocationCopyWith<$Res>? get location {
    if (_value.location == null) {
      return null;
    }

    return $LocationCopyWith<$Res>(_value.location!, (value) {
      return _then(_value.copyWith(location: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$HostinfoImplCopyWith<$Res>
    implements $HostinfoCopyWith<$Res> {
  factory _$$HostinfoImplCopyWith(
          _$HostinfoImpl value, $Res Function(_$HostinfoImpl) then) =
      __$$HostinfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'IPNVersion') String? ipnVersion,
      @JsonKey(name: 'FrontendLogID') String? frontendLogID,
      @JsonKey(name: 'BackendLogID') String? backendLogID,
      @JsonKey(name: 'OS') String? os,
      @JsonKey(name: 'OSVersion') String? osVersion,
      @JsonKey(name: 'Env') String? env,
      @JsonKey(name: 'Distro') String? distro,
      @JsonKey(name: 'DistroVersion') String? distroVersion,
      @JsonKey(name: 'DistroCodeName') String? distroCodeName,
      @JsonKey(name: 'Desktop') bool? desktop,
      @JsonKey(name: 'Package') String? package,
      @JsonKey(name: 'DeviceModel') String? deviceModel,
      @JsonKey(name: 'ShareeNode') bool? shareeNode,
      @JsonKey(name: 'Hostname') String? hostname,
      @JsonKey(name: 'ShieldsUp') bool? shieldsUp,
      @JsonKey(name: 'NoLogsNoSupport') bool? noLogsNoSupport,
      @JsonKey(name: 'Machine') String? machine,
      @JsonKey(name: 'RoutableIPs') List<String>? routableIPs,
      @JsonKey(name: 'Services') List<Service>? services,
      @JsonKey(name: 'Location') Location? location});

  @override
  $LocationCopyWith<$Res>? get location;
}

/// @nodoc
class __$$HostinfoImplCopyWithImpl<$Res>
    extends _$HostinfoCopyWithImpl<$Res, _$HostinfoImpl>
    implements _$$HostinfoImplCopyWith<$Res> {
  __$$HostinfoImplCopyWithImpl(
      _$HostinfoImpl _value, $Res Function(_$HostinfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of Hostinfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ipnVersion = freezed,
    Object? frontendLogID = freezed,
    Object? backendLogID = freezed,
    Object? os = freezed,
    Object? osVersion = freezed,
    Object? env = freezed,
    Object? distro = freezed,
    Object? distroVersion = freezed,
    Object? distroCodeName = freezed,
    Object? desktop = freezed,
    Object? package = freezed,
    Object? deviceModel = freezed,
    Object? shareeNode = freezed,
    Object? hostname = freezed,
    Object? shieldsUp = freezed,
    Object? noLogsNoSupport = freezed,
    Object? machine = freezed,
    Object? routableIPs = freezed,
    Object? services = freezed,
    Object? location = freezed,
  }) {
    return _then(_$HostinfoImpl(
      ipnVersion: freezed == ipnVersion
          ? _value.ipnVersion
          : ipnVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      frontendLogID: freezed == frontendLogID
          ? _value.frontendLogID
          : frontendLogID // ignore: cast_nullable_to_non_nullable
              as String?,
      backendLogID: freezed == backendLogID
          ? _value.backendLogID
          : backendLogID // ignore: cast_nullable_to_non_nullable
              as String?,
      os: freezed == os
          ? _value.os
          : os // ignore: cast_nullable_to_non_nullable
              as String?,
      osVersion: freezed == osVersion
          ? _value.osVersion
          : osVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      env: freezed == env
          ? _value.env
          : env // ignore: cast_nullable_to_non_nullable
              as String?,
      distro: freezed == distro
          ? _value.distro
          : distro // ignore: cast_nullable_to_non_nullable
              as String?,
      distroVersion: freezed == distroVersion
          ? _value.distroVersion
          : distroVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      distroCodeName: freezed == distroCodeName
          ? _value.distroCodeName
          : distroCodeName // ignore: cast_nullable_to_non_nullable
              as String?,
      desktop: freezed == desktop
          ? _value.desktop
          : desktop // ignore: cast_nullable_to_non_nullable
              as bool?,
      package: freezed == package
          ? _value.package
          : package // ignore: cast_nullable_to_non_nullable
              as String?,
      deviceModel: freezed == deviceModel
          ? _value.deviceModel
          : deviceModel // ignore: cast_nullable_to_non_nullable
              as String?,
      shareeNode: freezed == shareeNode
          ? _value.shareeNode
          : shareeNode // ignore: cast_nullable_to_non_nullable
              as bool?,
      hostname: freezed == hostname
          ? _value.hostname
          : hostname // ignore: cast_nullable_to_non_nullable
              as String?,
      shieldsUp: freezed == shieldsUp
          ? _value.shieldsUp
          : shieldsUp // ignore: cast_nullable_to_non_nullable
              as bool?,
      noLogsNoSupport: freezed == noLogsNoSupport
          ? _value.noLogsNoSupport
          : noLogsNoSupport // ignore: cast_nullable_to_non_nullable
              as bool?,
      machine: freezed == machine
          ? _value.machine
          : machine // ignore: cast_nullable_to_non_nullable
              as String?,
      routableIPs: freezed == routableIPs
          ? _value._routableIPs
          : routableIPs // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      services: freezed == services
          ? _value._services
          : services // ignore: cast_nullable_to_non_nullable
              as List<Service>?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as Location?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HostinfoImpl implements _Hostinfo {
  const _$HostinfoImpl(
      {@JsonKey(name: 'IPNVersion') this.ipnVersion,
      @JsonKey(name: 'FrontendLogID') this.frontendLogID,
      @JsonKey(name: 'BackendLogID') this.backendLogID,
      @JsonKey(name: 'OS') this.os,
      @JsonKey(name: 'OSVersion') this.osVersion,
      @JsonKey(name: 'Env') this.env,
      @JsonKey(name: 'Distro') this.distro,
      @JsonKey(name: 'DistroVersion') this.distroVersion,
      @JsonKey(name: 'DistroCodeName') this.distroCodeName,
      @JsonKey(name: 'Desktop') this.desktop,
      @JsonKey(name: 'Package') this.package,
      @JsonKey(name: 'DeviceModel') this.deviceModel,
      @JsonKey(name: 'ShareeNode') this.shareeNode,
      @JsonKey(name: 'Hostname') this.hostname,
      @JsonKey(name: 'ShieldsUp') this.shieldsUp,
      @JsonKey(name: 'NoLogsNoSupport') this.noLogsNoSupport,
      @JsonKey(name: 'Machine') this.machine,
      @JsonKey(name: 'RoutableIPs') final List<String>? routableIPs,
      @JsonKey(name: 'Services') final List<Service>? services,
      @JsonKey(name: 'Location') this.location})
      : _routableIPs = routableIPs,
        _services = services;

  factory _$HostinfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$HostinfoImplFromJson(json);

  @override
  @JsonKey(name: 'IPNVersion')
  final String? ipnVersion;
  @override
  @JsonKey(name: 'FrontendLogID')
  final String? frontendLogID;
  @override
  @JsonKey(name: 'BackendLogID')
  final String? backendLogID;
  @override
  @JsonKey(name: 'OS')
  final String? os;
  @override
  @JsonKey(name: 'OSVersion')
  final String? osVersion;
  @override
  @JsonKey(name: 'Env')
  final String? env;
  @override
  @JsonKey(name: 'Distro')
  final String? distro;
  @override
  @JsonKey(name: 'DistroVersion')
  final String? distroVersion;
  @override
  @JsonKey(name: 'DistroCodeName')
  final String? distroCodeName;
  @override
  @JsonKey(name: 'Desktop')
  final bool? desktop;
  @override
  @JsonKey(name: 'Package')
  final String? package;
  @override
  @JsonKey(name: 'DeviceModel')
  final String? deviceModel;
  @override
  @JsonKey(name: 'ShareeNode')
  final bool? shareeNode;
  @override
  @JsonKey(name: 'Hostname')
  final String? hostname;
  @override
  @JsonKey(name: 'ShieldsUp')
  final bool? shieldsUp;
  @override
  @JsonKey(name: 'NoLogsNoSupport')
  final bool? noLogsNoSupport;
  @override
  @JsonKey(name: 'Machine')
  final String? machine;
  final List<String>? _routableIPs;
  @override
  @JsonKey(name: 'RoutableIPs')
  List<String>? get routableIPs {
    final value = _routableIPs;
    if (value == null) return null;
    if (_routableIPs is EqualUnmodifiableListView) return _routableIPs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<Service>? _services;
  @override
  @JsonKey(name: 'Services')
  List<Service>? get services {
    final value = _services;
    if (value == null) return null;
    if (_services is EqualUnmodifiableListView) return _services;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'Location')
  final Location? location;

  @override
  String toString() {
    return 'Hostinfo(ipnVersion: $ipnVersion, frontendLogID: $frontendLogID, backendLogID: $backendLogID, os: $os, osVersion: $osVersion, env: $env, distro: $distro, distroVersion: $distroVersion, distroCodeName: $distroCodeName, desktop: $desktop, package: $package, deviceModel: $deviceModel, shareeNode: $shareeNode, hostname: $hostname, shieldsUp: $shieldsUp, noLogsNoSupport: $noLogsNoSupport, machine: $machine, routableIPs: $routableIPs, services: $services, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HostinfoImpl &&
            (identical(other.ipnVersion, ipnVersion) ||
                other.ipnVersion == ipnVersion) &&
            (identical(other.frontendLogID, frontendLogID) ||
                other.frontendLogID == frontendLogID) &&
            (identical(other.backendLogID, backendLogID) ||
                other.backendLogID == backendLogID) &&
            (identical(other.os, os) || other.os == os) &&
            (identical(other.osVersion, osVersion) ||
                other.osVersion == osVersion) &&
            (identical(other.env, env) || other.env == env) &&
            (identical(other.distro, distro) || other.distro == distro) &&
            (identical(other.distroVersion, distroVersion) ||
                other.distroVersion == distroVersion) &&
            (identical(other.distroCodeName, distroCodeName) ||
                other.distroCodeName == distroCodeName) &&
            (identical(other.desktop, desktop) || other.desktop == desktop) &&
            (identical(other.package, package) || other.package == package) &&
            (identical(other.deviceModel, deviceModel) ||
                other.deviceModel == deviceModel) &&
            (identical(other.shareeNode, shareeNode) ||
                other.shareeNode == shareeNode) &&
            (identical(other.hostname, hostname) ||
                other.hostname == hostname) &&
            (identical(other.shieldsUp, shieldsUp) ||
                other.shieldsUp == shieldsUp) &&
            (identical(other.noLogsNoSupport, noLogsNoSupport) ||
                other.noLogsNoSupport == noLogsNoSupport) &&
            (identical(other.machine, machine) || other.machine == machine) &&
            const DeepCollectionEquality()
                .equals(other._routableIPs, _routableIPs) &&
            const DeepCollectionEquality().equals(other._services, _services) &&
            (identical(other.location, location) ||
                other.location == location));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        ipnVersion,
        frontendLogID,
        backendLogID,
        os,
        osVersion,
        env,
        distro,
        distroVersion,
        distroCodeName,
        desktop,
        package,
        deviceModel,
        shareeNode,
        hostname,
        shieldsUp,
        noLogsNoSupport,
        machine,
        const DeepCollectionEquality().hash(_routableIPs),
        const DeepCollectionEquality().hash(_services),
        location
      ]);

  /// Create a copy of Hostinfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HostinfoImplCopyWith<_$HostinfoImpl> get copyWith =>
      __$$HostinfoImplCopyWithImpl<_$HostinfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HostinfoImplToJson(
      this,
    );
  }
}

abstract class _Hostinfo implements Hostinfo {
  const factory _Hostinfo(
      {@JsonKey(name: 'IPNVersion') final String? ipnVersion,
      @JsonKey(name: 'FrontendLogID') final String? frontendLogID,
      @JsonKey(name: 'BackendLogID') final String? backendLogID,
      @JsonKey(name: 'OS') final String? os,
      @JsonKey(name: 'OSVersion') final String? osVersion,
      @JsonKey(name: 'Env') final String? env,
      @JsonKey(name: 'Distro') final String? distro,
      @JsonKey(name: 'DistroVersion') final String? distroVersion,
      @JsonKey(name: 'DistroCodeName') final String? distroCodeName,
      @JsonKey(name: 'Desktop') final bool? desktop,
      @JsonKey(name: 'Package') final String? package,
      @JsonKey(name: 'DeviceModel') final String? deviceModel,
      @JsonKey(name: 'ShareeNode') final bool? shareeNode,
      @JsonKey(name: 'Hostname') final String? hostname,
      @JsonKey(name: 'ShieldsUp') final bool? shieldsUp,
      @JsonKey(name: 'NoLogsNoSupport') final bool? noLogsNoSupport,
      @JsonKey(name: 'Machine') final String? machine,
      @JsonKey(name: 'RoutableIPs') final List<String>? routableIPs,
      @JsonKey(name: 'Services') final List<Service>? services,
      @JsonKey(name: 'Location') final Location? location}) = _$HostinfoImpl;

  factory _Hostinfo.fromJson(Map<String, dynamic> json) =
      _$HostinfoImpl.fromJson;

  @override
  @JsonKey(name: 'IPNVersion')
  String? get ipnVersion;
  @override
  @JsonKey(name: 'FrontendLogID')
  String? get frontendLogID;
  @override
  @JsonKey(name: 'BackendLogID')
  String? get backendLogID;
  @override
  @JsonKey(name: 'OS')
  String? get os;
  @override
  @JsonKey(name: 'OSVersion')
  String? get osVersion;
  @override
  @JsonKey(name: 'Env')
  String? get env;
  @override
  @JsonKey(name: 'Distro')
  String? get distro;
  @override
  @JsonKey(name: 'DistroVersion')
  String? get distroVersion;
  @override
  @JsonKey(name: 'DistroCodeName')
  String? get distroCodeName;
  @override
  @JsonKey(name: 'Desktop')
  bool? get desktop;
  @override
  @JsonKey(name: 'Package')
  String? get package;
  @override
  @JsonKey(name: 'DeviceModel')
  String? get deviceModel;
  @override
  @JsonKey(name: 'ShareeNode')
  bool? get shareeNode;
  @override
  @JsonKey(name: 'Hostname')
  String? get hostname;
  @override
  @JsonKey(name: 'ShieldsUp')
  bool? get shieldsUp;
  @override
  @JsonKey(name: 'NoLogsNoSupport')
  bool? get noLogsNoSupport;
  @override
  @JsonKey(name: 'Machine')
  String? get machine;
  @override
  @JsonKey(name: 'RoutableIPs')
  List<String>? get routableIPs;
  @override
  @JsonKey(name: 'Services')
  List<Service>? get services;
  @override
  @JsonKey(name: 'Location')
  Location? get location;

  /// Create a copy of Hostinfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HostinfoImplCopyWith<_$HostinfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Location _$LocationFromJson(Map<String, dynamic> json) {
  return _Location.fromJson(json);
}

/// @nodoc
mixin _$Location {
  @JsonKey(name: 'Country')
  String? get country => throw _privateConstructorUsedError;
  @JsonKey(name: 'CountryCode')
  String? get countryCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'City')
  String? get city => throw _privateConstructorUsedError;
  @JsonKey(name: 'CityCode')
  String? get cityCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'Priority')
  int? get priority => throw _privateConstructorUsedError;

  /// Serializes this Location to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Location
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LocationCopyWith<Location> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LocationCopyWith<$Res> {
  factory $LocationCopyWith(Location value, $Res Function(Location) then) =
      _$LocationCopyWithImpl<$Res, Location>;
  @useResult
  $Res call(
      {@JsonKey(name: 'Country') String? country,
      @JsonKey(name: 'CountryCode') String? countryCode,
      @JsonKey(name: 'City') String? city,
      @JsonKey(name: 'CityCode') String? cityCode,
      @JsonKey(name: 'Priority') int? priority});
}

/// @nodoc
class _$LocationCopyWithImpl<$Res, $Val extends Location>
    implements $LocationCopyWith<$Res> {
  _$LocationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Location
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? country = freezed,
    Object? countryCode = freezed,
    Object? city = freezed,
    Object? cityCode = freezed,
    Object? priority = freezed,
  }) {
    return _then(_value.copyWith(
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      countryCode: freezed == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      cityCode: freezed == cityCode
          ? _value.cityCode
          : cityCode // ignore: cast_nullable_to_non_nullable
              as String?,
      priority: freezed == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LocationImplCopyWith<$Res>
    implements $LocationCopyWith<$Res> {
  factory _$$LocationImplCopyWith(
          _$LocationImpl value, $Res Function(_$LocationImpl) then) =
      __$$LocationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Country') String? country,
      @JsonKey(name: 'CountryCode') String? countryCode,
      @JsonKey(name: 'City') String? city,
      @JsonKey(name: 'CityCode') String? cityCode,
      @JsonKey(name: 'Priority') int? priority});
}

/// @nodoc
class __$$LocationImplCopyWithImpl<$Res>
    extends _$LocationCopyWithImpl<$Res, _$LocationImpl>
    implements _$$LocationImplCopyWith<$Res> {
  __$$LocationImplCopyWithImpl(
      _$LocationImpl _value, $Res Function(_$LocationImpl) _then)
      : super(_value, _then);

  /// Create a copy of Location
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? country = freezed,
    Object? countryCode = freezed,
    Object? city = freezed,
    Object? cityCode = freezed,
    Object? priority = freezed,
  }) {
    return _then(_$LocationImpl(
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      countryCode: freezed == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      cityCode: freezed == cityCode
          ? _value.cityCode
          : cityCode // ignore: cast_nullable_to_non_nullable
              as String?,
      priority: freezed == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LocationImpl extends _Location {
  const _$LocationImpl(
      {@JsonKey(name: 'Country') this.country,
      @JsonKey(name: 'CountryCode') this.countryCode,
      @JsonKey(name: 'City') this.city,
      @JsonKey(name: 'CityCode') this.cityCode,
      @JsonKey(name: 'Priority') this.priority})
      : super._();

  factory _$LocationImpl.fromJson(Map<String, dynamic> json) =>
      _$$LocationImplFromJson(json);

  @override
  @JsonKey(name: 'Country')
  final String? country;
  @override
  @JsonKey(name: 'CountryCode')
  final String? countryCode;
  @override
  @JsonKey(name: 'City')
  final String? city;
  @override
  @JsonKey(name: 'CityCode')
  final String? cityCode;
  @override
  @JsonKey(name: 'Priority')
  final int? priority;

  @override
  String toString() {
    return 'Location(country: $country, countryCode: $countryCode, city: $city, cityCode: $cityCode, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocationImpl &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.countryCode, countryCode) ||
                other.countryCode == countryCode) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.cityCode, cityCode) ||
                other.cityCode == cityCode) &&
            (identical(other.priority, priority) ||
                other.priority == priority));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, country, countryCode, city, cityCode, priority);

  /// Create a copy of Location
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LocationImplCopyWith<_$LocationImpl> get copyWith =>
      __$$LocationImplCopyWithImpl<_$LocationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LocationImplToJson(
      this,
    );
  }
}

abstract class _Location extends Location {
  const factory _Location(
      {@JsonKey(name: 'Country') final String? country,
      @JsonKey(name: 'CountryCode') final String? countryCode,
      @JsonKey(name: 'City') final String? city,
      @JsonKey(name: 'CityCode') final String? cityCode,
      @JsonKey(name: 'Priority') final int? priority}) = _$LocationImpl;
  const _Location._() : super._();

  factory _Location.fromJson(Map<String, dynamic> json) =
      _$LocationImpl.fromJson;

  @override
  @JsonKey(name: 'Country')
  String? get country;
  @override
  @JsonKey(name: 'CountryCode')
  String? get countryCode;
  @override
  @JsonKey(name: 'City')
  String? get city;
  @override
  @JsonKey(name: 'CityCode')
  String? get cityCode;
  @override
  @JsonKey(name: 'Priority')
  int? get priority;

  /// Create a copy of Location
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LocationImplCopyWith<_$LocationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Service _$ServiceFromJson(Map<String, dynamic> json) {
  return _Service.fromJson(json);
}

/// @nodoc
mixin _$Service {
  @JsonKey(name: 'Proto')
  String get proto => throw _privateConstructorUsedError;
  @JsonKey(name: 'Port')
  int get port => throw _privateConstructorUsedError;
  @JsonKey(name: 'Description')
  String? get description => throw _privateConstructorUsedError;

  /// Serializes this Service to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Service
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ServiceCopyWith<Service> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ServiceCopyWith<$Res> {
  factory $ServiceCopyWith(Service value, $Res Function(Service) then) =
      _$ServiceCopyWithImpl<$Res, Service>;
  @useResult
  $Res call(
      {@JsonKey(name: 'Proto') String proto,
      @JsonKey(name: 'Port') int port,
      @JsonKey(name: 'Description') String? description});
}

/// @nodoc
class _$ServiceCopyWithImpl<$Res, $Val extends Service>
    implements $ServiceCopyWith<$Res> {
  _$ServiceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Service
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? proto = null,
    Object? port = null,
    Object? description = freezed,
  }) {
    return _then(_value.copyWith(
      proto: null == proto
          ? _value.proto
          : proto // ignore: cast_nullable_to_non_nullable
              as String,
      port: null == port
          ? _value.port
          : port // ignore: cast_nullable_to_non_nullable
              as int,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ServiceImplCopyWith<$Res> implements $ServiceCopyWith<$Res> {
  factory _$$ServiceImplCopyWith(
          _$ServiceImpl value, $Res Function(_$ServiceImpl) then) =
      __$$ServiceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Proto') String proto,
      @JsonKey(name: 'Port') int port,
      @JsonKey(name: 'Description') String? description});
}

/// @nodoc
class __$$ServiceImplCopyWithImpl<$Res>
    extends _$ServiceCopyWithImpl<$Res, _$ServiceImpl>
    implements _$$ServiceImplCopyWith<$Res> {
  __$$ServiceImplCopyWithImpl(
      _$ServiceImpl _value, $Res Function(_$ServiceImpl) _then)
      : super(_value, _then);

  /// Create a copy of Service
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? proto = null,
    Object? port = null,
    Object? description = freezed,
  }) {
    return _then(_$ServiceImpl(
      proto: null == proto
          ? _value.proto
          : proto // ignore: cast_nullable_to_non_nullable
              as String,
      port: null == port
          ? _value.port
          : port // ignore: cast_nullable_to_non_nullable
              as int,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ServiceImpl implements _Service {
  const _$ServiceImpl(
      {@JsonKey(name: 'Proto') required this.proto,
      @JsonKey(name: 'Port') required this.port,
      @JsonKey(name: 'Description') this.description});

  factory _$ServiceImpl.fromJson(Map<String, dynamic> json) =>
      _$$ServiceImplFromJson(json);

  @override
  @JsonKey(name: 'Proto')
  final String proto;
  @override
  @JsonKey(name: 'Port')
  final int port;
  @override
  @JsonKey(name: 'Description')
  final String? description;

  @override
  String toString() {
    return 'Service(proto: $proto, port: $port, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServiceImpl &&
            (identical(other.proto, proto) || other.proto == proto) &&
            (identical(other.port, port) || other.port == port) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, proto, port, description);

  /// Create a copy of Service
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ServiceImplCopyWith<_$ServiceImpl> get copyWith =>
      __$$ServiceImplCopyWithImpl<_$ServiceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ServiceImplToJson(
      this,
    );
  }
}

abstract class _Service implements Service {
  const factory _Service(
      {@JsonKey(name: 'Proto') required final String proto,
      @JsonKey(name: 'Port') required final int port,
      @JsonKey(name: 'Description') final String? description}) = _$ServiceImpl;

  factory _Service.fromJson(Map<String, dynamic> json) = _$ServiceImpl.fromJson;

  @override
  @JsonKey(name: 'Proto')
  String get proto;
  @override
  @JsonKey(name: 'Port')
  int get port;
  @override
  @JsonKey(name: 'Description')
  String? get description;

  /// Create a copy of Service
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ServiceImplCopyWith<_$ServiceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PingResult _$PingResultFromJson(Map<String, dynamic> json) {
  return _PingResult.fromJson(json);
}

/// @nodoc
mixin _$PingResult {
  @JsonKey(name: 'IP')
  String? get ip => throw _privateConstructorUsedError;
  @JsonKey(name: 'NodeIP')
  String? get nodeIP => throw _privateConstructorUsedError;
  @JsonKey(name: 'NodeName')
  String? get nodeName => throw _privateConstructorUsedError;
  @JsonKey(name: 'Err')
  String? get error => throw _privateConstructorUsedError;
  @JsonKey(name: 'LatencySeconds')
  double? get latencySeconds => throw _privateConstructorUsedError;
  @JsonKey(name: 'Endpoint')
  String? get endpoint => throw _privateConstructorUsedError;
  @JsonKey(name: 'DERPRegionID')
  int? get derpRegionId => throw _privateConstructorUsedError;
  @JsonKey(name: 'DERPRegionCode')
  String? get derpRegionCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'PeerAPIPort')
  int? get peerAPIPort => throw _privateConstructorUsedError;
  @JsonKey(name: 'PeerAPIURL')
  String? get peerAPIUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'IsLocalIP')
  bool? get isLocalIP => throw _privateConstructorUsedError;

  /// Serializes this PingResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PingResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PingResultCopyWith<PingResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PingResultCopyWith<$Res> {
  factory $PingResultCopyWith(
          PingResult value, $Res Function(PingResult) then) =
      _$PingResultCopyWithImpl<$Res, PingResult>;
  @useResult
  $Res call(
      {@JsonKey(name: 'IP') String? ip,
      @JsonKey(name: 'NodeIP') String? nodeIP,
      @JsonKey(name: 'NodeName') String? nodeName,
      @JsonKey(name: 'Err') String? error,
      @JsonKey(name: 'LatencySeconds') double? latencySeconds,
      @JsonKey(name: 'Endpoint') String? endpoint,
      @JsonKey(name: 'DERPRegionID') int? derpRegionId,
      @JsonKey(name: 'DERPRegionCode') String? derpRegionCode,
      @JsonKey(name: 'PeerAPIPort') int? peerAPIPort,
      @JsonKey(name: 'PeerAPIURL') String? peerAPIUrl,
      @JsonKey(name: 'IsLocalIP') bool? isLocalIP});
}

/// @nodoc
class _$PingResultCopyWithImpl<$Res, $Val extends PingResult>
    implements $PingResultCopyWith<$Res> {
  _$PingResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PingResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ip = freezed,
    Object? nodeIP = freezed,
    Object? nodeName = freezed,
    Object? error = freezed,
    Object? latencySeconds = freezed,
    Object? endpoint = freezed,
    Object? derpRegionId = freezed,
    Object? derpRegionCode = freezed,
    Object? peerAPIPort = freezed,
    Object? peerAPIUrl = freezed,
    Object? isLocalIP = freezed,
  }) {
    return _then(_value.copyWith(
      ip: freezed == ip
          ? _value.ip
          : ip // ignore: cast_nullable_to_non_nullable
              as String?,
      nodeIP: freezed == nodeIP
          ? _value.nodeIP
          : nodeIP // ignore: cast_nullable_to_non_nullable
              as String?,
      nodeName: freezed == nodeName
          ? _value.nodeName
          : nodeName // ignore: cast_nullable_to_non_nullable
              as String?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      latencySeconds: freezed == latencySeconds
          ? _value.latencySeconds
          : latencySeconds // ignore: cast_nullable_to_non_nullable
              as double?,
      endpoint: freezed == endpoint
          ? _value.endpoint
          : endpoint // ignore: cast_nullable_to_non_nullable
              as String?,
      derpRegionId: freezed == derpRegionId
          ? _value.derpRegionId
          : derpRegionId // ignore: cast_nullable_to_non_nullable
              as int?,
      derpRegionCode: freezed == derpRegionCode
          ? _value.derpRegionCode
          : derpRegionCode // ignore: cast_nullable_to_non_nullable
              as String?,
      peerAPIPort: freezed == peerAPIPort
          ? _value.peerAPIPort
          : peerAPIPort // ignore: cast_nullable_to_non_nullable
              as int?,
      peerAPIUrl: freezed == peerAPIUrl
          ? _value.peerAPIUrl
          : peerAPIUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isLocalIP: freezed == isLocalIP
          ? _value.isLocalIP
          : isLocalIP // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PingResultImplCopyWith<$Res>
    implements $PingResultCopyWith<$Res> {
  factory _$$PingResultImplCopyWith(
          _$PingResultImpl value, $Res Function(_$PingResultImpl) then) =
      __$$PingResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'IP') String? ip,
      @JsonKey(name: 'NodeIP') String? nodeIP,
      @JsonKey(name: 'NodeName') String? nodeName,
      @JsonKey(name: 'Err') String? error,
      @JsonKey(name: 'LatencySeconds') double? latencySeconds,
      @JsonKey(name: 'Endpoint') String? endpoint,
      @JsonKey(name: 'DERPRegionID') int? derpRegionId,
      @JsonKey(name: 'DERPRegionCode') String? derpRegionCode,
      @JsonKey(name: 'PeerAPIPort') int? peerAPIPort,
      @JsonKey(name: 'PeerAPIURL') String? peerAPIUrl,
      @JsonKey(name: 'IsLocalIP') bool? isLocalIP});
}

/// @nodoc
class __$$PingResultImplCopyWithImpl<$Res>
    extends _$PingResultCopyWithImpl<$Res, _$PingResultImpl>
    implements _$$PingResultImplCopyWith<$Res> {
  __$$PingResultImplCopyWithImpl(
      _$PingResultImpl _value, $Res Function(_$PingResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of PingResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ip = freezed,
    Object? nodeIP = freezed,
    Object? nodeName = freezed,
    Object? error = freezed,
    Object? latencySeconds = freezed,
    Object? endpoint = freezed,
    Object? derpRegionId = freezed,
    Object? derpRegionCode = freezed,
    Object? peerAPIPort = freezed,
    Object? peerAPIUrl = freezed,
    Object? isLocalIP = freezed,
  }) {
    return _then(_$PingResultImpl(
      ip: freezed == ip
          ? _value.ip
          : ip // ignore: cast_nullable_to_non_nullable
              as String?,
      nodeIP: freezed == nodeIP
          ? _value.nodeIP
          : nodeIP // ignore: cast_nullable_to_non_nullable
              as String?,
      nodeName: freezed == nodeName
          ? _value.nodeName
          : nodeName // ignore: cast_nullable_to_non_nullable
              as String?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      latencySeconds: freezed == latencySeconds
          ? _value.latencySeconds
          : latencySeconds // ignore: cast_nullable_to_non_nullable
              as double?,
      endpoint: freezed == endpoint
          ? _value.endpoint
          : endpoint // ignore: cast_nullable_to_non_nullable
              as String?,
      derpRegionId: freezed == derpRegionId
          ? _value.derpRegionId
          : derpRegionId // ignore: cast_nullable_to_non_nullable
              as int?,
      derpRegionCode: freezed == derpRegionCode
          ? _value.derpRegionCode
          : derpRegionCode // ignore: cast_nullable_to_non_nullable
              as String?,
      peerAPIPort: freezed == peerAPIPort
          ? _value.peerAPIPort
          : peerAPIPort // ignore: cast_nullable_to_non_nullable
              as int?,
      peerAPIUrl: freezed == peerAPIUrl
          ? _value.peerAPIUrl
          : peerAPIUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isLocalIP: freezed == isLocalIP
          ? _value.isLocalIP
          : isLocalIP // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PingResultImpl implements _PingResult {
  const _$PingResultImpl(
      {@JsonKey(name: 'IP') this.ip,
      @JsonKey(name: 'NodeIP') this.nodeIP,
      @JsonKey(name: 'NodeName') this.nodeName,
      @JsonKey(name: 'Err') this.error,
      @JsonKey(name: 'LatencySeconds') this.latencySeconds,
      @JsonKey(name: 'Endpoint') this.endpoint,
      @JsonKey(name: 'DERPRegionID') this.derpRegionId,
      @JsonKey(name: 'DERPRegionCode') this.derpRegionCode,
      @JsonKey(name: 'PeerAPIPort') this.peerAPIPort,
      @JsonKey(name: 'PeerAPIURL') this.peerAPIUrl,
      @JsonKey(name: 'IsLocalIP') this.isLocalIP});

  factory _$PingResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$PingResultImplFromJson(json);

  @override
  @JsonKey(name: 'IP')
  final String? ip;
  @override
  @JsonKey(name: 'NodeIP')
  final String? nodeIP;
  @override
  @JsonKey(name: 'NodeName')
  final String? nodeName;
  @override
  @JsonKey(name: 'Err')
  final String? error;
  @override
  @JsonKey(name: 'LatencySeconds')
  final double? latencySeconds;
  @override
  @JsonKey(name: 'Endpoint')
  final String? endpoint;
  @override
  @JsonKey(name: 'DERPRegionID')
  final int? derpRegionId;
  @override
  @JsonKey(name: 'DERPRegionCode')
  final String? derpRegionCode;
  @override
  @JsonKey(name: 'PeerAPIPort')
  final int? peerAPIPort;
  @override
  @JsonKey(name: 'PeerAPIURL')
  final String? peerAPIUrl;
  @override
  @JsonKey(name: 'IsLocalIP')
  final bool? isLocalIP;

  @override
  String toString() {
    return 'PingResult(ip: $ip, nodeIP: $nodeIP, nodeName: $nodeName, error: $error, latencySeconds: $latencySeconds, endpoint: $endpoint, derpRegionId: $derpRegionId, derpRegionCode: $derpRegionCode, peerAPIPort: $peerAPIPort, peerAPIUrl: $peerAPIUrl, isLocalIP: $isLocalIP)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PingResultImpl &&
            (identical(other.ip, ip) || other.ip == ip) &&
            (identical(other.nodeIP, nodeIP) || other.nodeIP == nodeIP) &&
            (identical(other.nodeName, nodeName) ||
                other.nodeName == nodeName) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.latencySeconds, latencySeconds) ||
                other.latencySeconds == latencySeconds) &&
            (identical(other.endpoint, endpoint) ||
                other.endpoint == endpoint) &&
            (identical(other.derpRegionId, derpRegionId) ||
                other.derpRegionId == derpRegionId) &&
            (identical(other.derpRegionCode, derpRegionCode) ||
                other.derpRegionCode == derpRegionCode) &&
            (identical(other.peerAPIPort, peerAPIPort) ||
                other.peerAPIPort == peerAPIPort) &&
            (identical(other.peerAPIUrl, peerAPIUrl) ||
                other.peerAPIUrl == peerAPIUrl) &&
            (identical(other.isLocalIP, isLocalIP) ||
                other.isLocalIP == isLocalIP));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      ip,
      nodeIP,
      nodeName,
      error,
      latencySeconds,
      endpoint,
      derpRegionId,
      derpRegionCode,
      peerAPIPort,
      peerAPIUrl,
      isLocalIP);

  /// Create a copy of PingResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PingResultImplCopyWith<_$PingResultImpl> get copyWith =>
      __$$PingResultImplCopyWithImpl<_$PingResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PingResultImplToJson(
      this,
    );
  }
}

abstract class _PingResult implements PingResult {
  const factory _PingResult(
      {@JsonKey(name: 'IP') final String? ip,
      @JsonKey(name: 'NodeIP') final String? nodeIP,
      @JsonKey(name: 'NodeName') final String? nodeName,
      @JsonKey(name: 'Err') final String? error,
      @JsonKey(name: 'LatencySeconds') final double? latencySeconds,
      @JsonKey(name: 'Endpoint') final String? endpoint,
      @JsonKey(name: 'DERPRegionID') final int? derpRegionId,
      @JsonKey(name: 'DERPRegionCode') final String? derpRegionCode,
      @JsonKey(name: 'PeerAPIPort') final int? peerAPIPort,
      @JsonKey(name: 'PeerAPIURL') final String? peerAPIUrl,
      @JsonKey(name: 'IsLocalIP') final bool? isLocalIP}) = _$PingResultImpl;

  factory _PingResult.fromJson(Map<String, dynamic> json) =
      _$PingResultImpl.fromJson;

  @override
  @JsonKey(name: 'IP')
  String? get ip;
  @override
  @JsonKey(name: 'NodeIP')
  String? get nodeIP;
  @override
  @JsonKey(name: 'NodeName')
  String? get nodeName;
  @override
  @JsonKey(name: 'Err')
  String? get error;
  @override
  @JsonKey(name: 'LatencySeconds')
  double? get latencySeconds;
  @override
  @JsonKey(name: 'Endpoint')
  String? get endpoint;
  @override
  @JsonKey(name: 'DERPRegionID')
  int? get derpRegionId;
  @override
  @JsonKey(name: 'DERPRegionCode')
  String? get derpRegionCode;
  @override
  @JsonKey(name: 'PeerAPIPort')
  int? get peerAPIPort;
  @override
  @JsonKey(name: 'PeerAPIURL')
  String? get peerAPIUrl;
  @override
  @JsonKey(name: 'IsLocalIP')
  bool? get isLocalIP;

  /// Create a copy of PingResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PingResultImplCopyWith<_$PingResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PeerStatusLite _$PeerStatusLiteFromJson(Map<String, dynamic> json) {
  return _PeerStatusLite.fromJson(json);
}

/// @nodoc
mixin _$PeerStatusLite {
  @JsonKey(name: 'RxBytes')
  int get rxBytes => throw _privateConstructorUsedError;
  @JsonKey(name: 'TxBytes')
  int get txBytes => throw _privateConstructorUsedError;
  @JsonKey(name: 'LastHandshake')
  String get lastHandshake => throw _privateConstructorUsedError;
  @JsonKey(name: 'NodeKey')
  String get nodeKey => throw _privateConstructorUsedError;

  /// Serializes this PeerStatusLite to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PeerStatusLite
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PeerStatusLiteCopyWith<PeerStatusLite> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PeerStatusLiteCopyWith<$Res> {
  factory $PeerStatusLiteCopyWith(
          PeerStatusLite value, $Res Function(PeerStatusLite) then) =
      _$PeerStatusLiteCopyWithImpl<$Res, PeerStatusLite>;
  @useResult
  $Res call(
      {@JsonKey(name: 'RxBytes') int rxBytes,
      @JsonKey(name: 'TxBytes') int txBytes,
      @JsonKey(name: 'LastHandshake') String lastHandshake,
      @JsonKey(name: 'NodeKey') String nodeKey});
}

/// @nodoc
class _$PeerStatusLiteCopyWithImpl<$Res, $Val extends PeerStatusLite>
    implements $PeerStatusLiteCopyWith<$Res> {
  _$PeerStatusLiteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PeerStatusLite
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rxBytes = null,
    Object? txBytes = null,
    Object? lastHandshake = null,
    Object? nodeKey = null,
  }) {
    return _then(_value.copyWith(
      rxBytes: null == rxBytes
          ? _value.rxBytes
          : rxBytes // ignore: cast_nullable_to_non_nullable
              as int,
      txBytes: null == txBytes
          ? _value.txBytes
          : txBytes // ignore: cast_nullable_to_non_nullable
              as int,
      lastHandshake: null == lastHandshake
          ? _value.lastHandshake
          : lastHandshake // ignore: cast_nullable_to_non_nullable
              as String,
      nodeKey: null == nodeKey
          ? _value.nodeKey
          : nodeKey // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PeerStatusLiteImplCopyWith<$Res>
    implements $PeerStatusLiteCopyWith<$Res> {
  factory _$$PeerStatusLiteImplCopyWith(_$PeerStatusLiteImpl value,
          $Res Function(_$PeerStatusLiteImpl) then) =
      __$$PeerStatusLiteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'RxBytes') int rxBytes,
      @JsonKey(name: 'TxBytes') int txBytes,
      @JsonKey(name: 'LastHandshake') String lastHandshake,
      @JsonKey(name: 'NodeKey') String nodeKey});
}

/// @nodoc
class __$$PeerStatusLiteImplCopyWithImpl<$Res>
    extends _$PeerStatusLiteCopyWithImpl<$Res, _$PeerStatusLiteImpl>
    implements _$$PeerStatusLiteImplCopyWith<$Res> {
  __$$PeerStatusLiteImplCopyWithImpl(
      _$PeerStatusLiteImpl _value, $Res Function(_$PeerStatusLiteImpl) _then)
      : super(_value, _then);

  /// Create a copy of PeerStatusLite
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rxBytes = null,
    Object? txBytes = null,
    Object? lastHandshake = null,
    Object? nodeKey = null,
  }) {
    return _then(_$PeerStatusLiteImpl(
      rxBytes: null == rxBytes
          ? _value.rxBytes
          : rxBytes // ignore: cast_nullable_to_non_nullable
              as int,
      txBytes: null == txBytes
          ? _value.txBytes
          : txBytes // ignore: cast_nullable_to_non_nullable
              as int,
      lastHandshake: null == lastHandshake
          ? _value.lastHandshake
          : lastHandshake // ignore: cast_nullable_to_non_nullable
              as String,
      nodeKey: null == nodeKey
          ? _value.nodeKey
          : nodeKey // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PeerStatusLiteImpl implements _PeerStatusLite {
  const _$PeerStatusLiteImpl(
      {@JsonKey(name: 'RxBytes') required this.rxBytes,
      @JsonKey(name: 'TxBytes') required this.txBytes,
      @JsonKey(name: 'LastHandshake') required this.lastHandshake,
      @JsonKey(name: 'NodeKey') required this.nodeKey});

  factory _$PeerStatusLiteImpl.fromJson(Map<String, dynamic> json) =>
      _$$PeerStatusLiteImplFromJson(json);

  @override
  @JsonKey(name: 'RxBytes')
  final int rxBytes;
  @override
  @JsonKey(name: 'TxBytes')
  final int txBytes;
  @override
  @JsonKey(name: 'LastHandshake')
  final String lastHandshake;
  @override
  @JsonKey(name: 'NodeKey')
  final String nodeKey;

  @override
  String toString() {
    return 'PeerStatusLite(rxBytes: $rxBytes, txBytes: $txBytes, lastHandshake: $lastHandshake, nodeKey: $nodeKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PeerStatusLiteImpl &&
            (identical(other.rxBytes, rxBytes) || other.rxBytes == rxBytes) &&
            (identical(other.txBytes, txBytes) || other.txBytes == txBytes) &&
            (identical(other.lastHandshake, lastHandshake) ||
                other.lastHandshake == lastHandshake) &&
            (identical(other.nodeKey, nodeKey) || other.nodeKey == nodeKey));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, rxBytes, txBytes, lastHandshake, nodeKey);

  /// Create a copy of PeerStatusLite
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PeerStatusLiteImplCopyWith<_$PeerStatusLiteImpl> get copyWith =>
      __$$PeerStatusLiteImplCopyWithImpl<_$PeerStatusLiteImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PeerStatusLiteImplToJson(
      this,
    );
  }
}

abstract class _PeerStatusLite implements PeerStatusLite {
  const factory _PeerStatusLite(
          {@JsonKey(name: 'RxBytes') required final int rxBytes,
          @JsonKey(name: 'TxBytes') required final int txBytes,
          @JsonKey(name: 'LastHandshake') required final String lastHandshake,
          @JsonKey(name: 'NodeKey') required final String nodeKey}) =
      _$PeerStatusLiteImpl;

  factory _PeerStatusLite.fromJson(Map<String, dynamic> json) =
      _$PeerStatusLiteImpl.fromJson;

  @override
  @JsonKey(name: 'RxBytes')
  int get rxBytes;
  @override
  @JsonKey(name: 'TxBytes')
  int get txBytes;
  @override
  @JsonKey(name: 'LastHandshake')
  String get lastHandshake;
  @override
  @JsonKey(name: 'NodeKey')
  String get nodeKey;

  /// Create a copy of PeerStatusLite
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PeerStatusLiteImplCopyWith<_$PeerStatusLiteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PeerStatus _$PeerStatusFromJson(Map<String, dynamic> json) {
  return _PeerStatus.fromJson(json);
}

/// @nodoc
mixin _$PeerStatus {
  @JsonKey(name: 'ID')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'HostName')
  String get hostName => throw _privateConstructorUsedError;
  @JsonKey(name: 'DNSName')
  String get dnsName => throw _privateConstructorUsedError;
  @JsonKey(name: 'TailscaleIPs')
  List<String>? get tailscaleIPs => throw _privateConstructorUsedError;
  @JsonKey(name: 'Tags')
  List<String>? get tags => throw _privateConstructorUsedError;
  @JsonKey(name: 'PrimaryRoutes')
  List<String>? get primaryRoutes => throw _privateConstructorUsedError;
  @JsonKey(name: 'Addrs')
  List<String>? get addrs => throw _privateConstructorUsedError;
  @JsonKey(name: 'CurAddr')
  String? get curAddr => throw _privateConstructorUsedError;
  @JsonKey(name: 'Relay')
  String? get relay => throw _privateConstructorUsedError;
  @JsonKey(name: 'Online')
  bool get online => throw _privateConstructorUsedError;
  @JsonKey(name: 'ExitNode')
  bool get exitNode => throw _privateConstructorUsedError;
  @JsonKey(name: 'ExitNodeOption')
  bool get exitNodeOption => throw _privateConstructorUsedError;
  @JsonKey(name: 'Active')
  bool get active => throw _privateConstructorUsedError;
  @JsonKey(name: 'PeerAPIURL')
  List<String>? get peerAPIUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'Capabilities')
  List<String>? get capabilities => throw _privateConstructorUsedError;
  @JsonKey(name: 'SSH_HostKeys')
  List<String>? get sshHostKeys => throw _privateConstructorUsedError;
  @JsonKey(name: 'ShareeNode')
  bool? get shareeNode => throw _privateConstructorUsedError;
  @JsonKey(name: 'Expired')
  bool? get expired => throw _privateConstructorUsedError;
  @JsonKey(name: 'Location')
  Location? get location => throw _privateConstructorUsedError;

  /// Serializes this PeerStatus to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PeerStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PeerStatusCopyWith<PeerStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PeerStatusCopyWith<$Res> {
  factory $PeerStatusCopyWith(
          PeerStatus value, $Res Function(PeerStatus) then) =
      _$PeerStatusCopyWithImpl<$Res, PeerStatus>;
  @useResult
  $Res call(
      {@JsonKey(name: 'ID') String id,
      @JsonKey(name: 'HostName') String hostName,
      @JsonKey(name: 'DNSName') String dnsName,
      @JsonKey(name: 'TailscaleIPs') List<String>? tailscaleIPs,
      @JsonKey(name: 'Tags') List<String>? tags,
      @JsonKey(name: 'PrimaryRoutes') List<String>? primaryRoutes,
      @JsonKey(name: 'Addrs') List<String>? addrs,
      @JsonKey(name: 'CurAddr') String? curAddr,
      @JsonKey(name: 'Relay') String? relay,
      @JsonKey(name: 'Online') bool online,
      @JsonKey(name: 'ExitNode') bool exitNode,
      @JsonKey(name: 'ExitNodeOption') bool exitNodeOption,
      @JsonKey(name: 'Active') bool active,
      @JsonKey(name: 'PeerAPIURL') List<String>? peerAPIUrl,
      @JsonKey(name: 'Capabilities') List<String>? capabilities,
      @JsonKey(name: 'SSH_HostKeys') List<String>? sshHostKeys,
      @JsonKey(name: 'ShareeNode') bool? shareeNode,
      @JsonKey(name: 'Expired') bool? expired,
      @JsonKey(name: 'Location') Location? location});

  $LocationCopyWith<$Res>? get location;
}

/// @nodoc
class _$PeerStatusCopyWithImpl<$Res, $Val extends PeerStatus>
    implements $PeerStatusCopyWith<$Res> {
  _$PeerStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PeerStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? hostName = null,
    Object? dnsName = null,
    Object? tailscaleIPs = freezed,
    Object? tags = freezed,
    Object? primaryRoutes = freezed,
    Object? addrs = freezed,
    Object? curAddr = freezed,
    Object? relay = freezed,
    Object? online = null,
    Object? exitNode = null,
    Object? exitNodeOption = null,
    Object? active = null,
    Object? peerAPIUrl = freezed,
    Object? capabilities = freezed,
    Object? sshHostKeys = freezed,
    Object? shareeNode = freezed,
    Object? expired = freezed,
    Object? location = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      hostName: null == hostName
          ? _value.hostName
          : hostName // ignore: cast_nullable_to_non_nullable
              as String,
      dnsName: null == dnsName
          ? _value.dnsName
          : dnsName // ignore: cast_nullable_to_non_nullable
              as String,
      tailscaleIPs: freezed == tailscaleIPs
          ? _value.tailscaleIPs
          : tailscaleIPs // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      tags: freezed == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      primaryRoutes: freezed == primaryRoutes
          ? _value.primaryRoutes
          : primaryRoutes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      addrs: freezed == addrs
          ? _value.addrs
          : addrs // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      curAddr: freezed == curAddr
          ? _value.curAddr
          : curAddr // ignore: cast_nullable_to_non_nullable
              as String?,
      relay: freezed == relay
          ? _value.relay
          : relay // ignore: cast_nullable_to_non_nullable
              as String?,
      online: null == online
          ? _value.online
          : online // ignore: cast_nullable_to_non_nullable
              as bool,
      exitNode: null == exitNode
          ? _value.exitNode
          : exitNode // ignore: cast_nullable_to_non_nullable
              as bool,
      exitNodeOption: null == exitNodeOption
          ? _value.exitNodeOption
          : exitNodeOption // ignore: cast_nullable_to_non_nullable
              as bool,
      active: null == active
          ? _value.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool,
      peerAPIUrl: freezed == peerAPIUrl
          ? _value.peerAPIUrl
          : peerAPIUrl // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      capabilities: freezed == capabilities
          ? _value.capabilities
          : capabilities // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      sshHostKeys: freezed == sshHostKeys
          ? _value.sshHostKeys
          : sshHostKeys // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      shareeNode: freezed == shareeNode
          ? _value.shareeNode
          : shareeNode // ignore: cast_nullable_to_non_nullable
              as bool?,
      expired: freezed == expired
          ? _value.expired
          : expired // ignore: cast_nullable_to_non_nullable
              as bool?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as Location?,
    ) as $Val);
  }

  /// Create a copy of PeerStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LocationCopyWith<$Res>? get location {
    if (_value.location == null) {
      return null;
    }

    return $LocationCopyWith<$Res>(_value.location!, (value) {
      return _then(_value.copyWith(location: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PeerStatusImplCopyWith<$Res>
    implements $PeerStatusCopyWith<$Res> {
  factory _$$PeerStatusImplCopyWith(
          _$PeerStatusImpl value, $Res Function(_$PeerStatusImpl) then) =
      __$$PeerStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'ID') String id,
      @JsonKey(name: 'HostName') String hostName,
      @JsonKey(name: 'DNSName') String dnsName,
      @JsonKey(name: 'TailscaleIPs') List<String>? tailscaleIPs,
      @JsonKey(name: 'Tags') List<String>? tags,
      @JsonKey(name: 'PrimaryRoutes') List<String>? primaryRoutes,
      @JsonKey(name: 'Addrs') List<String>? addrs,
      @JsonKey(name: 'CurAddr') String? curAddr,
      @JsonKey(name: 'Relay') String? relay,
      @JsonKey(name: 'Online') bool online,
      @JsonKey(name: 'ExitNode') bool exitNode,
      @JsonKey(name: 'ExitNodeOption') bool exitNodeOption,
      @JsonKey(name: 'Active') bool active,
      @JsonKey(name: 'PeerAPIURL') List<String>? peerAPIUrl,
      @JsonKey(name: 'Capabilities') List<String>? capabilities,
      @JsonKey(name: 'SSH_HostKeys') List<String>? sshHostKeys,
      @JsonKey(name: 'ShareeNode') bool? shareeNode,
      @JsonKey(name: 'Expired') bool? expired,
      @JsonKey(name: 'Location') Location? location});

  @override
  $LocationCopyWith<$Res>? get location;
}

/// @nodoc
class __$$PeerStatusImplCopyWithImpl<$Res>
    extends _$PeerStatusCopyWithImpl<$Res, _$PeerStatusImpl>
    implements _$$PeerStatusImplCopyWith<$Res> {
  __$$PeerStatusImplCopyWithImpl(
      _$PeerStatusImpl _value, $Res Function(_$PeerStatusImpl) _then)
      : super(_value, _then);

  /// Create a copy of PeerStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? hostName = null,
    Object? dnsName = null,
    Object? tailscaleIPs = freezed,
    Object? tags = freezed,
    Object? primaryRoutes = freezed,
    Object? addrs = freezed,
    Object? curAddr = freezed,
    Object? relay = freezed,
    Object? online = null,
    Object? exitNode = null,
    Object? exitNodeOption = null,
    Object? active = null,
    Object? peerAPIUrl = freezed,
    Object? capabilities = freezed,
    Object? sshHostKeys = freezed,
    Object? shareeNode = freezed,
    Object? expired = freezed,
    Object? location = freezed,
  }) {
    return _then(_$PeerStatusImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      hostName: null == hostName
          ? _value.hostName
          : hostName // ignore: cast_nullable_to_non_nullable
              as String,
      dnsName: null == dnsName
          ? _value.dnsName
          : dnsName // ignore: cast_nullable_to_non_nullable
              as String,
      tailscaleIPs: freezed == tailscaleIPs
          ? _value._tailscaleIPs
          : tailscaleIPs // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      tags: freezed == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      primaryRoutes: freezed == primaryRoutes
          ? _value._primaryRoutes
          : primaryRoutes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      addrs: freezed == addrs
          ? _value._addrs
          : addrs // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      curAddr: freezed == curAddr
          ? _value.curAddr
          : curAddr // ignore: cast_nullable_to_non_nullable
              as String?,
      relay: freezed == relay
          ? _value.relay
          : relay // ignore: cast_nullable_to_non_nullable
              as String?,
      online: null == online
          ? _value.online
          : online // ignore: cast_nullable_to_non_nullable
              as bool,
      exitNode: null == exitNode
          ? _value.exitNode
          : exitNode // ignore: cast_nullable_to_non_nullable
              as bool,
      exitNodeOption: null == exitNodeOption
          ? _value.exitNodeOption
          : exitNodeOption // ignore: cast_nullable_to_non_nullable
              as bool,
      active: null == active
          ? _value.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool,
      peerAPIUrl: freezed == peerAPIUrl
          ? _value._peerAPIUrl
          : peerAPIUrl // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      capabilities: freezed == capabilities
          ? _value._capabilities
          : capabilities // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      sshHostKeys: freezed == sshHostKeys
          ? _value._sshHostKeys
          : sshHostKeys // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      shareeNode: freezed == shareeNode
          ? _value.shareeNode
          : shareeNode // ignore: cast_nullable_to_non_nullable
              as bool?,
      expired: freezed == expired
          ? _value.expired
          : expired // ignore: cast_nullable_to_non_nullable
              as bool?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as Location?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PeerStatusImpl implements _PeerStatus {
  const _$PeerStatusImpl(
      {@JsonKey(name: 'ID') required this.id,
      @JsonKey(name: 'HostName') required this.hostName,
      @JsonKey(name: 'DNSName') required this.dnsName,
      @JsonKey(name: 'TailscaleIPs') final List<String>? tailscaleIPs,
      @JsonKey(name: 'Tags') final List<String>? tags,
      @JsonKey(name: 'PrimaryRoutes') final List<String>? primaryRoutes,
      @JsonKey(name: 'Addrs') final List<String>? addrs,
      @JsonKey(name: 'CurAddr') this.curAddr,
      @JsonKey(name: 'Relay') this.relay,
      @JsonKey(name: 'Online') required this.online,
      @JsonKey(name: 'ExitNode') required this.exitNode,
      @JsonKey(name: 'ExitNodeOption') required this.exitNodeOption,
      @JsonKey(name: 'Active') required this.active,
      @JsonKey(name: 'PeerAPIURL') final List<String>? peerAPIUrl,
      @JsonKey(name: 'Capabilities') final List<String>? capabilities,
      @JsonKey(name: 'SSH_HostKeys') final List<String>? sshHostKeys,
      @JsonKey(name: 'ShareeNode') this.shareeNode,
      @JsonKey(name: 'Expired') this.expired,
      @JsonKey(name: 'Location') this.location})
      : _tailscaleIPs = tailscaleIPs,
        _tags = tags,
        _primaryRoutes = primaryRoutes,
        _addrs = addrs,
        _peerAPIUrl = peerAPIUrl,
        _capabilities = capabilities,
        _sshHostKeys = sshHostKeys;

  factory _$PeerStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$PeerStatusImplFromJson(json);

  @override
  @JsonKey(name: 'ID')
  final String id;
  @override
  @JsonKey(name: 'HostName')
  final String hostName;
  @override
  @JsonKey(name: 'DNSName')
  final String dnsName;
  final List<String>? _tailscaleIPs;
  @override
  @JsonKey(name: 'TailscaleIPs')
  List<String>? get tailscaleIPs {
    final value = _tailscaleIPs;
    if (value == null) return null;
    if (_tailscaleIPs is EqualUnmodifiableListView) return _tailscaleIPs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _tags;
  @override
  @JsonKey(name: 'Tags')
  List<String>? get tags {
    final value = _tags;
    if (value == null) return null;
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _primaryRoutes;
  @override
  @JsonKey(name: 'PrimaryRoutes')
  List<String>? get primaryRoutes {
    final value = _primaryRoutes;
    if (value == null) return null;
    if (_primaryRoutes is EqualUnmodifiableListView) return _primaryRoutes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _addrs;
  @override
  @JsonKey(name: 'Addrs')
  List<String>? get addrs {
    final value = _addrs;
    if (value == null) return null;
    if (_addrs is EqualUnmodifiableListView) return _addrs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'CurAddr')
  final String? curAddr;
  @override
  @JsonKey(name: 'Relay')
  final String? relay;
  @override
  @JsonKey(name: 'Online')
  final bool online;
  @override
  @JsonKey(name: 'ExitNode')
  final bool exitNode;
  @override
  @JsonKey(name: 'ExitNodeOption')
  final bool exitNodeOption;
  @override
  @JsonKey(name: 'Active')
  final bool active;
  final List<String>? _peerAPIUrl;
  @override
  @JsonKey(name: 'PeerAPIURL')
  List<String>? get peerAPIUrl {
    final value = _peerAPIUrl;
    if (value == null) return null;
    if (_peerAPIUrl is EqualUnmodifiableListView) return _peerAPIUrl;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _capabilities;
  @override
  @JsonKey(name: 'Capabilities')
  List<String>? get capabilities {
    final value = _capabilities;
    if (value == null) return null;
    if (_capabilities is EqualUnmodifiableListView) return _capabilities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _sshHostKeys;
  @override
  @JsonKey(name: 'SSH_HostKeys')
  List<String>? get sshHostKeys {
    final value = _sshHostKeys;
    if (value == null) return null;
    if (_sshHostKeys is EqualUnmodifiableListView) return _sshHostKeys;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'ShareeNode')
  final bool? shareeNode;
  @override
  @JsonKey(name: 'Expired')
  final bool? expired;
  @override
  @JsonKey(name: 'Location')
  final Location? location;

  @override
  String toString() {
    return 'PeerStatus(id: $id, hostName: $hostName, dnsName: $dnsName, tailscaleIPs: $tailscaleIPs, tags: $tags, primaryRoutes: $primaryRoutes, addrs: $addrs, curAddr: $curAddr, relay: $relay, online: $online, exitNode: $exitNode, exitNodeOption: $exitNodeOption, active: $active, peerAPIUrl: $peerAPIUrl, capabilities: $capabilities, sshHostKeys: $sshHostKeys, shareeNode: $shareeNode, expired: $expired, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PeerStatusImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.hostName, hostName) ||
                other.hostName == hostName) &&
            (identical(other.dnsName, dnsName) || other.dnsName == dnsName) &&
            const DeepCollectionEquality()
                .equals(other._tailscaleIPs, _tailscaleIPs) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality()
                .equals(other._primaryRoutes, _primaryRoutes) &&
            const DeepCollectionEquality().equals(other._addrs, _addrs) &&
            (identical(other.curAddr, curAddr) || other.curAddr == curAddr) &&
            (identical(other.relay, relay) || other.relay == relay) &&
            (identical(other.online, online) || other.online == online) &&
            (identical(other.exitNode, exitNode) ||
                other.exitNode == exitNode) &&
            (identical(other.exitNodeOption, exitNodeOption) ||
                other.exitNodeOption == exitNodeOption) &&
            (identical(other.active, active) || other.active == active) &&
            const DeepCollectionEquality()
                .equals(other._peerAPIUrl, _peerAPIUrl) &&
            const DeepCollectionEquality()
                .equals(other._capabilities, _capabilities) &&
            const DeepCollectionEquality()
                .equals(other._sshHostKeys, _sshHostKeys) &&
            (identical(other.shareeNode, shareeNode) ||
                other.shareeNode == shareeNode) &&
            (identical(other.expired, expired) || other.expired == expired) &&
            (identical(other.location, location) ||
                other.location == location));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        hostName,
        dnsName,
        const DeepCollectionEquality().hash(_tailscaleIPs),
        const DeepCollectionEquality().hash(_tags),
        const DeepCollectionEquality().hash(_primaryRoutes),
        const DeepCollectionEquality().hash(_addrs),
        curAddr,
        relay,
        online,
        exitNode,
        exitNodeOption,
        active,
        const DeepCollectionEquality().hash(_peerAPIUrl),
        const DeepCollectionEquality().hash(_capabilities),
        const DeepCollectionEquality().hash(_sshHostKeys),
        shareeNode,
        expired,
        location
      ]);

  /// Create a copy of PeerStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PeerStatusImplCopyWith<_$PeerStatusImpl> get copyWith =>
      __$$PeerStatusImplCopyWithImpl<_$PeerStatusImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PeerStatusImplToJson(
      this,
    );
  }
}

abstract class _PeerStatus implements PeerStatus {
  const factory _PeerStatus(
      {@JsonKey(name: 'ID') required final String id,
      @JsonKey(name: 'HostName') required final String hostName,
      @JsonKey(name: 'DNSName') required final String dnsName,
      @JsonKey(name: 'TailscaleIPs') final List<String>? tailscaleIPs,
      @JsonKey(name: 'Tags') final List<String>? tags,
      @JsonKey(name: 'PrimaryRoutes') final List<String>? primaryRoutes,
      @JsonKey(name: 'Addrs') final List<String>? addrs,
      @JsonKey(name: 'CurAddr') final String? curAddr,
      @JsonKey(name: 'Relay') final String? relay,
      @JsonKey(name: 'Online') required final bool online,
      @JsonKey(name: 'ExitNode') required final bool exitNode,
      @JsonKey(name: 'ExitNodeOption') required final bool exitNodeOption,
      @JsonKey(name: 'Active') required final bool active,
      @JsonKey(name: 'PeerAPIURL') final List<String>? peerAPIUrl,
      @JsonKey(name: 'Capabilities') final List<String>? capabilities,
      @JsonKey(name: 'SSH_HostKeys') final List<String>? sshHostKeys,
      @JsonKey(name: 'ShareeNode') final bool? shareeNode,
      @JsonKey(name: 'Expired') final bool? expired,
      @JsonKey(name: 'Location') final Location? location}) = _$PeerStatusImpl;

  factory _PeerStatus.fromJson(Map<String, dynamic> json) =
      _$PeerStatusImpl.fromJson;

  @override
  @JsonKey(name: 'ID')
  String get id;
  @override
  @JsonKey(name: 'HostName')
  String get hostName;
  @override
  @JsonKey(name: 'DNSName')
  String get dnsName;
  @override
  @JsonKey(name: 'TailscaleIPs')
  List<String>? get tailscaleIPs;
  @override
  @JsonKey(name: 'Tags')
  List<String>? get tags;
  @override
  @JsonKey(name: 'PrimaryRoutes')
  List<String>? get primaryRoutes;
  @override
  @JsonKey(name: 'Addrs')
  List<String>? get addrs;
  @override
  @JsonKey(name: 'CurAddr')
  String? get curAddr;
  @override
  @JsonKey(name: 'Relay')
  String? get relay;
  @override
  @JsonKey(name: 'Online')
  bool get online;
  @override
  @JsonKey(name: 'ExitNode')
  bool get exitNode;
  @override
  @JsonKey(name: 'ExitNodeOption')
  bool get exitNodeOption;
  @override
  @JsonKey(name: 'Active')
  bool get active;
  @override
  @JsonKey(name: 'PeerAPIURL')
  List<String>? get peerAPIUrl;
  @override
  @JsonKey(name: 'Capabilities')
  List<String>? get capabilities;
  @override
  @JsonKey(name: 'SSH_HostKeys')
  List<String>? get sshHostKeys;
  @override
  @JsonKey(name: 'ShareeNode')
  bool? get shareeNode;
  @override
  @JsonKey(name: 'Expired')
  bool? get expired;
  @override
  @JsonKey(name: 'Location')
  Location? get location;

  /// Create a copy of PeerStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PeerStatusImplCopyWith<_$PeerStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExitNodeStatus _$ExitNodeStatusFromJson(Map<String, dynamic> json) {
  return _ExitNodeStatus.fromJson(json);
}

/// @nodoc
mixin _$ExitNodeStatus {
  @JsonKey(name: 'ID')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'Online')
  bool get online => throw _privateConstructorUsedError;
  @JsonKey(name: 'TailscaleIPs')
  List<String>? get tailscaleIPs => throw _privateConstructorUsedError;

  /// Serializes this ExitNodeStatus to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExitNodeStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExitNodeStatusCopyWith<ExitNodeStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExitNodeStatusCopyWith<$Res> {
  factory $ExitNodeStatusCopyWith(
          ExitNodeStatus value, $Res Function(ExitNodeStatus) then) =
      _$ExitNodeStatusCopyWithImpl<$Res, ExitNodeStatus>;
  @useResult
  $Res call(
      {@JsonKey(name: 'ID') String id,
      @JsonKey(name: 'Online') bool online,
      @JsonKey(name: 'TailscaleIPs') List<String>? tailscaleIPs});
}

/// @nodoc
class _$ExitNodeStatusCopyWithImpl<$Res, $Val extends ExitNodeStatus>
    implements $ExitNodeStatusCopyWith<$Res> {
  _$ExitNodeStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExitNodeStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? online = null,
    Object? tailscaleIPs = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      online: null == online
          ? _value.online
          : online // ignore: cast_nullable_to_non_nullable
              as bool,
      tailscaleIPs: freezed == tailscaleIPs
          ? _value.tailscaleIPs
          : tailscaleIPs // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExitNodeStatusImplCopyWith<$Res>
    implements $ExitNodeStatusCopyWith<$Res> {
  factory _$$ExitNodeStatusImplCopyWith(_$ExitNodeStatusImpl value,
          $Res Function(_$ExitNodeStatusImpl) then) =
      __$$ExitNodeStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'ID') String id,
      @JsonKey(name: 'Online') bool online,
      @JsonKey(name: 'TailscaleIPs') List<String>? tailscaleIPs});
}

/// @nodoc
class __$$ExitNodeStatusImplCopyWithImpl<$Res>
    extends _$ExitNodeStatusCopyWithImpl<$Res, _$ExitNodeStatusImpl>
    implements _$$ExitNodeStatusImplCopyWith<$Res> {
  __$$ExitNodeStatusImplCopyWithImpl(
      _$ExitNodeStatusImpl _value, $Res Function(_$ExitNodeStatusImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExitNodeStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? online = null,
    Object? tailscaleIPs = freezed,
  }) {
    return _then(_$ExitNodeStatusImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      online: null == online
          ? _value.online
          : online // ignore: cast_nullable_to_non_nullable
              as bool,
      tailscaleIPs: freezed == tailscaleIPs
          ? _value._tailscaleIPs
          : tailscaleIPs // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExitNodeStatusImpl implements _ExitNodeStatus {
  const _$ExitNodeStatusImpl(
      {@JsonKey(name: 'ID') required this.id,
      @JsonKey(name: 'Online') required this.online,
      @JsonKey(name: 'TailscaleIPs') final List<String>? tailscaleIPs})
      : _tailscaleIPs = tailscaleIPs;

  factory _$ExitNodeStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExitNodeStatusImplFromJson(json);

  @override
  @JsonKey(name: 'ID')
  final String id;
  @override
  @JsonKey(name: 'Online')
  final bool online;
  final List<String>? _tailscaleIPs;
  @override
  @JsonKey(name: 'TailscaleIPs')
  List<String>? get tailscaleIPs {
    final value = _tailscaleIPs;
    if (value == null) return null;
    if (_tailscaleIPs is EqualUnmodifiableListView) return _tailscaleIPs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'ExitNodeStatus(id: $id, online: $online, tailscaleIPs: $tailscaleIPs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExitNodeStatusImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.online, online) || other.online == online) &&
            const DeepCollectionEquality()
                .equals(other._tailscaleIPs, _tailscaleIPs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, online,
      const DeepCollectionEquality().hash(_tailscaleIPs));

  /// Create a copy of ExitNodeStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExitNodeStatusImplCopyWith<_$ExitNodeStatusImpl> get copyWith =>
      __$$ExitNodeStatusImplCopyWithImpl<_$ExitNodeStatusImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExitNodeStatusImplToJson(
      this,
    );
  }
}

abstract class _ExitNodeStatus implements ExitNodeStatus {
  const factory _ExitNodeStatus(
          {@JsonKey(name: 'ID') required final String id,
          @JsonKey(name: 'Online') required final bool online,
          @JsonKey(name: 'TailscaleIPs') final List<String>? tailscaleIPs}) =
      _$ExitNodeStatusImpl;

  factory _ExitNodeStatus.fromJson(Map<String, dynamic> json) =
      _$ExitNodeStatusImpl.fromJson;

  @override
  @JsonKey(name: 'ID')
  String get id;
  @override
  @JsonKey(name: 'Online')
  bool get online;
  @override
  @JsonKey(name: 'TailscaleIPs')
  List<String>? get tailscaleIPs;

  /// Create a copy of ExitNodeStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExitNodeStatusImplCopyWith<_$ExitNodeStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TailnetStatus _$TailnetStatusFromJson(Map<String, dynamic> json) {
  return _TailnetStatus.fromJson(json);
}

/// @nodoc
mixin _$TailnetStatus {
  @JsonKey(name: 'Name')
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'MagicDNSSuffix')
  String get magicDNSSuffix => throw _privateConstructorUsedError;
  @JsonKey(name: 'MagicDNSEnabled')
  bool get magicDNSEnabled => throw _privateConstructorUsedError;

  /// Serializes this TailnetStatus to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TailnetStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TailnetStatusCopyWith<TailnetStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TailnetStatusCopyWith<$Res> {
  factory $TailnetStatusCopyWith(
          TailnetStatus value, $Res Function(TailnetStatus) then) =
      _$TailnetStatusCopyWithImpl<$Res, TailnetStatus>;
  @useResult
  $Res call(
      {@JsonKey(name: 'Name') String name,
      @JsonKey(name: 'MagicDNSSuffix') String magicDNSSuffix,
      @JsonKey(name: 'MagicDNSEnabled') bool magicDNSEnabled});
}

/// @nodoc
class _$TailnetStatusCopyWithImpl<$Res, $Val extends TailnetStatus>
    implements $TailnetStatusCopyWith<$Res> {
  _$TailnetStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TailnetStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? magicDNSSuffix = null,
    Object? magicDNSEnabled = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      magicDNSSuffix: null == magicDNSSuffix
          ? _value.magicDNSSuffix
          : magicDNSSuffix // ignore: cast_nullable_to_non_nullable
              as String,
      magicDNSEnabled: null == magicDNSEnabled
          ? _value.magicDNSEnabled
          : magicDNSEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TailnetStatusImplCopyWith<$Res>
    implements $TailnetStatusCopyWith<$Res> {
  factory _$$TailnetStatusImplCopyWith(
          _$TailnetStatusImpl value, $Res Function(_$TailnetStatusImpl) then) =
      __$$TailnetStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Name') String name,
      @JsonKey(name: 'MagicDNSSuffix') String magicDNSSuffix,
      @JsonKey(name: 'MagicDNSEnabled') bool magicDNSEnabled});
}

/// @nodoc
class __$$TailnetStatusImplCopyWithImpl<$Res>
    extends _$TailnetStatusCopyWithImpl<$Res, _$TailnetStatusImpl>
    implements _$$TailnetStatusImplCopyWith<$Res> {
  __$$TailnetStatusImplCopyWithImpl(
      _$TailnetStatusImpl _value, $Res Function(_$TailnetStatusImpl) _then)
      : super(_value, _then);

  /// Create a copy of TailnetStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? magicDNSSuffix = null,
    Object? magicDNSEnabled = null,
  }) {
    return _then(_$TailnetStatusImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      magicDNSSuffix: null == magicDNSSuffix
          ? _value.magicDNSSuffix
          : magicDNSSuffix // ignore: cast_nullable_to_non_nullable
              as String,
      magicDNSEnabled: null == magicDNSEnabled
          ? _value.magicDNSEnabled
          : magicDNSEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TailnetStatusImpl implements _TailnetStatus {
  const _$TailnetStatusImpl(
      {@JsonKey(name: 'Name') required this.name,
      @JsonKey(name: 'MagicDNSSuffix') required this.magicDNSSuffix,
      @JsonKey(name: 'MagicDNSEnabled') required this.magicDNSEnabled});

  factory _$TailnetStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$TailnetStatusImplFromJson(json);

  @override
  @JsonKey(name: 'Name')
  final String name;
  @override
  @JsonKey(name: 'MagicDNSSuffix')
  final String magicDNSSuffix;
  @override
  @JsonKey(name: 'MagicDNSEnabled')
  final bool magicDNSEnabled;

  @override
  String toString() {
    return 'TailnetStatus(name: $name, magicDNSSuffix: $magicDNSSuffix, magicDNSEnabled: $magicDNSEnabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TailnetStatusImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.magicDNSSuffix, magicDNSSuffix) ||
                other.magicDNSSuffix == magicDNSSuffix) &&
            (identical(other.magicDNSEnabled, magicDNSEnabled) ||
                other.magicDNSEnabled == magicDNSEnabled));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, magicDNSSuffix, magicDNSEnabled);

  /// Create a copy of TailnetStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TailnetStatusImplCopyWith<_$TailnetStatusImpl> get copyWith =>
      __$$TailnetStatusImplCopyWithImpl<_$TailnetStatusImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TailnetStatusImplToJson(
      this,
    );
  }
}

abstract class _TailnetStatus implements TailnetStatus {
  const factory _TailnetStatus(
      {@JsonKey(name: 'Name') required final String name,
      @JsonKey(name: 'MagicDNSSuffix') required final String magicDNSSuffix,
      @JsonKey(name: 'MagicDNSEnabled')
      required final bool magicDNSEnabled}) = _$TailnetStatusImpl;

  factory _TailnetStatus.fromJson(Map<String, dynamic> json) =
      _$TailnetStatusImpl.fromJson;

  @override
  @JsonKey(name: 'Name')
  String get name;
  @override
  @JsonKey(name: 'MagicDNSSuffix')
  String get magicDNSSuffix;
  @override
  @JsonKey(name: 'MagicDNSEnabled')
  bool get magicDNSEnabled;

  /// Create a copy of TailnetStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TailnetStatusImplCopyWith<_$TailnetStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Status _$StatusFromJson(Map<String, dynamic> json) {
  return _Status.fromJson(json);
}

/// @nodoc
mixin _$Status {
  @JsonKey(name: 'Version')
  String get version => throw _privateConstructorUsedError;
  @JsonKey(name: 'TUN')
  bool get tun => throw _privateConstructorUsedError;
  @JsonKey(name: 'BackendState')
  String get backendState => throw _privateConstructorUsedError;
  @JsonKey(name: 'AuthURL')
  String get authUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'TailscaleIPs')
  List<String>? get tailscaleIPs => throw _privateConstructorUsedError;
  @JsonKey(name: 'Self')
  PeerStatus? get self => throw _privateConstructorUsedError;
  @JsonKey(name: 'ExitNodeStatus')
  ExitNodeStatus? get exitNodeStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'Health')
  List<String>? get health => throw _privateConstructorUsedError;
  @JsonKey(name: 'CurrentTailnet')
  TailnetStatus? get currentTailnet => throw _privateConstructorUsedError;
  @JsonKey(name: 'CertDomains')
  List<String>? get certDomains => throw _privateConstructorUsedError;
  @JsonKey(name: 'Peer')
  Map<String, PeerStatus>? get peer => throw _privateConstructorUsedError;
  @JsonKey(name: 'User')
  Map<String, UserProfile>? get user => throw _privateConstructorUsedError;
  @JsonKey(name: 'ClientVersion')
  ClientVersion? get clientVersion => throw _privateConstructorUsedError;

  /// Serializes this Status to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Status
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StatusCopyWith<Status> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StatusCopyWith<$Res> {
  factory $StatusCopyWith(Status value, $Res Function(Status) then) =
      _$StatusCopyWithImpl<$Res, Status>;
  @useResult
  $Res call(
      {@JsonKey(name: 'Version') String version,
      @JsonKey(name: 'TUN') bool tun,
      @JsonKey(name: 'BackendState') String backendState,
      @JsonKey(name: 'AuthURL') String authUrl,
      @JsonKey(name: 'TailscaleIPs') List<String>? tailscaleIPs,
      @JsonKey(name: 'Self') PeerStatus? self,
      @JsonKey(name: 'ExitNodeStatus') ExitNodeStatus? exitNodeStatus,
      @JsonKey(name: 'Health') List<String>? health,
      @JsonKey(name: 'CurrentTailnet') TailnetStatus? currentTailnet,
      @JsonKey(name: 'CertDomains') List<String>? certDomains,
      @JsonKey(name: 'Peer') Map<String, PeerStatus>? peer,
      @JsonKey(name: 'User') Map<String, UserProfile>? user,
      @JsonKey(name: 'ClientVersion') ClientVersion? clientVersion});

  $PeerStatusCopyWith<$Res>? get self;
  $ExitNodeStatusCopyWith<$Res>? get exitNodeStatus;
  $TailnetStatusCopyWith<$Res>? get currentTailnet;
  $ClientVersionCopyWith<$Res>? get clientVersion;
}

/// @nodoc
class _$StatusCopyWithImpl<$Res, $Val extends Status>
    implements $StatusCopyWith<$Res> {
  _$StatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Status
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? tun = null,
    Object? backendState = null,
    Object? authUrl = null,
    Object? tailscaleIPs = freezed,
    Object? self = freezed,
    Object? exitNodeStatus = freezed,
    Object? health = freezed,
    Object? currentTailnet = freezed,
    Object? certDomains = freezed,
    Object? peer = freezed,
    Object? user = freezed,
    Object? clientVersion = freezed,
  }) {
    return _then(_value.copyWith(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      tun: null == tun
          ? _value.tun
          : tun // ignore: cast_nullable_to_non_nullable
              as bool,
      backendState: null == backendState
          ? _value.backendState
          : backendState // ignore: cast_nullable_to_non_nullable
              as String,
      authUrl: null == authUrl
          ? _value.authUrl
          : authUrl // ignore: cast_nullable_to_non_nullable
              as String,
      tailscaleIPs: freezed == tailscaleIPs
          ? _value.tailscaleIPs
          : tailscaleIPs // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      self: freezed == self
          ? _value.self
          : self // ignore: cast_nullable_to_non_nullable
              as PeerStatus?,
      exitNodeStatus: freezed == exitNodeStatus
          ? _value.exitNodeStatus
          : exitNodeStatus // ignore: cast_nullable_to_non_nullable
              as ExitNodeStatus?,
      health: freezed == health
          ? _value.health
          : health // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      currentTailnet: freezed == currentTailnet
          ? _value.currentTailnet
          : currentTailnet // ignore: cast_nullable_to_non_nullable
              as TailnetStatus?,
      certDomains: freezed == certDomains
          ? _value.certDomains
          : certDomains // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      peer: freezed == peer
          ? _value.peer
          : peer // ignore: cast_nullable_to_non_nullable
              as Map<String, PeerStatus>?,
      user: freezed == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as Map<String, UserProfile>?,
      clientVersion: freezed == clientVersion
          ? _value.clientVersion
          : clientVersion // ignore: cast_nullable_to_non_nullable
              as ClientVersion?,
    ) as $Val);
  }

  /// Create a copy of Status
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PeerStatusCopyWith<$Res>? get self {
    if (_value.self == null) {
      return null;
    }

    return $PeerStatusCopyWith<$Res>(_value.self!, (value) {
      return _then(_value.copyWith(self: value) as $Val);
    });
  }

  /// Create a copy of Status
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExitNodeStatusCopyWith<$Res>? get exitNodeStatus {
    if (_value.exitNodeStatus == null) {
      return null;
    }

    return $ExitNodeStatusCopyWith<$Res>(_value.exitNodeStatus!, (value) {
      return _then(_value.copyWith(exitNodeStatus: value) as $Val);
    });
  }

  /// Create a copy of Status
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TailnetStatusCopyWith<$Res>? get currentTailnet {
    if (_value.currentTailnet == null) {
      return null;
    }

    return $TailnetStatusCopyWith<$Res>(_value.currentTailnet!, (value) {
      return _then(_value.copyWith(currentTailnet: value) as $Val);
    });
  }

  /// Create a copy of Status
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ClientVersionCopyWith<$Res>? get clientVersion {
    if (_value.clientVersion == null) {
      return null;
    }

    return $ClientVersionCopyWith<$Res>(_value.clientVersion!, (value) {
      return _then(_value.copyWith(clientVersion: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$StatusImplCopyWith<$Res> implements $StatusCopyWith<$Res> {
  factory _$$StatusImplCopyWith(
          _$StatusImpl value, $Res Function(_$StatusImpl) then) =
      __$$StatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Version') String version,
      @JsonKey(name: 'TUN') bool tun,
      @JsonKey(name: 'BackendState') String backendState,
      @JsonKey(name: 'AuthURL') String authUrl,
      @JsonKey(name: 'TailscaleIPs') List<String>? tailscaleIPs,
      @JsonKey(name: 'Self') PeerStatus? self,
      @JsonKey(name: 'ExitNodeStatus') ExitNodeStatus? exitNodeStatus,
      @JsonKey(name: 'Health') List<String>? health,
      @JsonKey(name: 'CurrentTailnet') TailnetStatus? currentTailnet,
      @JsonKey(name: 'CertDomains') List<String>? certDomains,
      @JsonKey(name: 'Peer') Map<String, PeerStatus>? peer,
      @JsonKey(name: 'User') Map<String, UserProfile>? user,
      @JsonKey(name: 'ClientVersion') ClientVersion? clientVersion});

  @override
  $PeerStatusCopyWith<$Res>? get self;
  @override
  $ExitNodeStatusCopyWith<$Res>? get exitNodeStatus;
  @override
  $TailnetStatusCopyWith<$Res>? get currentTailnet;
  @override
  $ClientVersionCopyWith<$Res>? get clientVersion;
}

/// @nodoc
class __$$StatusImplCopyWithImpl<$Res>
    extends _$StatusCopyWithImpl<$Res, _$StatusImpl>
    implements _$$StatusImplCopyWith<$Res> {
  __$$StatusImplCopyWithImpl(
      _$StatusImpl _value, $Res Function(_$StatusImpl) _then)
      : super(_value, _then);

  /// Create a copy of Status
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? tun = null,
    Object? backendState = null,
    Object? authUrl = null,
    Object? tailscaleIPs = freezed,
    Object? self = freezed,
    Object? exitNodeStatus = freezed,
    Object? health = freezed,
    Object? currentTailnet = freezed,
    Object? certDomains = freezed,
    Object? peer = freezed,
    Object? user = freezed,
    Object? clientVersion = freezed,
  }) {
    return _then(_$StatusImpl(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      tun: null == tun
          ? _value.tun
          : tun // ignore: cast_nullable_to_non_nullable
              as bool,
      backendState: null == backendState
          ? _value.backendState
          : backendState // ignore: cast_nullable_to_non_nullable
              as String,
      authUrl: null == authUrl
          ? _value.authUrl
          : authUrl // ignore: cast_nullable_to_non_nullable
              as String,
      tailscaleIPs: freezed == tailscaleIPs
          ? _value._tailscaleIPs
          : tailscaleIPs // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      self: freezed == self
          ? _value.self
          : self // ignore: cast_nullable_to_non_nullable
              as PeerStatus?,
      exitNodeStatus: freezed == exitNodeStatus
          ? _value.exitNodeStatus
          : exitNodeStatus // ignore: cast_nullable_to_non_nullable
              as ExitNodeStatus?,
      health: freezed == health
          ? _value._health
          : health // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      currentTailnet: freezed == currentTailnet
          ? _value.currentTailnet
          : currentTailnet // ignore: cast_nullable_to_non_nullable
              as TailnetStatus?,
      certDomains: freezed == certDomains
          ? _value._certDomains
          : certDomains // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      peer: freezed == peer
          ? _value._peer
          : peer // ignore: cast_nullable_to_non_nullable
              as Map<String, PeerStatus>?,
      user: freezed == user
          ? _value._user
          : user // ignore: cast_nullable_to_non_nullable
              as Map<String, UserProfile>?,
      clientVersion: freezed == clientVersion
          ? _value.clientVersion
          : clientVersion // ignore: cast_nullable_to_non_nullable
              as ClientVersion?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StatusImpl implements _Status {
  const _$StatusImpl(
      {@JsonKey(name: 'Version') required this.version,
      @JsonKey(name: 'TUN') required this.tun,
      @JsonKey(name: 'BackendState') required this.backendState,
      @JsonKey(name: 'AuthURL') required this.authUrl,
      @JsonKey(name: 'TailscaleIPs') final List<String>? tailscaleIPs,
      @JsonKey(name: 'Self') this.self,
      @JsonKey(name: 'ExitNodeStatus') this.exitNodeStatus,
      @JsonKey(name: 'Health') final List<String>? health,
      @JsonKey(name: 'CurrentTailnet') this.currentTailnet,
      @JsonKey(name: 'CertDomains') final List<String>? certDomains,
      @JsonKey(name: 'Peer') final Map<String, PeerStatus>? peer,
      @JsonKey(name: 'User') final Map<String, UserProfile>? user,
      @JsonKey(name: 'ClientVersion') this.clientVersion})
      : _tailscaleIPs = tailscaleIPs,
        _health = health,
        _certDomains = certDomains,
        _peer = peer,
        _user = user;

  factory _$StatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$StatusImplFromJson(json);

  @override
  @JsonKey(name: 'Version')
  final String version;
  @override
  @JsonKey(name: 'TUN')
  final bool tun;
  @override
  @JsonKey(name: 'BackendState')
  final String backendState;
  @override
  @JsonKey(name: 'AuthURL')
  final String authUrl;
  final List<String>? _tailscaleIPs;
  @override
  @JsonKey(name: 'TailscaleIPs')
  List<String>? get tailscaleIPs {
    final value = _tailscaleIPs;
    if (value == null) return null;
    if (_tailscaleIPs is EqualUnmodifiableListView) return _tailscaleIPs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'Self')
  final PeerStatus? self;
  @override
  @JsonKey(name: 'ExitNodeStatus')
  final ExitNodeStatus? exitNodeStatus;
  final List<String>? _health;
  @override
  @JsonKey(name: 'Health')
  List<String>? get health {
    final value = _health;
    if (value == null) return null;
    if (_health is EqualUnmodifiableListView) return _health;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'CurrentTailnet')
  final TailnetStatus? currentTailnet;
  final List<String>? _certDomains;
  @override
  @JsonKey(name: 'CertDomains')
  List<String>? get certDomains {
    final value = _certDomains;
    if (value == null) return null;
    if (_certDomains is EqualUnmodifiableListView) return _certDomains;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, PeerStatus>? _peer;
  @override
  @JsonKey(name: 'Peer')
  Map<String, PeerStatus>? get peer {
    final value = _peer;
    if (value == null) return null;
    if (_peer is EqualUnmodifiableMapView) return _peer;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final Map<String, UserProfile>? _user;
  @override
  @JsonKey(name: 'User')
  Map<String, UserProfile>? get user {
    final value = _user;
    if (value == null) return null;
    if (_user is EqualUnmodifiableMapView) return _user;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'ClientVersion')
  final ClientVersion? clientVersion;

  @override
  String toString() {
    return 'Status(version: $version, tun: $tun, backendState: $backendState, authUrl: $authUrl, tailscaleIPs: $tailscaleIPs, self: $self, exitNodeStatus: $exitNodeStatus, health: $health, currentTailnet: $currentTailnet, certDomains: $certDomains, peer: $peer, user: $user, clientVersion: $clientVersion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StatusImpl &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.tun, tun) || other.tun == tun) &&
            (identical(other.backendState, backendState) ||
                other.backendState == backendState) &&
            (identical(other.authUrl, authUrl) || other.authUrl == authUrl) &&
            const DeepCollectionEquality()
                .equals(other._tailscaleIPs, _tailscaleIPs) &&
            (identical(other.self, self) || other.self == self) &&
            (identical(other.exitNodeStatus, exitNodeStatus) ||
                other.exitNodeStatus == exitNodeStatus) &&
            const DeepCollectionEquality().equals(other._health, _health) &&
            (identical(other.currentTailnet, currentTailnet) ||
                other.currentTailnet == currentTailnet) &&
            const DeepCollectionEquality()
                .equals(other._certDomains, _certDomains) &&
            const DeepCollectionEquality().equals(other._peer, _peer) &&
            const DeepCollectionEquality().equals(other._user, _user) &&
            (identical(other.clientVersion, clientVersion) ||
                other.clientVersion == clientVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      version,
      tun,
      backendState,
      authUrl,
      const DeepCollectionEquality().hash(_tailscaleIPs),
      self,
      exitNodeStatus,
      const DeepCollectionEquality().hash(_health),
      currentTailnet,
      const DeepCollectionEquality().hash(_certDomains),
      const DeepCollectionEquality().hash(_peer),
      const DeepCollectionEquality().hash(_user),
      clientVersion);

  /// Create a copy of Status
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StatusImplCopyWith<_$StatusImpl> get copyWith =>
      __$$StatusImplCopyWithImpl<_$StatusImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StatusImplToJson(
      this,
    );
  }
}

abstract class _Status implements Status {
  const factory _Status(
          {@JsonKey(name: 'Version') required final String version,
          @JsonKey(name: 'TUN') required final bool tun,
          @JsonKey(name: 'BackendState') required final String backendState,
          @JsonKey(name: 'AuthURL') required final String authUrl,
          @JsonKey(name: 'TailscaleIPs') final List<String>? tailscaleIPs,
          @JsonKey(name: 'Self') final PeerStatus? self,
          @JsonKey(name: 'ExitNodeStatus') final ExitNodeStatus? exitNodeStatus,
          @JsonKey(name: 'Health') final List<String>? health,
          @JsonKey(name: 'CurrentTailnet') final TailnetStatus? currentTailnet,
          @JsonKey(name: 'CertDomains') final List<String>? certDomains,
          @JsonKey(name: 'Peer') final Map<String, PeerStatus>? peer,
          @JsonKey(name: 'User') final Map<String, UserProfile>? user,
          @JsonKey(name: 'ClientVersion') final ClientVersion? clientVersion}) =
      _$StatusImpl;

  factory _Status.fromJson(Map<String, dynamic> json) = _$StatusImpl.fromJson;

  @override
  @JsonKey(name: 'Version')
  String get version;
  @override
  @JsonKey(name: 'TUN')
  bool get tun;
  @override
  @JsonKey(name: 'BackendState')
  String get backendState;
  @override
  @JsonKey(name: 'AuthURL')
  String get authUrl;
  @override
  @JsonKey(name: 'TailscaleIPs')
  List<String>? get tailscaleIPs;
  @override
  @JsonKey(name: 'Self')
  PeerStatus? get self;
  @override
  @JsonKey(name: 'ExitNodeStatus')
  ExitNodeStatus? get exitNodeStatus;
  @override
  @JsonKey(name: 'Health')
  List<String>? get health;
  @override
  @JsonKey(name: 'CurrentTailnet')
  TailnetStatus? get currentTailnet;
  @override
  @JsonKey(name: 'CertDomains')
  List<String>? get certDomains;
  @override
  @JsonKey(name: 'Peer')
  Map<String, PeerStatus>? get peer;
  @override
  @JsonKey(name: 'User')
  Map<String, UserProfile>? get user;
  @override
  @JsonKey(name: 'ClientVersion')
  ClientVersion? get clientVersion;

  /// Create a copy of Status
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StatusImplCopyWith<_$StatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
