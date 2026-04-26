import AppKit

// Handles post-launch setup that requires NSApplication to be fully initialized
// NSStatusBar.system.statusItem requires the app run loop to be active
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var panelController: ClipboardPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = SharedState.shared.store
        let monitor = SharedState.shared.monitor
        panelController = ClipboardPanelController(
            store: store, monitor: monitor)
    }
}

// Shared state accessible from both SwiftUI App and AppDelegate
@MainActor
final class SharedState {
    static let shared = SharedState()
    let store = ClipboardStore()
    lazy var monitor = ClipboardMonitor(store: store)
    private init() {}
}
