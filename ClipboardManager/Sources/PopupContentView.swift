import SwiftUI

// Main popup view shown when clicking the menu bar icon
struct PopupContentView: View {
    let store: ClipboardStore
    var monitor: ClipboardMonitor?

    @State private var searchQuery = ""
    @State private var selectedIndex: Int? = nil

    private var filteredItems: [ClipboardItem] {
        store.search(query: searchQuery)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                TextField("Search clipboard history...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .default))
                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)

            Divider()

            // Item list
            if filteredItems.isEmpty {
                Spacer()
                if store.items.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "clipboard")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No clipboard history yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Copy something to get started")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                } else {
                    Text("No matches for \"\(searchQuery)\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(
                                Array(filteredItems.enumerated()),
                                id: \.element.id
                            ) { index, item in
                                ClipboardItemRow(
                                    item: item,
                                    onDelete: { store.remove(id: item.id) }
                                )
                                .background(
                                    selectedIndex == index
                                        ? Color.accentColor.opacity(0.15)
                                        : Color.clear
                                )
                                .onTapGesture {
                                    PasteboardWriter.pasteItem(
                                        item, monitor: monitor)
                                }
                                .contextMenu {
                                    Button("Paste") {
                                        PasteboardWriter.pasteItem(
                                            item, monitor: monitor)
                                    }
                                    Button("Copy to Clipboard") {
                                        PasteboardWriter.copyItem(
                                            item, monitor: monitor)
                                    }
                                    Button("Paste as Plain Text") {
                                        PasteboardWriter.pasteItemAsPlainText(
                                            item, monitor: monitor)
                                    }
                                    Divider()
                                    Button("Delete") {
                                        store.remove(id: item.id)
                                    }
                                }
                                .id(item.id)

                                if index < filteredItems.count - 1 {
                                    Divider().padding(.horizontal, 10)
                                }
                            }
                        }
                    }
                    .onChange(of: selectedIndex) { _, newIndex in
                        if let idx = newIndex, idx < filteredItems.count {
                            withAnimation {
                                scrollProxy.scrollTo(
                                    filteredItems[idx].id, anchor: .center)
                            }
                        }
                    }
                }
            }

            Divider()

            // Footer
            HStack {
                Text("\(store.items.count) items")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                SettingsLink {
                    Text("Settings...")
                }
                .font(.caption2)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                Spacer()
                    .frame(width: 12)
                Button("Clear All") {
                    store.clear()
                }
                .font(.caption2)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .frame(width: 320, height: 450)
        .onKeyPress(.upArrow) {
            moveSelection(by: -1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(by: 1)
            return .handled
        }
        .onKeyPress(.return) {
            pasteSelected()
            return .handled
        }
        .onKeyPress(.escape) {
            if !searchQuery.isEmpty {
                searchQuery = ""
                return .handled
            }
            // Close the panel
            NSApp.keyWindow?.orderOut(nil)
            return .handled
        }
        .onChange(of: searchQuery) { _, _ in
            // Reset selection when search changes to avoid stale index
            selectedIndex = nil
        }
    }

    private func moveSelection(by offset: Int) {
        let count = filteredItems.count
        guard count > 0 else { return }
        if let current = selectedIndex {
            selectedIndex = max(0, min(count - 1, current + offset))
        } else {
            selectedIndex = offset > 0 ? 0 : count - 1
        }
    }

    private func pasteSelected() {
        guard let idx = selectedIndex, idx < filteredItems.count else {
            return
        }
        PasteboardWriter.pasteItem(filteredItems[idx], monitor: monitor)
    }
}
