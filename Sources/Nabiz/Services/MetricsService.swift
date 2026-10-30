import Foundation
import Darwin
import IOKit
import IOKit.ps
import Observation

struct ProcInfo: Identifiable, Hashable, Sendable {
    let id: Int32
    let name: String
    let cpu: Double      // yüzde (tek çekirdek = 100)
    let memBytes: Int64
}

struct BatteryInfo: Sendable {
    var level: Double
    var isCharging: Bool
    var onAC: Bool
    var minutesLeft: Int?
    var cycleCount: Int?
    var health: Double?
}

@Observable @MainActor
final class MetricsService {
    static let historyLength = 60

    var cpu: Double = 0
    var cpuHistory = Array(repeating: 0.0, count: historyLength)
    var cores: [Double] = []

    let memTotal = ProcessInfo.processInfo.physicalMemory
    var memUsed: UInt64 = 0
    var memApp: UInt64 = 0
    var memWired: UInt64 = 0
    var memCompressed: UInt64 = 0
    var memHistory = Array(repeating: 0.0, count: historyLength)
    var swapUsed: UInt64 = 0
    var pressureLevel = 1   // 1 normal, 2 uyarı, 4 kritik

    var diskTotal: Int64 = 0
    var diskFree: Int64 = 0

    var battery: BatteryInfo?

    var netIn: Double = 0
    var netOut: Double = 0
    var netInHistory = Array(repeating: 0.0, count: historyLength)
    var netOutHistory = Array(repeating: 0.0, count: historyLength)

    var uptime: TimeInterval = ProcessInfo.processInfo.systemUptime
    var thermal: ProcessInfo.ThermalState = ProcessInfo.processInfo.thermalState
    var load: [Double] = [0, 0, 0]
    var topProcesses: [ProcInfo] = []

    var machineName = "Mac"
    var chip = MetricsService.sysctlString("machdep.cpu.brand_string")
    let osVersion = "macOS " + ProcessInfo.processInfo.operatingSystemVersionString
        .replacingOccurrences(of: "Version ", with: "")
    let hostName = Host.current().localizedName ?? "Mac"

    var memFraction: Double { memTotal > 0 ? Double(memUsed) / Double(memTotal) : 0 }
    var diskUsedFraction: Double { diskTotal > 0 ? 1 - Double(diskFree) / Double(diskTotal) : 0 }
    var diskFreeFraction: Double { 1 - diskUsedFraction }
    var cpuAverage: Double {
        let r = cpuHistory.suffix(12)
        return r.reduce(0, +) / Double(max(r.count, 1))
    }
    var pressureText: String { pressureLevel >= 4 ? L("Kritik", "Critical") : pressureLevel >= 2 ? L("Yüksek", "High") : "Normal" }

    @ObservationIgnored private var prevTicks: [[UInt32]] = []
    @ObservationIgnored private var prevNet: (UInt64, UInt64, Date)?
    @ObservationIgnored private var tick = 0
    @ObservationIgnored private var loop: Task<Void, Never>?

    init() {
        sampleDisk()
        battery = Self.readBattery()
        Task { await loadHardwareInfo() }
        loop = Task { [weak self] in
            while !Task.isCancelled {
                self?.sample()
                try? await Task.sleep(for: .seconds(1.5))
            }
        }
    }

    func refreshSlow() {
        sampleDisk()
        battery = Self.readBattery()
        Task { await refreshProcesses() }
    }

    private func sample() {
        sampleCPU()
        sampleMemory()
        sampleNetwork()
        uptime = ProcessInfo.processInfo.systemUptime
        thermal = ProcessInfo.processInfo.thermalState
        var l = [0.0, 0.0, 0.0]
        if getloadavg(&l, 3) == 3 { load = l }
        if tick % 3 == 0 { Task { await refreshProcesses() } }
        if tick % 10 == 0 { sampleDisk(); battery = Self.readBattery() }
        tick += 1
    }

    private func push(_ arr: inout [Double], _ v: Double) {
        arr.append(v)
        if arr.count > Self.historyLength { arr.removeFirst(arr.count - Self.historyLength) }
    }

    // MARK: CPU
    private func sampleCPU() {
        var cpuCount: natural_t = 0
        var info: processor_info_array_t?
        var count: mach_msg_type_number_t = 0
        guard host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &cpuCount, &info, &count) == KERN_SUCCESS,
              let info else { return }
        defer {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info),
                          vm_size_t(Int(count) * MemoryLayout<integer_t>.stride))
        }
        var ticks: [[UInt32]] = []
        var perCore: [Double] = []
        var used: UInt64 = 0, all: UInt64 = 0
        let n = Int(cpuCount)
        for i in 0..<n {
            let b = Int(CPU_STATE_MAX) * i
            let t = [Int(CPU_STATE_USER), Int(CPU_STATE_SYSTEM), Int(CPU_STATE_IDLE), Int(CPU_STATE_NICE)]
                .map { UInt32(bitPattern: info[b + $0]) }
            ticks.append(t)
            if prevTicks.count == n {
                let p = prevTicks[i]
                let u = UInt64(t[0] &- p[0]) + UInt64(t[1] &- p[1]) + UInt64(t[3] &- p[3])
                let a = u + UInt64(t[2] &- p[2])
                perCore.append(a > 0 ? Double(u) / Double(a) : 0)
                used += u; all += a
            }
        }
        prevTicks = ticks
        guard !perCore.isEmpty else { return }
        cores = perCore
        cpu = all > 0 ? Double(used) / Double(all) : 0
        push(&cpuHistory, cpu)
    }

    // MARK: Bellek
    private func sampleMemory() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let kr = withUnsafeMutablePointer(to: &stats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return }
        let page = UInt64(getpagesize())
        let internalPages = UInt64(stats.internal_page_count)
        memApp = (internalPages - min(UInt64(stats.purgeable_count), internalPages)) * page
        memWired = UInt64(stats.wire_count) * page
        memCompressed = UInt64(stats.compressor_page_count) * page
        memUsed = memApp + memWired + memCompressed
        push(&memHistory, memFraction)

        var xsw = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        if sysctlbyname("vm.swapusage", &xsw, &size, nil, 0) == 0 { swapUsed = xsw.xsu_used }
        var level: Int32 = 0
        size = MemoryLayout<Int32>.size
        if sysctlbyname("kern.memorystatus_vm_pressure_level", &level, &size, nil, 0) == 0 { pressureLevel = Int(level) }
    }

    // MARK: Ağ
    private func sampleNetwork() {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return }
        defer { freeifaddrs(ifaddr) }
        var inB: UInt64 = 0, outB: UInt64 = 0
        var p = ifaddr
        while let ptr = p {
            let ifa = ptr.pointee
            if let addr = ifa.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK), let data = ifa.ifa_data {
                let name = String(cString: ifa.ifa_name)
                if !name.hasPrefix("lo") {
                    let d = data.assumingMemoryBound(to: if_data.self).pointee
                    inB += UInt64(d.ifi_ibytes)
                    outB += UInt64(d.ifi_obytes)
                }
            }
            p = ifa.ifa_next
        }
        let now = Date()
        if let (pi, po, pt) = prevNet {
            let dt = max(now.timeIntervalSince(pt), 0.1)
            netIn = inB >= pi ? Double(inB - pi) / dt : 0
            netOut = outB >= po ? Double(outB - po) / dt : 0
            push(&netInHistory, netIn)
            push(&netOutHistory, netOut)
        }
        prevNet = (inB, outB, now)
    }

    // MARK: Disk
    private func sampleDisk() {
        let keys: Set<URLResourceKey> = [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
        if let v = try? URL(fileURLWithPath: "/").resourceValues(forKeys: keys) {
            diskTotal = Int64(v.volumeTotalCapacity ?? 0)
            diskFree = v.volumeAvailableCapacityForImportantUsage ?? 0
        }
    }

    // MARK: Pil
    nonisolated static func readBattery() -> BatteryInfo? {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] else { return nil }
        for src in list {
            guard let desc = IOPSGetPowerSourceDescription(blob, src)?.takeUnretainedValue() as? [String: Any],
                  (desc["Type"] as? String) == "InternalBattery" else { continue }
            let cur = desc["Current Capacity"] as? Int ?? 0
            let max = desc["Max Capacity"] as? Int ?? 100
            var info = BatteryInfo(level: Double(cur) / Double(Swift.max(max, 1)),
                                   isCharging: desc["Is Charging"] as? Bool ?? false,
                                   onAC: (desc["Power Source State"] as? String) == "AC Power")
            if let t = desc["Time to Empty"] as? Int, t > 0 { info.minutesLeft = t }
            let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
            if service != 0 {
                defer { IOObjectRelease(service) }
                var props: Unmanaged<CFMutableDictionary>?
                if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                   let d = props?.takeRetainedValue() as? [String: Any] {
                    info.cycleCount = d["CycleCount"] as? Int
                    if let design = d["DesignCapacity"] as? Int, design > 0,
                       let raw = (d["AppleRawMaxCapacity"] as? Int) ?? (d["NominalChargeCapacity"] as? Int) {
                        info.health = min(1, Double(raw) / Double(design))
                    }
                }
            }
            return info
        }
        return nil
    }

    // MARK: İşlemler
    private func refreshProcesses() async {
        let r = await Shell.run("/bin/ps", ["-Aceo", "pid=,pcpu=,rss=,comm=", "-r"], timeout: 5)
        var list: [ProcInfo] = []
        for line in r.out.split(separator: "\n") {
            let parts = line.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: true)
            guard parts.count == 4, let pid = Int32(parts[0]), let c = Double(parts[1].replacingOccurrences(of: ",", with: ".")),
                  let rss = Int64(parts[2]) else { continue }
            let name = String(parts[3])
            if name == "ps" || name == "kernel_task" && c < 1 { continue }
            list.append(ProcInfo(id: pid, name: name, cpu: c, memBytes: rss * 1024))
            if list.count == 8 { break }
        }
        topProcesses = list
    }

    private func loadHardwareInfo() async {
        let r = await Shell.run("/usr/sbin/system_profiler", ["SPHardwareDataType"], timeout: 15)
        for line in r.out.split(separator: "\n") {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("Model Name:") { machineName = String(t.dropFirst(11)).trimmingCharacters(in: .whitespaces) }
            if t.hasPrefix("Chip:") { chip = String(t.dropFirst(5)).trimmingCharacters(in: .whitespaces) }
        }
    }

    nonisolated static func sysctlString(_ name: String) -> String {
        var size = 0
        sysctlbyname(name, nil, &size, nil, 0)
        guard size > 0 else { return "" }
        var buf = [CChar](repeating: 0, count: size)
        sysctlbyname(name, &buf, &size, nil, 0)
        return String(cString: buf)
    }
}
