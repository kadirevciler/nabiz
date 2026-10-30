import SwiftUI

struct SecurityView: View {
    @Environment(AppModel.self) private var model
    @Environment(HelpRouter.self) private var help
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let s = model.security
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(section: .security) {
                    if s.isScanning { ProgressView().controlSize(.small).padding(.trailing, 6) }
                    IconButton("arrow.clockwise", L("Yeniden tara (⇧⌘S)", "Rescan (⇧⌘S)")) { s.runAll() }
                }
                .appear()

                GlassCard(padding: 22, glow: Palette.score(s.score)) {
                    HStack(spacing: 28) {
                        RingGauge(value: s.score, colors: [Palette.violet, Palette.score(s.score)], lineWidth: 13) {
                            VStack(spacing: 0) {
                                BigNumber(text: "\(Int(s.score * 100))", size: 40)
                                Text(L("puan", "score")).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 130, height: 130)
                        VStack(alignment: .leading, spacing: 12) {
                            Text(s.score >= 0.9 ? L("Mac'iniz iyi korunuyor", "Your Mac is well protected") : s.score >= 0.7 ? L("Birkaç ayar iyileştirilebilir", "A few settings can be improved") : L("Koruma ayarlarınızı gözden geçirin", "Review your protection settings"))
                                .font(.title3.weight(.semibold))
                            HStack(spacing: 18) {
                                stat(.pass, s.count(.pass), L("Tamam", "OK"))
                                stat(.warn, s.count(.warn), L("Uyarı", "Warning"))
                                stat(.fail, s.count(.fail), L("Risk", "Risk"))
                            }
                            if let d = s.lastScan {
                                Text(L("Son tarama \(d.formatted(date: .omitted, time: .shortened))", "Last scan \(d.formatted(date: .omitted, time: .shortened))")).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                }
                .appear(0.05)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16)], spacing: 16) {
                    ForEach(Array(s.checks.enumerated()), id: \.element.id) { i, c in
                        CheckCard(check: c,
                                  onFix: c.fixURL.map { url in { model.perform(.open(url)) } },
                                  onHelp: { help.open(c.helpTopic); openWindow(id: "help") })
                            .appear(0.08 + Double(i) * 0.03)
                    }
                }
            }
            .padding(28)
        }
    }

    private func stat(_ st: CheckStatus, _ n: Int, _ label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: st.icon).foregroundStyle(Palette.status(st))
            BigNumber(text: "\(n)", size: 18)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}

private struct CheckCard: View {
    let check: SecurityCheck
    let onFix: (() -> Void)?
    let onHelp: () -> Void

    var body: some View {
        let color = Palette.status(check.status)
        GlassCard(padding: 16, glow: check.status == .pass ? nil : color) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: check.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(color.opacity(0.14)))
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(check.title).font(.headline)
                        Image(systemName: check.status.icon).foregroundStyle(color)
                            .symbolEffect(.pulse, isActive: check.status == .checking)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    Text(check.detail).font(.callout).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                VStack(spacing: 8) {
                    if let onFix, check.status == .fail || check.status == .warn || check.status == .info {
                        IconButton("gearshape.fill", L("İlgili ayarı aç", "Open related setting"), tint: color, size: 30, action: onFix)
                    }
                    IconButton("questionmark", L("Bu konu hakkında yardım", "Help on this topic"), size: 30, action: onHelp)
                }
            }
        }
        .animation(.spring, value: check.status)
    }
}
