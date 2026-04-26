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

        // Use NSPasteboardItem for reliable multi-type writes
        let pbItem = NSPasteboardItem()

        switch item.contentType {
        case .text:
            if let text = item.textContent {
                pbItem.setString(text, forType: .string)
            }
        case .image:
            if let data = item.imageData {
                pbItem.setData(data, forType: .png)
            }
        case .rtf:
            if let data = item.rtfData {
                pbItem.setData(data, forType: .rtf)
            }
            if let text = item.textContent {
                pbItem.setString(text, forType: .string)
            }
        case .html:
            if let html = item.htmlContent {
                pbItem.setString(html, forType: .html)
            }
            if let text = item.textContent {
                pbItem.setString(text, forType: .string)
            }
        case .fileURL:
            if let urls = item.fileURLs {
                // File URLs need writeObjects, not NSPasteboardItem
                pb.writeObjects(urls as [NSURL])
                monitor?.syncChangeCount()
                monitor?.startMonitoring()
                NSLog("[ClipboardManager] Wrote \(urls.count) file URLs")
                return
            }
        }

        pb.writeObjects([pbItem])
        monitor?.syncChangeCount()
        monitor?.startMonitoring()
        NSLog("[ClipboardManager] Wrote \(item.contentType) to clipboard, changeCount=\(pb.changeCount)")
    }

    // Close panel and return focus to previous app
    private static func dismissPanel() {
        for window in NSApp.windows where window.isVisible && window is NSPanel {
            window.orderOut(nil)
        }
        SharedState.shared.panelController?.activatePreviousApp()
    }
}
