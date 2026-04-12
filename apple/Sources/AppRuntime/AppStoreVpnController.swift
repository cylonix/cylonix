// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import Foundation
import NetworkExtension
#if os(macOS)
import Darwin
#endif
#if SWIFT_PACKAGE
import WireGuardKitGo
#endif

class AppStoreVpnController: AppleVpnControlling {
    private let eventSink: VpnEventSink
    private let tunnelName = "Cylonix Tunnel"
    private let serverAddress = "Cylonix Mesh"
    var tunnelsManager: TunnelsManager?

    init(eventSink: @escaping VpnEventSink) {
        self.eventSink = eventSink
    }

    func createTunnelsManager(_ id: String) {
        wg_log(.info, staticMessage: "creating tunnels manager")
        TunnelsManager.create { result in
            self.handleTunnelCreateResult(id, result)
        }
    }

    func checkVPNPermission(_ id: String) {
        wg_log(.info, staticMessage: "check vpn permission")
        TunnelsManager.isPrepared { result in
            var state = false
            switch result {
            case let .success(isPrepared):
                wg_log(.info, message: "VPN is prepared: \(isPrepared)")
                state = isPrepared
            case let .failure(error):
                wg_log(.error, message: "Failed to check VPN preparation: \(error)")
            }
            self.emit("tunnelCreated", ["isCreated": state, "id": id])
        }
    }

    func handleGetLogs(_ id: String) -> String {
        wg_log(.debug, message: "handleGetWgLogs")
        tunnelsManager?.getWgLogs { logs in
            for log in logs {
                print(log)
            }
            wg_log(.debug, message: "wg logs retrived with \(logs.count) lines id=\(id)")
            self.emit("logs", ["id": id, "logs": logs])
        }
        return "Success"
    }

    func handleSendCommand(_ arguments: [String: String]) -> String {
        guard let tunnelsMgr = tunnelsManager else {
            let message = "FAILED: tunnels manager is nil. command: \(arguments["cmd"] ?? "<unknown>")"
            wg_log(.error, message: message)
            return message
        }

        guard let cmd = arguments["cmd"], let id = arguments["id"], let args = arguments["args"] else {
            let message = "Invalid arguments: \(arguments)"
            wg_log(.error, message: message)
            return message
        }

        tunnelsMgr.sendCommand(tunnelName, cmd, args) { result in
            if result == "Success", cmd == "start_tailchat" || cmd == "stop_tailchat" {
                self.persistTailchatServiceState(isEnabled: cmd == "start_tailchat")
            }
            if id.isEmpty {
                return
            }
            self.emit("commandResult", ["cmd": cmd, "id": id, "result": result])
        }
        return "Success"
    }

    func emit(_ method: String, _ arguments: Any?) {
        eventSink(method, arguments)
    }

    fileprivate func getCylonixTunnelConfiguration() -> TunnelConfiguration {
        let interface = InterfaceConfiguration(privateKey: PrivateKey())
        return TunnelConfiguration(name: tunnelName, interface: interface, peers: [], serverAddress: serverAddress)
    }

    fileprivate func getTunnel() -> TunnelContainer? {
        tunnelsManager?.tunnel(named: tunnelName)
    }

    fileprivate func setupOrUpdateTunnel() {
        let onDemandOption = ActivateOnDemandOption.anyInterface(ActivateOnDemandSSIDOption.anySSID)
        var tunnelConfig = getCylonixTunnelConfiguration()
        if let tunnel = getTunnel() {
            if let currentTunnelConfig = tunnel.tunnelConfiguration, currentTunnelConfig.name == tunnelConfig.name {
                tunnelConfig = currentTunnelConfig
            }

            if tunnel.isActivateOnDemandEnabled {
                let status = tunnel.status
                wg_log(.info, message: "Tunnel '\(tunnel.name)' on demand is already enabled. Current status '\(status)'.")
                emit("tunnelStatus", ["status": "\(status)"])
                if status == .inactive {
                    wg_log(.info, message: "Tunnel '\(tunnel.name)' is inactive. Start the tunnel.")
                    tunnelsManager?.start(tunnel.name)
                }
                return
            }

            tunnelsManager?.modify(
                tunnel: tunnel,
                tunnelConfiguration: tunnelConfig,
                onDemandOption: onDemandOption,
                shouldEnsureOnDemandEnabled: true
            ) { error in
                if let error {
                    let msg = "Failed to enable on demand for VPN Tunnel '\(tunnel.name)': \(error)"
                    wg_log(.error, message: msg)
                    self.emit("tunnelStatus", ["status": "invalid", "error": msg])
                    return
                }
                self.tunnelsManager?.start(tunnel.name)
                self.emit("tunnelStatus", ["status": "\(TunnelStatus.waiting)"])
            }
            return
        }

        tunnelsManager?.add(tunnelConfiguration: tunnelConfig, onDemandOption: onDemandOption) { result in
            var status = TunnelStatus.inactive
            switch result {
            case let .failure(error):
                let msg = "Failed to add VPN tunnel '\(String(describing: tunnelConfig.name))': \(error)"
                wg_log(.error, message: msg)
                self.emit("tunnelStatus", ["status": "invalid", "error": msg])
                return
            case .success:
                wg_log(.debug, message: "VPN tunnel '\(String(describing: tunnelConfig.name))' added successfully")
                status = .waiting
            }
            self.tunnelsManager?.start(tunnelConfig.name!)
            self.emit("tunnelStatus", ["status": "\(status)"])
        }
    }

    func handleTunnelCreateResult(_ id: String, _ result: Result<TunnelsManager, TunnelsManagerError>) {
        switch result {
        case let .failure(error):
            let (_, message) = error.alertText
            let alertMessage = "Tunnel creation failed: \(message)"
            wg_log(.error, message: alertMessage)
            emit("tunnelStatus", ["status": "invalid", "error": alertMessage])
            emit("tunnelCreated", ["id": id, "isCreated": false])
        case let .success(tunnelsMgr):
            wg_log(.info, message: "Tunnel manager created: tunnelsMgr=\(tunnelsMgr)")
            emit("tunnelCreated", ["id": id, "isCreated": true])
            tunnelsManager = tunnelsMgr

            TunnelsManager.onTunnelStatusChange { tunnelName, status in
                wg_log(.info, message: "Tunnel '\(tunnelName)' status changed to '\(status)'.")
                if tunnelName != self.tunnelName {
                    if let tunnel = self.tunnelsManager?.tunnel(named: tunnelName) {
                        self.tunnelsManager?.remove(tunnel: tunnel) { error in
                            if let error {
                                wg_log(.error, message: "Failed to remove tunnel '\(tunnelName): \(error)")
                            }
                        }
                    }
                    return
                }
                self.emit("tunnelStatus", ["status": status])
            }

            setupOrUpdateTunnel()
        }
    }

    private func persistTailchatServiceState(isEnabled: Bool) {
        guard let appGroupId = FileManager.appGroupId,
              let groupDefaults = UserDefaults(suiteName: appGroupId)
        else {
            wg_log(.error, message: "Failed to access app group defaults")
            return
        }

        groupDefaults.set(isEnabled, forKey: "tailchat_service_enabled")
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let name = "io.cylonix.sase.tailchat.stateChange" as CFString
        CFNotificationCenterPostNotification(
            center,
            CFNotificationName(name),
            nil,
            nil,
            true
        )
        let state = isEnabled ? "enabled" : "disabled"
        wg_log(.debug, message: "Saved tailchat service state as '\(state)' in app group defaults and notified")
    }
}
