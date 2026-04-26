import Foundation
import Observation

// In-memory store for clipboard history items with search and eviction
@MainActor @Observable
final class ClipboardStore {
    var items: [ClipboardItem] = []
    var maxItems: Int = 500

    // Add item to front of list, deduplicate against last, evict if over limit
    func add(_ item: ClipboardItem) {
        // Deduplicate: skip if identical to most recent item
        if let last = items.first, last.hasSameContent(as: item) {
            return
        }
        items.insert(item, at: 0)
        // Evict oldest items beyond soft limit
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
    }

    func clear() {
        items.removeAll()
    }

    // Case-insensitive search across text content and previews
    func search(query: String) -> [ClipboardItem] {
        guard !query.isEmpty else { return items }
        let lowered = query.lowercased()
        return items.filter { item in
            if let text = item.textContent,
               text.lowercased().contains(lowered) {
                return true
            }
            if let html = item.htmlContent,
               html.lowercased().contains(lowered) {
                return true
            }
            if item.preview.lowercased().contains(lowered) {
                return true
            }
            return false
        }
    }
}
