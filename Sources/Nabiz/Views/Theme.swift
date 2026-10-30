import SwiftUI
import Charts

enum Palette {
    static let bgTop = Color(red: 0.06, green: 0.07, blue: 0.13)
    static let bgBottom = Color(red: 0.02, green: 0.02, blue: 0.05)
    static let cyan = Color(red: 0.25, green: 0.85, blue: 0.97)
    static let violet = Color(red: 0.58, green: 0.45, blue: 1.0)
    static let pink = Color(red: 1.0, green: 0.40, blue: 0.65)
    static let green = Color(red: 0.32, green: 0.92, blue: 0.62)
    static let amber = Color(red: 1.0, green: 0.75, blue: 0.30)
    static let red = Color(red: 1.0, green: 0.38, blue: 0.40)

    static func load(_ v: Double) -> Color { v < 0.6 ? green : v < 0.85 ? amber : red }
    static func score(_ v: Double) -> Color { v >= 0.8 ? green : v >= 0.55 ? amber : red }
    static func status(_ s: CheckStatus) -> Color {
        switch s { case .pass: green; case .warn: amber; case .fail: red; case .info: cyan; case .checking: .gray }
    }
    static let brand = LinearGradient(colors: [violet, cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
}

extension CheckStatus {
    var icon: String {
        switch self {
        case .pass: "checkmark.circle.fill"
        case .warn: "exclamationmark.triangle.fill"
        case .fail: "xmark.octagon.fill"
        case .info: "info.circle.fill"
        case .checking: "circle.dotted"
        }
    }
}

/// Durağan, bir kez rasterleştirilen arka plan. Sürekli animasyon işlemciyi gereksiz yorar.
struct AnimatedBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Palette.bgTop, Palette.bgBottom], startPoint: .top, endPoint: .bottom)
            blob(Palette.violet.opacity(0.33), 560, CGSize(width: -260, height: -200))
            blob(Palette.cyan.opacity(0.22), 480, CGSize(width: 300, height: 220))
            blob(Palette.pink.opacity(0.16), 400, CGSize(width: 220, height: -220))
        }
        .drawingGroup()
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    private func blob(_ c: Color, _ size: CGFloat, _ o: CGSize) -> some View {
        Circle().fill(c).frame(width: size, height: size).blur(radius: 150).offset(o)
    }
}

struct GlassCard<Content: View>: View {
    var padding: CGFloat = 18
    var glow: Color? = nil
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.ultraThinMaterial).opacity(0.85)
                RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.white.opacity(0.025))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [(glow ?? .white).opacity(0.28), .white.opacity(0.03)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.35), radius: 18, y: 10)
    }
}

struct RingGauge<Center: View>: View {
    var value: Double
    var colors: [Color]
    var lineWidth: CGFloat = 12
    @ViewBuilder var center: Center
    @State private var shown = 0.0

    var body: some View {
        ZStack {
            ZStack {
                Circle().stroke(.white.opacity(0.07), lineWidth: lineWidth)
                Circle()
                    .trim(from: 0, to: max(0.002, min(shown, 1)))
                    .stroke(AngularGradient(colors: colors + [colors.first ?? .white], center: .center),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: (colors.last ?? .white).opacity(0.5), radius: lineWidth * 0.6)
            }
            .padding(lineWidth)
            .drawingGroup()          // GPU'da çiz; CPU'yu yormasın
            .padding(-lineWidth / 2)
            center
        }
        .onAppear { withAnimation(.spring(response: 1.3, dampingFraction: 0.8).delay(0.1)) { shown = Self.q(value) } }
        .onChange(of: Self.q(value)) { _, v in
            // Küçük dalgalanmalarda animasyon başlatma; enerji ve işlemci tasarrufu.
            if abs(v - shown) >= 0.03 { withAnimation(.easeOut(duration: 0.5)) { shown = v } } else { shown = v }
        }
    }

    private static func q(_ v: Double) -> Double { (v * 100).rounded() / 100 }
}

struct Sparkline: View {
    var values: [Double]
    var color: Color
    var maxValue: Double? = nil

    var body: some View {
        let top = maxValue ?? max(values.max() ?? 1, 1)
        Chart(Array(values.enumerated()), id: \.offset) { p in
            AreaMark(x: .value("t", p.offset), y: .value("v", min(p.element, top)))
                .interpolationMethod(.catmullRom)
                .foregroundStyle(LinearGradient(colors: [color.opacity(0.45), color.opacity(0)], startPoint: .top, endPoint: .bottom))
            LineMark(x: .value("t", p.offset), y: .value("v", min(p.element, top)))
                .interpolationMethod(.catmullRom)
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...top)
        .chartXScale(domain: 0...max(values.count - 1, 1))
    }
}

/// Yazısız, ipuçlu yuvarlak simge düğmesi.
struct IconButton: View {
    let systemName: String
    let help: String
    var tint: Color = .white
    var size: CGFloat = 34
    var prominent = false
    let action: () -> Void
    @State private var hover = false

    init(_ systemName: String, _ help: String, tint: Color = .white, size: CGFloat = 34, prominent: Bool = false, action: @escaping () -> Void) {
        self.systemName = systemName; self.help = help; self.tint = tint
        self.size = size; self.prominent = prominent; self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(prominent ? Color.black.opacity(0.85) : tint)
                .frame(width: size, height: size)
                .background {
                    if prominent { Circle().fill(tint.gradient) }
                    else { Circle().fill(Color.white.opacity(hover ? 0.15 : 0.07)) }
                }
                .overlay(Circle().strokeBorder(.white.opacity(prominent ? 0.3 : 0.12)))
                .shadow(color: tint.opacity(hover || prominent ? 0.5 : 0), radius: hover ? 14 : 8)
                .scaleEffect(hover ? 1.08 : 1)
                .contentShape(Circle())
        }
        .buttonStyle(PressableStyle())
        .help(help)
        .accessibilityLabel(help)
        .onHover { h in withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { hover = h } }
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct SectionHeader<Trailing: View>: View {
    let section: AppSection
    var subtitle: String? = nil
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: section.icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Palette.brand)
                .frame(width: 46, height: 46)
                .background(Circle().fill(.white.opacity(0.06)))
            VStack(alignment: .leading, spacing: 3) {
                Text(section.title).font(.system(size: 28, weight: .bold, design: .rounded))
                Text(subtitle ?? section.subtitle).font(.callout).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 10) { trailing }
        }
        .padding(.top, 8)
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(section: AppSection, subtitle: String? = nil) { self.init(section: section, subtitle: subtitle) { EmptyView() } }
}

struct Appear: ViewModifier {
    let delay: Double
    @State private var shown = false
    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 16)
            .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(delay)) { shown = true } }
    }
}

extension View {
    func appear(_ delay: Double = 0) -> some View { modifier(Appear(delay: delay)) }
}

struct BigNumber: View {
    let text: String
    var size: CGFloat = 28
    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .bold, design: .rounded))
            .monospacedDigit()
            .contentTransition(.numericText())
            .animation(.snappy, value: text)
    }
}

struct Caption: View {
    let text: String
    init(_ t: String) { text = t }
    var body: some View {
        Text(text.uppercased()).font(.system(size: 10.5, weight: .semibold)).tracking(0.8).foregroundStyle(.secondary)
    }
}

/// Yatay doluluk çubuğu.
struct Bar: View {
    var value: Double
    var color: Color
    var height: CGFloat = 8
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.07))
                Capsule().fill(color.gradient)
                    .frame(width: max(height, g.size.width * min(max(value, 0), 1)))
                    .shadow(color: color.opacity(0.5), radius: 4)
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.7, dampingFraction: 0.85), value: value)
    }
}

/// Dönen halka. Zamana bağlı çizilir; sonsuz tekrarlı animasyon kullanmaz,
/// bu yüzden görünüm kaldırılırken geçişler takılmaz.
struct SpinningRing: View {
    var colors: [Color]
    var lineWidth: CGFloat = 12
    var period: Double = 1.1

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 45)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(AngularGradient(colors: colors, center: .center),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(t.truncatingRemainder(dividingBy: period) / period * 360))
        }
    }
}
