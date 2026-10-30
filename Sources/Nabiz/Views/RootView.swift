import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        HStack(spacing: 0) {
            Rail()
            ZStack {
                switch model.section {
                case .overview: OverviewView()
                case .performance: PerformanceView()
                case .security: SecurityView()
                case .advice: AdviceView()
                case .cleanup: CleanupView()
                }
            }
            .id(model.section)
            .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 18)).combined(with: .scale(scale: 0.985)),
                                    removal: .opacity))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AnimatedBackground())
        .sheet(isPresented: $model.showBoost) { BoostSheet().environment(model) }
    }
}

struct Rail: View {
    @Environment(AppModel.self) private var model
    @Environment(HelpRouter.self) private var help
    @Environment(\.openWindow) private var openWindow
    @Namespace private var ns
    @State private var beat = false

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Palette.brand)
                .scaleEffect(beat ? 1.12 : 1)
                .shadow(color: Palette.cyan.opacity(0.6), radius: beat ? 10 : 4)
                .frame(height: 40)
                .padding(.top, 34)
                .padding(.bottom, 14)
                .help("Nabız")
                .onHover { h in withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) { beat = h } }

            ForEach(AppSection.allCases) { s in
                RailItem(section: s, selected: model.section == s, ns: ns,
                         badge: s == .advice ? model.advices.filter { $0.severity != .tip }.count : 0) {
                    model.go(s)
                }
            }
            Spacer()
            IconButton("bolt.fill", L("Hızlandır — tek dokunuşla analiz", "Boost — one-tap analysis"), tint: Palette.amber, size: 40, prominent: true) {
                model.showBoost = true
            }
            IconButton("globe", L("Dil: Türkçe — English'a geç (⇧⌘L)", "Language: English — switch to Türkçe (⇧⌘L)")) {
                model.toggleLanguage()
            }
            .overlay(alignment: .bottomTrailing) {
                Text(Loc.shared.lang.flag)
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .padding(.horizontal, 3).padding(.vertical, 1)
                    .background(Capsule().fill(Palette.violet))
                    .offset(x: 4, y: 3)
                    .allowsHitTesting(false)
                    .contentTransition(.opacity)
            }
            IconButton("questionmark", L("Yardım ve konu arama", "Help and topic search")) {
                help.open(nil)
                openWindow(id: "help")
            }
            .padding(.bottom, 18)
        }
        .frame(width: 80)
        .background {
            Rectangle().fill(.ultraThinMaterial).opacity(0.6)
                .overlay(alignment: .trailing) { Rectangle().fill(.white.opacity(0.06)).frame(width: 1) }
                .ignoresSafeArea()
        }
    }
}

private struct RailItem: View {
    let section: AppSection
    let selected: Bool
    let ns: Namespace.ID
    let badge: Int
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if selected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(colors: [Palette.violet.opacity(0.55), Palette.cyan.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(.white.opacity(0.25)))
                        .shadow(color: Palette.violet.opacity(0.6), radius: 12)
                        .matchedGeometryEffect(id: "sel", in: ns)
                } else if hover {
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white.opacity(0.07))
                }
                Image(systemName: section.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(selected ? .white : .white.opacity(0.6))
                    .symbolEffect(.bounce, value: selected)
            }
            .frame(width: 50, height: 50)
            .overlay(alignment: .topTrailing) {
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .padding(.horizontal, 5).frame(minWidth: 17, minHeight: 17)
                        .background(Capsule().fill(Palette.red))
                        .offset(x: 3, y: -3)
                        .transition(.scale)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .help("\(section.title)  ⌘\(section.shortcut)")
        .onHover { h in withAnimation(.easeOut(duration: 0.15)) { hover = h } }
    }
}
