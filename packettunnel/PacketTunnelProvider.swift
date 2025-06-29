
import NetworkExtension
import os
import Foundation

extension Data {
    func hexString() -> String {
        return self.map { String(format: "%02x", $0) }.joined()
    }
}

class PacketTunnelProvider: NEPacketTunnelProvider {
    private var tcpSessions = [String: TCPSession]()
    private var udpSessions = [String: UDPSession]()
    private var packetBuilder: PacketBuilder?

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
            guard let self = self else { return }
            packets.forEach { (packet) in
                if let name = parseDNSDomain(from: packet.data), !name.isEmpty {
                    NSLog(name)
                }

                if let ipPacket = IPPacket(packet.data) {
                    switch ipPacket.proto {
                    case .tcp:
                        self.handleTCPPacket(ipPacket)
                    case .udp:
                        self.sendUDPPacket(ipPacket)
                    case .icmp:
                        break
                    }
                }
            }
        }
    }
    
    private func handleTCPPacket(_ packet: IPPacket) {
        if packetBuilder == nil {
            packetBuilder = PacketBuilder(
                sourceIP: packet.source,
                destinationIP: packet.destination,
                sourcePort: packet.sourcePort,
                destinationPort: packet.destinationPort
            )
        }
        sendTCPPacket(packet)
    }
    
    private func sendTCPPacket(_ packet: IPPacket) {
        let tcpSession = TCPSession(
            host: packet.destination,
            port: packet.destinationPort,
            payload: packet.payload
        )

        let header = packet.tcpHeader
        if header.isSyn {
            packetFlow.writePacketObjects(
                packetBuilder!.replySynAck())
        } else if header.isAck {
            if packet.payload.count > 0 {
                tcpSession.send(packet.payload)
                tcpSession.onReceive = { [weak self] data in
                    guard let self = self else { return }
                    
                    packetFlow.writePacketObjects([
                        NEPacket(
                            data: data,
                            protocolFamily: sa_family_t(AF_INET)
                        )
                    ])
                }
            } else {
                packetFlow.writePacketObjects(
                    packetBuilder!.ackFinAck())
            }
        } else if header.isFin {
            packetFlow.writePacketObjects(packetBuilder!.ackFinAck())
        } else if header.isRst {
            packetFlow.writePacketObjects(packetBuilder!.reset())
        }
    }
    
    func sendUDPPacket(_ packet: IPPacket) {
        let key = "\(packet.source):\(packet.sourcePort) => \(packet.destination):\(packet.destinationPort)"

        if let session = self.udpSessions[key] {
            session.send(packet.payload)
        } else {
            let session = UDPSession(
                host: packet.destination,
                port: packet.destinationPort,
                payload: packet.payload
            )
            session.onReceive = { [weak self] (data) in
                guard let self = self else { return }

                let packet = IPPacket(
                    proto: packet.proto,
                    source: packet.destination,
                    destination: packet.source,
                    sourcePort: packet.destinationPort,
                    destinationPort: packet.sourcePort,
                    payload: data
                )

                self.packetFlow.writePacketObjects([
                    NEPacket(
                        data: packet.packetData,
                        protocolFamily: sa_family_t(AF_INET)
                    )
                ])
            }
            session.onError = { (error) in
                NSLog("UDP Error: \(error)")
            }

            self.udpSessions[key] = session
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
