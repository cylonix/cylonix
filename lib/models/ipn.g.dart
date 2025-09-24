// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ipn.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$IpnStateImpl _$$IpnStateImplFromJson(Map<String, dynamic> json) =>
    _$IpnStateImpl(
      backendState:
          $enumDecodeNullable(_$BackendStateEnumMap, json['backendState']) ??
              BackendState.noState,
      vpnState: $enumDecodeNullable(_$VpnStateEnumMap, json['vpnState']) ??
          VpnState.disconnected,
      loggedInUser: json['loggedInUser'] == null
          ? null
          : UserProfile.fromJson(json['loggedInUser'] as Map<String, dynamic>),
      selfNode: json['selfNode'] == null
          ? null
          : Node.fromJson(json['selfNode'] as Map<String, dynamic>),
      netmap: json['netmap'] == null
          ? null
          : NetworkMap.fromJson(json['netmap'] as Map<String, dynamic>),
      prefs: json['prefs'] == null
          ? null
          : IpnPrefs.fromJson(json['prefs'] as Map<String, dynamic>),
      health: json['health'] == null
          ? null
          : HealthState.fromJson(json['health'] as Map<String, dynamic>),
      browseToURL: json['browseToURL'] as String?,
      errMessage: json['errMessage'] as String?,
      outgoingFiles: (json['outgoingFiles'] as List<dynamic>?)
          ?.map((e) => OutgoingFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      filesWaiting: (json['filesWaiting'] as List<dynamic>?)
          ?.map((e) => AwaitingFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentProfile: json['currentProfile'] == null
          ? null
          : LoginProfile.fromJson(
              json['currentProfile'] as Map<String, dynamic>),
      loginProfiles: (json['loginProfiles'] as List<dynamic>?)
              ?.map((e) => LoginProfile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isRunningExitNode: json['isRunningExitNode'] as bool? ?? false,
    );

Map<String, dynamic> _$$IpnStateImplToJson(_$IpnStateImpl instance) =>
    <String, dynamic>{
      'backendState': _$BackendStateEnumMap[instance.backendState]!,
      'vpnState': _$VpnStateEnumMap[instance.vpnState]!,
      'loggedInUser': instance.loggedInUser,
      'selfNode': instance.selfNode,
      'netmap': instance.netmap,
      'prefs': instance.prefs,
      'health': instance.health,
      'browseToURL': instance.browseToURL,
      'errMessage': instance.errMessage,
      'outgoingFiles': instance.outgoingFiles,
      'filesWaiting': instance.filesWaiting,
      'currentProfile': instance.currentProfile,
      'loginProfiles': instance.loginProfiles,
      'isRunningExitNode': instance.isRunningExitNode,
    };

const _$BackendStateEnumMap = {
  BackendState.noState: 'noState',
  BackendState.inUseOtherUser: 'inUseOtherUser',
  BackendState.needsLogin: 'needsLogin',
  BackendState.needsMachineAuth: 'needsMachineAuth',
  BackendState.stopped: 'stopped',
  BackendState.starting: 'starting',
  BackendState.running: 'running',
  BackendState.stopping: 'stopping',
};

const _$VpnStateEnumMap = {
  VpnState.disconnecting: 'disconnecting',
  VpnState.disconnected: 'disconnected',
  VpnState.connecting: 'connecting',
  VpnState.connected: 'connected',
  VpnState.error: 'error',
};

_$IpnNotificationImpl _$$IpnNotificationImplFromJson(
        Map<String, dynamic> json) =>
    _$IpnNotificationImpl(
      version: json['Version'] as String?,
      errMessage: json['ErrMessage'] as String?,
      loginFinished: json['LoginFinished'] as Map<String, dynamic>?,
      filesWaiting: json['FilesWaiting'] as Map<String, dynamic>?,
      outgoingFiles: (json['OutgoingFiles'] as List<dynamic>?)
          ?.map((e) => OutgoingFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      state: (json['State'] as num?)?.toInt(),
      prefs: json['Prefs'] == null
          ? null
          : IpnPrefs.fromJson(json['Prefs'] as Map<String, dynamic>),
      netMap: json['NetMap'] == null
          ? null
          : NetworkMap.fromJson(json['NetMap'] as Map<String, dynamic>),
      engine: json['Engine'] == null
          ? null
          : EngineStatus.fromJson(json['Engine'] as Map<String, dynamic>),
      browseToURL: json['BrowseToURL'] as String?,
      backendLogId: json['BackendLogID'] as String?,
      localTCPPort: (json['LocalTCPPort'] as num?)?.toInt(),
      incomingFiles: (json['IncomingFiles'] as List<dynamic>?)
          ?.map((e) => PartialFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      clientVersion: json['ClientVersion'] == null
          ? null
          : ClientVersion.fromJson(
              json['ClientVersion'] as Map<String, dynamic>),
      tailFSShares: (json['TailFSShares'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      health: json['Health'] == null
          ? null
          : HealthState.fromJson(json['Health'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$IpnNotificationImplToJson(
        _$IpnNotificationImpl instance) =>
    <String, dynamic>{
      'Version': instance.version,
      'ErrMessage': instance.errMessage,
      'LoginFinished': instance.loginFinished,
      'FilesWaiting': instance.filesWaiting,
      'OutgoingFiles': instance.outgoingFiles,
      'State': instance.state,
      'Prefs': instance.prefs,
      'NetMap': instance.netMap,
      'Engine': instance.engine,
      'BrowseToURL': instance.browseToURL,
      'BackendLogID': instance.backendLogId,
      'LocalTCPPort': instance.localTCPPort,
      'IncomingFiles': instance.incomingFiles,
      'ClientVersion': instance.clientVersion,
      'TailFSShares': instance.tailFSShares,
      'Health': instance.health,
    };

_$HealthStateImpl _$$HealthStateImplFromJson(Map<String, dynamic> json) =>
    _$HealthStateImpl(
      warnings: (json['Warnings'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
            k,
            e == null
                ? null
                : UnhealthyState.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$$HealthStateImplToJson(_$HealthStateImpl instance) =>
    <String, dynamic>{
      'Warnings': instance.warnings,
    };

_$UnhealthyStateImpl _$$UnhealthyStateImplFromJson(Map<String, dynamic> json) =>
    _$UnhealthyStateImpl(
      warnableCode: json['WarnableCode'] as String,
      severity: $enumDecode(_$SeverityEnumMap, json['Severity']),
      title: json['Title'] as String,
      text: json['Text'] as String,
      brokenSince: json['BrokenSince'] as String?,
      args: (json['Args'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      impactsConnectivity: json['ImpactsConnectivity'] as bool?,
      dependsOn: (json['DependsOn'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$UnhealthyStateImplToJson(
        _$UnhealthyStateImpl instance) =>
    <String, dynamic>{
      'WarnableCode': instance.warnableCode,
      'Severity': _$SeverityEnumMap[instance.severity]!,
      'Title': instance.title,
      'Text': instance.text,
      'BrokenSince': instance.brokenSince,
      'Args': instance.args,
      'ImpactsConnectivity': instance.impactsConnectivity,
      'DependsOn': instance.dependsOn,
    };

const _$SeverityEnumMap = {
  Severity.low: 'low',
  Severity.medium: 'medium',
  Severity.high: 'high',
};

_$IpnPrefsImpl _$$IpnPrefsImplFromJson(Map<String, dynamic> json) =>
    _$IpnPrefsImpl(
      controlURL: json['ControlURL'] as String? ?? '',
      routeAll: json['RouteAll'] as bool? ?? false,
      allowsSingleHosts: json['AllowsSingleHosts'] as bool? ?? false,
      corpDNS: json['CorpDNS'] as bool? ?? false,
      wantRunning: json['WantRunning'] as bool? ?? false,
      loggedOut: json['LoggedOut'] as bool? ?? false,
      shieldsUp: json['ShieldsUp'] as bool? ?? false,
      advertiseRoutes: (json['AdvertiseRoutes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      advertiseTags: (json['AdvertiseTags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      exitNodeID: json['ExitNodeID'] as String?,
      exitNodeAllowLANAccess: json['ExitNodeAllowLANAccess'] as bool? ?? false,
      config: json['Config'] == null
          ? null
          : PersistConfig.fromJson(json['Config'] as Map<String, dynamic>),
      forceDaemon: json['ForceDaemon'] as bool? ?? false,
      hostName: json['HostName'] as String? ?? '',
      autoUpdate: json['AutoUpdate'] == null
          ? null
          : AutoUpdatePrefs.fromJson(
              json['AutoUpdate'] as Map<String, dynamic>),
      internalExitNodePrior: json['InternalExitNodePrior'] as String?,
    );

Map<String, dynamic> _$$IpnPrefsImplToJson(_$IpnPrefsImpl instance) =>
    <String, dynamic>{
      'ControlURL': instance.controlURL,
      'RouteAll': instance.routeAll,
      'AllowsSingleHosts': instance.allowsSingleHosts,
      'CorpDNS': instance.corpDNS,
      'WantRunning': instance.wantRunning,
      'LoggedOut': instance.loggedOut,
      'ShieldsUp': instance.shieldsUp,
      'AdvertiseRoutes': instance.advertiseRoutes,
      'AdvertiseTags': instance.advertiseTags,
      'ExitNodeID': instance.exitNodeID,
      'ExitNodeAllowLANAccess': instance.exitNodeAllowLANAccess,
      'Config': instance.config,
      'ForceDaemon': instance.forceDaemon,
      'HostName': instance.hostName,
      'AutoUpdate': instance.autoUpdate,
      'InternalExitNodePrior': instance.internalExitNodePrior,
    };

_$IpnOptionsImpl _$$IpnOptionsImplFromJson(Map<String, dynamic> json) =>
    _$IpnOptionsImpl(
      frontendLogID: json['FrontendLogID'] as String?,
      updatePrefs: json['UpdatePrefs'] == null
          ? null
          : IpnPrefs.fromJson(json['UpdatePrefs'] as Map<String, dynamic>),
      authKey: json['AuthKey'] as String?,
    );

Map<String, dynamic> _$$IpnOptionsImplToJson(_$IpnOptionsImpl instance) =>
    <String, dynamic>{
      'FrontendLogID': instance.frontendLogID,
      'UpdatePrefs': instance.updatePrefs,
      'AuthKey': instance.authKey,
    };

_$MaskedPrefsImpl _$$MaskedPrefsImplFromJson(Map<String, dynamic> json) =>
    _$MaskedPrefsImpl(
      controlURLSet: json['ControlURLSet'] as bool?,
      routeAllSet: json['RouteAllSet'] as bool?,
      corpDNSSet: json['CorpDNSSet'] as bool?,
      exitNodeIDSet: json['ExitNodeIDSet'] as bool?,
      exitNodeAllowLANAccessSet: json['ExitNodeAllowLANAccessSet'] as bool?,
      wantRunningSet: json['WantRunningSet'] as bool?,
      shieldsUpSet: json['ShieldsUpSet'] as bool?,
      advertiseRoutesSet: json['AdvertiseRoutesSet'] as bool?,
      forceDaemonSet: json['ForceDaemonSet'] as bool?,
      hostnameSet: json['HostnameSet'] as bool?,
      internalExitNodePriorSet: json['InternalExitNodePriorSet'] as bool?,
      controlURL: json['ControlURL'] as String?,
      routeAll: json['RouteAll'] as bool?,
      corpDNS: json['CorpDNS'] as bool?,
      exitNodeID: json['ExitNodeID'] as String?,
      internalExitNodePrior: json['InternalExitNodePrior'] as String?,
      exitNodeAllowLANAccess: json['ExitNodeAllowLANAccess'] as bool?,
      wantRunning: json['WantRunning'] as bool?,
      shieldsUp: json['ShieldsUp'] as bool?,
      advertiseRoutes: (json['AdvertiseRoutes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      forceDaemon: json['ForceDaemon'] as bool?,
      hostname: json['Hostname'] as String?,
    );

Map<String, dynamic> _$$MaskedPrefsImplToJson(_$MaskedPrefsImpl instance) =>
    <String, dynamic>{
      'ControlURLSet': instance.controlURLSet,
      'RouteAllSet': instance.routeAllSet,
      'CorpDNSSet': instance.corpDNSSet,
      'ExitNodeIDSet': instance.exitNodeIDSet,
      'ExitNodeAllowLANAccessSet': instance.exitNodeAllowLANAccessSet,
      'WantRunningSet': instance.wantRunningSet,
      'ShieldsUpSet': instance.shieldsUpSet,
      'AdvertiseRoutesSet': instance.advertiseRoutesSet,
      'ForceDaemonSet': instance.forceDaemonSet,
      'HostnameSet': instance.hostnameSet,
      'InternalExitNodePriorSet': instance.internalExitNodePriorSet,
      'ControlURL': instance.controlURL,
      'RouteAll': instance.routeAll,
      'CorpDNS': instance.corpDNS,
      'ExitNodeID': instance.exitNodeID,
      'InternalExitNodePrior': instance.internalExitNodePrior,
      'ExitNodeAllowLANAccess': instance.exitNodeAllowLANAccess,
      'WantRunning': instance.wantRunning,
      'ShieldsUp': instance.shieldsUp,
      'AdvertiseRoutes': instance.advertiseRoutes,
      'ForceDaemon': instance.forceDaemon,
      'Hostname': instance.hostname,
    };

_$PersistConfigImpl _$$PersistConfigImplFromJson(Map<String, dynamic> json) =>
    _$PersistConfigImpl(
      privateMachineKey:
          json['PrivateMachineKey'] as String? ?? _zeroPrivateKey,
      privateNodeKey: json['PrivateNodeKey'] as String? ?? _zeroPrivateKey,
      oldPrivateNodeKey:
          json['OldPrivateNodeKey'] as String? ?? _zeroPrivateKey,
      provider: json['Provider'] as String? ?? '',
    );

Map<String, dynamic> _$$PersistConfigImplToJson(_$PersistConfigImpl instance) =>
    <String, dynamic>{
      'PrivateMachineKey': instance.privateMachineKey,
      'PrivateNodeKey': instance.privateNodeKey,
      'OldPrivateNodeKey': instance.oldPrivateNodeKey,
      'Provider': instance.provider,
    };

_$NetworkMapImpl _$$NetworkMapImplFromJson(Map<String, dynamic> json) =>
    _$NetworkMapImpl(
      selfNode: Node.fromJson(json['SelfNode'] as Map<String, dynamic>),
      nodeKey: json['NodeKey'] as String,
      peers: (json['Peers'] as List<dynamic>?)
          ?.map((e) => Node.fromJson(e as Map<String, dynamic>))
          .toList(),
      expiry: DateTime.parse(json['Expiry'] as String),
      domain: json['Domain'] as String,
      userProfiles: (json['UserProfiles'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, UserProfile.fromJson(e as Map<String, dynamic>)),
      ),
      tkaEnabled: json['TKAEnabled'] as bool,
      dns: json['DNS'] == null
          ? null
          : DNSConfig.fromJson(json['DNS'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$NetworkMapImplToJson(_$NetworkMapImpl instance) =>
    <String, dynamic>{
      'SelfNode': instance.selfNode,
      'NodeKey': instance.nodeKey,
      'Peers': instance.peers,
      'Expiry': instance.expiry.toIso8601String(),
      'Domain': instance.domain,
      'UserProfiles': instance.userProfiles,
      'TKAEnabled': instance.tkaEnabled,
      'DNS': instance.dns,
    };

_$NodeImpl _$$NodeImplFromJson(Map<String, dynamic> json) => _$NodeImpl(
      id: (json['ID'] as num).toInt(),
      stableID: json['StableID'] as String,
      name: json['Name'] as String,
      userID: (json['User'] as num).toInt(),
      sharer: (json['Sharer'] as num?)?.toInt(),
      key: json['Key'] as String,
      keyExpiry: json['KeyExpiry'] as String,
      machine: json['Machine'] as String,
      addresses:
          (json['Addresses'] as List<dynamic>).map((e) => e as String).toList(),
      allowedIPs: (json['AllowedIPs'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      endpoints: (json['Endpoints'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      hostinfo: json['Hostinfo'] == null
          ? null
          : Hostinfo.fromJson(json['Hostinfo'] as Map<String, dynamic>),
      created: json['Created'] as String?,
      lastSeen: json['LastSeen'] as String?,
      online: json['Online'] as bool?,
      isWireGuardOnly: json['IsWireGuardOnly'] as bool?,
      capabilities: (json['Capabilities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      capMap: json['CapMap'] as Map<String, dynamic>?,
      computedName: json['ComputedName'] as String?,
      computedNameWithHost: json['ComputedNameWithHost'] as String?,
    );

Map<String, dynamic> _$$NodeImplToJson(_$NodeImpl instance) =>
    <String, dynamic>{
      'ID': instance.id,
      'StableID': instance.stableID,
      'Name': instance.name,
      'User': instance.userID,
      'Sharer': instance.sharer,
      'Key': instance.key,
      'KeyExpiry': instance.keyExpiry,
      'Machine': instance.machine,
      'Addresses': instance.addresses,
      'AllowedIPs': instance.allowedIPs,
      'Endpoints': instance.endpoints,
      'Hostinfo': instance.hostinfo,
      'Created': instance.created,
      'LastSeen': instance.lastSeen,
      'Online': instance.online,
      'IsWireGuardOnly': instance.isWireGuardOnly,
      'Capabilities': instance.capabilities,
      'CapMap': instance.capMap,
      'ComputedName': instance.computedName,
      'ComputedNameWithHost': instance.computedNameWithHost,
    };

_$UserProfileImpl _$$UserProfileImplFromJson(Map<String, dynamic> json) =>
    _$UserProfileImpl(
      id: (json['ID'] as num).toInt(),
      displayName: json['DisplayName'] as String,
      loginName: json['LoginName'] as String,
      profilePicURL: json['ProfilePicURL'] as String? ?? '',
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'ID': instance.id,
      'DisplayName': instance.displayName,
      'LoginName': instance.loginName,
      'ProfilePicURL': instance.profilePicURL,
    };

_$LoginProfileImpl _$$LoginProfileImplFromJson(Map<String, dynamic> json) =>
    _$LoginProfileImpl(
      id: json['ID'] as String,
      name: json['Name'] as String,
      key: json['Key'] as String,
      userProfile:
          UserProfile.fromJson(json['UserProfile'] as Map<String, dynamic>),
      networkProfile: json['NetworkProfile'] == null
          ? null
          : NetworkProfile.fromJson(
              json['NetworkProfile'] as Map<String, dynamic>),
      localUserId: json['LocalUserID'] as String,
      controlURL: json['ControlURL'] as String,
    );

Map<String, dynamic> _$$LoginProfileImplToJson(_$LoginProfileImpl instance) =>
    <String, dynamic>{
      'ID': instance.id,
      'Name': instance.name,
      'Key': instance.key,
      'UserProfile': instance.userProfile,
      'NetworkProfile': instance.networkProfile,
      'LocalUserID': instance.localUserId,
      'ControlURL': instance.controlURL,
    };

_$NetworkProfileImpl _$$NetworkProfileImplFromJson(Map<String, dynamic> json) =>
    _$NetworkProfileImpl(
      magicDNSName: json['MagicDNSName'] as String?,
      domainName: json['DomainName'] as String?,
    );

Map<String, dynamic> _$$NetworkProfileImplToJson(
        _$NetworkProfileImpl instance) =>
    <String, dynamic>{
      'MagicDNSName': instance.magicDNSName,
      'DomainName': instance.domainName,
    };

_$DNSHostEntryImpl _$$DNSHostEntryImplFromJson(Map<String, dynamic> json) =>
    _$DNSHostEntryImpl(
      addr: json['Addr'] as String?,
      hosts:
          (json['Hosts'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$$DNSHostEntryImplToJson(_$DNSHostEntryImpl instance) =>
    <String, dynamic>{
      'Addr': instance.addr,
      'Hosts': instance.hosts,
    };

_$OSConfigImpl _$$OSConfigImplFromJson(Map<String, dynamic> json) =>
    _$OSConfigImpl(
      hosts: (json['Hosts'] as List<dynamic>?)
          ?.map((e) => DNSHostEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      nameservers: (json['Nameservers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      searchDomains: (json['SearchDomains'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      matchDomains: (json['MatchDomains'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$OSConfigImplToJson(_$OSConfigImpl instance) =>
    <String, dynamic>{
      'Hosts': instance.hosts,
      'Nameservers': instance.nameservers,
      'SearchDomains': instance.searchDomains,
      'MatchDomains': instance.matchDomains,
    };

_$ResolverImpl _$$ResolverImplFromJson(Map<String, dynamic> json) =>
    _$ResolverImpl(
      addr: json['Addr'] as String?,
      bootstrapResolution: (json['BootstrapResolution'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$ResolverImplToJson(_$ResolverImpl instance) =>
    <String, dynamic>{
      'Addr': instance.addr,
      'BootstrapResolution': instance.bootstrapResolution,
    };

_$DNSConfigImpl _$$DNSConfigImplFromJson(Map<String, dynamic> json) =>
    _$DNSConfigImpl(
      resolvers: (json['Resolvers'] as List<dynamic>?)
          ?.map((e) => Resolver.fromJson(e as Map<String, dynamic>))
          .toList(),
      routes: (json['Routes'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
            k,
            (e as List<dynamic>?)
                ?.map((e) => Resolver.fromJson(e as Map<String, dynamic>))
                .toList()),
      ),
      fallbackResolvers: (json['FallbackResolvers'] as List<dynamic>?)
          ?.map((e) => Resolver.fromJson(e as Map<String, dynamic>))
          .toList(),
      domains:
          (json['Domains'] as List<dynamic>?)?.map((e) => e as String).toList(),
      nameservers: (json['Nameservers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$DNSConfigImplToJson(_$DNSConfigImpl instance) =>
    <String, dynamic>{
      'Resolvers': instance.resolvers,
      'Routes': instance.routes,
      'FallbackResolvers': instance.fallbackResolvers,
      'Domains': instance.domains,
      'Nameservers': instance.nameservers,
    };

_$HealthImpl _$$HealthImplFromJson(Map<String, dynamic> json) => _$HealthImpl(
      state: json['State'] as String?,
      code: (json['Code'] as num?)?.toInt(),
      message: json['Message'] as String?,
    );

Map<String, dynamic> _$$HealthImplToJson(_$HealthImpl instance) =>
    <String, dynamic>{
      'State': instance.state,
      'Code': instance.code,
      'Message': instance.message,
    };

_$PartialFileImpl _$$PartialFileImplFromJson(Map<String, dynamic> json) =>
    _$PartialFileImpl(
      name: json['Name'] as String,
      started: json['Started'] as String,
      declaredSize: (json['DeclaredSize'] as num).toInt(),
      received: (json['Received'] as num).toInt(),
      partialPath: json['PartialPath'] as String?,
      finalPath: json['FinalPath'] as String?,
      done: json['Done'] as bool?,
    );

Map<String, dynamic> _$$PartialFileImplToJson(_$PartialFileImpl instance) =>
    <String, dynamic>{
      'Name': instance.name,
      'Started': instance.started,
      'DeclaredSize': instance.declaredSize,
      'Received': instance.received,
      'PartialPath': instance.partialPath,
      'FinalPath': instance.finalPath,
      'Done': instance.done,
    };

_$EngineStatusImpl _$$EngineStatusImplFromJson(Map<String, dynamic> json) =>
    _$EngineStatusImpl(
      rBytes: (json['RBytes'] as num).toInt(),
      wBytes: (json['WBytes'] as num).toInt(),
      numLive: (json['NumLive'] as num).toInt(),
      livePeers: (json['LivePeers'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, PeerStatusLite.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$$EngineStatusImplToJson(_$EngineStatusImpl instance) =>
    <String, dynamic>{
      'RBytes': instance.rBytes,
      'WBytes': instance.wBytes,
      'NumLive': instance.numLive,
      'LivePeers': instance.livePeers,
    };

_$OutgoingFileImpl _$$OutgoingFileImplFromJson(Map<String, dynamic> json) =>
    _$OutgoingFileImpl(
      id: json['ID'] as String? ?? '',
      name: json['Name'] as String,
      peerID: json['PeerID'] as String? ?? '',
      started: json['Started'] as String?,
      declaredSize: (json['DeclaredSize'] as num).toInt(),
      sent: (json['Sent'] as num?)?.toInt() ?? 0,
      partialPath: json['PartialPath'] as String?,
      finalPath: json['FinalPath'] as String?,
      finished: json['Finished'] as bool? ?? false,
      succeeded: json['Succeeded'] as bool? ?? false,
      path: json['Path'] as String?,
    );

Map<String, dynamic> _$$OutgoingFileImplToJson(_$OutgoingFileImpl instance) =>
    <String, dynamic>{
      'ID': instance.id,
      'Name': instance.name,
      'PeerID': instance.peerID,
      'Started': instance.started,
      'DeclaredSize': instance.declaredSize,
      'Sent': instance.sent,
      'PartialPath': instance.partialPath,
      'FinalPath': instance.finalPath,
      'Finished': instance.finished,
      'Succeeded': instance.succeeded,
      'Path': instance.path,
    };

_$AutoUpdatePrefsImpl _$$AutoUpdatePrefsImplFromJson(
        Map<String, dynamic> json) =>
    _$AutoUpdatePrefsImpl(
      check: json['Check'] as bool?,
      apply: json['Apply'] as bool?,
    );

Map<String, dynamic> _$$AutoUpdatePrefsImplToJson(
        _$AutoUpdatePrefsImpl instance) =>
    <String, dynamic>{
      'Check': instance.check,
      'Apply': instance.apply,
    };

_$ClientVersionImpl _$$ClientVersionImplFromJson(Map<String, dynamic> json) =>
    _$ClientVersionImpl(
      major: json['Major'] as String?,
      minor: json['Minor'] as String?,
      patch: json['Patch'] as String?,
      suffix: json['Suffix'] as String?,
      candidate: json['Candidate'] as bool?,
    );

Map<String, dynamic> _$$ClientVersionImplToJson(_$ClientVersionImpl instance) =>
    <String, dynamic>{
      'Major': instance.major,
      'Minor': instance.minor,
      'Patch': instance.patch,
      'Suffix': instance.suffix,
      'Candidate': instance.candidate,
    };

_$HostinfoImpl _$$HostinfoImplFromJson(Map<String, dynamic> json) =>
    _$HostinfoImpl(
      ipnVersion: json['IPNVersion'] as String?,
      frontendLogID: json['FrontendLogID'] as String?,
      backendLogID: json['BackendLogID'] as String?,
      os: json['OS'] as String?,
      osVersion: json['OSVersion'] as String?,
      env: json['Env'] as String?,
      distro: json['Distro'] as String?,
      distroVersion: json['DistroVersion'] as String?,
      distroCodeName: json['DistroCodeName'] as String?,
      desktop: json['Desktop'] as bool?,
      package: json['Package'] as String?,
      deviceModel: json['DeviceModel'] as String?,
      shareeNode: json['ShareeNode'] as bool?,
      hostname: json['Hostname'] as String?,
      shieldsUp: json['ShieldsUp'] as bool?,
      noLogsNoSupport: json['NoLogsNoSupport'] as bool?,
      machine: json['Machine'] as String?,
      routableIPs: (json['RoutableIPs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      services: (json['Services'] as List<dynamic>?)
          ?.map((e) => Service.fromJson(e as Map<String, dynamic>))
          .toList(),
      location: json['Location'] == null
          ? null
          : Location.fromJson(json['Location'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$HostinfoImplToJson(_$HostinfoImpl instance) =>
    <String, dynamic>{
      'IPNVersion': instance.ipnVersion,
      'FrontendLogID': instance.frontendLogID,
      'BackendLogID': instance.backendLogID,
      'OS': instance.os,
      'OSVersion': instance.osVersion,
      'Env': instance.env,
      'Distro': instance.distro,
      'DistroVersion': instance.distroVersion,
      'DistroCodeName': instance.distroCodeName,
      'Desktop': instance.desktop,
      'Package': instance.package,
      'DeviceModel': instance.deviceModel,
      'ShareeNode': instance.shareeNode,
      'Hostname': instance.hostname,
      'ShieldsUp': instance.shieldsUp,
      'NoLogsNoSupport': instance.noLogsNoSupport,
      'Machine': instance.machine,
      'RoutableIPs': instance.routableIPs,
      'Services': instance.services,
      'Location': instance.location,
    };

_$LocationImpl _$$LocationImplFromJson(Map<String, dynamic> json) =>
    _$LocationImpl(
      country: json['Country'] as String?,
      countryCode: json['CountryCode'] as String?,
      city: json['City'] as String?,
      cityCode: json['CityCode'] as String?,
      priority: (json['Priority'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$LocationImplToJson(_$LocationImpl instance) =>
    <String, dynamic>{
      'Country': instance.country,
      'CountryCode': instance.countryCode,
      'City': instance.city,
      'CityCode': instance.cityCode,
      'Priority': instance.priority,
    };

_$ServiceImpl _$$ServiceImplFromJson(Map<String, dynamic> json) =>
    _$ServiceImpl(
      proto: json['Proto'] as String,
      port: (json['Port'] as num).toInt(),
      description: json['Description'] as String?,
    );

Map<String, dynamic> _$$ServiceImplToJson(_$ServiceImpl instance) =>
    <String, dynamic>{
      'Proto': instance.proto,
      'Port': instance.port,
      'Description': instance.description,
    };

_$AwaitingFileImpl _$$AwaitingFileImplFromJson(Map<String, dynamic> json) =>
    _$AwaitingFileImpl(
      name: json['Name'] as String,
      size: (json['Size'] as num).toInt(),
    );

Map<String, dynamic> _$$AwaitingFileImplToJson(_$AwaitingFileImpl instance) =>
    <String, dynamic>{
      'Name': instance.name,
      'Size': instance.size,
    };

_$PingResultImpl _$$PingResultImplFromJson(Map<String, dynamic> json) =>
    _$PingResultImpl(
      ip: json['IP'] as String?,
      nodeIP: json['NodeIP'] as String?,
      nodeName: json['NodeName'] as String?,
      error: json['Err'] as String?,
      latencySeconds: (json['LatencySeconds'] as num?)?.toDouble(),
      endpoint: json['Endpoint'] as String?,
      derpRegionId: (json['DERPRegionID'] as num?)?.toInt(),
      derpRegionCode: json['DERPRegionCode'] as String?,
      peerAPIPort: (json['PeerAPIPort'] as num?)?.toInt(),
      peerAPIUrl: json['PeerAPIURL'] as String?,
      isLocalIP: json['IsLocalIP'] as bool?,
    );

Map<String, dynamic> _$$PingResultImplToJson(_$PingResultImpl instance) =>
    <String, dynamic>{
      'IP': instance.ip,
      'NodeIP': instance.nodeIP,
      'NodeName': instance.nodeName,
      'Err': instance.error,
      'LatencySeconds': instance.latencySeconds,
      'Endpoint': instance.endpoint,
      'DERPRegionID': instance.derpRegionId,
      'DERPRegionCode': instance.derpRegionCode,
      'PeerAPIPort': instance.peerAPIPort,
      'PeerAPIURL': instance.peerAPIUrl,
      'IsLocalIP': instance.isLocalIP,
    };

_$PeerStatusLiteImpl _$$PeerStatusLiteImplFromJson(Map<String, dynamic> json) =>
    _$PeerStatusLiteImpl(
      rxBytes: (json['RxBytes'] as num).toInt(),
      txBytes: (json['TxBytes'] as num).toInt(),
      lastHandshake: json['LastHandshake'] as String,
      nodeKey: json['NodeKey'] as String,
    );

Map<String, dynamic> _$$PeerStatusLiteImplToJson(
        _$PeerStatusLiteImpl instance) =>
    <String, dynamic>{
      'RxBytes': instance.rxBytes,
      'TxBytes': instance.txBytes,
      'LastHandshake': instance.lastHandshake,
      'NodeKey': instance.nodeKey,
    };

_$PeerStatusImpl _$$PeerStatusImplFromJson(Map<String, dynamic> json) =>
    _$PeerStatusImpl(
      id: json['ID'] as String,
      hostName: json['HostName'] as String,
      dnsName: json['DNSName'] as String,
      os: json['OS'] as String?,
      tailscaleIPs: (json['TailscaleIPs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      tags: (json['Tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      primaryRoutes: (json['PrimaryRoutes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      addrs:
          (json['Addrs'] as List<dynamic>?)?.map((e) => e as String).toList(),
      curAddr: json['CurAddr'] as String?,
      relay: json['Relay'] as String?,
      online: json['Online'] as bool,
      exitNode: json['ExitNode'] as bool,
      exitNodeOption: json['ExitNodeOption'] as bool,
      active: json['Active'] as bool,
      peerAPIUrl: (json['PeerAPIURL'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      capabilities: (json['Capabilities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      sshHostKeys: (json['SSH_HostKeys'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      shareeNode: json['ShareeNode'] as bool?,
      expired: json['Expired'] as bool?,
      location: json['Location'] == null
          ? null
          : Location.fromJson(json['Location'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$PeerStatusImplToJson(_$PeerStatusImpl instance) =>
    <String, dynamic>{
      'ID': instance.id,
      'HostName': instance.hostName,
      'DNSName': instance.dnsName,
      'OS': instance.os,
      'TailscaleIPs': instance.tailscaleIPs,
      'Tags': instance.tags,
      'PrimaryRoutes': instance.primaryRoutes,
      'Addrs': instance.addrs,
      'CurAddr': instance.curAddr,
      'Relay': instance.relay,
      'Online': instance.online,
      'ExitNode': instance.exitNode,
      'ExitNodeOption': instance.exitNodeOption,
      'Active': instance.active,
      'PeerAPIURL': instance.peerAPIUrl,
      'Capabilities': instance.capabilities,
      'SSH_HostKeys': instance.sshHostKeys,
      'ShareeNode': instance.shareeNode,
      'Expired': instance.expired,
      'Location': instance.location,
    };

_$ExitNodeStatusImpl _$$ExitNodeStatusImplFromJson(Map<String, dynamic> json) =>
    _$ExitNodeStatusImpl(
      id: json['ID'] as String,
      online: json['Online'] as bool,
      tailscaleIPs: (json['TailscaleIPs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$ExitNodeStatusImplToJson(
        _$ExitNodeStatusImpl instance) =>
    <String, dynamic>{
      'ID': instance.id,
      'Online': instance.online,
      'TailscaleIPs': instance.tailscaleIPs,
    };

_$TailnetStatusImpl _$$TailnetStatusImplFromJson(Map<String, dynamic> json) =>
    _$TailnetStatusImpl(
      name: json['Name'] as String,
      magicDNSSuffix: json['MagicDNSSuffix'] as String,
      magicDNSEnabled: json['MagicDNSEnabled'] as bool,
    );

Map<String, dynamic> _$$TailnetStatusImplToJson(_$TailnetStatusImpl instance) =>
    <String, dynamic>{
      'Name': instance.name,
      'MagicDNSSuffix': instance.magicDNSSuffix,
      'MagicDNSEnabled': instance.magicDNSEnabled,
    };

_$StatusImpl _$$StatusImplFromJson(Map<String, dynamic> json) => _$StatusImpl(
      version: json['Version'] as String,
      tun: json['TUN'] as bool,
      backendState: json['BackendState'] as String,
      authUrl: json['AuthURL'] as String,
      tailscaleIPs: (json['TailscaleIPs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      self: json['Self'] == null
          ? null
          : PeerStatus.fromJson(json['Self'] as Map<String, dynamic>),
      exitNodeStatus: json['ExitNodeStatus'] == null
          ? null
          : ExitNodeStatus.fromJson(
              json['ExitNodeStatus'] as Map<String, dynamic>),
      health:
          (json['Health'] as List<dynamic>?)?.map((e) => e as String).toList(),
      currentTailnet: json['CurrentTailnet'] == null
          ? null
          : TailnetStatus.fromJson(
              json['CurrentTailnet'] as Map<String, dynamic>),
      certDomains: (json['CertDomains'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      peer: (json['Peer'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, PeerStatus.fromJson(e as Map<String, dynamic>)),
      ),
      user: (json['User'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, UserProfile.fromJson(e as Map<String, dynamic>)),
      ),
      clientVersion: json['ClientVersion'] == null
          ? null
          : ClientVersion.fromJson(
              json['ClientVersion'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$StatusImplToJson(_$StatusImpl instance) =>
    <String, dynamic>{
      'Version': instance.version,
      'TUN': instance.tun,
      'BackendState': instance.backendState,
      'AuthURL': instance.authUrl,
      'TailscaleIPs': instance.tailscaleIPs,
      'Self': instance.self,
      'ExitNodeStatus': instance.exitNodeStatus,
      'Health': instance.health,
      'CurrentTailnet': instance.currentTailnet,
      'CertDomains': instance.certDomains,
      'Peer': instance.peer,
      'User': instance.user,
      'ClientVersion': instance.clientVersion,
    };
