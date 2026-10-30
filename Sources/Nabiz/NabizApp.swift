import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct NabizApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var model = AppModel()
    @State private var help = HelpRouter.shared

    var body: some Scene {
        WindowGroup("Nabız", id: "main") {
            RootView()
                .environment(model)
                .environment(help)
                .frame(minWidth: 1060, minHeight: 720)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
        .commands { AppCommands(model: model, help: help) }

        Window(L("Nabız Yardım", "Nabız Help"), id: "help") {
            HelpView()
                .environment(help)
                .frame(minWidth: 780, minHeight: 520)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 960, height: 640)
    }
}

struct AppCommands: Commands {
    let model: AppModel
    let help: HelpRouter
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button(L("Nabız Yardımı", "Nabız Help")) { help.open(nil); openWindow(id: "help") }
                .keyboardShortcut("?", modifiers: .command)
            Button(L("Yardımda Ara…", "Search Help…")) { help.query = ""; openWindow(id: "help") }
                .keyboardShortcut("f", modifiers: [.command, .option])
            Divider()
            ForEach(HelpLibrary.categories, id: \.self) { cat in
                Menu(cat) {
                    ForEach(HelpLibrary.topics.filter { $0.category == cat }) { t in
                        Button(t.title) { help.open(t.id); openWindow(id: "help") }
                    }
                }
            }
        }
        CommandMenu(L("Bakım", "Maintenance")) {
            Button(L("Hızlandır", "Boost")) { model.showBoost = true }.keyboardShortcut("b", modifiers: [.command, .shift])
            Divider()
            Button(L("Tümünü Yenile", "Refresh All")) { model.refreshAll() }.keyboardShortcut("r")
            Button(L("Güvenlik Taraması", "Security Scan")) { model.go(.security); model.security.runAll() }.keyboardShortcut("s", modifiers: [.command, .shift])
            Button(L("Gereksiz Dosya Taraması", "Junk File Scan")) { model.go(.cleanup); model.cleanup.scan() }.keyboardShortcut("k", modifiers: [.command, .shift])
        }
        CommandMenu(L("Dil", "Language")) {
            ForEach(AppLanguage.allCases) { l in
                Toggle(l.name, isOn: Binding(get: { Loc.shared.lang == l }, set: { if $0 { model.setLanguage(l) } }))
            }
            Divider()
            Button(L("Dili Değiştir", "Switch Language")) { model.toggleLanguage() }
                .keyboardShortcut("l", modifiers: [.command, .shift])
        }
        CommandGroup(after: .sidebar) {
            ForEach(AppSection.allCases) { s in
                Button(s.title) { model.go(s) }.keyboardShortcut(KeyEquivalent(s.shortcut))
            }
        }
    }
}
