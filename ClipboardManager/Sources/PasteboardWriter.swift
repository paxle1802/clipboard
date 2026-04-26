import AppKit

// Writes clipboard items back to NSPasteboard and auto-pastes into previous app
@MainActor
struct PasteboardWriter {
    // Write item to clipboard, close panel, and simulate Cmd+V in previous app
    static func pasteItem(
        _ item: ClipboardItem, monitor: ClipboardMonitor?
    ) {
        writeToClipboard(item, monitor: monitor)
        dismissAndPaste()
    }

    // Write plain text only, then auto-paste
    static func pasteItemAsPlainText(
        _ item: ClipboardItem, monitor: ClipboardMonitor?
    ) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(item.textContent ?? item.preview, forType: .string)
        monitor?.syncChangeCount()
        dismissAndPaste()
    }

    // Copy to clipboard without pasting (for context menu "Copy")
    static func copyItem(
        _ item: ClipboardItem, monitor: ClipboardMonitor?
    ) {
        writeToClipboard(item, monitor: monitor)
        NSApp.keyWindow?.orderOut(nil)
    }

    // MARK: - Private

    private static func writeToClipboard(
        _ item: ClipboardItem, monitor: ClipboardMonitor?
    ) {
        let pb = NSPasteboard.general
        pb.clearContents()

        switch item.contentType {
        case .text:
            if let text = item.textContent {
                pb.setString(text, forType: .string)
            }
        case .image:
            if let data = item.imageData {
                pb.setData(data, forType: .png)
            }
        case .rtf:
            if let data = item.rtfData {
                pb.setData(data, forType: .rtf)
            }
            if let text = item.textContent {
                pb.setString(text, forType: .string)
            }
        case .html:
            if let html = item.htmlContent {
                pb.setString(html, forType: .html)
            }
            if let text = item.textContent {
                pb.setString(text, forType: .string)
            }
        case .fileURL:
            if let urls = item.fileURLs {
                pb.writeObjects(urls as [NSURL])
            }
        }

        monitor?.syncChangeCount()
    }

    // Close panel, activate previous app, simulate Cmd+V
    private static func dismissAndPaste() {
        // 1. Close our panel
        for window in NSApp.windows where window.isVisible && window is NSPanel {
            window.orderOut(nil)
        }

        // 2. Activate the app that was focused before we showed the panel
        SharedState.shared.panelController?.activatePreviousApp()

        // 3. Wait for previous app to gain focus, then simulate Cmd+V
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            simulatePasteKeystroke()
        }
    }

    // Simulate Cmd+V keystroke using CGEvent
    // NOTE: Requires Accessibility permission in System Settings
    private static func simulatePasteKeystroke() {
        let source = CGEventSource(stateID: .hidSystemState)
        // Key code 9 = V key
        guard let keyDown = CGEvent(
            keyboardEventSource: source, virtualKey: 9, keyDown: true),
              let keyUp = CGEvent(
            keyboardEventSource: source, virtualKey: 9, keyDown: false)
        else { return }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
