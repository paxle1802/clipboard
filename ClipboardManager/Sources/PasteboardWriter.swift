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

    // Close panel, activate previous app, wait for focus, then paste
    private static func dismissAndPaste() {
        let panelController = SharedState.shared.panelController

        // 1. Close our panel
        for window in NSApp.windows where window.isVisible && window is NSPanel {
            window.orderOut(nil)
        }

        // 2. Activate the previous app and wait until it's actually frontmost
        panelController?.activatePreviousApp()

        // 3. Poll until the previous app is frontmost, then simulate Cmd+V
        //    Max 10 attempts * 50ms = 500ms timeout
        waitForFocusAndPaste(attempts: 0, maxAttempts: 10)
    }

    // Retry paste until previous app has focus or we hit max attempts
    private static func waitForFocusAndPaste(
        attempts: Int, maxAttempts: Int
    ) {
        let frontApp = NSWorkspace.shared.frontmostApplication
        let ourBundleId = Bundle.main.bundleIdentifier

        // Check if a different app is now frontmost (not us)
        let otherAppIsFront = frontApp?.bundleIdentifier != ourBundleId

        if otherAppIsFront || attempts >= maxAttempts {
            simulatePasteKeystroke()
        } else {
            // Re-activate and retry after 50ms
            SharedState.shared.panelController?.activatePreviousApp()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                waitForFocusAndPaste(
                    attempts: attempts + 1, maxAttempts: maxAttempts)
            }
        }
    }

    // Simulate Cmd+V keystroke using CGEvent
    // Requires Accessibility permission in System Settings
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
