import Foundation

/// Küçük, zaman aşımlı komut çalıştırıcı. Tüm sistem komutları salt-okunurdur.
enum Shell {
    struct Result: Sendable { let out: String; let err: String; let code: Int32
        var all: String { out + "\n" + err }
    }

    static func run(_ path: String, _ args: [String] = [], timeout: TimeInterval = 15) async -> Result {
        await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .utility).async {
                let p = Process()
                p.executableURL = URL(fileURLWithPath: path)
                p.arguments = args
                let o = Pipe(), e = Pipe()
                p.standardOutput = o
                p.standardError = e
                do { try p.run() } catch {
                    cont.resume(returning: Result(out: "", err: error.localizedDescription, code: -1))
                    return
                }
                DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                    if p.isRunning { p.terminate() }
                }
                let od = o.fileHandleForReading.readDataToEndOfFile()
                let ed = e.fileHandleForReading.readDataToEndOfFile()
                p.waitUntilExit()
                cont.resume(returning: Result(out: String(decoding: od, as: UTF8.self),
                                              err: String(decoding: ed, as: UTF8.self),
                                              code: p.terminationStatus))
            }
        }
    }
}

enum Fmt {
    static func pct(_ v: Double) -> String { "%\(Int((max(0, v) * 100).rounded()))" }
    static func bytes(_ v: Int64) -> String { ByteCountFormatter.string(fromByteCount: max(0, v), countStyle: .file) }
    static func bytes(_ v: UInt64) -> String { bytes(Int64(clamping: v)) }
    static func rate(_ v: Double) -> String { bytes(Int64(v)) + L("/sn", "/s") }
    static func duration(_ t: TimeInterval) -> String {
        let m = Int(t) / 60, h = m / 60, d = h / 24
        if d > 0 { return L("\(d) gün \(h % 24) sa", "\(d)d \(h % 24)h") }
        if h > 0 { return L("\(h) sa \(m % 60) dk", "\(h)h \(m % 60)m") }
        return L("\(m) dk", "\(m) min")
    }
    static func thermal(_ s: ProcessInfo.ThermalState) -> String {
        switch s {
        case .nominal: return "Normal"
        case .fair: return L("Ilık", "Warm")
        case .serious: return L("Sıcak", "Hot")
        case .critical: return L("Kritik", "Critical")
        @unknown default: return "—"
        }
    }
}
