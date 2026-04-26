import AppKit

// Writes clipboard items back to NSPasteboard and closes panel
// User then Cmd+V to paste — standard behavior for clipboard managers
@MainActor
struct PasteboardWriter {
    // Copy item to clipboard and close panel
    static func selectItem(
        _ item: ClipboardItem, monitor: ClipboardMonitor?
    ) {
        writeToClipboard(item, monitor: monitor)
        dismissPanel()
    }

    // Copy plain text only and close panel
    static func selectItemAsPlainText(
        _ item: ClipboardItem, monitor: ClipboardMonitor?
    ) {
        writeToClipboard(item, monitor: monitor, forcePlainText: true)
        dismissPanel()
    }

    // Copy to clipboard without closing panel (context menu "Copy")
    static func copyItem(
        _ item: ClipboardItem, monitor: ClipboardMonitor?
    ) {
        writeToClipboard(item, monitor: monitor)
    }

    // MARK: - Private

    private static func writeToClipboard(
        _ item: ClipboardItem, monitor: ClipboardMonitor?,
        forcePlainText: Bool = false
    ) {
        let pb = NSPasteboard.general

        // Write using declareTypes + setString pattern (most compatible)
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

        // Tell monitor to skip this change
        monitor?.syncChangeCount()
    }

    // Close panel and return focus to previous app
    private static func dismissPanel() {
        // Close panel first
        for window in NSApp.windows where window.isVisible && window is NSPanel {
            window.orderOut(nil)
        }
        // Return focus to previous app
        SharedState.shared.panelController?.activatePreviousApp()
    }
}
