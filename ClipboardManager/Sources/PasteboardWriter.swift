import AppKit

// Writes clipboard items back to NSPasteboard for pasting
@MainActor
struct PasteboardWriter {
    // Write item content back to the system clipboard
    static func write(_ item: ClipboardItem, monitor: ClipboardMonitor?) {
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

        // Sync monitor's changeCount so it skips this self-triggered change
        monitor?.syncChangeCount()
    }

    // Write plain text only (strips formatting)
    static func writePlainText(
        _ item: ClipboardItem, monitor: ClipboardMonitor?
    ) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(item.textContent ?? item.preview, forType: .string)
        monitor?.syncChangeCount()
    }
}
