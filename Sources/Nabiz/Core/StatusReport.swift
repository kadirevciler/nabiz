import Foundation

/// Yapay zekâ araçlarına verilmek üzere düzenlenmiş durum raporu.
/// Gizlilik: bilgisayar adı, kullanıcı adı ve dosya adları rapora eklenmez.
@MainActor
enum StatusReport {

    /// AI'ya verilen görev tanımı (hem API çağrısında hem rapor başında kullanılır).
    static var analysisInstructions: String {
        L("""
        Sen deneyimli bir macOS performans ve güvenlik uzmanısın. Aşağıdaki Nabız durum raporunu incele ve Türkçe yanıt ver.
        Yanıtını şu başlıklarla, Markdown olarak düzenle:
        1. Genel değerlendirme (2-3 cümle, 10 üzerinden puan)
        2. Acil sorunlar (varsa)
        3. Performans önerileri
        4. Güvenlik önerileri
        5. Adım adım eylem planı (öncelik sırasıyla, her adımda Sistem Ayarları yolunu yaz)
        Somut ol, rapordaki sayılara dayan, tahmin ettiğin yerleri belirt. SIP veya Gatekeeper'ı kapatmayı asla önerme. Veri kaybına yol açabilecek adımlar için önce yedek almayı hatırlat.
        """, """
        You are an experienced macOS performance and security expert. Review the Nabız status report below and answer in English.
        Structure your answer in Markdown with these headings:
        1. Overall assessment (2-3 sentences, score out of 10)
        2. Urgent issues (if any)
        3. Performance recommendations
        4. Security recommendations
        5. Step-by-step action plan (in priority order, include the System Settings path for each step)
        Be concrete, rely on the numbers in the report, and flag anything you are inferring. Never suggest disabling SIP or Gatekeeper. Remind the user to back up before any step that could lose data.
        """)
    }

    static func markdown(_ model: AppModel, includeInstructions: Bool = true) -> String {
        let m = model.metrics, s = model.security, c = model.cleanup
        let now = Date().formatted(.iso8601)
        var out: [String] = []

        out.append("# " + L("Nabız Mac Durum Raporu", "Nabız Mac Status Report"))
        out.append(L("Oluşturulma: ", "Generated: ") + now + " · Nabız 1.1")
        out.append("")
        if includeInstructions {
            out.append("## " + L("0. Yapay zekâ için görev", "0. Task for the AI"))
            out.append(analysisInstructions)
            out.append("")
        }

        out.append("## " + L("1. Özet", "1. Summary"))
        out.append("- " + L("Sistem sağlığı", "System health") + ": \(Int(model.healthScore * 100))/100 (\(model.healthLabel))")
        out.append("- " + L("Performans puanı", "Performance score") + ": \(Int(model.performanceScore * 100))/100")
        out.append("- " + L("Güvenlik puanı", "Security score") + ": \(Int(s.score * 100))/100")
        out.append("- " + L("Açık öneri sayısı", "Open advice items") + ": \(model.advices.count)")
        out.append("")

        out.append("## " + L("2. Donanım ve sistem", "2. Hardware and system"))
        out.append("- " + L("Model", "Model") + ": \(m.machineName)")
        out.append("- " + L("Çip", "Chip") + ": \(m.chip)")
        out.append("- " + L("İşletim sistemi", "Operating system") + ": \(m.osVersion)")
        out.append("- " + L("Çekirdek sayısı", "Cores") + ": \(m.cores.count)")
        out.append("- " + L("Toplam bellek", "Total memory") + ": \(Fmt.bytes(m.memTotal))")
        out.append("- " + L("Çalışma süresi", "Uptime") + ": \(Fmt.duration(m.uptime))")
        out.append("")

        out.append("## " + L("3. Performans", "3. Performance"))
        out.append("| " + L("Ölçüm", "Metric") + " | " + L("Değer", "Value") + " |")
        out.append("|---|---|")
        out.append("| " + L("İşlemci (anlık)", "CPU (now)") + " | \(Fmt.pct(m.cpu)) |")
        out.append("| " + L("İşlemci (son ~18 sn ort.)", "CPU (last ~18 s avg)") + " | \(Fmt.pct(m.cpuAverage)) |")
        out.append("| " + L("Yük ortalaması 1/5/15 dk", "Load average 1/5/15 min") + " | \(m.load.map { String(format: "%.2f", $0) }.joined(separator: " / ")) |")
        out.append("| " + L("Bellek kullanımı", "Memory used") + " | \(Fmt.bytes(m.memUsed)) / \(Fmt.bytes(m.memTotal)) (\(Fmt.pct(m.memFraction))) |")
        out.append("| " + L("Uygulama / Sabit / Sıkıştırılmış", "App / Wired / Compressed") + " | \(Fmt.bytes(m.memApp)) / \(Fmt.bytes(m.memWired)) / \(Fmt.bytes(m.memCompressed)) |")
        out.append("| " + L("Bellek baskısı", "Memory pressure") + " | \(m.pressureText) |")
        out.append("| " + L("Takas (swap)", "Swap") + " | \(Fmt.bytes(m.swapUsed)) |")
        out.append("| " + L("Disk boş alan", "Disk free") + " | \(Fmt.bytes(m.diskFree)) / \(Fmt.bytes(m.diskTotal)) (\(Fmt.pct(m.diskFreeFraction))) |")
        out.append("| " + L("Isı durumu", "Thermal state") + " | \(Fmt.thermal(m.thermal)) |")
        out.append("| " + L("Ağ indirme / yükleme", "Network down / up") + " | \(Fmt.rate(m.netIn)) / \(Fmt.rate(m.netOut)) |")
        if let b = m.battery {
            let h = b.health.map(Fmt.pct) ?? "—", cyc = b.cycleCount.map(String.init) ?? "—"
            out.append("| " + L("Pil", "Battery") + " | \(Fmt.pct(b.level)), " + L("sağlık", "health") + " \(h), \(cyc) " + L("döngü", "cycles") + " |")
        }
        out.append("")

        out.append("## " + L("4. En çok kaynak kullanan süreçler", "4. Top processes"))
        out.append("| " + L("Süreç", "Process") + " | CPU % | " + L("Bellek", "Memory") + " |")
        out.append("|---|---|---|")
        for p in m.topProcesses { out.append("| \(p.name) | \(String(format: "%.1f", p.cpu)) | \(Fmt.bytes(p.memBytes)) |") }
        out.append("")

        out.append("## " + L("5. Güvenlik denetimi", "5. Security audit"))
        out.append("| " + L("Denetim", "Check") + " | " + L("Durum", "Status") + " | " + L("Ayrıntı", "Detail") + " |")
        out.append("|---|---|---|")
        for ch in s.checks { out.append("| \(ch.title) | \(statusWord(ch.status)) | \(ch.detail.replacingOccurrences(of: "|", with: "/")) |") }
        out.append("")

        out.append("## " + L("6. Gereksiz dosyalar", "6. Junk files"))
        if c.categories.isEmpty {
            out.append(L("_Tarama yapılmadı._", "_Not scanned yet._"))
        } else {
            out.append("| " + L("Kategori", "Category") + " | " + L("Öğe", "Items") + " | " + L("Boyut", "Size") + " |")
            out.append("|---|---|---|")
            for cat in c.categories { out.append("| \(cat.title) | \(cat.items.count) | \(Fmt.bytes(cat.size)) |") }
            out.append("| **" + L("Toplam", "Total") + "** | | **\(Fmt.bytes(c.totalSize))** |")
        }
        out.append("")

        out.append("## " + L("7. Nabız önerileri", "7. Nabız advice"))
        if model.advices.isEmpty { out.append(L("_Öneri yok._", "_No advice._")) }
        for a in model.advices { out.append("- [\(a.severity.label)] **\(a.title)** — \(a.detail)") }
        out.append("")

        out.append("## " + L("8. Makine okunur veri (JSON)", "8. Machine-readable data (JSON)"))
        out.append("```json")
        out.append(json(model))
        out.append("```")
        out.append("")
        out.append(L("_Gizlilik: Bu rapor bilgisayar adı, kullanıcı adı veya dosya adı içermez._",
                     "_Privacy: this report contains no computer name, user name or file names._"))
        return out.joined(separator: "\n")
    }

    static func json(_ model: AppModel) -> String {
        let m = model.metrics, s = model.security, c = model.cleanup
        var d: [String: Any] = [
            "generated": Date().formatted(.iso8601),
            "scores": ["health": round2(model.healthScore), "performance": round2(model.performanceScore), "security": round2(s.score)],
            "system": ["model": m.machineName, "chip": m.chip, "os": m.osVersion, "cores": m.cores.count,
                       "memoryBytes": m.memTotal, "uptimeSeconds": Int(m.uptime)],
            "performance": [
                "cpuNow": round2(m.cpu), "cpuAvg": round2(m.cpuAverage), "load": m.load.map(round2),
                "memUsedBytes": m.memUsed, "memAppBytes": m.memApp, "memWiredBytes": m.memWired,
                "memCompressedBytes": m.memCompressed, "memoryPressureLevel": m.pressureLevel,
                "swapUsedBytes": m.swapUsed, "diskFreeBytes": m.diskFree, "diskTotalBytes": m.diskTotal,
                "thermalState": ["nominal", "fair", "serious", "critical"][min(m.thermal.rawValue, 3)],
            ],
            "topProcesses": m.topProcesses.map { ["name": $0.name, "cpuPercent": $0.cpu, "memBytes": $0.memBytes] },
            "security": s.checks.map { ["id": $0.id, "status": statusKey($0.status), "detail": $0.detail] },
            "junk": c.categories.map { ["category": $0.id, "items": $0.items.count, "bytes": $0.size] },
            "advice": model.advices.map { ["id": $0.id, "severity": ["critical", "warning", "tip"][$0.severity.rawValue], "title": $0.title] },
        ]
        if let b = m.battery {
            d["battery"] = ["level": round2(b.level), "health": b.health.map(round2) as Any, "cycles": b.cycleCount as Any, "charging": b.isCharging]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: d, options: [.prettyPrinted, .sortedKeys]) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }

    private static func round2(_ v: Double) -> Double { (v * 100).rounded() / 100 }

    private static func statusKey(_ s: CheckStatus) -> String {
        switch s { case .pass: "pass"; case .warn: "warning"; case .fail: "fail"; case .info: "info"; case .checking: "checking" }
    }

    private static func statusWord(_ s: CheckStatus) -> String {
        switch s {
        case .pass: L("✅ Tamam", "✅ OK")
        case .warn: L("⚠️ Uyarı", "⚠️ Warning")
        case .fail: L("❌ Risk", "❌ Risk")
        case .info: L("ℹ️ Bilgi", "ℹ️ Info")
        case .checking: L("… Kontrol ediliyor", "… Checking")
        }
    }
}
