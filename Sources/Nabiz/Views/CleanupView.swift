import SwiftUI
import AppKit

struct CleanupView: View {
    @Environment(AppModel.self) private var model
    @State private var confirming = false

    var body: some View {
        @Bindable var c = model.cleanup
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SectionHeader(section: .cleanup) {
                        if c.hasScanned { IconButton("arrow.clockwise", L("Yeniden tara (⇧⌘K)", "Rescan (⇧⌘K)")) { c.scan() } }
                        IconButton("trash", L("Çöp Sepeti'ni Finder'da aç", "Open Trash in Finder")) {
                            NSWorkspace.shared.open(FileManager.default.homeDirectoryForCurrentUser.appending(path: ".Trash"))
                        }
                    }
                    .appear()

                    switch c.phase {
                    case .idle:
                        ScanPrompt { c.scan() }.transition(.opacity)
                    case .scanning(let label):
                        ScanningView(label: label, found: c.totalSize).transition(.opacity)
                    case .ready:
                        summary(c)
                        ForEach($c.categories) { $cat in CategoryCard(category: $cat) }
                    case .cleaning(let p):
                        CleaningView(progress: p)
                    case .done(let freed, let failed, let trashed):
                        DoneView(freed: freed, failed: failed, trashed: trashed) { c.scan() }
                    }
                }
                .padding(28)
                .padding(.bottom, 90)
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: c.phase)
            }

            if c.phase == .ready && c.selectedCount > 0 {
                BottomBar(size: c.selectedSize, count: c.selectedCount) { confirming = true }
                    .padding(20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: c.selectedCount > 0)
        .sheet(isPresented: $confirming) {
            ConfirmCleanupSheet(cleanup: c, onCancel: { confirming = false }, onConfirm: {
                confirming = false
                c.clean()
            })
        }
    }

    private func summary(_ c: CleanupService) -> some View {
        GlassCard(padding: 22, glow: Palette.cyan) {
            HStack(spacing: 20) {
                Image(systemName: "sparkles").font(.system(size: 34)).foregroundStyle(Palette.brand)
                    .symbolEffect(.bounce, value: c.totalSize)
                VStack(alignment: .leading, spacing: 4) {
                    Caption(L("Bulunan", "Found"))
                    BigNumber(text: Fmt.bytes(c.totalSize), size: 34)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Caption(L("Seçili", "Selected"))
                    BigNumber(text: Fmt.bytes(c.selectedSize), size: 22)
                }
            }
        }
        .appear()
    }
}

private struct ScanPrompt: View {
    let start: () -> Void
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 26) {
            ZStack {
                ForEach(0..<3) { i in
                    Circle().stroke(Palette.cyan.opacity(0.35), lineWidth: 2)
                        .frame(width: 180, height: 180)
                        .scaleEffect(pulse ? 1.6 : 1)
                        .opacity(pulse ? 0 : 0.8)
                        .animation(.easeOut(duration: 2.4).repeatForever(autoreverses: false).delay(Double(i) * 0.8), value: pulse)
                }
                Button(action: start) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 58, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 180, height: 180)
                        .background(Circle().fill(LinearGradient(colors: [Palette.violet, Palette.cyan], startPoint: .topLeading, endPoint: .bottomTrailing)))
                        .overlay(Circle().strokeBorder(.white.opacity(0.3), lineWidth: 1.5))
                        .shadow(color: Palette.violet.opacity(0.6), radius: 30)
                }
                .buttonStyle(PressableStyle())
                .help(L("Taramayı başlat", "Start scan"))
            }
            .frame(height: 300)
            VStack(spacing: 8) {
                Text(L("Gereksiz dosyaları bulalım", "Let\'s find junk files")).font(.title2.weight(.semibold))
                Text(L("Önbellekler, günlükler, eski yükleyiciler ve geliştirici artıkları taranır.", "Caches, logs, old installers and developer leftovers are scanned."))
                    .foregroundStyle(.secondary)
                Label(L("Onayınız olmadan hiçbir dosya silinmez.", "Nothing is deleted without your approval."), systemImage: "lock.fill")
                    .font(.callout).foregroundStyle(Palette.green).padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 30)
        .onAppear { pulse = true }
    }
}

private struct ScanningView: View {
    let label: String
    let found: Int64
    @State private var spin = false

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle().stroke(.white.opacity(0.06), lineWidth: 14)
                Circle().trim(from: 0, to: 0.7)
                    .stroke(AngularGradient(colors: [.clear, Palette.violet, Palette.cyan], center: .center),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(.linear(duration: 1.1).repeatForever(autoreverses: false), value: spin)
                Image(systemName: "doc.viewfinder").font(.system(size: 44)).foregroundStyle(Palette.cyan)
                    .symbolEffect(.pulse)
            }
            .frame(width: 170, height: 170)
            Text(L("Taranıyor", "Scanning")).font(.title3.weight(.semibold))
            Text(label).foregroundStyle(.secondary).contentTransition(.opacity).animation(.easeInOut, value: label)
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
        .onAppear { spin = true }
    }
}

private struct CleaningView: View {
    let progress: Double
    var body: some View {
        VStack(spacing: 20) {
            RingGauge(value: progress, colors: [Palette.violet, Palette.cyan], lineWidth: 14) {
                BigNumber(text: Fmt.pct(progress), size: 34)
            }
            .frame(width: 170, height: 170)
            Text(L("Temizleniyor…", "Cleaning…")).font(.title3.weight(.semibold))
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }
}

private struct DoneView: View {
    let freed: Int64, failed: Int, trashed: Bool
    let rescan: () -> Void
    @State private var pop = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 90))
                .foregroundStyle(LinearGradient(colors: [Palette.green, Palette.cyan], startPoint: .top, endPoint: .bottom))
                .shadow(color: Palette.green.opacity(0.6), radius: 30)
                .scaleEffect(pop ? 1 : 0.3)
                .symbolEffect(.bounce, value: pop)
            BigNumber(text: Fmt.bytes(freed), size: 44)
            Text(trashed ? L("Çöp Sepeti'ne taşındı. Alan, Çöp Sepeti boşaltılınca açılır; o zamana kadar geri alabilirsiniz.", "Moved to Trash. Space is freed when the Trash is emptied; until then you can restore it.")
                         : L("Kalıcı olarak temizlendi.", "Permanently cleaned."))
                .foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: 420)
            if failed > 0 {
                Label(L("\(failed) öğe kullanımda olduğu için atlandı.", "\(failed) item(s) skipped because they are in use."), systemImage: "exclamationmark.triangle.fill")
                    .font(.callout).foregroundStyle(Palette.amber)
            }
            IconButton("arrow.clockwise", L("Yeniden tara", "Rescan"), size: 44, action: rescan).padding(.top, 8)
        }
        .frame(maxWidth: .infinity).padding(.top, 50)
        .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.55)) { pop = true } }
    }
}

private struct CategoryCard: View {
    @Binding var category: CleanupCategory

    var body: some View {
        GlassCard(padding: 16, glow: category.permanent && category.selectedCount > 0 ? Palette.red : nil) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    SelectToggle(state: category.selection, size: 22) {
                        withAnimation(.spring) { category.setAll(category.selection != .all) }
                    }
                    .disabled(category.items.isEmpty)
                    Image(systemName: category.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(category.permanent ? Palette.red : Palette.cyan)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill((category.permanent ? Palette.red : Palette.cyan).opacity(0.14)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.title).font(.headline)
                        Text(category.detail).font(.caption).foregroundStyle(category.permanent ? Palette.red.opacity(0.9) : .secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        BigNumber(text: Fmt.bytes(category.size), size: 17)
                        Text(L("\(category.items.count) öğe", "\(category.items.count) items")).font(.caption).foregroundStyle(.secondary)
                    }
                    if !category.items.isEmpty {
                        IconButton("chevron.down", category.expanded ? L("Ayrıntıları gizle", "Hide details") : L("Ayrıntıları göster", "Show details"), size: 28) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { category.expanded.toggle() }
                        }
                        .rotationEffect(.degrees(category.expanded ? 180 : 0))
                    }
                }
                if let note = category.note {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.trianglebadge.exclamationmark").foregroundStyle(Palette.amber)
                        Text(note).font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        IconButton("gearshape.fill", L("Tam Disk Erişimi ayarını aç", "Open Full Disk Access setting"), tint: Palette.amber, size: 26) {
                            NSWorkspace.shared.open(URL(string: SettingsURL.fullDisk)!)
                        }
                    }
                }
                if category.expanded {
                    VStack(spacing: 2) {
                        ForEach(category.items.indices.prefix(80), id: \.self) { i in
                            ItemRow(item: $category.items[i])
                        }
                        if category.items.count > 80 {
                            Text(L("+\(category.items.count - 80) öğe daha", "+\(category.items.count - 80) more")).font(.caption).foregroundStyle(.secondary).padding(.top, 4)
                        }
                    }
                    .padding(.leading, 36)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .appear()
    }
}

private struct ItemRow: View {
    @Binding var item: CleanupItem
    @State private var hover = false

    var body: some View {
        HStack(spacing: 10) {
            SelectToggle(state: item.selected ? .all : .none, size: 17) { item.selected.toggle() }
            Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path)).resizable().frame(width: 18, height: 18)
            Text(item.name).font(.callout).lineLimit(1).truncationMode(.middle)
            Spacer()
            Text(Fmt.bytes(item.size)).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            IconButton("magnifyingglass", L("Finder'da göster", "Show in Finder"), size: 24) {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            }
            .opacity(hover ? 1 : 0.35)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(hover ? 0.05 : 0)))
        .onHover { hover = $0 }
    }
}

struct SelectToggle: View {
    let state: SelectionState
    var size: CGFloat = 20
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: state == .all ? "checkmark.circle.fill" : state == .some ? "minus.circle.fill" : "circle")
                .font(.system(size: size))
                .foregroundStyle(state == .none ? AnyShapeStyle(Color.white.opacity(0.35)) : AnyShapeStyle(Palette.brand))
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(PressableStyle())
        .help(state == .all ? L("Seçimi kaldır", "Deselect") : L("Seç", "Select"))
    }
}

private struct BottomBar: View {
    let size: Int64
    let count: Int
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "checklist").font(.title3).foregroundStyle(Palette.cyan)
            VStack(alignment: .leading, spacing: 0) {
                BigNumber(text: Fmt.bytes(size), size: 22)
                Text(L("\(count) öğe seçili", "\(count) items selected")).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            IconButton("trash.fill", L("Seçilenleri temizle…", "Clean selected…"), tint: Palette.red, size: 50, prominent: true, action: action)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(Capsule().fill(.ultraThinMaterial))
        .overlay(Capsule().strokeBorder(.white.opacity(0.15)))
        .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
        .frame(maxWidth: 560)
    }
}

/// Silmeden önce kullanıcıya ne olacağını açıkça gösteren onay penceresi.
struct ConfirmCleanupSheet: View {
    let cleanup: CleanupService
    let onCancel: () -> Void
    let onConfirm: () -> Void
    @State private var shake = false

    var body: some View {
        let selected = cleanup.categories.filter { $0.selectedCount > 0 }
        let permanent = selected.filter(\.permanent)
        VStack(spacing: 18) {
            Image(systemName: permanent.isEmpty ? "trash.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(permanent.isEmpty ? Palette.cyan : Palette.red)
                .symbolEffect(.bounce, value: shake)
            VStack(spacing: 6) {
                Text(L("\(cleanup.selectedCount) öğe temizlensin mi?", "Clean \(cleanup.selectedCount) items?")).font(.title2.weight(.bold))
                BigNumber(text: Fmt.bytes(cleanup.selectedSize), size: 20).foregroundStyle(.secondary)
            }
            VStack(spacing: 8) {
                ForEach(selected) { c in
                    HStack {
                        Image(systemName: c.icon).foregroundStyle(c.permanent ? Palette.red : Palette.cyan).frame(width: 20)
                        Text(c.title)
                        Spacer()
                        Text("\(c.selectedCount) · \(Fmt.bytes(c.selectedSize))").font(.callout.monospacedDigit()).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.05)))

            Label(permanent.isEmpty
                  ? L("Dosyalar Çöp Sepeti'ne taşınır, istediğinizde geri alabilirsiniz.", "Files are moved to the Trash; you can restore them any time.")
                  : L("Çöp Sepeti'ndeki öğeler kalıcı olarak silinir ve geri alınamaz. Diğerleri Çöp Sepeti'ne taşınır.", "Items in the Trash are deleted permanently and cannot be restored. Others are moved to the Trash."),
                  systemImage: permanent.isEmpty ? "arrow.uturn.backward.circle" : "exclamationmark.octagon")
                .font(.callout)
                .foregroundStyle(permanent.isEmpty ? Palette.green : Palette.red)
                .multilineTextAlignment(.center)

            HStack(spacing: 14) {
                Button(action: onCancel) {
                    Label(L("Vazgeç", "Cancel"), systemImage: "xmark").frame(maxWidth: .infinity).frame(height: 40)
                        .background(Capsule().fill(.white.opacity(0.08)))
                }
                .keyboardShortcut(.cancelAction)
                Button(action: onConfirm) {
                    Label(L("Temizle", "Clean"), systemImage: "trash.fill").fontWeight(.semibold).foregroundStyle(.black.opacity(0.85))
                        .frame(maxWidth: .infinity).frame(height: 40)
                        .background(Capsule().fill(Palette.red.gradient))
                }
            }
            .buttonStyle(PressableStyle())
        }
        .padding(28)
        .frame(width: 460)
        .background(AnimatedBackground())
        .onAppear { shake.toggle() }
    }
}
