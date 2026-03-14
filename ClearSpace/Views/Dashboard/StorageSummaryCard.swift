import SwiftUI

struct StorageSummaryCard: View {
    @Environment(PhotoManager.self) private var photoManager

    var body: some View {
        VStack(spacing: 16) {
            // Animated junk size
            Text(photoManager.totalJunkFormatted)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.red.gradient)
                .contentTransition(.numericText())

            Text("of recoverable space found")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 24) {
                StatBadge(
                    value: "\(photoManager.totalJunkCount)",
                    label: "Junk Items"
                )
                StatBadge(
                    value: "\(photoManager.trashQueue.count)",
                    label: "In Trash"
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
    }
}

struct StatBadge: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold().monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
