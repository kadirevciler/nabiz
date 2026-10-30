import SwiftUI
import AppKit

struct PerformanceView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let m = model.metrics
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(section: .performance) {
                    IconButton("waveform.path.ecg", L("Etkinlik Monitörü'nü aç", "Open Activity Monitor")) { model.perform(.activityMonitor) }
                }
                .appear()

                HStack(alignment: .top, spacing: 18) {
                    GlassCard(glow: Palette.cyan) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .firstTextBaseline) {
                                Caption(L("İşlemci", "CPU")); Spacer()
                                Text(L("Yük", "Load") + " " + m.load.map { String(format: "%.1f", $0) }.joined(separator: " · "))
                                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                            }
                            BigNumber(text: Fmt.pct(m.cpu), size: 36)
                            Sparkline(values: m.cpuHistory, color: Palette.cyan, maxValue: 1).frame(height: 90)
                            CoreBars(cores: m.cores).frame(height: 44)
                        }
                    }
                    .appear(0.05)

                    GlassCard(glow: Palette.violet) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack { Caption(L("Bellek", "Memory")); Spacer(); pressureBadge(m) }
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                BigNumber(text: Fmt.bytes(m.memUsed), size: 36)
                                Text("/ \(Fmt.bytes(m.memTotal))").foregroundStyle(.secondary)
                            }
                            Sparkline(values: m.memHistory, color: Palette.violet, maxValue: 1).frame(height: 90)
                            MemoryBreakdown(app: m.memApp, wired: m.memWired, compressed: m.memCompressed, total: m.memTotal)
                            Text(L("Takas: \(Fmt.bytes(m.swapUsed))", "Swap: \(Fmt.bytes(m.swapUsed))")).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .appear(0.1)
                }

                HStack(alignment: .top, spacing: 18) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Caption(L("Ağ", "Network"))
                            netRow("arrow.down", Palette.green, m.netIn, m.netInHistory)
                            netRow("arrow.up", Palette.pink, m.netOut, m.netOutHistory)
                        }
                    }
                    .appear(0.15)

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Caption("Disk"); Spacer()
                                IconButton("externaldrive.badge.questionmark", L("Depolama ayarlarını aç", "Open Storage settings"), size: 26) { model.perform(.open(SettingsURL.storage)) }
                            }
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                BigNumber(text: Fmt.bytes(m.diskFree), size: 30)
                                Text(L("boş", "free")).foregroundStyle(.secondary)
                            }
                            Bar(value: m.diskUsedFraction, color: Palette.load(m.diskUsedFraction), height: 12)
                            Text(L("\(Fmt.bytes(m.diskTotal)) toplam", "\(Fmt.bytes(m.diskTotal)) total")).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .appear(0.2)

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Caption(L("Isı ve güç", "Thermal & power"))
                            HStack(spacing: 10) {
                                Image(systemName: "thermometer.medium").font(.title2)
                                    .foregroundStyle([Palette.green, Palette.amber, Palette.red, Palette.red][min(m.thermal.rawValue, 3)])
                                BigNumber(text: Fmt.thermal(m.thermal), size: 26)
                            }
                            if let b = m.battery {
                                HStack(spacing: 10) {
                                    Image(systemName: "battery.100percent").foregroundStyle(Palette.green)
                                    Text(L("Sağlık \(b.health.map(Fmt.pct) ?? "—") · \(b.cycleCount.map { "\($0) döngü" } ?? "")", "Health \(b.health.map(Fmt.pct) ?? "—") · \(b.cycleCount.map { "\($0) cycles" } ?? "")"))
                                        .font(.callout)
                                }
                            }
                        }
                    }
                    .appear(0.25)
                }

                ProcessList(processes: m.topProcesses).appear(0.3)
            }
            .padding(28)
        }
    }

    private func pressureBadge(_ m: MetricsService) -> some View {
        let c = m.pressureLevel >= 4 ? Palette.red : m.pressureLevel >= 2 ? Palette.amber : Palette.green
        return Label(m.pressureText, systemImage: "gauge.medium")
            .font(.caption.weight(.semibold)).foregroundStyle(c)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(c.opacity(0.15)))
            .help(L("Bellek baskısı", "Memory pressure"))
    }

    private func netRow(_ icon: String, _ color: Color, _ rate: Double, _ hist: [Double]) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.headline).foregroundStyle(color).frame(width: 18)
            BigNumber(text: Fmt.rate(rate), size: 18).frame(width: 110, alignment: .leading)
            Sparkline(values: hist, color: color).frame(height: 36)
        }
    }
}

private struct CoreBars: View {
    let cores: [Double]
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(cores.enumerated()), id: \.offset) { _, v in
                GeometryReader { g in
                    VStack {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Palette.load(v).gradient)
                            .frame(height: max(3, g.size.height * v))
                    }
                }
                .background(RoundedRectangle(cornerRadius: 3).fill(.white.opacity(0.05)))
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: cores)
        .help(L("Çekirdek başına kullanım", "Per-core usage"))
    }
}

private struct MemoryBreakdown: View {
    let app: UInt64, wired: UInt64, compressed: UInt64, total: UInt64
    var body: some View {
        let parts: [(String, UInt64, Color)] = [(L("Uygulama", "App"), app, Palette.violet), (L("Sabit", "Wired"), wired, Palette.pink), (L("Sıkıştırılmış", "Compressed"), compressed, Palette.amber)]
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { g in
                HStack(spacing: 2) {
                    ForEach(parts, id: \.0) { p in
                        Capsule().fill(p.2.gradient).frame(width: max(2, g.size.width * Double(p.1) / Double(max(total, 1))))
                    }
                    Capsule().fill(.white.opacity(0.07))
                }
            }
            .frame(height: 10)
            .animation(.spring, value: app)
            HStack(spacing: 14) {
                ForEach(parts, id: \.0) { p in
                    HStack(spacing: 5) {
                        Circle().fill(p.2).frame(width: 7, height: 7)
                        Text("\(p.0) \(Fmt.bytes(p.1))").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private struct ProcessList: View {
    let processes: [ProcInfo]
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Caption(L("En çok işlemci kullananlar", "Top CPU consumers"))
                ForEach(processes) { p in
                    HStack(spacing: 12) {
                        Text(p.name).font(.callout).lineLimit(1).frame(width: 220, alignment: .leading)
                        Bar(value: min(p.cpu / 100, 1), color: Palette.load(p.cpu / 100))
                        Text(String(format: "%%%.0f", p.cpu)).font(.callout.monospacedDigit()).frame(width: 52, alignment: .trailing)
                        Text(Fmt.bytes(p.memBytes)).font(.caption.monospacedDigit()).foregroundStyle(.secondary).frame(width: 80, alignment: .trailing)
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut, value: processes.map(\.id))
        }
    }
}
