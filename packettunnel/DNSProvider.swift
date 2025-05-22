import Foundation

public func parseDNSDomain(from packet: Data) -> String? {
    guard packet.count >= 28 else {
        return nil
    }

    // IPヘッダーのIHL（4ビット単位）を取得
    let versionAndIHL = packet[0]
    let ihl = versionAndIHL & 0x0F
    let ipHeaderLength = Int(ihl) * 4

    // UDPかどうか判定（IPヘッダーの9バイト目）
    let protocolNumber = packet[9]
    guard protocolNumber == 0x11 else { return nil } // UDP = 17

    // UDPポート番号
    let udpStart = ipHeaderLength
    guard packet.count >= udpStart + 8 else { return nil }

    let srcPort = UInt16(packet[udpStart..<udpStart+2].withUnsafeBytes { $0.load(as: UInt16.self).bigEndian })
    let dstPort = UInt16(packet[udpStart+2..<udpStart+4].withUnsafeBytes { $0.load(as: UInt16.self).bigEndian })

    guard srcPort == 53 || dstPort == 53 else {
        return nil
    }

    // DNSヘッダーの開始位置 = UDPヘッダー（8バイト）の後
    let dnsStart = udpStart + 8
    guard packet.count > dnsStart + 12 else { return nil }

    // QNAMEのパース
    var domainParts: [String] = []
    var offset = dnsStart + 12 // DNSヘッダー後（質問セクションの名前部分）

    while offset < packet.count {
        let length = Int(packet[offset])
        if length == 0 {
            // null terminator
            offset += 1
            break
        }
        offset += 1
        guard offset + length <= packet.count else { return nil }
        let labelData = packet[offset..<(offset + length)]
        if let label = String(data: labelData, encoding: .ascii) {
            domainParts.append(label)
        } else {
            return nil
        }
        offset += length
    }

    return domainParts.joined(separator: ".")
}
