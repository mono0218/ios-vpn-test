import Foundation

extension Data {
    func to<T>(type: T.Type) -> T {
        withUnsafeBytes {
            let bytes = $0.bindMemory(to: T.self).baseAddress!
            return bytes.pointee
        }
    }
}

extension Data {
    init?(hex: String) {
        let len = hex.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hex.index(hex.startIndex, offsetBy: i * 2)
            let k = hex.index(j, offsetBy: 2)
            let bytes = hex[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }

    var hex: String {
        return reduce("") { $0 + String(format: "%02x", $1) }
    }
}

extension Collection {
    func chunks(ofSize size: Int) -> [SubSequence] {
        guard !isEmpty else { return [] }
        return [prefix(size)] + dropFirst(size).chunks(ofSize: size)
    }
}