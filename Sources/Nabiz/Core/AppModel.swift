import SwiftUI
import AppKit
import Observation

enum Severity: Int, Comparable, CaseIterable {
    case critical, warning, tip
    static func < (a: Severity, b: Severity) -> Bool { a.rawValue < b.rawValue }
    var color: Color { [Palette.red, Palette.amber, Palette.cyan][rawValue] }
    var icon: String { ["exclamationmark.octagon.fill", "exclamationmark.triangle.fill", "lightbulb.fill"][rawValue] }
    var label: String { [L("Kritik", "Critical"), L("Uyarı", "Warning"), L("İpucu", "Tip")][rawValue] }
}

enum AdviceAction {
    case open(String)
    case go(AppSection)
    case activityMonitor
    case boost
}

struct Advice: Identifiable {
    let id: String
    let icon: String
    let title: String
    let detail: String
    let severity: Severity
    var action: AdviceAction?
    var actionHelp = L("Düzelt", "Fix")
    var actionIcon = "arrow.up.forward"
}

struct HeavyApp: Identifiable {
    var id: pid_t { pid }
    let pid: pid_t
    let name: String
    let icon: NSImage?
    let memBytes: Int64
    let cpu: Double
}

@Observable @MainActor
final class AppModel {
    var section: AppSection = .overview
    var showBoost = false
    var heavyApps: [HeavyApp] = []

    let metrics = MetricsService()
    let security = SecurityService()
    let cleanup = CleanupService()
    let ai = AIService()

    init() {
        security.runAll()
    }

    func setLanguage(_ l: AppLanguage) {
        guard Loc.shared.lang != l else { return }
        withAnimation(.easeInOut(duration: 0.25)) { Loc.shared.lang = l }
        security.relocalize()
        cleanup.relocalize()
    }

    func toggleLanguage() { setLanguage(Loc.shared.lang == .tr ? .en : .tr) }

    func go(_ s: AppSection) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { section = s }
    }

    func refreshAll() {
        security.runAll()
        metrics.refreshSlow()
        Task { await loadHeavyApps() }
    }

    // MARK: Puanlar
    var performanceScore: Double {
        let m = metrics
        var s = 100.0
        if m.cpuAverage > 0.85 { s -= 20 } else if m.cpuAverage > 0.6 { s -= 8 }
        if m.pressureLevel >= 4 { s -= 30 } else if m.pressureLevel >= 2 { s -= 15 }
        if m.swapUsed > 4 << 30 { s -= 12 } else if m.swapUsed > 1 << 30 { s -= 5 }
        if m.diskFreeFraction < 0.1 { s -= 25 } else if m.diskFreeFraction < 0.2 { s -= 10 }
        if m.thermal == .serious { s -= 12 } else if m.thermal == .critical { s -= 25 }
        if m.uptime > 14 * 86_400 { s -= 5 }
        return max(0, s) / 100
    }

    var healthScore: Double { performanceScore * 0.5 + security.score * 0.5 }

    var healthLabel: String {
        switch healthScore {
        case 0.9...: return L("Harika", "Excellent")
        case 0.75..<0.9: return L("İyi", "Good")
        case 0.55..<0.75: return L("Bakım gerekli", "Needs care")
        default: return L("Dikkat", "Attention")
        }
    }

    // MARK: Öneriler
    var advices: [Advice] {
        var list: [Advice] = []
        let m = metrics

        if m.diskTotal > 0 {
            if m.diskFreeFraction < 0.1 {
                list.append(.init(id: "disk-crit", icon: "internaldrive.fill", title: L("Disk neredeyse dolu", "Disk is almost full"),
                                  detail: L("Yalnızca \(Fmt.bytes(m.diskFree)) boş. Dolu disk Mac'i belirgin şekilde yavaşlatır.", "Only \(Fmt.bytes(m.diskFree)) free. A full disk slows your Mac noticeably."),
                                  severity: .critical, action: .go(.cleanup), actionHelp: L("Temizliğe git", "Go to Cleanup"), actionIcon: "sparkles"))
            } else if m.diskFreeFraction < 0.2 {
                list.append(.init(id: "disk-warn", icon: "internaldrive.fill", title: L("Disk alanı azalıyor", "Disk space is running low"),
                                  detail: L("\(Fmt.bytes(m.diskFree)) boş. %20'nin üzerinde boş alan bırakmak hızı korur.", "\(Fmt.bytes(m.diskFree)) free. Keeping over 20% free preserves speed."),
                                  severity: .warning, action: .go(.cleanup), actionHelp: L("Temizliğe git", "Go to Cleanup"), actionIcon: "sparkles"))
            }
        }
        if m.pressureLevel >= 2 {
            list.append(.init(id: "mem", icon: "memorychip.fill", title: L("Bellek zorlanıyor", "Memory is under pressure"),
                              detail: L("Açık uygulamalar belleği dolduruyor. Kullanmadıklarınızı kapatmak Mac'i hemen rahatlatır.", "Open apps are filling memory. Quitting the ones you don't use gives instant relief."),
                              severity: m.pressureLevel >= 4 ? .critical : .warning, action: .boost, actionHelp: L("Ağır uygulamaları göster", "Show heavy apps"), actionIcon: "bolt.fill"))
        } else if m.swapUsed > 2 << 30 {
            list.append(.init(id: "swap", icon: "arrow.left.arrow.right", title: L("Takas alanı yüksek", "Swap usage is high"),
                              detail: L("\(Fmt.bytes(m.swapUsed)) takas kullanılıyor. Birkaç uygulamayı kapatmak veya yeniden başlatmak iyi gelir.", "\(Fmt.bytes(m.swapUsed)) of swap in use. Quitting a few apps or restarting helps."),
                              severity: .warning, action: .boost, actionHelp: L("Ağır uygulamaları göster", "Show heavy apps"), actionIcon: "bolt.fill"))
        }
        if m.cpuAverage > 0.8, let top = m.topProcesses.first {
            list.append(.init(id: "cpu", icon: "cpu.fill", title: L("İşlemci sürekli yoğun", "CPU is constantly busy"),
                              detail: L("En çok \(top.name) çalışıyor (%\(Int(top.cpu))). Gerekmiyorsa kapatın.", "\(top.name) is the busiest (\(Int(top.cpu))%). Quit it if you don\'t need it."),
                              severity: .warning, action: .activityMonitor, actionHelp: L("Etkinlik Monitörü'nü aç", "Open Activity Monitor"), actionIcon: "waveform.path.ecg"))
        } else if let top = m.topProcesses.first, top.cpu > 90 {
            list.append(.init(id: "cpu-proc", icon: "cpu.fill", title: L("\(top.name) çok işlemci kullanıyor", "\(top.name) is using a lot of CPU"),
                              detail: L("Bu işlem tek başına bir çekirdeği dolduruyor. Takılmış olabilir.", "This process alone fills a whole core. It may be stuck."),
                              severity: .tip, action: .activityMonitor, actionHelp: L("Etkinlik Monitörü'nü aç", "Open Activity Monitor"), actionIcon: "waveform.path.ecg"))
        }
        if m.thermal == .serious || m.thermal == .critical {
            list.append(.init(id: "thermal", icon: "thermometer.high", title: L("Mac ısınmış", "Your Mac is hot"),
                              detail: L("Isınma işlemciyi yavaşlatır. Havalandırmayı açık tutun, ağır işleri azaltın.", "Heat throttles the CPU. Keep vents clear and reduce heavy work."),
                              severity: m.thermal == .critical ? .critical : .warning))
        }
        if m.uptime > 7 * 86_400 {
            list.append(.init(id: "uptime", icon: "restart.circle.fill", title: L("Uzun süredir yeniden başlatılmadı", "Not restarted for a long time"),
                              detail: L("\(Fmt.duration(m.uptime)) açık. Yeniden başlatmak belleği tazeler ve bekleyen güncellemeleri uygular.", "Up for \(Fmt.duration(m.uptime)). A restart refreshes memory and applies pending updates."),
                              severity: .tip))
        }
        if let b = m.battery {
            if let h = b.health, h < 0.8 {
                list.append(.init(id: "battery", icon: "battery.25percent", title: L("Pil yıpranmış", "Battery is worn"),
                                  detail: L("Pil kapasitesi \(Fmt.pct(h)). Servis için Apple'a danışabilirsiniz.", "Battery capacity is \(Fmt.pct(h)). Consider Apple service."),
                                  severity: .warning, action: .open(SettingsURL.battery), actionHelp: L("Pil ayarlarını aç", "Open Battery settings"), actionIcon: "gearshape.fill"))
            }
        }
        for c in security.checks where c.status == .fail || c.status == .warn {
            list.append(.init(id: "sec-\(c.id)", icon: c.icon, title: c.title, detail: c.detail,
                              severity: c.status == .fail ? .critical : .warning,
                              action: c.fixURL.map { .open($0) } ?? .go(.security),
                              actionHelp: c.fixURL == nil ? L("Güvenliğe git", "Go to Security") : L("Ayarı aç", "Open setting"), actionIcon: "gearshape.fill"))
        }
        if cleanup.totalSize > 1 << 30 && cleanup.phase == .ready {
            list.append(.init(id: "junk", icon: "sparkles", title: L("\(Fmt.bytes(cleanup.totalSize)) gereksiz dosya bulundu", "\(Fmt.bytes(cleanup.totalSize)) of junk found"),
                              detail: L("Önbellek ve eski dosyaları temizleyerek alan kazanın.", "Reclaim space by cleaning caches and old files."),
                              severity: .tip, action: .go(.cleanup), actionHelp: L("Temizliğe git", "Go to Cleanup"), actionIcon: "sparkles"))
        } else if cleanup.phase == .idle {
            list.append(.init(id: "junk-scan", icon: "magnifyingglass", title: L("Gereksiz dosyaları tarayın", "Scan for junk files"),
                              detail: L("Henüz tarama yapılmadı. Önbellek ve eski yükleyiciler yer kaplıyor olabilir.", "No scan yet. Caches and old installers may be taking up space."),
                              severity: .tip, action: .go(.cleanup), actionHelp: L("Temizliğe git", "Go to Cleanup"), actionIcon: "sparkles"))
        }
        return list.sorted { $0.severity < $1.severity }
    }

    func perform(_ action: AdviceAction) {
        switch action {
        case .open(let url): if let u = URL(string: url) { NSWorkspace.shared.open(u) }
        case .go(let s): go(s)
        case .activityMonitor: NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
        case .boost: showBoost = true
        }
    }

    // MARK: Hızlandır
    func loadHeavyApps() async {
        let r = await Shell.run("/bin/ps", ["-Aceo", "pid=,rss=,pcpu="], timeout: 5)
        var usage: [pid_t: (Int64, Double)] = [:]
        for line in r.out.split(separator: "\n") {
            let p = line.split(separator: " ", omittingEmptySubsequences: true)
            if p.count >= 3, let pid = Int32(p[0]), let rss = Int64(p[1]) {
                usage[pid] = (rss * 1024, Double(p[2].replacingOccurrences(of: ",", with: ".")) ?? 0)
            }
        }
        let me = ProcessInfo.processInfo.processIdentifier
        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && $0.processIdentifier != me && $0.bundleIdentifier != "com.apple.finder"
        }
        heavyApps = apps.compactMap { app in
            guard let u = usage[app.processIdentifier] else { return nil }
            return HeavyApp(pid: app.processIdentifier, name: app.localizedName ?? L("Uygulama", "App"),
                            icon: app.icon, memBytes: u.0, cpu: u.1)
        }
        .filter { $0.memBytes > 150_000_000 || $0.cpu > 20 }
        .sorted { $0.memBytes > $1.memBytes }
    }

    /// Uygulamaya normal "çık" isteği gönderir; kaydedilmemiş belge varsa uygulama kendisi sorar.
    func quit(_ app: HeavyApp) {
        NSRunningApplication(processIdentifier: app.pid)?.terminate()
        withAnimation(.spring) { heavyApps.removeAll { $0.pid == app.pid } }
    }
}
