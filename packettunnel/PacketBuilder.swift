import NetworkExtension
import Foundation

class PacketBuilder {
    private let sourceIP: String
    private let destinationIP: String
    private let sourcePort: UInt16
    private let destinationPort: UInt16
    
    init(sourceIP: String, destinationIP: String, sourcePort: UInt16, destinationPort: UInt16) {
        self.sourceIP = sourceIP
        self.destinationIP = destinationIP
        self.sourcePort = sourcePort
        self.destinationPort = destinationPort
    }
    
    func replySynAck() -> [NEPacket] {
        var packet = IPPacket(
            proto: .tcp,
            source: destinationIP,
            destination: sourceIP,
            sourcePort: destinationPort,
            destinationPort: sourcePort,
            payload: Data()
        )
        
        packet.setTCPFlags(syn: true, ack: true)
        
        return [NEPacket(data: packet.packetData, protocolFamily: sa_family_t(AF_INET))]
    }
    
    func ackFinAck() -> [NEPacket] {
        var packet = IPPacket(
            proto: .tcp,
            source: destinationIP,
            destination: sourceIP,
            sourcePort: destinationPort,
            destinationPort: sourcePort,
            payload: Data()
        )
        
        packet.setTCPFlags(syn: true, ack: true)
        
        return [NEPacket(data: packet.packetData, protocolFamily: sa_family_t(AF_INET))]
    }
    
    func reset() -> [NEPacket] {
        var packet = IPPacket(
            proto: .tcp,
            source: destinationIP,
            destination: sourceIP,
            sourcePort: destinationPort,
            destinationPort: sourcePort,
            payload: Data()
        )
        
        packet.setTCPFlags(rst: true)
        
        return [NEPacket(data: packet.packetData, protocolFamily: sa_family_t(AF_INET))]
    }
}
