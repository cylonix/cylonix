import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'ipn.freezed.dart';
part 'ipn.g.dart';

typedef Addr = String;
typedef Prefix = String;
typedef NodeID = int;
typedef KeyNodePublic = String;
typedef MachineKey = String;
typedef UserID = int;
typedef Time = String;
typedef StableNodeID = String;
typedef BugReportID = String;
const _zeroPrivateKey =
    "privkey:0000000000000000000000000000000000000000000000000000000000000000";

enum BackendState {
  noState(0),
  inUseOtherUser(1),
  needsLogin(2),
  needsMachineAuth(3),
  stopped(4),
  starting(5),
  running(6),
  stopping(7);

  const BackendState(this.value);
  final int value;

  static BackendState fromInt(int value) {
    return BackendState.values.firstWhere((state) => state.value == value,
        orElse: () => BackendState.noState);
  }

  static BackendState fromString(String value) {
    return BackendState.values.firstWhere(
        (state) => state.name.toLowerCase() == value.toLowerCase(),
        orElse: () => BackendState.noState);
  }
}

@freezed
class IpnState with _$IpnState {
  const factory IpnState({
    @Default(BackendState.noState) BackendState backendState,
    @Default(VpnState.disconnected) VpnState vpnState,
    UserProfile? loggedInUser,
    Node? selfNode,
    NetworkMap? netmap,
    IpnPrefs? prefs,
    HealthState? health,
    String? browseToURL,
    String? errMessage,
    List<OutgoingFile>? outgoingFiles,
    List<AwaitingFile>? filesWaiting,
    LoginProfile? currentProfile,
    @Default([]) List<LoginProfile> loginProfiles,
    @Default(false) bool isRunningExitNode,
  }) = _IpnState;

  factory IpnState.fromJson(Map<String, dynamic> json) =>
      _$IpnStateFromJson(json);
}

enum VpnState { disconnecting, disconnected, connecting, connected, error }

@freezed
class IpnNotification with _$IpnNotification {
  const factory IpnNotification({
    @JsonKey(name: 'Version') String? version,
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
    @JsonKey(name: 'Health') HealthState? health,
  }) = _IpnNotification;

  factory IpnNotification.fromJson(Map<String, dynamic> json) =>
      _$IpnNotificationFromJson(json);
}

@freezed
class HealthState with _$HealthState {
  const factory HealthState({
    @JsonKey(name: 'Warnings') Map<String, UnhealthyState?>? warnings,
  }) = _HealthState;

  factory HealthState.fromJson(Map<String, dynamic> json) =>
      _$HealthStateFromJson(json);
}

@freezed
class UnhealthyState
    with _$UnhealthyState
    implements Comparable<UnhealthyState> {
  const factory UnhealthyState({
    @JsonKey(name: 'WarnableCode') required String warnableCode,
    @JsonKey(name: 'Severity') required Severity severity,
    @JsonKey(name: 'Title') required String title,
    @JsonKey(name: 'Text') required String text,
    @JsonKey(name: 'BrokenSince') String? brokenSince,
    @JsonKey(name: 'Args') Map<String, String>? args,
    @JsonKey(name: 'ImpactsConnectivity') bool? impactsConnectivity,
    @JsonKey(name: 'DependsOn') List<String>? dependsOn,
  }) = _UnhealthyState;

  const UnhealthyState._();

  bool hiddenByDependencies(Set<String> currentWarnableCodes) {
    return dependsOn?.any((depWarnableCode) =>
            currentWarnableCodes.contains(depWarnableCode)) ??
        false;
  }

  @override
  int compareTo(UnhealthyState other) {
    final severityComparison = severity.index.compareTo(other.severity.index);
    if (severityComparison != 0) {
      return severityComparison;
    }
    return warnableCode.compareTo(other.warnableCode);
  }

  factory UnhealthyState.fromJson(Map<String, dynamic> json) =>
      _$UnhealthyStateFromJson(json);
}

enum Severity {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high;

  ListTileThemeData getListTileTheme(ThemeData theme) {
    switch (this) {
      case Severity.low:
        return ListTileThemeData(
          tileColor: theme.colorScheme.surface,
          textColor: theme.colorScheme.secondary,
          iconColor: theme.colorScheme.secondary,
          titleTextStyle: TextStyle(color: theme.colorScheme.secondary),
          subtitleTextStyle: TextStyle(
            color: theme.colorScheme.secondary.withOpacity(0.8),
          ),
        );
      case Severity.medium:
      case Severity.high:
        return ListTileThemeData(
          tileColor: theme.colorScheme.error,
          textColor: theme.colorScheme.onError,
          iconColor: theme.colorScheme.onError,
          titleTextStyle: TextStyle(color: theme.colorScheme.onError),
          subtitleTextStyle: TextStyle(
            color: theme.colorScheme.onError.withOpacity(0.8),
          ),
        );
    }
  }
}

@freezed
class IpnPrefs with _$IpnPrefs {
  const factory IpnPrefs({
    @JsonKey(name: 'ControlURL') @Default('') String controlURL,
    @JsonKey(name: 'RouteAll') @Default(false) bool routeAll,
    @JsonKey(name: 'AllowsSingleHosts') @Default(false) bool allowsSingleHosts,
    @JsonKey(name: 'CorpDNS') @Default(false) bool corpDNS,
    @JsonKey(name: 'WantRunning') @Default(false) bool wantRunning,
    @JsonKey(name: 'LoggedOut') @Default(false) bool loggedOut,
    @JsonKey(name: 'ShieldsUp') @Default(false) bool shieldsUp,
    @JsonKey(name: 'AdvertiseRoutes') List<String>? advertiseRoutes,
    @JsonKey(name: 'AdvertiseTags') List<String>? advertiseTags,
    @JsonKey(name: 'ExitNodeID') String? exitNodeID,
    @JsonKey(name: 'ExitNodeAllowLANAccess')
    @Default(false)
    bool exitNodeAllowLANAccess,
    @JsonKey(name: 'Config') PersistConfig? config,
    @JsonKey(name: 'ForceDaemon') @Default(false) bool forceDaemon,
    @JsonKey(name: 'HostName') @Default('') String hostName,
    @JsonKey(name: 'AutoUpdate') AutoUpdatePrefs? autoUpdate,
    @JsonKey(name: 'InternalExitNodePrior') String? internalExitNodePrior,
  }) = _IpnPrefs;

  const IpnPrefs._();

  String? get selectedExitNodeID =>
      internalExitNodePrior?.isEmpty ?? true ? null : internalExitNodePrior;

  String? get activeExitNodeID =>
      exitNodeID?.isEmpty ?? true ? null : exitNodeID;

  factory IpnPrefs.fromJson(Map<String, dynamic> json) =>
      _$IpnPrefsFromJson(json);
}

@freezed
class IpnOptions with _$IpnOptions {
  const factory IpnOptions({
    @JsonKey(name: 'FrontendLogID') String? frontendLogID,
    @JsonKey(name: 'UpdatePrefs') IpnPrefs? updatePrefs,
    @JsonKey(name: 'AuthKey') String? authKey,
  }) = _IpnOptions;

  factory IpnOptions.fromJson(Map<String, dynamic> json) =>
      _$IpnOptionsFromJson(json);
}

@freezed
class MaskedPrefs with _$MaskedPrefs {
  const MaskedPrefs._();

  const factory MaskedPrefs({
    @JsonKey(name: 'ControlURLSet') bool? controlURLSet,
    @JsonKey(name: 'RouteAllSet') bool? routeAllSet,
    @JsonKey(name: 'CoprDNSSet') bool? corpDNSSet,
    @JsonKey(name: 'ExitNodeIDSet') bool? exitNodeIDSet,
    @JsonKey(name: 'ExitNodeAllowLANAccessSet') bool? exitNodeAllowLANAccessSet,
    @JsonKey(name: 'WantRunningSet') bool? wantRunningSet,
    @JsonKey(name: 'ShieldsUpSet') bool? shieldsUpSet,
    @JsonKey(name: 'AdvertiseRoutesSet') bool? advertiseRoutesSet,
    @JsonKey(name: 'ForceDaemonSet') bool? forceDaemonSet,
    @JsonKey(name: 'HostnameSet') bool? hostnameSet,
    @JsonKey(name: 'InternalExitNodePriorSet') bool? internalExitNodePriorSet,
    @JsonKey(name: 'ControlURL') String? controlURL,
    @JsonKey(name: 'RouteAll') bool? routeAll,
    @JsonKey(name: 'CorpDNS') bool? corpDNS,
    @JsonKey(name: 'ExitNodeID') StableNodeID? exitNodeID,
    @JsonKey(name: 'InternalExitNodePrior') String? internalExitNodePrior,
    @JsonKey(name: 'ExitNodeAllowLANAccess') bool? exitNodeAllowLANAccess,
    @JsonKey(name: 'WantRunning') bool? wantRunning,
    @JsonKey(name: 'ShieldsUp') bool? shieldsUp,
    @JsonKey(name: 'AdvertiseRoutes') List<String>? advertiseRoutes,
    @JsonKey(name: 'ForceDaemon') bool? forceDaemon,
    @JsonKey(name: 'Hostname') String? hostname,
  }) = _MaskedPrefs;

  factory MaskedPrefs.fromJson(Map<String, dynamic> json) =>
      _$MaskedPrefsFromJson(json);

  MaskedPrefs copyWithControlURL(String? value) => copyWith(
        controlURL: value,
        controlURLSet: true,
      );

  MaskedPrefs copyWithRouteAll(bool? value) => copyWith(
        routeAll: value,
        routeAllSet: true,
      );

  MaskedPrefs copyWithCorpDNS(bool? value) => copyWith(
        corpDNS: value,
        corpDNSSet: true,
      );

  MaskedPrefs copyWithExitNodeID(StableNodeID? value) => copyWith(
        exitNodeID: value,
        exitNodeIDSet: true,
      );

  MaskedPrefs copyWithInternalExitNodePrior(String? value) => copyWith(
        internalExitNodePrior: value,
        internalExitNodePriorSet: true,
      );

  MaskedPrefs copyWithExitNodeAllowLANAccess(bool? value) => copyWith(
        exitNodeAllowLANAccess: value,
        exitNodeAllowLANAccessSet: true,
      );

  MaskedPrefs copyWithWantRunning(bool? value) => copyWith(
        wantRunning: value,
        wantRunningSet: true,
      );

  MaskedPrefs copyWithShieldsUp(bool? value) => copyWith(
        shieldsUp: value,
        shieldsUpSet: true,
      );

  MaskedPrefs copyWithAdvertiseRoutes(List<String>? value) => copyWith(
        advertiseRoutes: value,
        advertiseRoutesSet: true,
      );

  MaskedPrefs copyWithForceDaemon(bool? value) => copyWith(
        forceDaemon: value,
        forceDaemonSet: true,
      );

  MaskedPrefs copyWithHostname(String? value) => copyWith(
        hostname: value,
        hostnameSet: true,
      );
}

@freezed
class PersistConfig with _$PersistConfig {
  const factory PersistConfig({
    @JsonKey(name: 'PrivateMachineKey')
    @Default(_zeroPrivateKey)
    String privateMachineKey,
    @JsonKey(name: 'PrivateNodeKey')
    @Default(_zeroPrivateKey)
    String privateNodeKey,
    @JsonKey(name: 'OldPrivateNodeKey')
    @Default(_zeroPrivateKey)
    String oldPrivateNodeKey,
    @JsonKey(name: 'Provider') @Default('') String provider,
  }) = _PersistConfig;

  factory PersistConfig.fromJson(Map<String, dynamic> json) =>
      _$PersistConfigFromJson(json);
}

@freezed
class NetworkMap with _$NetworkMap {
  const factory NetworkMap({
    @JsonKey(name: 'SelfNode') required Node selfNode,
    @JsonKey(name: 'NodeKey') required KeyNodePublic nodeKey,
    @JsonKey(name: 'Peers') List<Node>? peers,
    @JsonKey(name: 'Expiry') required DateTime expiry,
    @JsonKey(name: 'Domain') required String domain,
    @JsonKey(name: 'UserProfiles')
    required Map<String, UserProfile> userProfiles,
    @JsonKey(name: 'TKAEnabled') required bool tkaEnabled,
    @JsonKey(name: 'DNS') DNSConfig? dns,
  }) = _NetworkMap;

  const NetworkMap._();

  UserProfile? currentUserProfile() => userProfile(user());
  UserID user() => selfNode.userID;
  UserProfile? userProfile(UserID id) => userProfiles[id.toString()];
  Node? getPeer(StableNodeID id) => id == selfNode.stableID
      ? selfNode
      : peers?.firstWhereOrNull((node) => node.stableID == id);

  factory NetworkMap.fromJson(Map<String, dynamic> json) =>
      _$NetworkMapFromJson(json);
}

@freezed
class Node with _$Node {
  const factory Node({
    @JsonKey(name: 'ID') required NodeID id,
    @JsonKey(name: 'StableID') required StableNodeID stableID,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'User') required UserID userID,
    @JsonKey(name: 'Sharer') UserID? sharer,
    @JsonKey(name: 'Key') required KeyNodePublic key,
    @JsonKey(name: 'KeyExpiry') required String keyExpiry,
    @JsonKey(name: 'Machine') required MachineKey machine,
    @JsonKey(name: 'Addresses') required List<Prefix> addresses,
    @JsonKey(name: 'AllowedIPs') required List<Prefix> allowedIPs,
    @JsonKey(name: 'Endpoints') List<String>? endpoints,
    @JsonKey(name: 'Hostinfo') Hostinfo? hostinfo,
    @JsonKey(name: 'Created') Time? created,
    @JsonKey(name: 'LastSeen') Time? lastSeen,
    @JsonKey(name: 'Online') bool? online,
    @JsonKey(name: 'Capabilities') List<String>? capabilities,
    @JsonKey(name: 'CapMap') Map<String, dynamic>? capMap,
    @JsonKey(name: 'ComputedName') String? computedName,
    @JsonKey(name: 'ComputedNameWithHost') String? computedNameWithHost,
  }) = _Node;

  const Node._();

  bool get isAdmin =>
      capabilities?.contains('https://tailscale.com/cap/is-admin') == true ||
      capMap?.containsKey('https://tailscale.com/cap/is-admin') == true;

  String get nodeAdminUrl => primaryIPv4Address != null
      ? '${Links.adminUrl}/machines/$primaryIPv4Address'
      : Links.adminUrl;

  String? get primaryIPv4Address => displayAddresses
      .firstWhereOrNull((addr) => addr.type == AddressType.v4)
      ?.address;

  String? get primaryIPv6Address => displayAddresses
      .firstWhereOrNull((addr) => addr.type == AddressType.v6)
      ?.address;

  bool get isExitNode =>
      allowedIPs.contains('0.0.0.0/0') && allowedIPs.contains('::/0');

  bool get isMullvadNode => name.endsWith('.mullvad.ts.net.');

  String get displayName => computedName ?? name;

  String get exitNodeName {
    final location = hostinfo?.location;
    if (isMullvadNode &&
        location?.country != null &&
        location?.city != null &&
        location?.countryCode != null) {
      return '${location!.flag} ${location.country}: ${location.city}';
    }
    return displayName;
  }

  bool get keyDoesNotExpire => keyExpiry == '0001-01-01T00:00:00Z';

  String get nameWithoutTrailingDot => name.replaceAll(RegExp(r'\.$'), '');

  List<DisplayAddress> get displayAddresses {
    final result = <DisplayAddress>[];
    result.add(DisplayAddress(nameWithoutTrailingDot));
    if (addresses.isNotEmpty) {
      result.addAll(addresses.map((addr) => DisplayAddress(addr)));
    }
    return result;
  }

  bool isSelfNode(NetworkMap netmap) => stableID == netmap.selfNode.stableID;

  bool connectedOrSelfNode(NetworkMap? nm) =>
      online == true || stableID == nm?.selfNode.stableID;

  String connectedString(NetworkMap? nm) =>
      connectedOrSelfNode(nm) ? 'Connected' : 'Not Connected';

  String expiryLabel() {
    if (keyExpiry == GoTimeUtil.zeroTimeString) {
      return 'Device key never expires';
    }
    final expDate = GoTimeUtil.dateFromGoString(keyExpiry);
    final now = DateTime.now();
    final exp = GoTimeUtil.keyExpiryFromGoTime(keyExpiry);
    return expDate.isAfter(now)
        ? 'Device key expires in $exp'
        : 'Device key expired $exp';
  }

  @override
  String toString() => jsonEncode(toJson());

  factory Node.fromJson(Map<String, dynamic> json) => _$NodeFromJson(json);
}

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    @JsonKey(name: 'ID') required int id,
    @JsonKey(name: 'DisplayName') required String displayName,
    @JsonKey(name: 'LoginName') required String loginName,
    @JsonKey(name: 'ProfilePicURL') @Default('') String profilePicURL,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  const UserProfile._();

  String get tailnetTitle {
    final tailnet = loginName.split('@').last;

    // List of well-known public email domains to filter
    const publicDomains = {
      'gmail.com',
      'yahoo.com',
      'hotmail.com',
      'outlook.com',
      'icloud.com',
      'me.com',
      'mac.com',
      'aol.com',
      'live.com',
      'msn.com',
      'protonmail.com',
      'proton.me',
      'privaterelay.appleid.com',
    };

    // Return full loginName if domain is a public email provider
    if (publicDomains.contains(tailnet.toLowerCase())) {
      if (tailnet.toLowerCase() == 'privaterelay.appleid.com') {
        // Special case for Apple Private Relay
        return 'Apple Private Relay';
      }
      return loginName;
    }

    return tailnet.isNotEmpty ? tailnet : loginName;
  }
}

@freezed
class LoginProfile with _$LoginProfile {
  const factory LoginProfile({
    @JsonKey(name: 'ID') required String id,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'Key') required String key,
    @JsonKey(name: 'UserProfile') required UserProfile userProfile,
    @JsonKey(name: 'NetworkProfile') NetworkProfile? networkProfile,
    @JsonKey(name: 'LocalUserID') required String localUserId,
    @JsonKey(name: 'ControlURL') required String controlURL,
  }) = _LoginProfile;

  const LoginProfile._();

  factory LoginProfile.fromJson(Map<String, dynamic> json) =>
      _$LoginProfileFromJson(json);

  bool get isEmpty => id.isEmpty;
}

@freezed
class NetworkProfile with _$NetworkProfile {
  const factory NetworkProfile({
    @JsonKey(name: 'MagicDNSName') String? magicDNSName,
    @JsonKey(name: 'DomainName') String? domainName,
  }) = _NetworkProfile;
  const NetworkProfile._();
  factory NetworkProfile.fromJson(Map<String, dynamic> json) =>
      _$NetworkProfileFromJson(json);
}

@freezed
class DNSHostEntry with _$DNSHostEntry {
  const factory DNSHostEntry({
    @JsonKey(name: 'Addr') String? addr,
    @JsonKey(name: 'Hosts') List<String>? hosts,
  }) = _DNSHostEntry;

  factory DNSHostEntry.fromJson(Map<String, dynamic> json) =>
      _$DNSHostEntryFromJson(json);
}

@freezed
class OSConfig with _$OSConfig {
  const factory OSConfig({
    @JsonKey(name: 'Hosts') List<DNSHostEntry>? hosts,
    @JsonKey(name: 'Nameservers') List<String>? nameservers,
    @JsonKey(name: 'SearchDomains') List<String>? searchDomains,
    @JsonKey(name: 'MatchDomains') List<String>? matchDomains,
  }) = _OSConfig;

  const OSConfig._();

  bool get isEmpty =>
      (hosts?.isEmpty ?? true) &&
      (nameservers?.isEmpty ?? true) &&
      (searchDomains?.isEmpty ?? true) &&
      (matchDomains?.isEmpty ?? true);

  factory OSConfig.fromJson(Map<String, dynamic> json) =>
      _$OSConfigFromJson(json);
}

@freezed
class Resolver with _$Resolver {
  const factory Resolver({
    @JsonKey(name: 'Addr') String? addr,
    @JsonKey(name: 'BootstrapResolution') List<String>? bootstrapResolution,
  }) = _Resolver;

  factory Resolver.fromJson(Map<String, dynamic> json) =>
      _$ResolverFromJson(json);
}

@freezed
class DNSConfig with _$DNSConfig {
  const factory DNSConfig({
    @JsonKey(name: 'Resolvers') List<Resolver>? resolvers,
    @JsonKey(name: 'Routes') Map<String, List<Resolver>?>? routes,
    @JsonKey(name: 'FallbackResolvers') List<Resolver>? fallbackResolvers,
    @JsonKey(name: 'Domains') List<String>? domains,
    @JsonKey(name: 'Nameservers') List<String>? nameservers,
  }) = _DNSConfig;

  factory DNSConfig.fromJson(Map<String, dynamic> json) =>
      _$DNSConfigFromJson(json);
}

@freezed
class Health with _$Health {
  const factory Health({
    @JsonKey(name: 'State') String? state,
    @JsonKey(name: 'Code') int? code,
    @JsonKey(name: 'Message') String? message,
  }) = _Health;

  factory Health.fromJson(Map<String, dynamic> json) => _$HealthFromJson(json);
}

@freezed
class PartialFile with _$PartialFile {
  const factory PartialFile({
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'Started') required String started,
    @JsonKey(name: 'DeclaredSize') required int declaredSize,
    @JsonKey(name: 'Received') required int received,
    @JsonKey(name: 'PartialPath') String? partialPath,
    @JsonKey(name: 'FinalPath') String? finalPath,
    @JsonKey(name: 'Done') bool? done,
  }) = _PartialFile;

  factory PartialFile.fromJson(Map<String, dynamic> json) =>
      _$PartialFileFromJson(json);
}

@freezed
class EngineStatus with _$EngineStatus {
  const factory EngineStatus({
    @JsonKey(name: 'RBytes') required int rBytes,
    @JsonKey(name: 'WBytes') required int wBytes,
    @JsonKey(name: 'NumLive') required int numLive,
    @JsonKey(name: 'LivePeers') required Map<String, PeerStatusLite> livePeers,
  }) = _EngineStatus;

  factory EngineStatus.fromJson(Map<String, dynamic> json) =>
      _$EngineStatusFromJson(json);
}

@freezed
class OutgoingFile with _$OutgoingFile {
  const factory OutgoingFile({
    @JsonKey(name: 'ID') @Default('') String id,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'PeerID') @Default('') String peerID,
    @JsonKey(name: 'Started') String? started,
    @JsonKey(name: 'DeclaredSize') required int declaredSize,
    @JsonKey(name: 'Sent') @Default(0) int sent,
    @JsonKey(name: 'PartialPath') String? partialPath,
    @JsonKey(name: 'FinalPath') String? finalPath,
    @JsonKey(name: 'Finished') @Default(false) bool finished,
    @JsonKey(name: 'Succeeded') @Default(false) bool succeeded,
    @JsonKey(name: 'Path') String? path,
  }) = _OutgoingFile;

  const OutgoingFile._();

  OutgoingFile prepare(String peerID) {
    return OutgoingFile(
      id: const Uuid().v4(),
      name: name,
      peerID: peerID,
      declaredSize: declaredSize,
      path: path,
    );
  }

  factory OutgoingFile.fromJson(Map<String, dynamic> json) =>
      _$OutgoingFileFromJson(json);
}

@freezed
class AutoUpdatePrefs with _$AutoUpdatePrefs {
  const factory AutoUpdatePrefs({
    @JsonKey(name: 'Check') bool? check,
    @JsonKey(name: 'Apply') bool? apply,
  }) = _AutoUpdatePrefs;

  factory AutoUpdatePrefs.fromJson(Map<String, dynamic> json) =>
      _$AutoUpdatePrefsFromJson(json);
}

@freezed
class ClientVersion with _$ClientVersion {
  const factory ClientVersion({
    @JsonKey(name: 'Major') String? major,
    @JsonKey(name: 'Minor') String? minor,
    @JsonKey(name: 'Patch') String? patch,
    @JsonKey(name: 'Suffix') String? suffix,
    @JsonKey(name: 'Candidate') bool? candidate,
  }) = _ClientVersion;

  factory ClientVersion.fromJson(Map<String, dynamic> json) =>
      _$ClientVersionFromJson(json);
}

@freezed
class PeerSet with _$PeerSet {
  const factory PeerSet({
    UserProfile? user,
    required List<Node> peers,
  }) = _PeerSet;
}

class PeerCategorizer {
  Node? selfNode;
  UserProfile? me;
  List<PeerSet> peerSets = [];
  List<PeerSet> lastSearchResult = [];
  String lastSearchTerm = "";

  void regenerateGroupedPeers(NetworkMap netmap) {
    final me = netmap.currentUserProfile();
    final selfNode = netmap.selfNode;
    final grouped = <UserID, List<Node>>{};
    final peers = netmap.peers ?? [];

    final mdm = MDMSettings.hiddenNetworkDevices;
    final hideMyDevices = mdm?.contains('current-user') ?? false;
    final hideOtherDevices = mdm?.contains('other-users') ?? false;
    final hideTaggedDevices = mdm?.contains('tagged-devices') ?? false;

    this.selfNode = selfNode;
    this.me = me;

    for (final peer in [...peers, selfNode]) {
      final userID = peer.userID;
      final profile = netmap.userProfile(userID);

      if (peer.isMullvadNode) continue;
      if (hideMyDevices && userID == me?.id) continue;
      if (hideOtherDevices && userID != me?.id) continue;
      if (hideTaggedDevices && (profile?.isTaggedDevice() ?? false)) continue;

      grouped.putIfAbsent(userID, () => []).add(peer);
    }

    peerSets = grouped.entries.map((entry) {
      final userId = entry.key;
      final peers = entry.value;
      final profile = netmap.userProfile(userId);

      return PeerSet(
        user: profile,
        peers: peers
          ..sort((a, b) {
            if (a.stableID == b.stableID) return 0;
            if (a.isSelfNode(netmap)) return -1;
            if (b.isSelfNode(netmap)) return 1;
            return (a.computedName ?? '')
                .toLowerCase()
                .compareTo((b.computedName ?? '').toLowerCase());
          }),
      );
    }).toList();

    peerSets.sort((a, b) {
      if (a.user?.id == me?.id) return -1;
      if (b.user?.id == me?.id) return 1;
      return (a.user?.displayName ?? 'unknown user')
          .toLowerCase()
          .compareTo((b.user?.displayName ?? 'unknown user').toLowerCase());
    });
  }

  PeerSet? get myPeerSet {
    if (selfNode == null || me == null) return null;
    // Since it is a sorted list, my peer set will be the first one.
    return peerSets.firstWhereOrNull((peerSet) => peerSet.user?.id == me?.id);
  }

  List<PeerSet> groupedAndFilteredPeers([String searchTerm = '']) {
    if (searchTerm.isEmpty) return peerSets;
    if (searchTerm == lastSearchTerm) return lastSearchResult;

    final setsToSearch =
        (lastSearchTerm.isNotEmpty && searchTerm.startsWith(lastSearchTerm))
            ? lastSearchResult
            : peerSets;
    lastSearchTerm = searchTerm;

    lastSearchResult = setsToSearch
        .map((peerSet) {
          final user = peerSet.user;
          final peers = peerSet.peers;

          if (user?.displayName
                  .toLowerCase()
                  .contains(searchTerm.toLowerCase()) ??
              false) {
            return peerSet;
          }

          final matchingPeers = peers.where((peer) {
            return peer.displayName
                    .toLowerCase()
                    .contains(searchTerm.toLowerCase()) ||
                peer.addresses.any((addr) => addr.contains(searchTerm));
          }).toList();

          if (matchingPeers.isNotEmpty) {
            return PeerSet(user: user, peers: matchingPeers);
          }
          return null;
        })
        .whereType<PeerSet>()
        .toList();

    return lastSearchResult;
  }
}

extension NodeHelper on Node {
  bool get isMullvadNode => name.startsWith('mullvad-');
  bool isSelfNode(NetworkMap netmap) => stableID == netmap.selfNode.stableID;
}

extension UserProfileHelper on UserProfile {
  bool isTaggedDevice() => loginName.startsWith('tagged-device-');
}

class MDMSettings {
  static List<String>? get hiddenNetworkDevices => null;
  static String? get keyExpirationNotice => null;
}

@freezed
class Hostinfo with _$Hostinfo {
  const factory Hostinfo({
    @JsonKey(name: 'IPNVersion') String? ipnVersion,
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
    @JsonKey(name: 'Location') Location? location,
  }) = _Hostinfo;

  factory Hostinfo.fromJson(Map<String, dynamic> json) =>
      _$HostinfoFromJson(json);
}

@freezed
class Location with _$Location {
  const factory Location({
    @JsonKey(name: 'Country') String? country,
    @JsonKey(name: 'CountryCode') String? countryCode,
    @JsonKey(name: 'City') String? city,
    @JsonKey(name: 'CityCode') String? cityCode,
    @JsonKey(name: 'Priority') int? priority,
  }) = _Location;

  const Location._();

  String? get flag => countryCode?.toUpperCase().replaceAllMapped(
        RegExp(r'[A-Z]'),
        (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 127397),
      );

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);
}

@freezed
class Service with _$Service {
  const factory Service({
    @JsonKey(name: 'Proto') required String proto,
    @JsonKey(name: 'Port') required int port,
    @JsonKey(name: 'Description') String? description,
  }) = _Service;

  factory Service.fromJson(Map<String, dynamic> json) =>
      _$ServiceFromJson(json);
}

@freezed
class AwaitingFile with _$AwaitingFile {
  const factory AwaitingFile({
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'Size') required int size,
  }) = _AwaitingFile;

  factory AwaitingFile.fromJson(Map<String, dynamic> json) =>
      _$AwaitingFileFromJson(json);
}

class Links {
  Links._();

  static const String defaultControlUrl = 'https://controlplane.tailscale.com';
  static const String serverUrl = 'https://login.tailscale.com';
  static const String adminUrl = '$serverUrl/admin';
  static const String signinUrl = 'https://tailscale.com/login';
  static const String privacyPolicyUrl =
      'https://tailscale.com/privacy-policy/';
  static const String termsUrl = 'https://tailscale.com/terms';
  static const String docsUrl = 'https://tailscale.com/kb/';
  static const String startGuideUrl = 'https://tailscale.com/kb/1017/install/';
  static const String licensesUrl = 'https://tailscale.com/licenses/android';
  static const String deleteAccountUrl =
      'https://login.tailscale.com/login?next_url=%2Fadmin%2Fsettings%2Fgeneral';
  static const String tailnetLockKbUrl =
      'https://tailscale.com/kb/1226/tailnet-lock/';
  static const String keyExpiryKbUrl =
      'https://tailscale.com/kb/1028/key-expiry/';
  static const String installTailscaleKbUrl =
      'https://tailscale.com/kb/installation/';
  static const String installUnstableKbUrl =
      'https://tailscale.com/kb/1083/install-unstable';
  static const String magicDnsKbUrl = 'https://tailscale.com/kb/1081/magicdns';
  static const String troubleshootingKbUrl =
      'https://tailscale.com/kb/1023/troubleshooting';
  static const String supportUrl =
      'https://tailscale.com/contact/support#support-form';
  static const String taildropKbUrl = 'https://tailscale.com/kb/1106/taildrop';
  static const String tailfsKbUrl = 'https://tailscale.com/kb/1106/taildrop';
}

enum AddressType { v4, v6, magicDNS }

class DisplayAddress {
  final AddressType type;
  final String address;

  DisplayAddress(String ip)
      : type = _determineType(ip),
        address = _formatAddress(ip);

  static AddressType _determineType(String ip) {
    if (ip.isIPv6) return AddressType.v6;
    if (ip.isIPv4) return AddressType.v4;
    return AddressType.magicDNS;
  }

  static String _formatAddress(String ip) {
    if (_determineType(ip) == AddressType.magicDNS) return ip;
    return ip.split('/').first;
  }

  String get typeString {
    switch (type) {
      case AddressType.v4:
        return 'IPv4';
      case AddressType.v6:
        return 'IPv6';
      case AddressType.magicDNS:
        return 'MagicDNS';
    }
  }
}

extension IPAddressValidation on String {
  bool get isIPv6 => contains(':');

  bool get isIPv4 {
    final parts = split('/').first.split('.');
    if (parts.length != 4) return false;
    return parts.every((part) {
      final value = int.tryParse(part);
      return value != null && value >= 0 && value <= 255;
    });
  }
}

class GoTimeUtil {
  static const String _tag = 'TimeUtil';
  static const zeroTimeString = "0001-01-01T00:00:00Z";

  static String keyExpiryFromGoTime(String? goTime) {
    if (goTime == null) return '';
    final expTime = epochMillisFromGoTime(goTime);
    final now = DateTime.now().millisecondsSinceEpoch;
    var diff = (expTime - now) ~/ 1000;
    return diff < 0 ? _formatExpiredTime(diff.abs()) : _formatFutureTime(diff);
  }

  static String _formatExpiredTime(int diff) {
    if (diff <= 60) return 'under a minute ago';
    if (diff <= 7200) return '${diff ~/ 60} minutes ago';
    if (diff <= 172800) return '${diff ~/ 3600} hours ago';
    if (diff <= 5184000) return '${diff ~/ 86400} days ago';
    if (diff <= 124416000) return '${diff ~/ 2592000} months ago';
    return '${(diff / 31536000.0).toStringAsFixed(1)} years ago';
  }

  static String _formatFutureTime(int diff) {
    if (diff <= 60) return 'in under a minute';
    if (diff <= 7200) return 'in ${diff ~/ 60} minutes';
    if (diff <= 172800) return 'in ${diff ~/ 3600} hours';
    if (diff <= 5184000) return 'in ${diff ~/ 86400} days';
    if (diff <= 124416000) return 'in ${diff ~/ 2592000} months';
    return 'in ${(diff / 31536000.0).toStringAsFixed(1)} years';
  }

  static int epochMillisFromGoTime(String goTime) =>
      DateTime.parse(goTime).millisecondsSinceEpoch;

  static DateTime dateFromGoString(String goTime) => DateTime.parse(goTime);

  static bool isWithinExpiryNotificationWindow(Duration window, String goTime) {
    final expTime = epochMillisFromGoTime(goTime);
    final now = DateTime.now().millisecondsSinceEpoch;
    return (expTime - now) ~/ 1000 < window.inSeconds;
  }

  static Duration? duration(String goDuration) {
    if (goDuration.contains('ms') || goDuration.contains('us')) return null;

    var duration = 0.0;
    var valStr = '';

    for (var i = 0; i < goDuration.length; i++) {
      final c = goDuration[i];
      if (RegExp(r'[\d.]').hasMatch(c)) {
        valStr += c;
        continue;
      }
      try {
        final durationFragment = double.parse(valStr);
        duration += _convertDurationUnit(durationFragment, c);
        valStr = '';
      } catch (e) {
        throw FormatException(
            '$_tag: Invalid duration string: $goDuration: $e');
      }
    }
    return Duration(seconds: duration.round());
  }

  static double _convertDurationUnit(double value, String unit) {
    switch (unit) {
      case 'y':
        return value * 31536000.0;
      case 'w':
        return value * 604800.0;
      case 'd':
        return value * 86400.0;
      case 'h':
        return value * 3600.0;
      case 'm':
        return value * 60.0;
      case 's':
        return value;
      default:
        throw FormatException('Invalid duration unit: $unit');
    }
  }
}

@freezed
class PingResult with _$PingResult {
  const factory PingResult({
    @JsonKey(name: 'IP') String? ip,
    @JsonKey(name: 'NodeIP') String? nodeIP,
    @JsonKey(name: 'NodeName') String? nodeName,
    @JsonKey(name: 'Err') String? error,
    @JsonKey(name: 'LatencySeconds') double? latencySeconds,
    @JsonKey(name: 'Endpoint') String? endpoint,
    @JsonKey(name: 'DERPRegionID') int? derpRegionId,
    @JsonKey(name: 'DERPRegionCode') String? derpRegionCode,
    @JsonKey(name: 'PeerAPIPort') int? peerAPIPort,
    @JsonKey(name: 'PeerAPIURL') String? peerAPIUrl,
    @JsonKey(name: 'IsLocalIP') bool? isLocalIP,
  }) = _PingResult;

  factory PingResult.fromJson(Map<String, dynamic> json) =>
      _$PingResultFromJson(json);
}

extension PingResultExtension on PingResult {
  bool get isError => error != null && error!.isNotEmpty;

  String get formattedLatency {
    if (latencySeconds == null) return '';
    return '${(latencySeconds! * 1000).toStringAsFixed(1)} ms';
  }

  String get connectionType {
    if (endpoint?.isNotEmpty == true) return 'Direct';
    if (derpRegionCode?.isNotEmpty == true) {
      return 'Via Relay ($derpRegionCode)';
    }
    return 'Not Connected';
  }
}

@freezed
class PeerStatusLite with _$PeerStatusLite {
  const factory PeerStatusLite({
    @JsonKey(name: 'RxBytes') required int rxBytes,
    @JsonKey(name: 'TxBytes') required int txBytes,
    @JsonKey(name: 'LastHandshake') required String lastHandshake,
    @JsonKey(name: 'NodeKey') required String nodeKey,
  }) = _PeerStatusLite;

  factory PeerStatusLite.fromJson(Map<String, dynamic> json) =>
      _$PeerStatusLiteFromJson(json);
}

@freezed
class PeerStatus with _$PeerStatus {
  const factory PeerStatus({
    @JsonKey(name: 'ID') required String id,
    @JsonKey(name: 'HostName') required String hostName,
    @JsonKey(name: 'DNSName') required String dnsName,
    @JsonKey(name: 'OS') String? os,
    @JsonKey(name: 'TailscaleIPs') List<String>? tailscaleIPs,
    @JsonKey(name: 'Tags') List<String>? tags,
    @JsonKey(name: 'PrimaryRoutes') List<String>? primaryRoutes,
    @JsonKey(name: 'Addrs') List<String>? addrs,
    @JsonKey(name: 'CurAddr') String? curAddr,
    @JsonKey(name: 'Relay') String? relay,
    @JsonKey(name: 'Online') required bool online,
    @JsonKey(name: 'ExitNode') required bool exitNode,
    @JsonKey(name: 'ExitNodeOption') required bool exitNodeOption,
    @JsonKey(name: 'Active') required bool active,
    @JsonKey(name: 'PeerAPIURL') List<String>? peerAPIUrl,
    @JsonKey(name: 'Capabilities') List<String>? capabilities,
    @JsonKey(name: 'SSH_HostKeys') List<String>? sshHostKeys,
    @JsonKey(name: 'ShareeNode') bool? shareeNode,
    @JsonKey(name: 'Expired') bool? expired,
    @JsonKey(name: 'Location') Location? location,
  }) = _PeerStatus;

  factory PeerStatus.fromJson(Map<String, dynamic> json) =>
      _$PeerStatusFromJson(json);
}

@freezed
class ExitNodeStatus with _$ExitNodeStatus {
  const factory ExitNodeStatus({
    @JsonKey(name: 'ID') required String id,
    @JsonKey(name: 'Online') required bool online,
    @JsonKey(name: 'TailscaleIPs') List<String>? tailscaleIPs,
  }) = _ExitNodeStatus;

  factory ExitNodeStatus.fromJson(Map<String, dynamic> json) =>
      _$ExitNodeStatusFromJson(json);
}

@freezed
class TailnetStatus with _$TailnetStatus {
  const factory TailnetStatus({
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'MagicDNSSuffix') required String magicDNSSuffix,
    @JsonKey(name: 'MagicDNSEnabled') required bool magicDNSEnabled,
  }) = _TailnetStatus;

  factory TailnetStatus.fromJson(Map<String, dynamic> json) =>
      _$TailnetStatusFromJson(json);
}

@freezed
class Status with _$Status {
  const factory Status({
    @JsonKey(name: 'Version') required String version,
    @JsonKey(name: 'TUN') required bool tun,
    @JsonKey(name: 'BackendState') required String backendState,
    @JsonKey(name: 'AuthURL') required String authUrl,
    @JsonKey(name: 'TailscaleIPs') List<String>? tailscaleIPs,
    @JsonKey(name: 'Self') PeerStatus? self,
    @JsonKey(name: 'ExitNodeStatus') ExitNodeStatus? exitNodeStatus,
    @JsonKey(name: 'Health') List<String>? health,
    @JsonKey(name: 'CurrentTailnet') TailnetStatus? currentTailnet,
    @JsonKey(name: 'CertDomains') List<String>? certDomains,
    @JsonKey(name: 'Peer') Map<String, PeerStatus>? peer,
    @JsonKey(name: 'User') Map<String, UserProfile>? user,
    @JsonKey(name: 'ClientVersion') ClientVersion? clientVersion,
  }) = _Status;

  factory Status.fromJson(Map<String, dynamic> json) => _$StatusFromJson(json);
}

extension PeerStatusExtension on PeerStatus {
  String computedName(Status status) {
    final suffix = status.currentTailnet?.magicDNSSuffix;
    if (suffix == null) return dnsName;

    if (!dnsName.endsWith('.$suffix.')) return dnsName;

    return dnsName.substring(0, dnsName.length - suffix.length - 2);
  }
}

class ExitNode {
  final String? id;
  final String label;
  final bool online;
  final bool selected;
  final bool mullvad;
  final int priority;
  final String countryCode;
  final String country;
  final String city;

  ExitNode({
    this.id,
    required this.label,
    required this.online,
    required this.selected,
    this.mullvad = false,
    this.priority = 0,
    this.countryCode = '',
    this.country = '',
    this.city = '',
  });
}

class NotifyWatchOpt {
  // Private constructor to prevent instantiation
  NotifyWatchOpt._();

  /// If set, causes Engine updates to be sent to the client either regularly
  /// or when they change, without having to ask for each one via Engine.RequestStatus.
  static const int watchEngineUpdates = 1 << 0;

  /// If set, the first Notify message (sent immediately) will contain
  /// the current State + BrowseToURL + SessionID
  static const int initialState = 1 << 1;

  /// If set, the first Notify message (sent immediately) will contain the current Prefs
  static const int initialPrefs = 1 << 2;

  /// If set, the first Notify message (sent immediately) will contain the current NetMap
  static const int initialNetMap = 1 << 3;

  /// If set, private keys that would normally be sent in updates are zeroed out
  static const int noPrivateKeys = 1 << 4;

  /// If set, the first Notify message (sent immediately) will contain
  /// the current Taildrive Shares
  static const int initialDriveShares = 1 << 5;

  /// If set, the first Notify message (sent immediately) will contain
  /// the current Taildrop OutgoingFiles
  static const int initialOutgoingFiles = 1 << 6;

  /// If set, the first Notify message (sent immediately) will contain
  /// the current health.State of the client
  static const int initialHealthState = 1 << 7;

  /// If set, rate limit spammy netmap updates to every few seconds
  static const int rateLimit = 1 << 8;

  /// Helper method to combine multiple options
  static int combine(List<int> opts) {
    return opts.fold(0, (acc, opt) => acc | opt);
  }
}

class FilePart {
  final String filename;
  final String contentType;
  final int contentLength;
  final File file;

  FilePart({
    required this.filename,
    this.contentType = 'application/octet-stream',
    required this.contentLength,
    required this.file,
  });
}
