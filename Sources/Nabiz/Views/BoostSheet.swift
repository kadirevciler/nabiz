import SwiftUI

/// L("Hızlandır", "Boost"): tek dokunuşla analiz, ardından kullanıcı onaylı adımlar.
struct BoostSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0          // 0..3 analiz adımları, 4 = bitti
    @State private var spin = false

    private let steps: [(String, String)] = [
        ("memorychip", L("Bellek ve açık uygulamalar", "Memory and open apps")),
        ("lock.shield", L("Güvenlik ayarları", "Security settings")),
        ("sparkles", L("Gereksiz dosyalar", "Junk files")),
        ("lightbulb.max", L("Öneriler hazırlanıyor", "Preparing advice")),
    ]

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "bolt.fill").font(.title2).foregroundStyle(Palette.amber)
                    .symbolEffect(.bounce, value: step)
                Text(L("Hızlandır", "Boost")).font(.title2.weight(.bold))
                Spacer()
                IconButton("xmark", L("Kapat", "Close"), size: 30) { dismiss() }
            }

            if step < 4 { analyzing } else { results }
        }
        .padding(26)
        .frame(width: 560, height: 600, alignment: .top)
        .background(AnimatedBackground())
        .task { await run() }
    }

    private var analyzing: some View {
        VStack(spacing: 26) {
            ZStack {
                Circle().stroke(.white.opacity(0.06), lineWidth: 12)
                Circle().trim(from: 0, to: 0.65)
                    .stroke(AngularGradient(colors: [.clear, Palette.amber, Palette.pink], center: .center),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: spin)
                Image(systemName: "bolt.fill").font(.system(size: 40)).foregroundStyle(Palette.amber)
            }
            .frame(width: 140, height: 140)
            .onAppear { spin = true }

            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(steps.enumerated()), id: \.offset) { i, s in
                    HStack(spacing: 12) {
                        Image(systemName: i < step ? "checkmark.circle.fill" : i == step ? "circle.dotted" : "circle")
                            .foregroundStyle(i < step ? Palette.green : i == step ? Palette.amber : .secondary)
                            .symbolEffect(.pulse, isActive: i == step)
                            .contentTransition(.symbolEffect(.replace))
                        Image(systemName: s.0).frame(width: 20).foregroundStyle(.secondary)
                        Text(s.1).foregroundStyle(i <= step ? .primary : .secondary)
                    }
                    .font(.body)
                }
            }
            .animation(.spring, value: step)
        }
        .padding(.top, 10)
    }

    private var results: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if model.heavyApps.isEmpty {
                    resultRow("checkmark.circle.fill", Palette.green, L("Ağır uygulama yok", "No heavy apps"), L("Açık uygulamalar belleği zorlamıyor.", "Open apps are not straining memory."))
                } else {
                    GlassCard(padding: 14) {
                        VStack(alignment: .leading, spacing: 10) {
                            Caption(L("Kaynak tüketen uygulamalar", "Resource-hungry apps"))
                            Text(L("Kullanmadıklarınızı kapatmak Mac'i anında rahatlatır. Kaydedilmemiş iş varsa uygulama size sorar.", "Quitting the ones you don't use gives instant relief. If there is unsaved work, the app will ask you."))
                                .font(.caption).foregroundStyle(.secondary)
                            ForEach(model.heavyApps.prefix(6)) { app in
                                HStack(spacing: 10) {
                                    if let icon = app.icon { Image(nsImage: icon).resizable().frame(width: 26, height: 26) }
                                    Text(app.name).lineLimit(1)
                                    Spacer()
                                    Text(Fmt.bytes(app.memBytes)).font(.callout.monospacedDigit()).foregroundStyle(.secondary)
                                    IconButton("power", L("\(app.name) uygulamasını kapat", "Quit \(app.name)"), tint: Palette.pink, size: 28) { model.quit(app) }
                                }
                                .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .trailing).combined(with: .opacity)))
                            }
                        }
                    }
                    .appear()
                }

                let c = model.cleanup
                resultRow("sparkles", Palette.cyan,
                          c.totalSize > 0 ? L("\(Fmt.bytes(c.totalSize)) gereksiz dosya", "\(Fmt.bytes(c.totalSize)) of junk") : L("Gereksiz dosya bulunmadı", "No junk found"),
                          c.totalSize > 0 ? L("Gözden geçirip onayınızla temizleyin.", "Review and clean with your approval.") : L("Temizlenecek önemli bir şey yok.", "Nothing significant to clean."),
                          action: c.totalSize > 0 ? ("arrow.right", L("Temizliğe git", "Go to Cleanup"), { dismiss(); model.go(.cleanup) }) : nil)
                    .appear(0.08)

                let s = model.security
                let issues = s.count(.fail) + s.count(.warn)
                resultRow("lock.shield.fill", issues == 0 ? Palette.green : Palette.amber,
                          issues == 0 ? L("Güvenlik ayarları iyi", "Security settings look good") : L("\(issues) güvenlik ayarı iyileştirilebilir", "\(issues) security setting(s) can be improved"),
                          L("Güvenlik puanı \(Fmt.pct(s.score))", "Security score \(Fmt.pct(s.score))"),
                          action: issues > 0 ? ("arrow.right", L("Güvenliğe git", "Go to Security"), { dismiss(); model.go(.security) }) : nil)
                    .appear(0.16)

                let urgent = model.advices.filter { $0.severity != .tip }.count
                resultRow("lightbulb.max.fill", urgent == 0 ? Palette.green : Palette.amber,
                          urgent == 0 ? L("Acil öneri yok", "No urgent advice") : L("\(urgent) önemli öneri", "\(urgent) important item(s)"),
                          L("Tüm önerileri tek listede görün.", "See all advice in one list."),
                          action: ("arrow.right", L("Önerilere git", "Go to Advice"), { dismiss(); model.go(.advice) }))
                    .appear(0.24)
            }
            .animation(.spring, value: model.heavyApps.map(\.pid))
        }
    }

    private func resultRow(_ icon: String, _ color: Color, _ title: String, _ detail: String,
                           action: (String, String, () -> Void)? = nil) -> some View {
        GlassCard(padding: 14, glow: color) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.title3).foregroundStyle(color)
                    .frame(width: 40, height: 40).background(Circle().fill(color.opacity(0.14)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if let action { IconButton(action.0, action.1, tint: color, size: 32, action: action.2) }
            }
        }
    }

    private func run() async {
        step = 0
        await model.loadHeavyApps()
        try? await Task.sleep(for: .milliseconds(500))
        withAnimation { step = 1 }
        model.security.runAll()
        try? await Task.sleep(for: .milliseconds(700))
        withAnimation { step = 2 }
        if model.cleanup.phase == .idle || model.cleanup.phase == .ready || { if case .done = model.cleanup.phase { return true }; return false }() {
            model.cleanup.scan()
        }
        while model.cleanup.isScanning { try? await Task.sleep(for: .milliseconds(200)) }
        withAnimation { step = 3 }
        try? await Task.sleep(for: .milliseconds(600))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { step = 4 }
    }
}
