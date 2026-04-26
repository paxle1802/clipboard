import AppKit
import Foundation

// Represents the type of content stored in a clipboard item
enum ClipboardContentType: String, Sendable {
    case text
    case image
    case rtf
    case html
    case fileURL
}

// A single clipboard history entry with all captured data
struct ClipboardItem: Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let contentType: ClipboardContentType
    let textContent: String?
    let imageData: Data? // compressed PNG/JPEG
    let thumbnailData: Data? // small thumbnail for list display
    let rtfData: Data?
    let htmlContent: String?
    let fileURLs: [URL]?

    // Short preview string for display in the list
    var preview: String {
        switch contentType {
        case .text:
            guard let text = textContent else { return "[Empty]" }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count <= 100 { return trimmed }
            return String(trimmed.prefix(100)) + "..."
        case .image:
            return "[Image]"
        case .rtf:
            if let data = rtfData,
               let attrStr = NSAttributedString(
                   rtf: data, documentAttributes: nil) {
                let plain = attrStr.string.trimmingCharacters(
                    in: .whitespacesAndNewlines)
                if plain.count <= 100 { return plain }
                return String(plain.prefix(100)) + "..."
            }
            return "[Rich Text]"
        case .html:
            guard let html = htmlContent else { return "[HTML]" }
            // Strip HTML tags for preview
            let stripped = html.replacingOccurrences(
                of: "<[^>]+>", with: "", options: .regularExpression)
            let trimmed = stripped.trimmingCharacters(
                in: .whitespacesAndNewlines)
            if trimmed.count <= 100 { return trimmed }
            return String(trimmed.prefix(100)) + "..."
        case .fileURL:
            guard let urls = fileURLs, !urls.isEmpty else {
                return "[File]"
            }
            if urls.count == 1 {
                return urls[0].lastPathComponent
            }
            return "\(urls[0].lastPathComponent) + \(urls.count - 1) more"
        }
    }

    // Check content equality for deduplication (ignores id/timestamp)
    func hasSameContent(as other: ClipboardItem) -> Bool {
        guard contentType == other.contentType else { return false }
        switch contentType {
        case .text: return textContent == other.textContent
        case .image: return imageData == other.imageData
        case .rtf: return rtfData == other.rtfData
        case .html: return htmlContent == other.htmlContent
        case .fileURL: return fileURLs == other.fileURLs
        }
    }
}
