import SwiftUI
import Observation

@Observable @MainActor
final class HelpRouter {
    static let shared = HelpRouter()
    var selectedTopicID: String? = "nabiz-nedir"
    var query = ""

    func open(_ id: String?) {
        if let id { selectedTopicID = id; query = "" }
    }
}

struct HelpView: View {
    @Environment(HelpRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        let results = HelpLibrary.search(router.query)
        NavigationSplitView {
            List(selection: $router.selectedTopicID) {
                if router.query.isEmpty {
                    ForEach(HelpLibrary.categories, id: \.self) { cat in
                        Section(cat) {
                            ForEach(results.filter { $0.category == cat }) { t in
                                Label(t.title, systemImage: t.icon).tag(t.id)
                            }
                        }
                    }
                } else {
                    Section(L("\(results.count) sonuç", "\(results.count) results")) {
                        ForEach(results) { t in
                            VStack(alignment: .leading, spacing: 2) {
                                Label(t.title, systemImage: t.icon)
                                Text(t.category).font(.caption).foregroundStyle(.secondary).padding(.leading, 28)
                            }
                            .tag(t.id)
                        }
                    }
                }
            }
            .searchable(text: $router.query, placement: .sidebar, prompt: L("Konu ara: bellek, firewall, temizlik…", "Search topics: memory, firewall, cleanup…"))
            .onChange(of: router.query) { _, _ in
                if let first = HelpLibrary.search(router.query).first, !router.query.isEmpty { router.selectedTopicID = first.id }
            }
            .navigationSplitViewColumnWidth(min: 240, ideal: 270)
        } detail: {
            if let id = router.selectedTopicID, let t = HelpLibrary.topic(id) {
                TopicDetail(topic: t).id(t.id)
            } else {
                ContentUnavailableView(L("Konu bulunamadı", "No topic found"), systemImage: "magnifyingglass",
                                       description: Text(L("Farklı bir kelimeyle aramayı deneyin.", "Try a different word.")))
            }
        }
    }
}

private struct TopicDetail: View {
    @Environment(HelpRouter.self) private var router
    let topic: HelpTopic

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    Image(systemName: topic.icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 58, height: 58)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.brand))
                        .shadow(color: Palette.violet.opacity(0.5), radius: 12)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(topic.category.uppercased()).font(.caption.weight(.semibold)).tracking(0.8).foregroundStyle(Palette.cyan)
                        Text(topic.title).font(.system(size: 26, weight: .bold, design: .rounded))
                    }
                }
                .appear()

                Text(Self.render(topic.body))
                    .font(.body)
                    .lineSpacing(5)
                    .textSelection(.enabled)
                    .appear(0.05)

                if !topic.related.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Caption(L("İlgili konular", "Related topics"))
                        HStack(spacing: 8) {
                            ForEach(topic.related.compactMap(HelpLibrary.topic)) { r in
                                Button { withAnimation { router.selectedTopicID = r.id } } label: {
                                    Label(r.title, systemImage: r.icon).font(.callout)
                                        .padding(.horizontal, 12).padding(.vertical, 7)
                                        .background(Capsule().fill(.white.opacity(0.08)))
                                }
                                .buttonStyle(PressableStyle())
                            }
                        }
                    }
                    .padding(.top, 8)
                    .appear(0.1)
                }
            }
            .padding(32)
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AnimatedBackground())
    }

    static func render(_ md: String) -> AttributedString {
        (try? AttributedString(markdown: md, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(md)
    }
}
