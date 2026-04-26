import SwiftUI

// Single row in the clipboard history list showing content preview and metadata
struct ClipboardItemRow: View {
    let item: ClipboardItem
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            contentPreview
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 4) {
                Text(RelativeTimeFormatter.string(from: item.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var contentPreview: some View {
        switch item.contentType {
        case .text:
            Text(item.preview)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(2)
                .foregroundStyle(.primary)

        case .image:
            if let thumbData = item.thumbnailData,
               let nsImage = NSImage(data: thumbData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 60)
                    .cornerRadius(4)
            } else if let imgData = item.imageData,
                      let nsImage = NSImage(data: imgData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 60)
                    .cornerRadius(4)
            } else {
                Label("[Image]", systemImage: "photo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .fileURL:
            Label(item.preview, systemImage: "doc")
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(.primary)

        case .rtf, .html:
            Text(item.preview)
                .font(.caption)
                .lineLimit(2)
                .foregroundStyle(.primary)
        }
    }
}
