import SwiftUI
import AppKit
import UniformTypeIdentifiers

enum AIMode: String { case api, report }

struct AIView: View {
    @Environment(AppModel.self) private var model
    @AppStorage("ai.mode") private var modeRaw = AIMode.api.rawValue
    private var mode: AIMode { AIMode(rawValue: modeRaw) ?? .api }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(section: .ai).appear()

                HStack(spacing: 16) {
                    ModeCard(icon: "key.horizontal.fill", title: L("API ile analiz", "Analyze via API"),
                             detail: L("Kendi anahtarınızla, seçtiğiniz model analiz etsin", "Your key, the model of your choice"),
                             selected: mode == .api, showLogos: true) { withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { modeRaw = AIMode.api.rawValue } }
                    ModeCard(icon: "doc.text.magnifyingglass", title: L("Durum raporu", "Status report"),
                             detail: L("Raporu alın, kullandığınız AI aracına yükleyin", "Take the report to the AI tool you use"),
                             selected: mode == .report, showLogos: false) { withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { modeRaw = AIMode.report.rawValue } }
                }
                .appear(0.05)

                Group {
                    if mode == .api { APIModeView() } else { ReportModeView() }
                }
                .transition(.opacity.combined(with: .offset(y: 10)))
            }
            .padding(28)
        }
    }
}

// MARK: - Ortak parçalar

struct ProviderLogo: View {
    let provider: AIProvider
    var size: CGFloat = 44

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
        ZStack {
            shape.fill(.white)
            if let img = Self.image(provider.logo) {
                Image(nsImage: img).resizable().interpolation(.high).scaledToFit()
                    .padding(Self.padded.contains(provider) ? size * 0.16 : 0)
            } else {
                Text(String(provider.name.prefix(1))).font(.system(size: size * 0.45, weight: .bold)).foregroundStyle(.black)
            }
        }
        .frame(width: size, height: size)
        .clipShape(shape)
        .overlay(shape.strokeBorder(.white.opacity(0.25)))
        .shadow(color: .black.opacity(0.3), radius: size * 0.12, y: size * 0.05)
        .accessibilityLabel(provider.company)
    }

    /// Şeffaf zeminli logolar beyaz karo içinde boşlukla gösterilir.
    private static let padded: Set<AIProvider> = [.openai, .gemini, .deepseek]
    private static var cache: [String: NSImage] = [:]

    static func image(_ name: String) -> NSImage? {
        if let c = cache[name] { return c }
        let candidates = [Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Logos"),
                          Bundle.main.url(forResource: name, withExtension: "png"),
                          URL(fileURLWithPath: "Resources/Logos/\(name).png")]
        for case let u? in candidates { if let img = NSImage(contentsOf: u) { cache[name] = img; return img } }
        return nil
    }
}

private struct ModeCard: View {
    let icon: String, title: String, detail: String
    let selected: Bool
    let showLogos: Bool
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            GlassCard(padding: 18, glow: selected ? Palette.cyan : nil) {
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(selected ? AnyShapeStyle(Color.black.opacity(0.85)) : AnyShapeStyle(Palette.brand))
                        .frame(width: 46, height: 46)
                        .background(Circle().fill(selected ? AnyShapeStyle(Palette.brand) : AnyShapeStyle(Color.white.opacity(0.07))))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title).font(.headline)
                        Text(detail).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        if showLogos {
                            HStack(spacing: -6) {
                                ForEach(AIProvider.allCases) { ProviderLogo(provider: $0, size: 20) }
                            }
                            .padding(.top, 2)
                        } else {
                            HStack(spacing: 6) {
                                ForEach(["doc.on.doc", "square.and.arrow.down", "square.and.arrow.up"], id: \.self) {
                                    Image(systemName: $0).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.title3).foregroundStyle(selected ? Palette.cyan : .white.opacity(0.3))
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .scaleEffect(hover ? 1.01 : 1)
        }
        .buttonStyle(PressableStyle())
        .onHover { h in withAnimation(.spring(response: 0.3)) { hover = h } }
    }
}

/// Basit Markdown görüntüleyici: başlıklar, maddeler, satır içi biçim.
struct MarkdownView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(Array(text.components(separatedBy: "\n").enumerated()), id: \.offset) { _, raw in
                line(raw)
            }
        }
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private func line(_ raw: String) -> some View {
        let t = raw.trimmingCharacters(in: .whitespaces)
        if t.isEmpty {
            Spacer().frame(height: 2)
        } else if t.hasPrefix("#") {
            let level = t.prefix { $0 == "#" }.count
            Text(inline(String(t.dropFirst(level)).trimmingCharacters(in: .whitespaces)))
                .font(.system(size: level <= 1 ? 22 : level == 2 ? 18 : 15, weight: .bold, design: .rounded))
                .foregroundStyle(level <= 2 ? AnyShapeStyle(Palette.brand) : AnyShapeStyle(Color.primary))
                .padding(.top, 8)
        } else if t.hasPrefix("- ") || t.hasPrefix("* ") || t.hasPrefix("• ") {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Circle().fill(Palette.cyan).frame(width: 5, height: 5).offset(y: -2)
                Text(inline(String(t.dropFirst(2))))
            }
            .padding(.leading, CGFloat(raw.prefix { $0 == " " }.count) * 6)
        } else if t == "---" || t == "***" {
            Divider().opacity(0.4)
        } else {
            Text(inline(t))
        }
    }

    private func inline(_ s: String) -> AttributedString {
        (try? AttributedString(markdown: s, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(s)
    }
}

private func copyToClipboard(_ s: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(s, forType: .string)
}

@MainActor private func saveText(_ s: String, name: String, ext: String) {
    let panel = NSSavePanel()
    panel.nameFieldStringValue = name
    panel.allowedContentTypes = [UTType(filenameExtension: ext) ?? .plainText]
    panel.canCreateDirectories = true
    if panel.runModal() == .OK, let url = panel.url {
        try? s.write(to: url, atomically: true, encoding: .utf8)
    }
}

private var reportFileStem: String {
    L("Nabiz-Durum-Raporu-", "Nabiz-Status-Report-") + Date().formatted(.iso8601.year().month().day())
}

/// Kısa süreli "Kopyalandı" bildirimi.
private struct Toast: View {
    let text: String
    var body: some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(.callout.weight(.semibold))
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Capsule().fill(Palette.green.opacity(0.9)))
            .foregroundStyle(.black.opacity(0.85))
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - API modu

private struct APIModeView: View {
    @Environment(AppModel.self) private var model
    @State private var keyInput = ""
    @State private var modelInput = ""
    @State private var toast: String?

    var body: some View {
        let ai = model.ai
        let p = ai.provider
        VStack(alignment: .leading, spacing: 18) {
            // Sağlayıcı seçimi
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(AIProvider.allCases) { pr in
                    ProviderTile(provider: pr, selected: pr == p, hasKey: ai.savedKeys.contains(pr)) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { ai.provider = pr }
                    }
                }
            }
            .appear(0.08)

            // Anahtar ve model
            GlassCard(padding: 20, glow: Palette.violet) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 14) {
                        ProviderLogo(provider: p, size: 58).id(p).transition(.scale.combined(with: .opacity))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(p.name) " + L("API anahtarı", "API key")).font(.title3.weight(.semibold))
                            Text(p.company).font(.callout).foregroundStyle(.secondary)
                        }
                        Spacer()
                        IconButton("arrow.up.right.square", L("\(p.company) sitesinden anahtar al", "Get a key from \(p.company)")) {
                            NSWorkspace.shared.open(p.keyPage)
                        }
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "key.fill").foregroundStyle(Palette.amber).frame(width: 20)
                        SecureField(ai.savedKeys.contains(p)
                                    ? L("•••••••• kayıtlı — değiştirmek için yeni anahtar yapıştırın", "•••••••• saved — paste a new key to replace")
                                    : L("API anahtarını yapıştırın", "Paste your API key"), text: $keyInput)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.06)))
                            .onSubmit(save)
                        IconButton("checkmark", L("Anahtarı Anahtar Zinciri'ne kaydet", "Save key to Keychain"), tint: Palette.green, size: 32, prominent: !keyInput.isEmpty, action: save)
                            .disabled(keyInput.isEmpty)
                        if ai.savedKeys.contains(p) {
                            IconButton("trash", L("Kayıtlı anahtarı sil", "Delete saved key"), tint: Palette.red, size: 32) {
                                ai.removeKey(for: p); flash(L("Anahtar silindi", "Key deleted"))
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "cpu").foregroundStyle(Palette.cyan).frame(width: 20)
                        TextField(L("Model adı, örn. ", "Model name, e.g. ") + p.modelPlaceholder, text: $modelInput)
                            .textFieldStyle(.plain)
                            .font(.body.monospaced())
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.06)))
                            .onChange(of: modelInput) { _, v in ai.setModel(v, for: p) }
                        IconButton("wand.and.stars", L("Önerilen modeli yaz: \(p.modelPlaceholder)", "Use suggested model: \(p.modelPlaceholder)"), size: 32) {
                            modelInput = p.modelPlaceholder
                        }
                    }

                    Label(L("Anahtar macOS Anahtar Zinciri'nde şifreli saklanır. Durum raporu yalnızca analiz düğmesine bastığınızda \(p.company)'ye gönderilir; bilgisayar adı ve dosya adları içermez.",
                            "The key is stored encrypted in the macOS Keychain. The status report is sent to \(p.company) only when you press Analyze; it contains no computer name or file names."),
                          systemImage: "lock.shield")
                        .font(.caption).foregroundStyle(.secondary)

                    HStack {
                        Spacer()
                        IconButton("sparkles", L("\(p.name) ile analiz et", "Analyze with \(p.name)"), tint: Palette.amber, size: 58, prominent: true) {
                            ai.analyze(report: StatusReport.markdown(model, includeInstructions: false),
                                       instructions: StatusReport.analysisInstructions)
                        }
                        .disabled(ai.isRunning)
                        .opacity(ai.isRunning ? 0.5 : 1)
                        Spacer()
                    }
                }
            }
            .appear(0.12)
            .overlay(alignment: .top) { if let toast { Toast(text: toast).offset(y: -16) } }

            ResultCard()
        }
        .onAppear(perform: syncFields)
        .onChange(of: ai.provider) { _, _ in syncFields() }
    }

    private func syncFields() {
        keyInput = ""
        modelInput = model.ai.model(for: model.ai.provider)
    }

    private func save() {
        guard !keyInput.isEmpty else { return }
        model.ai.saveKey(keyInput, for: model.ai.provider)
        keyInput = ""
        flash(L("Anahtar kaydedildi", "Key saved"))
    }

    private func flash(_ s: String) {
        withAnimation(.spring) { toast = s }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { withAnimation(.easeOut) { toast = nil } }
    }
}

private struct ProviderTile: View {
    let provider: AIProvider
    let selected: Bool
    let hasKey: Bool
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ProviderLogo(provider: provider, size: 52)
                    .scaleEffect(hover || selected ? 1.06 : 1)
                VStack(spacing: 1) {
                    Text(provider.name).font(.callout.weight(.semibold))
                    Text(provider.company).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selected ? AnyShapeStyle(LinearGradient(colors: [Palette.violet.opacity(0.35), Palette.cyan.opacity(0.18)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                   : AnyShapeStyle(Color.white.opacity(hover ? 0.08 : 0.04)))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(selected ? Palette.cyan.opacity(0.7) : .white.opacity(0.08), lineWidth: selected ? 1.5 : 1)
            }
            .overlay(alignment: .topTrailing) {
                if hasKey {
                    Image(systemName: "key.fill").font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.black.opacity(0.8))
                        .padding(5).background(Circle().fill(Palette.green))
                        .padding(8)
                        .help(L("Anahtar kayıtlı", "Key saved"))
                        .transition(.scale)
                }
            }
            .shadow(color: selected ? Palette.cyan.opacity(0.3) : .clear, radius: 12)
        }
        .buttonStyle(PressableStyle())
        .help(provider.company)
        .onHover { h in withAnimation(.spring(response: 0.3)) { hover = h } }
    }
}

private struct ResultCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        switch model.ai.phase {
        case .idle:
            EmptyView()
        case .running(let p):
            GlassCard(padding: 22, glow: Palette.amber) {
                HStack(spacing: 16) {
                    ZStack {
                        SpinningRing(colors: [.clear, Palette.amber, Palette.pink], lineWidth: 4, period: 1)
                            .frame(width: 70, height: 70)
                        ProviderLogo(provider: p, size: 46)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("\(p.name) Mac'inizi analiz ediyor…", "\(p.name) is analyzing your Mac…")).font(.headline)
                        Text(L("Bu, modele göre birkaç saniye ile birkaç dakika sürebilir.", "Depending on the model this can take seconds to minutes."))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .transition(.opacity)
        case .failed(let msg):
            GlassCard(padding: 18, glow: Palette.red) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.octagon.fill").font(.title2).foregroundStyle(Palette.red)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("Analiz yapılamadı", "Analysis failed")).font(.headline)
                        Text(msg).font(.callout).foregroundStyle(.secondary).textSelection(.enabled)
                    }
                }
            }
            .transition(.opacity)
        case .done(let p, let modelName, let text, let secs):
            GlassCard(padding: 22, glow: Palette.green) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        ProviderLogo(provider: p, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L("AI analizi", "AI analysis")).font(.headline)
                            Text("\(p.name) · \(modelName) · \(secs) " + L("sn", "s")).font(.caption.monospaced()).foregroundStyle(.secondary)
                        }
                        Spacer()
                        IconButton("doc.on.doc", L("Analizi kopyala", "Copy analysis"), size: 30) { copyToClipboard(text) }
                        IconButton("square.and.arrow.down", L("Analizi kaydet (.md)", "Save analysis (.md)"), size: 30) {
                            saveText(text, name: L("Nabiz-AI-Analizi", "Nabiz-AI-Analysis") + ".md", ext: "md")
                        }
                    }
                    Divider().opacity(0.3)
                    MarkdownView(text: text)
                    Label(L("Yapay zekâ yanıtları hatalı olabilir; ayar değiştirmeden önce doğrulayın.",
                            "AI answers can be wrong; verify before changing settings."), systemImage: "info.circle")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .transition(.opacity.combined(with: .offset(y: 12)))
        }
    }
}

// MARK: - Rapor modu

private struct ReportModeView: View {
    @Environment(AppModel.self) private var model
    @State private var report = ""
    @State private var toast: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            GlassCard(padding: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    Caption(L("Nasıl kullanılır", "How to use"))
                    HStack(alignment: .top, spacing: 18) {
                        step(1, "doc.on.doc", L("Raporu kopyalayın veya .md olarak kaydedin", "Copy the report or save it as .md"))
                        step(2, "bubble.left.and.text.bubble.right", L("Kullandığınız AI aracını açın", "Open the AI tool you use"))
                        step(3, "arrow.up.doc", L("Yapıştırın ya da dosyayı yükleyin", "Paste it or upload the file"))
                    }
                    Divider().opacity(0.3)
                    Caption(L("Kopyala ve aç", "Copy & open"))
                    HStack(spacing: 14) {
                        ForEach(AIProvider.allCases) { p in
                            Button {
                                copyToClipboard(report)
                                NSWorkspace.shared.open(p.chatURL)
                                flash(L("Rapor kopyalandı — \(p.chatName)'e yapıştırın", "Report copied — paste into \(p.chatName)"))
                            } label: {
                                VStack(spacing: 6) {
                                    ProviderLogo(provider: p, size: 46)
                                    Text(p.chatName).font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(PressableStyle())
                            .help(L("Raporu kopyala ve \(p.chatName)'i aç", "Copy report and open \(p.chatName)"))
                        }
                    }
                }
            }
            .appear(0.08)
            .overlay(alignment: .top) { if let toast { Toast(text: toast).offset(y: -16) } }

            GlassCard(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Caption(L("Rapor önizleme", "Report preview"))
                        Text("· \(report.count) " + L("karakter", "characters")).font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        IconButton("arrow.clockwise", L("Raporu güncel verilerle yenile", "Refresh report with current data"), size: 30) { refresh() }
                        IconButton("doc.on.doc", L("Raporu kopyala", "Copy report"), size: 30) {
                            copyToClipboard(report); flash(L("Kopyalandı", "Copied"))
                        }
                        IconButton("square.and.arrow.down", L("Markdown olarak kaydet (.md)", "Save as Markdown (.md)"), size: 30) {
                            saveText(report, name: reportFileStem + ".md", ext: "md")
                        }
                        IconButton("curlybraces", L("Yalnızca veriyi JSON olarak kaydet", "Save data only as JSON"), size: 30) {
                            saveText(StatusReport.json(model), name: reportFileStem + ".json", ext: "json")
                        }
                        ShareLink(item: report) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(.white.opacity(0.07)))
                                .overlay(Circle().strokeBorder(.white.opacity(0.12)))
                        }
                        .buttonStyle(PressableStyle())
                        .help(L("Paylaş", "Share"))
                    }
                    ScrollView {
                        Text(report)
                            .font(.system(size: 11.5, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                    }
                    .frame(height: 420)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.black.opacity(0.25)))
                    Label(L("Rapor; bilgisayar adı, kullanıcı adı ve dosya adı içermez. Başında AI için hazır bir görev metni vardır.",
                            "The report contains no computer, user or file names. It starts with a ready-made task prompt for the AI."),
                          systemImage: "hand.raised.fill")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .appear(0.12)
        }
        .onAppear(perform: refresh)
        .onChange(of: Loc.shared.lang) { _, _ in refresh() }
    }

    private func refresh() { withAnimation(.easeInOut(duration: 0.2)) { report = StatusReport.markdown(model) } }

    private func flash(_ s: String) {
        withAnimation(.spring) { toast = s }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { withAnimation(.easeOut) { toast = nil } }
    }

    private func step(_ n: Int, _ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(n)").font(.system(size: 13, weight: .bold, design: .rounded))
                .frame(width: 26, height: 26).background(Circle().fill(Palette.brand)).foregroundStyle(.black.opacity(0.85))
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: icon).foregroundStyle(Palette.cyan)
                Text(text).font(.callout).fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
