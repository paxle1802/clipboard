import SwiftUI

// Main popup view — Apple glass liquid design with vibrancy and smooth animations
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
            // Header with glass search bar
            searchBar

            // Subtle separator
            Rectangle()
                .fill(.quaternary)
                .frame(height: 0.5)
                .padding(.horizontal, 16)

            // Item list or empty state
            if filteredItems.isEmpty {
                emptyState
            } else {
                itemList
            }

            // Glass footer
            footerBar
        }
        .frame(width: 340, height: 480)
        .background(.ultraThinMaterial)
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
            NSApp.keyWindow?.orderOut(nil)
            return .handled
        }
        .onChange(of: searchQuery) { _, _ in
            selectedIndex = nil
        }
    }

    // MARK: - Search bar with frosted glass effect

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            TextField("Search...", text: $searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
            if !searchQuery.isEmpty {
                Button(action: {
                    withAnimation(.easeOut(duration: 0.15)) {
                        searchQuery = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.white.opacity(0.06))
                .stroke(.white.opacity(0.08), lineWidth: 0.5)
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Empty state with subtle gradient icon

    private var emptyState: some View {
        VStack {
            Spacer()
            if store.items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clipboard")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.blue.opacity(0.6), .purple.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing))
                    Text("No clipboard history")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("Copy something to get started")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text("No results for \"\(searchQuery)\"")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    // MARK: - Item list with glass selection highlight

    private var itemList: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(
                        Array(filteredItems.enumerated()),
                        id: \.element.id
                    ) { index, item in
                        ClipboardItemRow(
                            item: item,
                            onDelete: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    store.remove(id: item.id)
                                }
                            }
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(selectedIndex == index
                                    ? Color.accentColor.opacity(0.15)
                                    : Color.clear)
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
                                withAnimation {
                                    store.remove(id: item.id)
                                }
                            }
                        }
                        .id(item.id)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
            }
            .onChange(of: selectedIndex) { _, newIndex in
                if let idx = newIndex, idx < filteredItems.count {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        scrollProxy.scrollTo(
                            filteredItems[idx].id, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Glass footer bar

    private var footerBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(.quaternary)
                .frame(height: 0.5)
                .padding(.horizontal, 16)

            HStack(spacing: 16) {
                // Item count with subtle pill badge
                HStack(spacing: 4) {
                    Text("\(store.items.count)")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.06))
                        )
                    Text("items")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                SettingsLink {
                    Image(systemName: "gear")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        store.clear()
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Keyboard navigation

    private func moveSelection(by offset: Int) {
        let count = filteredItems.count
        guard count > 0 else { return }
        withAnimation(.easeInOut(duration: 0.1)) {
            if let current = selectedIndex {
                selectedIndex = max(0, min(count - 1, current + offset))
            } else {
                selectedIndex = offset > 0 ? 0 : count - 1
            }
        }
    }

    private func pasteSelected() {
        guard let idx = selectedIndex, idx < filteredItems.count else {
            return
        }
        PasteboardWriter.pasteItem(filteredItems[idx], monitor: monitor)
    }
}
