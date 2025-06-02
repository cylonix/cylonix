// SPDX-License-Identifier: MIT
// Copyright © 2018-2020 WireGuard LLC. All Rights Reserved.

import Foundation
class Utils: NSObject {
    enum ParseError: Error {
        case invalidLine(String.SubSequence)
        case noInterface
        case multipleInterfaces
        case interfaceHasNoPrivateKey
        case interfaceHasInvalidPrivateKey(String)
        case interfaceHasInvalidListenPort(String)
        case interfaceHasInvalidAddress(String)
        case interfaceHasInvalidDNS(String)
        case interfaceHasInvalidMTU(String)
        case interfaceHasUnrecognizedKey(String)
        case peerHasNoPublicKey
        case peerHasInvalidPublicKey(String)
        case peerHasInvalidPreSharedKey(String)
        case peerHasInvalidAllowedIP(String)
        case peerHasInvalidEndpoint(String)
        case peerHasInvalidPersistentKeepAlive(String)
        case peerHasInvalidTransferBytes(String)
        case peerHasInvalidLastHandshakeTime(String)
        case peerHasUnrecognizedKey(String)
        case multiplePeersWithSamePublicKey
        case multipleEntriesForKey(String)
    }
    static func converFromConfig(config: Config) throws -> TunnelConfiguration{
        var tunnelConfig: TunnelConfiguration

        //construct InterfaceConfiguration
        let privateKeyString: String = config.sk
        let privateKey = PrivateKey(base64Key: privateKeyString)
        var interface = InterfaceConfiguration(privateKey: privateKey!)
        var addresses = [IPAddressRange]()
        let address = IPAddressRange(from: config.ip)
        addresses.append(address!)
        interface.addresses = addresses

        //construct peerConfigurations
        var peerConfigurations = [PeerConfiguration]()
        let publicKeyString = config.peerPk
        let publicKey = PublicKey(base64Key: publicKeyString)
        var peer = PeerConfiguration(publicKey: publicKey!)
        var allowedIPs = [IPAddressRange]()
        let allowedIPsString: [String]
        allowedIPsString = config.peerAllowedIps
        for allowedIPString in allowedIPsString{
            let allowedIP = IPAddressRange(from: allowedIPString)
            allowedIPs.append(allowedIP!)
        }
        peer.allowedIPs = allowedIPs
        let endpointString = config.peerIp
        guard let endpoint = Endpoint(from: endpointString) else {
            throw ParseError.peerHasInvalidEndpoint(endpointString)
        }
        peer.endpoint = endpoint
        peerConfigurations.append(peer)

        //construct TunnelConfiguration
        tunnelConfig = TunnelConfiguration.init(name: "cylonix", interface: interface, peers: peerConfigurations)
        return tunnelConfig
    }
}
