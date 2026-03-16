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

            // Device storage gauge
            if photoManager.deviceTotalBytes > 0 {
                StorageGauge(
                    usedPercent: photoManager.deviceUsedPercent,
                    reclaimableBytes: photoManager.totalJunkBytes,
                    totalBytes: photoManager.deviceTotalBytes,
                    freeFormatted: photoManager.deviceFreeFormatted
                )
            }

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(photoManager.totalJunkFormatted) of recoverable space found. \(photoManager.totalJunkCount) junk items. \(photoManager.trashQueue.count) in trash.")
    }
}

// MARK: - Storage Gauge

struct StorageGauge: View {
    let usedPercent: Double
    let reclaimableBytes: Int64
    let totalBytes: Int64
    let freeFormatted: String

    private var reclaimablePercent: Double {
        guard totalBytes > 0, reclaimableBytes > 0 else { return 0 }
        let percent = Double(reclaimableBytes) / Double(totalBytes)
        // Clamp: don't show reclaimable as larger than used
        return min(percent, usedPercent)
    }

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background (total capacity)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))

                    // Used space
                    RoundedRectangle(cornerRadius: 6)
                        .fill(usedPercent > 0.85 ? Color.red.opacity(0.7) : Color.blue.opacity(0.5))
                        .frame(width: geo.size.width * min(usedPercent, 1.0))

                    // Reclaimable overlay (green section at the end of used bar)
                    if reclaimablePercent > 0 {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.green.opacity(0.6))
                            .frame(width: max(geo.size.width * reclaimablePercent, 4))
                            .offset(x: geo.size.width * (min(usedPercent, 1.0) - reclaimablePercent))
                    }
                }
            }
            .frame(height: 12)

            HStack {
                Text("\(freeFormatted) free")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                if reclaimableBytes > 0 {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green.opacity(0.6))
                            .frame(width: 8, height: 8)
                        Text("Reclaimable")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(freeFormatted) free storage. \(ByteCountFormatter.string(fromByteCount: reclaimableBytes, countStyle: .file)) reclaimable.")
    }
}

struct StatBadge: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold().monospacedDigit())
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
