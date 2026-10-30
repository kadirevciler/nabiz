import Foundation
import AppKit
import Observation

struct CleanupItem: Identifiable, Hashable, Sendable {
    var id: URL { url }
    let url: URL
    let size: Int64
    var selected = true
    var name: String { url.lastPathComponent }
}

enum SelectionState { case none, some, all }

struct CleanupCategory: Identifiable {
    let id: String
    var title: String
    let icon: String
    var detail: String
    /// true ise Çöp Sepeti'ne taşınmaz, kalıcı silinir (yalnızca Çöp Sepeti kategorisi).
    let permanent: Bool
    let defaultSelected: Bool
    var items: [CleanupItem] = []
    var expanded = false
    var note: String?

    var size: Int64 { items.reduce(0) { $0 + $1.size } }
    var selectedSize: Int64 { items.filter(\.selected).reduce(0) { $0 + $1.size } }
    var selectedCount: Int { items.filter(\.selected).count }
    var selection: SelectionState {
        let n = selectedCount
        return n == 0 ? .none : n == items.count ? .all : .some
    }
    mutating func setAll(_ on: Bool) { for i in items.indices { items[i].selected = on } }
}

enum CleanupPhase: Equatable {
    case idle
    case scanning(String)
    case ready
    case cleaning(Double)
    case done(freed: Int64, failed: Int, trashed: Bool)
}

@Observable @MainActor
final class CleanupService {
    var categories: [CleanupCategory] = []
    var phase: CleanupPhase = .idle

    var totalSize: Int64 { categories.reduce(0) { $0 + $1.size } }
    var selectedSize: Int64 { categories.reduce(0) { $0 + $1.selectedSize } }
    var selectedCount: Int { categories.reduce(0) { $0 + $1.selectedCount } }
    var hasScanned: Bool { phase != .idle && !isScanning }
    var isScanning: Bool { if case .scanning = phase { return true }; return false }
    var scanLabel: String { if case .scanning(let l) = phase { return l }; return L("Hazırlanıyor", "Preparing") }

    static var definitions: [CleanupCategory] = [
        .init(id: "caches", title: L("Uygulama önbellekleri", "App caches"), icon: "square.stack.3d.up.fill",
              detail: L("Uygulamalar gerektiğinde yeniden oluşturur.", "Apps rebuild these when needed."), permanent: false, defaultSelected: true),
        .init(id: "logs", title: L("Günlük dosyaları", "Log files"), icon: "doc.text.fill",
              detail: L("Eski kayıt ve çökme raporları.", "Old logs and crash reports."), permanent: false, defaultSelected: true),
        .init(id: "dev", title: L("Geliştirici artıkları", "Developer leftovers"), icon: "hammer.fill",
              detail: L("Xcode DerivedData, simülatör önbelleği, npm önbelleği.", "Xcode DerivedData, simulator caches, npm cache."), permanent: false, defaultSelected: true),
        .init(id: "installers", title: L("Eski yükleyiciler", "Old installers"), icon: "shippingbox.fill",
              detail: L("İndirilenler'deki .dmg ve .pkg dosyaları.", ".dmg and .pkg files in Downloads."), permanent: false, defaultSelected: true),
        .init(id: "olddownloads", title: L("Büyük ve eski indirmeler", "Large old downloads"), icon: "arrow.down.circle.fill",
              detail: L("90 günden eski, 100 MB üstü dosyalar. Tek tek gözden geçirin.", "Files over 100 MB, older than 90 days. Review one by one."), permanent: false, defaultSelected: false),
        .init(id: "trash", title: L("Çöp Sepeti", "Trash"), icon: "trash.fill",
              detail: L("Seçerseniz kalıcı olarak silinir, geri alınamaz.", "If selected, deleted permanently — cannot be undone."), permanent: true, defaultSelected: false),
    ]

    /// Dil değişince kategori adlarını yeniler.
    func relocalize() {
        for i in categories.indices {
            if let d = Self.definitions.first(where: { $0.id == categories[i].id }) {
                categories[i].title = d.title
                categories[i].detail = d.detail
            }
        }
    }

    func scan() {
        guard !isScanning else { return }
        phase = .scanning(L("Hazırlanıyor", "Preparing"))
        categories = []
        Task {
            for def in Self.definitions {
                phase = .scanning(def.title)
                let id = def.id
                let (items, note) = await Task.detached(priority: .userInitiated) { CleanupService.collect(id) }.value
                var cat = def
                cat.items = items.filter { $0.size > 0 }
                    .map { var i = $0; i.selected = def.defaultSelected; return i }
                    .sorted { $0.size > $1.size }
                cat.note = note
                if !cat.items.isEmpty || note != nil { categories.append(cat) }
            }
            phase = .ready
        }
    }

    func clean() {
        let targets = categories.flatMap { c in c.items.filter(\.selected).map { ($0, c.permanent) } }
        guard !targets.isEmpty else { return }
        phase = .cleaning(0)
        Task {
            var freed: Int64 = 0, failed = 0
            var removed = Set<URL>()
            for (idx, (item, permanent)) in targets.enumerated() {
                let url = item.url
                let ok = await Task.detached(priority: .userInitiated) { () -> Bool in
                    do {
                        if permanent { try FileManager.default.removeItem(at: url) }
                        else { try FileManager.default.trashItem(at: url, resultingItemURL: nil) }
                        return true
                    } catch { return false }
                }.value
                if ok { freed += item.size; removed.insert(url) } else { failed += 1 }
                phase = .cleaning(Double(idx + 1) / Double(targets.count))
            }
            for i in categories.indices { categories[i].items.removeAll { removed.contains($0.url) } }
            categories.removeAll { $0.items.isEmpty && $0.note == nil }
            let trashed = targets.contains { !$0.1 }
            phase = .done(freed: freed, failed: failed, trashed: trashed)
        }
    }

    // MARK: Tarama (arka planda)
    nonisolated static func collect(_ id: String) -> ([CleanupItem], String?) {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let downloads = home.appending(path: "Downloads")
        switch id {
        case "caches":
            let own = Bundle.main.bundleIdentifier ?? "com.kadir.nabiz"
            return children(home.appending(path: "Library/Caches")) { !$0.hasPrefix("com.apple.") && $0 != own && $0 != "CloudKit" }
        case "logs":
            return children(home.appending(path: "Library/Logs"))
        case "dev":
            var items: [CleanupItem] = []
            for sub in ["Library/Developer/Xcode/DerivedData", "Library/Developer/CoreSimulator/Caches",
                        "Library/Developer/Xcode/iOS DeviceSupport"] {
                items += children(home.appending(path: sub)).0
            }
            let npm = home.appending(path: ".npm/_cacache")
            if fm.fileExists(atPath: npm.path) { items.append(CleanupItem(url: npm, size: allocatedSize(npm))) }
            return (items, nil)
        case "installers":
            return children(downloads) { name in
                ["dmg", "pkg", "mpkg", "xip"].contains((name as NSString).pathExtension.lowercased())
            }
        case "olddownloads":
            let cutoff = Date().addingTimeInterval(-90 * 86_400)
            let (all, note) = children(downloads) { !["dmg", "pkg", "mpkg", "xip"].contains(($0 as NSString).pathExtension.lowercased()) }
            let old = all.filter { item in
                let d = (try? item.url.resourceValues(forKeys: [.contentAccessDateKey, .contentModificationDateKey]))
                let last = max(d?.contentAccessDate ?? .distantPast, d?.contentModificationDate ?? .distantPast)
                return item.size > 100_000_000 && last < cutoff
            }
            return (old, note)
        case "trash":
            return children(home.appending(path: ".Trash"))
        default:
            return ([], nil)
        }
    }

    nonisolated private static func children(_ dir: URL, include: (String) -> Bool = { _ in true }) -> ([CleanupItem], String?) {
        let fm = FileManager.default
        guard fm.fileExists(atPath: dir.path) else { return ([], nil) }
        do {
            let names = try fm.contentsOfDirectory(atPath: dir.path)
            let items = names.filter { !$0.hasPrefix(".") && include($0) }.map { name -> CleanupItem in
                let u = dir.appending(path: name)
                return CleanupItem(url: u, size: allocatedSize(u))
            }
            return (items, nil)
        } catch {
            return ([], L("Bu klasörü okumak için izin gerekiyor. Sistem Ayarları › Gizlilik › Tam Disk Erişimi'nden Nabız'a izin verin.", "Permission is needed to read this folder. Allow Nabız in System Settings › Privacy › Full Disk Access."))
        }
    }

    nonisolated static func allocatedSize(_ url: URL) -> Int64 {
        let keys: Set<URLResourceKey> = [.isDirectoryKey, .isSymbolicLinkKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey]
        guard let v = try? url.resourceValues(forKeys: keys) else { return 0 }
        if v.isSymbolicLink == true { return 0 }
        if v.isDirectory != true { return Int64(v.totalFileAllocatedSize ?? v.fileAllocatedSize ?? 0) }
        var total: Int64 = 0
        let e = FileManager.default.enumerator(at: url, includingPropertiesForKeys: Array(keys), options: [], errorHandler: { _, _ in true })
        while let f = e?.nextObject() as? URL {
            if let s = try? f.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey]) {
                total += Int64(s.totalFileAllocatedSize ?? s.fileAllocatedSize ?? 0)
            }
        }
        return total
    }
}

