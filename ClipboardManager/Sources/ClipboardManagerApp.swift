import KeyboardShortcuts
import SwiftUI

@main
struct ClipboardManagerApp: App {
    @State private var store: ClipboardStore
    @State private var monitor: ClipboardMonitor

    var body: some Scene {
        MenuBarExtra("Clipboard Manager", systemImage: "clipboard") {
            PopupContentView(store: store, monitor: monitor)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(store: store)
        }
    }

    init() {
        let store = ClipboardStore()
        let monitor = ClipboardMonitor(store: store)
        _store = State(initialValue: store)
        _monitor = State(initialValue: monitor)
    }
}
