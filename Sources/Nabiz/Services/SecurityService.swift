import Foundation
import Observation

enum CheckStatus: Sendable { case checking, pass, warn, fail, info }

struct SecurityCheck: Identifiable {
    let id: String
    var title: String
    let icon: String
    let weight: Int
    var fixURL: String?
    var helpTopic: String
    var status: CheckStatus = .checking
    var detail = L("Kontrol ediliyor…", "Checking…")
}

@Observable @MainActor
final class SecurityService {
    var checks: [SecurityCheck] = SecurityService.definitions
    var isScanning = false
    var lastScan: Date?

    /// 0…1, ağırlıklı. Uyarı yarım puan alır.
    var score: Double {
        let scored = checks.filter { [.pass, .warn, .fail].contains($0.status) && $0.weight > 0 }
        let total = scored.reduce(0) { $0 + $1.weight }
        guard total > 0 else { return 1 }
        let got = scored.reduce(0.0) { $0 + ($1.status == .pass ? Double($1.weight) : $1.status == .warn ? Double($1.weight) / 2 : 0) }
        return got / Double(total)
    }

    func count(_ s: CheckStatus) -> Int { checks.filter { $0.status == s }.count }

    /// Dil değişince başlıkları yeniler ve ayrıntıları yeni dilde üretmek için yeniden tarar.
    func relocalize() {
        for i in checks.indices {
            if let d = Self.definitions.first(where: { $0.id == checks[i].id }) { checks[i].title = d.title }
        }
        runAll()
    }

    func runAll() {
        guard !isScanning else { return }
        isScanning = true
        for i in checks.indices { checks[i].status = .checking; checks[i].detail = L("Kontrol ediliyor…", "Checking…") }
        let ids = checks.map(\.id)
        Task {
            await withTaskGroup(of: (String, CheckStatus, String).self) { group in
                for id in ids { group.addTask { await SecurityService.evaluate(id) } }
                for await (id, status, detail) in group { self.apply(id, status, detail) }
            }
            isScanning = false
            lastScan = Date()
        }
    }

    private func apply(_ id: String, _ status: CheckStatus, _ detail: String) {
        guard let i = checks.firstIndex(where: { $0.id == id }) else { return }
        checks[i].status = status
        checks[i].detail = detail
    }

    static var definitions: [SecurityCheck] = [
        .init(id: "filevault", title: L("FileVault disk şifreleme", "FileVault disk encryption"), icon: "lock.doc.fill", weight: 3, fixURL: SettingsURL.fileVault, helpTopic: "filevault"),
        .init(id: "sip", title: L("Sistem Bütünlüğü Koruması", "System Integrity Protection"), icon: "shield.lefthalf.filled", weight: 3, fixURL: nil, helpTopic: "sip"),
        .init(id: "gatekeeper", title: "Gatekeeper", icon: "checkmark.shield.fill", weight: 3, fixURL: SettingsURL.privacy, helpTopic: "gatekeeper"),
        .init(id: "firewall", title: L("Güvenlik duvarı", "Firewall"), icon: "flame.fill", weight: 2, fixURL: SettingsURL.firewall, helpTopic: "firewall"),
        .init(id: "stealth", title: L("Gizli mod", "Stealth mode"), icon: "eye.slash.fill", weight: 1, fixURL: SettingsURL.firewall, helpTopic: "firewall"),
        .init(id: "autoupdate", title: L("Otomatik güncellemeler", "Automatic updates"), icon: "arrow.triangle.2.circlepath", weight: 2, fixURL: SettingsURL.updates, helpTopic: "guncelleme"),
        .init(id: "pending", title: L("Bekleyen güncellemeler", "Pending updates"), icon: "arrow.down.app.fill", weight: 2, fixURL: SettingsURL.updates, helpTopic: "guncelleme"),
        .init(id: "screenlock", title: L("Ekran kilidi parolası", "Screen lock password"), icon: "lock.display", weight: 2, fixURL: SettingsURL.lockScreen, helpTopic: "ekran-kilidi"),
        .init(id: "autologin", title: L("Otomatik giriş", "Automatic login"), icon: "person.badge.key.fill", weight: 3, fixURL: SettingsURL.users, helpTopic: "otomatik-giris"),
        .init(id: "guest", title: L("Misafir hesabı", "Guest account"), icon: "person.crop.circle.badge.questionmark", weight: 1, fixURL: SettingsURL.users, helpTopic: "otomatik-giris"),
        .init(id: "ssh", title: L("Uzaktan giriş (SSH)", "Remote Login (SSH)"), icon: "terminal.fill", weight: 1, fixURL: SettingsURL.sharing, helpTopic: "uzaktan-erisim"),
        .init(id: "screenshare", title: L("Ekran paylaşımı", "Screen Sharing"), icon: "rectangle.on.rectangle", weight: 1, fixURL: SettingsURL.sharing, helpTopic: "uzaktan-erisim"),
        .init(id: "fileshare", title: L("Dosya paylaşımı", "File Sharing"), icon: "folder.badge.person.crop", weight: 1, fixURL: SettingsURL.sharing, helpTopic: "uzaktan-erisim"),
        .init(id: "launchitems", title: L("Arka plan öğeleri", "Background items"), icon: "gearshape.2.fill", weight: 0, fixURL: SettingsURL.loginItems, helpTopic: "arka-plan-ogeleri"),
    ]

    // MARK: Denetimler (salt-okunur)
    nonisolated static func evaluate(_ id: String) async -> (String, CheckStatus, String) {
        switch id {
        case "filevault":
            let r = await Shell.run("/usr/bin/fdesetup", ["status"])
            if r.out.contains("FileVault is On") { return (id, .pass, L("Disk şifreli. Mac'iniz çalınsa bile verileriniz okunamaz.", "Disk is encrypted. Your data stays unreadable even if your Mac is stolen.")) }
            if r.out.contains("Off") { return (id, .fail, L("Disk şifrelenmemiş. FileVault'u açmanızı öneririz.", "Disk is not encrypted. We recommend turning on FileVault.")) }
            return (id, .info, L("Durum okunamadı.", "Status could not be read."))
        case "sip":
            let r = await Shell.run("/usr/bin/csrutil", ["status"])
            if r.out.contains("enabled") && !r.out.contains("disabled") { return (id, .pass, L("Sistem dosyaları değiştirilmeye karşı korunuyor.", "System files are protected against modification.")) }
            if r.out.contains("disabled") { return (id, .fail, L("SIP kapalı. Kurtarma modundan yeniden açılmalı.", "SIP is off. Re-enable it from Recovery mode.")) }
            return (id, .info, L("Durum okunamadı.", "Status could not be read."))
        case "gatekeeper":
            let r = await Shell.run("/usr/sbin/spctl", ["--status"])
            if r.all.contains("assessments enabled") { return (id, .pass, L("Yalnızca güvenilir geliştiricilerin uygulamaları açılır.", "Only apps from trusted developers can open.")) }
            return (id, .fail, L("Gatekeeper kapalı; imzasız uygulamalar denetlenmeden açılabilir.", "Gatekeeper is off; unsigned apps can open unchecked."))
        case "firewall":
            let r = await Shell.run("/usr/libexec/ApplicationFirewall/socketfilterfw", ["--getglobalstate"])
            if r.out.contains("enabled") { return (id, .pass, L("Gelen istenmeyen bağlantılar engelleniyor.", "Unwanted incoming connections are blocked.")) }
            return (id, .warn, L("Güvenlik duvarı kapalı. Özellikle ortak Wi‑Fi'de açmanız önerilir.", "Firewall is off. Turn it on, especially on public Wi‑Fi."))
        case "stealth":
            let r = await Shell.run("/usr/libexec/ApplicationFirewall/socketfilterfw", ["--getstealthmode"])
            if r.out.lowercased().contains("enabled") || r.out.contains(" on") { return (id, .pass, L("Mac'iniz ağ taramalarına yanıt vermiyor.", "Your Mac does not answer network probes.")) }
            return (id, .warn, L("Gizli mod kapalı; Mac'iniz ağda 'ping' isteklerine görünür.", "Stealth mode is off; your Mac answers 'ping' on the network."))
        case "autoupdate":
            let check = await Shell.run("/usr/bin/defaults", ["read", "/Library/Preferences/com.apple.SoftwareUpdate", "AutomaticCheckEnabled"])
            let install = await Shell.run("/usr/bin/defaults", ["read", "/Library/Preferences/com.apple.SoftwareUpdate", "CriticalUpdateInstall"])
            if check.out.trimmingCharacters(in: .whitespacesAndNewlines) == "0" { return (id, .fail, L("Güncellemeler otomatik denetlenmiyor.", "Updates are not checked automatically.")) }
            if install.out.trimmingCharacters(in: .whitespacesAndNewlines) == "0" { return (id, .warn, L("Güvenlik yamaları otomatik yüklenmiyor.", "Security patches are not installed automatically.")) }
            return (id, .pass, L("Güncellemeler ve güvenlik yamaları otomatik geliyor.", "Updates and security patches arrive automatically."))
        case "pending":
            let r = await Shell.run("/usr/sbin/softwareupdate", ["-l"], timeout: 90)
            let labels = r.out.split(separator: "\n").filter { $0.trimmingCharacters(in: .whitespaces).hasPrefix("* Label:") }
            if !labels.isEmpty {
                let names = labels.prefix(2).map { $0.replacingOccurrences(of: "* Label:", with: "").trimmingCharacters(in: .whitespaces) }
                return (id, .warn, L("\(labels.count) güncelleme bekliyor: \(names.joined(separator: ", "))", "\(labels.count) update(s) waiting: \(names.joined(separator: ", "))"))
            }
            if r.all.contains("No new software") { return (id, .pass, L("macOS güncel.", "macOS is up to date.")) }
            return (id, .info, L("Güncelleme sunucusuna ulaşılamadı.", "Could not reach the update server."))
        case "screenlock":
            let r = await Shell.run("/usr/sbin/sysadminctl", ["-screenLock", "status"])
            let t = r.all.lowercased()
            if t.contains("is off") { return (id, .fail, L("Uyku/ekran koruyucudan sonra parola istenmiyor.", "No password is required after sleep or screen saver.")) }
            if t.contains("immediate") { return (id, .pass, L("Ekran kilitlenince hemen parola isteniyor.", "A password is required immediately after locking.")) }
            if let range = t.range(of: "delay is "), let secs = Int(t[range.upperBound...].prefix { $0.isNumber }) {
                return secs <= 300 ? (id, .pass, L("Parola \(secs) sn sonra isteniyor.", "Password required after \(secs) s.")) : (id, .warn, L("Parola ancak \(secs / 60) dk sonra isteniyor; süreyi kısaltın.", "Password only required after \(secs / 60) min; shorten the delay."))
            }
            return (id, .info, L("Durum okunamadı.", "Status could not be read."))
        case "autologin":
            let r = await Shell.run("/usr/bin/defaults", ["read", "/Library/Preferences/com.apple.loginwindow", "autoLoginUser"])
            if r.code == 0 && !r.out.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return (id, .fail, L("Mac parola sormadan açılıyor. Otomatik girişi kapatın.", "Your Mac starts without a password. Turn off automatic login.")) }
            return (id, .pass, L("Açılışta parola isteniyor.", "A password is required at startup."))
        case "guest":
            let r = await Shell.run("/usr/bin/defaults", ["read", "/Library/Preferences/com.apple.loginwindow", "GuestEnabled"])
            if r.out.trimmingCharacters(in: .whitespacesAndNewlines) == "1" { return (id, .warn, L("Misafir hesabı açık.", "Guest account is on.")) }
            return (id, .pass, L("Misafir hesabı kapalı.", "Guest account is off."))
        case "ssh", "screenshare", "fileshare":
            let port = ["ssh": ".22", "screenshare": ".5900", "fileshare": ".445"][id]!
            let r = await Shell.run("/usr/sbin/netstat", ["-anp", "tcp"])
            let listening = r.out.split(separator: "\n").contains { line in
                let c = line.split(separator: " ", omittingEmptySubsequences: true)
                return c.count >= 6 && c[5] == "LISTEN" && c[3].hasSuffix(port)
            }
            let name = ["ssh": L("Uzaktan giriş", "Remote Login"), "screenshare": L("Ekran paylaşımı", "Screen Sharing"), "fileshare": L("Dosya paylaşımı", "File Sharing")][id]!
            return listening ? (id, .warn, L("\(name) açık. Kullanmıyorsanız kapatın.", "\(name) is on. Turn it off if you don\'t use it.")) : (id, .pass, L("\(name) kapalı.", "\(name) is off."))
        case "launchitems":
            let fm = FileManager.default
            let dirs = [fm.homeDirectoryForCurrentUser.appending(path: "Library/LaunchAgents").path,
                        "/Library/LaunchAgents", "/Library/LaunchDaemons"]
            let items = dirs.flatMap { (try? fm.contentsOfDirectory(atPath: $0)) ?? [] }
                .filter { $0.hasSuffix(".plist") && !$0.hasPrefix("com.apple.") }
            if items.isEmpty { return (id, .pass, L("Üçüncü taraf arka plan öğesi yok.", "No third-party background items.")) }
            let names = items.prefix(3).map { $0.replacingOccurrences(of: ".plist", with: "") }
            return (id, .info, L("\(items.count) arka plan öğesi: \(names.joined(separator: ", "))\(items.count > 3 ? "…" : "")", "\(items.count) background items: \(names.joined(separator: ", "))\(items.count > 3 ? "…" : "")"))
        default:
            return (id, .info, "")
        }
    }
}
