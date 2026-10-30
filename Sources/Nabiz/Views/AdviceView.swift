import SwiftUI

struct AdviceView: View {
    @Environment(AppModel.self) private var model
    @State private var filter: Severity?

    var body: some View {
        let all = model.advices
        let list = all.filter { filter == nil || $0.severity == filter }
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(section: .advice) {
                    chip(nil, "line.3.horizontal.decrease", L("Tümü", "All"), all.count, .white)
                    ForEach(Severity.allCases, id: \.self) { s in
                        chip(s, s.icon, s.label, all.filter { $0.severity == s }.count, s.color)
                    }
                }
                .appear()

                if list.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "checkmark.seal.fill").font(.system(size: 64)).foregroundStyle(Palette.green)
                            .symbolEffect(.bounce, value: list.isEmpty)
                            .shadow(color: Palette.green.opacity(0.5), radius: 20)
                        Text(L("Yapılacak bir şey yok", "Nothing to do")).font(.title3.weight(.semibold))
                        Text(L("Mac'iniz bu kategoride iyi durumda.", "Your Mac is in good shape here.")).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding(.top, 80)
                    .transition(.scale.combined(with: .opacity))
                } else {
                    VStack(spacing: 12) {
                        ForEach(Array(list.enumerated()), id: \.element.id) { i, a in
                            GlassCard(padding: 16, glow: a.severity.color) { AdviceRow(advice: a) }
                                .appear(0.04 * Double(i))
                                .transition(.asymmetric(insertion: .opacity, removal: .opacity.combined(with: .scale(scale: 0.95))))
                        }
                    }
                }
            }
            .padding(28)
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: list.map(\.id))
        }
    }

    private func chip(_ s: Severity?, _ icon: String, _ label: String, _ n: Int, _ color: Color) -> some View {
        let on = filter == s
        return Button { withAnimation(.spring) { filter = s } } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                Text("\(n)").monospacedDigit()
            }
            .font(.callout.weight(.semibold))
            .foregroundStyle(on ? .black.opacity(0.85) : color)
            .padding(.horizontal, 11).frame(height: 32)
            .background(Capsule().fill(on ? AnyShapeStyle(color.gradient) : AnyShapeStyle(Color.white.opacity(0.07))))
        }
        .buttonStyle(PressableStyle())
        .help(label)
    }
}

struct AdviceRow: View {
    @Environment(AppModel.self) private var model
    let advice: Advice
    var compact = false

    var body: some View {
        HStack(alignment: compact ? .center : .top, spacing: 14) {
            Image(systemName: advice.icon)
                .font(.system(size: compact ? 14 : 17, weight: .semibold))
                .foregroundStyle(advice.severity.color)
                .frame(width: compact ? 32 : 42, height: compact ? 32 : 42)
                .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(advice.severity.color.opacity(0.15)))
            VStack(alignment: .leading, spacing: 3) {
                Text(advice.title).font(compact ? .callout.weight(.semibold) : .headline).lineLimit(1)
                Text(advice.detail).font(compact ? .caption : .callout).foregroundStyle(.secondary)
                    .lineLimit(compact ? 1 : nil)
            }
            Spacer(minLength: 0)
            if let action = advice.action {
                IconButton(advice.actionIcon, advice.actionHelp, tint: advice.severity.color, size: compact ? 28 : 34) {
                    model.perform(action)
                }
            }
        }
    }
}
