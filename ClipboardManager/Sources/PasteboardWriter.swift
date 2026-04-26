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
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(item.textContent ?? item.preview, forType: .string)
        monitor?.syncChangeCount()
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
        _ item: ClipboardItem, monitor: ClipboardMonitor?
    ) {
        // Stop monitoring temporarily to prevent race condition
        monitor?.stopMonitoring()

        let pb = NSPasteboard.general
        pb.clearContents()

        switch item.contentType {
        case .text, .rtf, .html:
            // Always write as plain string — most reliable for Cmd+V
            let text = item.textContent ?? item.preview
            pb.setString(text, forType: .string)
        case .image:
            if let data = item.imageData {
                pb.setData(data, forType: .png)
            }
        case .fileURL:
            if let urls = item.fileURLs {
                pb.writeObjects(urls as [NSURL])
            }
        }

        monitor?.syncChangeCount()
        monitor?.startMonitoring()
    }

    // Close panel and return focus to previous app
    private static func dismissPanel() {
        for window in NSApp.windows where window.isVisible && window is NSPanel {
            window.orderOut(nil)
        }
        SharedState.shared.panelController?.activatePreviousApp()
    }
}
