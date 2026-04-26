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
        // Just close the panel, don't simulate paste
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

    // Close panel, return focus to previous app, simulate Cmd+V
    private static func dismissAndPaste() {
        // Close our panel and deactivate app to return focus
        for window in NSApp.windows where window.isVisible && window is NSPanel {
            window.orderOut(nil)
        }

        // Small delay to let previous app regain focus, then simulate Cmd+V
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            simulatePasteKeystroke()
        }
    }

    // Simulate Cmd+V keystroke using CGEvent
    private static func simulatePasteKeystroke() {
        let source = CGEventSource(stateID: .hidSystemState)
        // Key code 9 = V key
        let keyDown = CGEvent(
            keyboardEventSource: source, virtualKey: 9, keyDown: true)
        let keyUp = CGEvent(
            keyboardEventSource: source, virtualKey: 9, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
