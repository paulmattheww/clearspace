import SwiftUI
import Photos

struct SwipeCardView: View {
    @Environment(PhotoManager.self) private var photoManager

    let asset: PHAsset
    let direction: SwipeDeckView.SwipeDirection?

    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack {
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
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))

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
    }

    private func overlayColor(for direction: SwipeDeckView.SwipeDirection) -> Color {
        direction == .left ? .red : .green
    }

    private func overlayIcon(for direction: SwipeDeckView.SwipeDirection) -> String {
        direction == .left ? "xmark.circle.fill" : "checkmark.circle.fill"
    }
}
