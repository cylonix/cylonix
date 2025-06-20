import 'ipn.dart';

class BackendNotifyEvent {
  final IpnNotification notification;
  const BackendNotifyEvent(this.notification);
}

// From wireguard-apple/Sources/WireGuardApp/Tunnel/TunnelStatus.swift
// Instead of NEVPNStatus
/*
        case .inactive: return "inactive"
        case .activating: return "activating"
        case .active: return "active"
        case .deactivating: return "deactivating"
        case .reasserting: return "reasserting"
        case .restarting: return "restarting"
        case .waiting: return "waiting"
*/

class TunnelStatus {
  final String status;
  const TunnelStatus(this.status);
  static const inactive = TunnelStatus("inactive");
  static const activating = TunnelStatus("activating");
  static const active = TunnelStatus("active");
  static const deactivating = TunnelStatus("deactivating");
  static const reasserting = TunnelStatus("reasserting");
  static const restarting = TunnelStatus("restarting");
  static const waiting = TunnelStatus("waiting");

  bool get readyToStart {
    return status == active.status;
  }

  @override
  bool operator ==(Object other) {
    if (other is! TunnelStatus) {
      return false;
    }
    return status == other.status;
  }

  @override
  int get hashCode => status.hashCode;

  @override
  String toString() {
    return status;
  }
}

class TunnelStatusEvent {
  final TunnelStatus status;
  final String? error;
  const TunnelStatusEvent(this.status, {this.error});
  @override
  String toString() {
    return "status: $status ${error ?? ''}";
  }
}

class VpnPermissionEvent {
  final bool isGranted;

  const VpnPermissionEvent({
    this.isGranted = false,
  });

  @override
  String toString() {
    return "VpnPermissionEvent(isGranted: $isGranted)";
  }
}
