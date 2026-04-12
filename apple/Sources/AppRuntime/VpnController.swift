// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import Foundation
#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

typealias VpnEventSink = (String, Any?) -> Void

protocol AppleVpnControlling: AnyObject {
    func createTunnelsManager(_ id: String)
    func checkVPNPermission(_ id: String)
    func handleGetLogs(_ id: String) -> String
    func handleSendCommand(_ arguments: [String: String]) -> String
}

enum CylonixDistributionMode: String {
    case appStore = "appstore"
    case direct = "direct"

    static func current() -> CylonixDistributionMode {
        #if os(macOS)
            let rawValue = Bundle.main.object(forInfoDictionaryKey: "io.cylonix.distribution_mode") as? String
            return CylonixDistributionMode(rawValue: rawValue ?? "") ?? .appStore
        #else
            return .appStore
        #endif
    }
}

enum AppleVpnControllerFactory {
    static func make(eventSink: @escaping VpnEventSink) -> AppleVpnControlling {
        return AppStoreVpnController(eventSink: eventSink)
    }
}
