import SwiftUI

// Single row in clipboard history — glass liquid style with hover effects
struct ClipboardItemRow: View {
    let item: ClipboardItem
    let onDelete: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Content type icon badge
            contentTypeIcon
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                )

            // Content preview
            VStack(alignment: .leading, spacing: 3) {
                contentPreview
                Text(RelativeTimeFormatter.string(from: item.timestamp))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Delete button — only visible on hover
            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    // Icon badge per content type with SF Symbol + gradient
    @ViewBuilder
    private var contentTypeIcon: some View {
        switch item.contentType {
        case .text:
            Image(systemName: "doc.text")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.blue)
        case .image:
            Image(systemName: "photo")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.purple)
        case .fileURL:
            Image(systemName: "folder")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.orange)
        case .rtf:
            Image(systemName: "doc.richtext")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.green)
        case .html:
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.pink)
        }
    }

    @ViewBuilder
    private var contentPreview: some View {
        switch item.contentType {
        case .text:
            Text(item.preview)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .lineLimit(2)
                .foregroundStyle(.primary)

        case .image:
            if let thumbData = item.thumbnailData,
               let nsImage = NSImage(data: thumbData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 3, y: 1)
            } else if let imgData = item.imageData,
                      let nsImage = NSImage(data: imgData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            } else {
                Text("[Image]")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .fileURL:
            Text(item.preview)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .foregroundStyle(.primary)

        case .rtf, .html:
            Text(item.preview)
                .font(.system(size: 12))
                .lineLimit(2)
                .foregroundStyle(.primary)
        }
    }
}
