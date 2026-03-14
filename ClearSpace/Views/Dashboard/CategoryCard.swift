import SwiftUI
import Photos

struct CategoryCard: View {
    let category: JunkCategory
    let count: Int
    let assets: [PHAsset]

    var body: some View {
        NavigationLink {
            SwipeDeckView(category: category, assets: assets)
        } label: {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(category.color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: category.icon)
                        .font(.title3)
                        .foregroundStyle(category.color)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.rawValue)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(category.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Count badge
                if count > 0 {
                    Text("\(count)")
                        .font(.subheadline.bold().monospacedDigit())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(category.color.opacity(0.15), in: Capsule())
                        .foregroundStyle(category.color)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .disabled(count == 0)
    }
}
