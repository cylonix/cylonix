// SPDX-License-Identifier: MIT
// Copyright © 2018-2020 WireGuard LLC. All Rights Reserved.

import Foundation
struct Config {
    var dns: String
    var ip: String
    var peerIp: String
    var peerAllowedIps: [String]
    var peerPk: String
    var sk: String
    init(dns: String, ip: String, peerIp: String, peerAllowedIps: [String], peerPk: String, sk: String) {
        self.dns = dns
        self.ip = ip
        self.peerIp = peerIp
        self.peerPk = peerPk
        self.sk = sk
        self.peerAllowedIps = peerAllowedIps
    }
}
