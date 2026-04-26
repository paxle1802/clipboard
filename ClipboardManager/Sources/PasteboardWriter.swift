import AppKit

// Writes clipboard items back to NSPasteboard, closes panel, auto-pastes
@MainActor
struct PasteboardWriter {
    // Copy item to clipboard, close panel, auto-paste into previous app
    static func selectItem(
        _ item: ClipboardItem, monitor: ClipboardMonitor?
    ) {
        writeToClipboard(item, monitor: monitor)
        dismissAndPaste()
    }

    // Copy plain text only, close panel, auto-paste
    static func selectItemAsPlainText(
        _ item: ClipboardItem, monitor: ClipboardMonitor?
    ) {
        writeToClipboard(item, monitor: monitor, forcePlainText: true)
        dismissAndPaste()
    }

    // Copy to clipboard only (context menu "Copy")
    static func copyItem(
        _ item: ClipboardItem, monitor: ClipboardMonitor?
    ) {
        writeToClipboard(item, monitor: monitor)
    }

    // MARK: - Clipboard write

    private static func writeToClipboard(
        _ item: ClipboardItem, monitor: ClipboardMonitor?,
        forcePlainText: Bool = false
    ) {
        let pb = NSPasteboard.general

        if forcePlainText || item.contentType == .text
            || item.contentType == .rtf || item.contentType == .html
        {
            let text = item.textContent ?? item.preview
            pb.declareTypes([.string], owner: nil)
            pb.setString(text, forType: .string)
        } else if item.contentType == .image, let data = item.imageData {
            pb.declareTypes([.png], owner: nil)
            pb.setData(data, forType: .png)
        } else if item.contentType == .fileURL, let urls = item.fileURLs {
            pb.clearContents()
            pb.writeObjects(urls as [NSURL])
        }

        monitor?.syncChangeCount()
    }

    // MARK: - Dismiss and auto-paste

    private static func dismissAndPaste() {
        let panelController = SharedState.shared.panelController

        // 1. Close panel
        for window in NSApp.windows where window.isVisible && window is NSPanel {
            window.orderOut(nil)
        }

        // 2. Activate previous app and wait for it to become frontmost
        panelController?.activatePreviousApp()

        // 3. Use global dispatch queue for CGEvent (avoids main thread issues)
        DispatchQueue.global(qos: .userInteractive).asyncAfter(
            deadline: .now() + 0.5
        ) {
            // Re-activate previous app from background thread as well
            DispatchQueue.main.sync {
                panelController?.activatePreviousApp()
            }
            // Small extra delay after second activation
            Thread.sleep(forTimeInterval: 0.1)
            simulatePaste()
        }
    }

    // Simulate Cmd+V via CGEvent on background thread
    // Requires: ClipboardManager in Accessibility settings
    private static func simulatePaste() {
        let source = CGEventSource(stateID: .combinedSessionState)
        guard let keyDown = CGEvent(
            keyboardEventSource: source, virtualKey: 9, keyDown: true),
              let keyUp = CGEvent(
            keyboardEventSource: source, virtualKey: 9, keyDown: false)
        else {
            NSLog("[ClipboardManager] CGEvent creation failed")
            return
        }
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)
    }
}
