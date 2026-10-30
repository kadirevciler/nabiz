import Foundation

enum AppSection: String, CaseIterable, Identifiable {
    case overview, performance, security, advice, cleanup
    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return L("Genel Bakış", "Overview")
        case .performance: return L("Performans", "Performance")
        case .security: return L("Güvenlik", "Security")
        case .advice: return L("Öneriler", "Advice")
        case .cleanup: return L("Temizlik", "Cleanup")
        }
    }

    var subtitle: String {
        switch self {
        case .overview: return L("Mac'inizin tek bakışta durumu", "Your Mac at a glance")
        case .performance: return L("Canlı işlemci, bellek, disk ve ağ ölçümleri", "Live CPU, memory, disk and network metrics")
        case .security: return L("macOS koruma ayarlarının denetimi", "An audit of macOS protection settings")
        case .advice: return L("Mac'inizi hızlandırmak ve korumak için yapılacaklar", "What to do to speed up and protect your Mac")
        case .cleanup: return L("Gereksiz dosyaları bulun, onayınızla temizleyin", "Find junk files and clean them with your approval")
        }
    }

    var icon: String {
        switch self {
        case .overview: return "square.grid.2x2.fill"
        case .performance: return "gauge.with.dots.needle.67percent"
        case .security: return "lock.shield.fill"
        case .advice: return "lightbulb.max.fill"
        case .cleanup: return "sparkles"
        }
    }

    var shortcut: Character { Character("\((AppSection.allCases.firstIndex(of: self) ?? 0) + 1)") }
}

enum SettingsURL {
    static let fileVault = "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?FileVault"
    static let privacy = "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension"
    static let fullDisk = "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles"
    static let firewall = "x-apple.systempreferences:com.apple.Network-Settings.extension?Firewall"
    static let updates = "x-apple.systempreferences:com.apple.Software-Update-Settings.extension"
    static let sharing = "x-apple.systempreferences:com.apple.Sharing-Settings.extension"
    static let lockScreen = "x-apple.systempreferences:com.apple.Lock-Screen-Settings.extension"
    static let users = "x-apple.systempreferences:com.apple.Users-Groups-Settings.extension"
    static let loginItems = "x-apple.systempreferences:com.apple.LoginItems-Settings.extension"
    static let battery = "x-apple.systempreferences:com.apple.Battery-Settings.extension"
    static let storage = "x-apple.systempreferences:com.apple.settings.Storage"
}
