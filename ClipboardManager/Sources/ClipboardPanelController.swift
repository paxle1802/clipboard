import AppKit
import KeyboardShortcuts
import SwiftUI

// Custom panel that accepts key events even as a floating panel
final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// Manages a floating NSPanel that displays clipboard history
// Toggled by global hotkey (Cmd+Shift+V) or menu bar icon click
@MainActor
final class ClipboardPanelController: NSObject {
    private var panel: NSPanel?
    private let store: ClipboardStore
    private let monitor: ClipboardMonitor
    private var statusItem: NSStatusItem?
    private var eventMonitor: Any?
    // Remember which app was active before we showed our panel
    private var previousApp: NSRunningApplication?

    var isVisible: Bool { panel?.isVisible ?? false }

    init(store: ClipboardStore, monitor: ClipboardMonitor) {
        self.store = store
        self.monitor = monitor
        super.init()
        setupStatusItem()
        setupHotkey()
        setupPanel()
    }

    // MARK: - Status bar icon

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "clipboard",
                accessibilityDescription: "Clipboard Manager")
            button.action = #selector(statusItemClicked)
            button.target = self
        }
    }

    @objc private func statusItemClicked() {
        togglePanel()
    }

    // MARK: - Global hotkey

    private func setupHotkey() {
        KeyboardShortcuts.onKeyUp(for: .toggleClipboardHistory) { [weak self] in
            Task { @MainActor in
                self?.togglePanel()
            }
        }
    }

    // MARK: - Panel management

    private func setupPanel() {
        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 450),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: true)
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.acceptsMouseMovedEvents = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = true
        panel.animationBehavior = .utilityWindow
        panel.isReleasedWhenClosed = false
        // Transparent background — vibrancy comes from .ultraThinMaterial in SwiftUI
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true

        let hostingView = NSHostingView(
            rootView: PopupContentView(store: store, monitor: monitor)
        )
        panel.contentView = hostingView
        self.panel = panel
    }

    func togglePanel() {
        guard let panel = panel else { return }
        if panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        guard let panel = panel else { return }
        // Save the currently active app so we can return focus after paste
        previousApp = NSWorkspace.shared.frontmostApplication
        positionPanel()
        panel.makeKeyAndOrderFront(nil)
        // Activate app so panel receives keyboard events
        NSApp.activate(ignoringOtherApps: true)
        // Monitor clicks outside panel to dismiss
        startClickMonitor()
    }

    // Activate the app that was in focus before we opened the panel
    func activatePreviousApp() {
        previousApp?.activate(options: [.activateIgnoringOtherApps])
    }

    private func hidePanel() {
        panel?.orderOut(nil)
        stopClickMonitor()
    }

    // Position panel below status item, or center of active screen
    private func positionPanel() {
        guard let panel = panel else { return }

        if let buttonFrame = statusItem?.button?.window?.frame {
            // Position below the menu bar icon
            let x = buttonFrame.midX - panel.frame.width / 2
            let y = buttonFrame.minY - panel.frame.height - 4
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            // Fallback: center on active screen
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let x = screenFrame.midX - panel.frame.width / 2
                let y = screenFrame.midY - panel.frame.height / 2
                panel.setFrameOrigin(NSPoint(x: x, y: y))
            }
        }
    }

    // Dismiss panel when clicking outside
    private func startClickMonitor() {
        stopClickMonitor()
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            Task { @MainActor in
                self?.hidePanel()
            }
        }
    }

    private func stopClickMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
