
import NetworkExtension
import os
import Foundation

extension Data {
    func hexString() -> String {
        return self.map { String(format: "%02x", $0) }.joined()
    }
}

class PacketTunnelProvider: NEPacketTunnelProvider {

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        NSLog("Starting tunnel with options: \(options ?? [:])")
        NSLog("Start VPN")
        
        let ip = "10.10.10.10"
        let subnetMask = "255.255.255.0"

        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        let ipv4Settings = NEIPv4Settings(addresses: [ip], subnetMasks: [subnetMask])

        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        ipv4Settings.excludedRoutes = [
            NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),
            NEIPv4Route(destinationAddress: "127.0.0.0", subnetMask: "255.0.0.0"),
            NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
        ]
        settings.ipv4Settings = ipv4Settings

        let dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "8.8.4.4","1.1.1.1"])
        dnsSettings.matchDomains = [""]
        settings.dnsSettings = dnsSettings

        setTunnelNetworkSettings(settings) { [weak self] error in
            guard let self = self else { return }

            completionHandler(error)
            if let error = error {
                NSLog("Tunnel network settings error: \(error)")
            } else {
                self.localPacketsToServer()
            }
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
            completionHandler()
    }

    private func localPacketsToServer() {
        packetFlow.readPacketObjects { [weak self] (packets) in
            defer { self?.localPacketsToServer() }
            packets.forEach { (packet) in
                if let name = parseDNSDomain(from: packet.data), !name.isEmpty {
                    NSLog(name)
                }
            }
        }
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Add code here to handle the message.
        if let handler = completionHandler {
            handler(messageData)
        }
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        // Add code here to get ready to sleep.
        completionHandler()
    }
    
    override func wake() {
        // Add code here to wake up.
    }
}
