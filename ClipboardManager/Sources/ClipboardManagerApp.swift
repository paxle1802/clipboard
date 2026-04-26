import KeyboardShortcuts
import SwiftUI

@main
struct ClipboardManagerApp: App {
    @State private var store: ClipboardStore
    @State private var monitor: ClipboardMonitor
    // Panel controller manages the floating window + status item + hotkey
    @State private var panelController: ClipboardPanelController?

    var body: some Scene {
        Settings {
            SettingsView(store: store)
        }
    }

    init() {
        let store = ClipboardStore()
        let monitor = ClipboardMonitor(store: store)
        _store = State(initialValue: store)
        _monitor = State(initialValue: monitor)
        _panelController = State(
            initialValue: ClipboardPanelController(
                store: store, monitor: monitor))
    }
}
