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
        // 1. Close panel
        for window in NSApp.windows where window.isVisible && window is NSPanel {
            window.orderOut(nil)
        }

        // 2. Activate previous app
        SharedState.shared.panelController?.activatePreviousApp()

        // 3. Wait for focus switch, then paste via osascript
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            simulatePaste()
        }
    }

    // Use osascript subprocess to simulate Cmd+V — more reliable than CGEvent
    // Requires Accessibility permission for "System Events"
    private static func simulatePaste() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = [
            "-e",
            "tell application \"System Events\" to keystroke \"v\" using command down",
        ]
        do {
            try task.run()
        } catch {
            NSLog("[ClipboardManager] osascript paste failed: \(error)")
        }
    }
}
