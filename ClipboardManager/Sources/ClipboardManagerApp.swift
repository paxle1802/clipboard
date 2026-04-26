import KeyboardShortcuts
import SwiftUI

@main
struct ClipboardManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private var store: ClipboardStore { SharedState.shared.store }

    var body: some Scene {
        Settings {
            SettingsView(store: store)
        }
    }
}
