import SwiftUI
import Photos

struct SwipeCardView: View {
    @Environment(PhotoManager.self) private var photoManager

    let asset: PHAsset
    let direction: SwipeDeckView.SwipeDirection?

    @State private var thumbnail: UIImage?

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        ZStack(alignment: .bottom) {
            // Photo
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
                .overlay {
                    if let thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ProgressView()
                            .accessibilityLabel("Loading photo")
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))

            // Metadata bar
            HStack(spacing: 12) {
                if let date = asset.creationDate {
                    Label(Self.dateFormatter.string(from: date), systemImage: "calendar")
                }

                Spacer()

                let size = PhotoManager.estimatedFileSize(for: asset)
                if size > 0 {
                    Label(
                        ByteCountFormatter.string(fromByteCount: size, countStyle: .file),
                        systemImage: "internaldrive"
                    )
                }

                Text("\(asset.pixelWidth)\u{00D7}\(asset.pixelHeight)")
            }
            .font(.caption2)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial.opacity(0.8))
            .background(Color.black.opacity(0.4))
            .clipShape(
                .rect(bottomLeadingRadius: 20, bottomTrailingRadius: 20)
            )

            // Swipe overlay
            if let direction {
                RoundedRectangle(cornerRadius: 20)
                    .fill(overlayColor(for: direction).opacity(0.3))

                VStack {
                    Image(systemName: overlayIcon(for: direction))
                        .font(.system(size: 64, weight: .bold))
                        .foregroundStyle(overlayColor(for: direction))
                        .shadow(radius: 4)

                    Text(direction == .left ? "TRASH" : "KEEP")
                        .font(.title.bold())
                        .foregroundStyle(overlayColor(for: direction))
                }
            }
        }
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        .task(id: asset.localIdentifier) {
            thumbnail = await photoManager.loadThumbnail(for: asset)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var parts: [String] = ["Photo"]
        if let date = asset.creationDate {
            parts.append("from \(Self.dateFormatter.string(from: date))")
        }
        let size = PhotoManager.estimatedFileSize(for: asset)
        if size > 0 {
            parts.append(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
        }
        return parts.joined(separator: ", ")
    }

    private func overlayColor(for direction: SwipeDeckView.SwipeDirection) -> Color {
        direction == .left ? .red : .green
    }

    private func overlayIcon(for direction: SwipeDeckView.SwipeDirection) -> String {
        direction == .left ? "xmark.circle.fill" : "checkmark.circle.fill"
    }
}
