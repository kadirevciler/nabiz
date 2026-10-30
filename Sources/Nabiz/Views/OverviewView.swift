import SwiftUI

struct OverviewView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let m = model.metrics
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(section: .overview, subtitle: "\(m.hostName) · \(m.machineName)") {
                    IconButton("arrow.clockwise", L("Tümünü yenile (⌘R)", "Refresh all (⌘R)")) { model.refreshAll() }
                }
                .appear()

                HStack(alignment: .top, spacing: 18) {
                    HealthCard().frame(width: 340).appear(0.05)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 18), GridItem(.flexible())], spacing: 18) {
                        MetricTile(title: L("İşlemci", "CPU"), icon: "cpu", value: m.cpu, text: Fmt.pct(m.cpu),
                                   sub: L("\(m.cores.count) çekirdek", "\(m.cores.count) cores"), colors: [Palette.cyan, Palette.violet])
                            .appear(0.1)
                        MetricTile(title: L("Bellek", "Memory"), icon: "memorychip", value: m.memFraction, text: Fmt.pct(m.memFraction),
                                   sub: "\(Fmt.bytes(m.memUsed)) / \(Fmt.bytes(m.memTotal))", colors: [Palette.violet, Palette.pink])
                            .appear(0.15)
                        MetricTile(title: "Disk", icon: "internaldrive", value: m.diskUsedFraction, text: Fmt.pct(m.diskUsedFraction),
                                   sub: L("\(Fmt.bytes(m.diskFree)) boş", "\(Fmt.bytes(m.diskFree)) free"), colors: [Palette.green, Palette.cyan])
                            .appear(0.2)
                        if let b = m.battery {
                            MetricTile(title: L("Pil", "Battery"), icon: b.isCharging ? "battery.100percent.bolt" : "battery.75percent",
                                       value: b.level, text: Fmt.pct(b.level),
                                       sub: b.isCharging ? L("Şarj oluyor", "Charging") : b.onAC ? L("Adaptöre bağlı", "On power adapter") : b.minutesLeft.map { "≈ \(Fmt.duration(Double($0) * 60))" } ?? L("Pilde", "On battery"),
                                       colors: [Palette.amber, Palette.green])
                                .appear(0.25)
                        } else {
                            MetricTile(title: L("Isı", "Thermal"), icon: "thermometer.medium",
                                       value: [0.25, 0.5, 0.8, 1.0][min(m.thermal.rawValue, 3)], text: Fmt.thermal(m.thermal),
                                       sub: L("Termal durum", "Thermal state"), colors: [Palette.green, Palette.amber])
                                .appear(0.25)
                        }
                    }
                }

                HStack(alignment: .top, spacing: 18) {
                    TopAdviceCard().appear(0.3)
                    SystemInfoCard().frame(width: 340).appear(0.35)
                }
            }
            .padding(28)
        }
    }
}

private struct HealthCard: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        let score = model.healthScore
        GlassCard(padding: 22, glow: Palette.score(score)) {
            VStack(spacing: 18) {
                RingGauge(value: score, colors: [Palette.violet, Palette.cyan, Palette.score(score)], lineWidth: 16) {
                    VStack(spacing: 2) {
                        BigNumber(text: "\(Int(score * 100))", size: 54)
                        Text(model.healthLabel).font(.headline).foregroundStyle(Palette.score(score))
                    }
                }
                .frame(width: 190, height: 190)
                .frame(maxWidth: .infinity)

                VStack(spacing: 10) {
                    scoreRow("lock.shield.fill", L("Güvenlik", "Security"), model.security.score)
                    scoreRow("gauge.with.dots.needle.67percent", L("Performans", "Performance"), model.performanceScore)
                }

                Button { model.showBoost = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                        Text(L("Hızlandır", "Boost")).fontWeight(.semibold)
                    }
                    .foregroundStyle(.black.opacity(0.85))
                    .frame(maxWidth: .infinity).frame(height: 42)
                    .background(Capsule().fill(LinearGradient(colors: [Palette.amber, Palette.pink], startPoint: .leading, endPoint: .trailing)))
                    .shadow(color: Palette.amber.opacity(0.5), radius: 12)
                }
                .buttonStyle(PressableStyle())
                .help(L("Mac'inizi analiz edip hızlandırma adımlarını gösterir", "Analyzes your Mac and shows steps to speed it up"))
            }
        }
    }

    private func scoreRow(_ icon: String, _ title: String, _ v: Double) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).frame(width: 18).foregroundStyle(.secondary)
            Text(title).font(.callout).frame(width: 84, alignment: .leading)
            Bar(value: v, color: Palette.score(v))
            Text(Fmt.pct(v)).font(.callout.monospacedDigit()).frame(width: 42, alignment: .trailing)
        }
    }
}

struct MetricTile: View {
    let title: String, icon: String
    let value: Double
    let text: String, sub: String
    let colors: [Color]

    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                RingGauge(value: value, colors: colors, lineWidth: 9) {
                    Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(colors.last ?? .white)
                }
                .frame(width: 74, height: 74)
                VStack(alignment: .leading, spacing: 4) {
                    Caption(title)
                    BigNumber(text: text, size: 26)
                    Text(sub).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

private struct TopAdviceCard: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        let list = Array(model.advices.prefix(4))
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Caption(L("Öne çıkan öneriler", "Top advice"))
                    Spacer()
                    IconButton("arrow.right", L("Tüm önerileri gör", "See all advice"), size: 28) { model.go(.advice) }
                }
                if list.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill").font(.title).foregroundStyle(Palette.green)
                            .symbolEffect(.bounce, value: list.isEmpty)
                        Text(L("Her şey yolunda. Şu an yapılacak bir şey yok.", "All good. Nothing to do right now.")).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 20)
                } else {
                    ForEach(list) { a in AdviceRow(advice: a, compact: true) }
                }
            }
        }
    }
}

private struct SystemInfoCard: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        let m = model.metrics
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Caption(L("Bu Mac", "This Mac"))
                info("laptopcomputer", m.machineName)
                info("cpu", m.chip)
                info("apple.logo", m.osVersion)
                info("memorychip", L("\(Fmt.bytes(m.memTotal)) bellek", "\(Fmt.bytes(m.memTotal)) memory"))
                info("clock.arrow.circlepath", L("\(Fmt.duration(m.uptime)) açık", "Up \(Fmt.duration(m.uptime))"))
                info("thermometer.medium", L("Isı: \(Fmt.thermal(m.thermal))", "Thermal: \(Fmt.thermal(m.thermal))"))
            }
        }
    }
    private func info(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).frame(width: 20).foregroundStyle(Palette.cyan)
            Text(text).font(.callout).lineLimit(1).truncationMode(.middle)
        }
    }
}
