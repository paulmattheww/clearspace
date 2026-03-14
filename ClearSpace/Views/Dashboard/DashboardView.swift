import SwiftUI

struct DashboardView: View {
    @Environment(PhotoManager.self) private var photoManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero storage card
                    StorageSummaryCard()

                    if photoManager.isScanning {
                        ScanningView(progress: photoManager.scanProgress, phase: photoManager.scanPhase)
                    } else {
                        // Category cards
                        VStack(spacing: 12) {
                            CategoryCard(
                                category: .screenshots,
                                count: photoManager.screenshots.count,
                                assets: photoManager.screenshots
                            )

                            CategoryCard(
                                category: .largeVideos,
                                count: photoManager.largeVideos.count,
                                assets: photoManager.largeVideos
                            )

                            // Placeholder cards for future phases
                            CategoryCard(
                                category: .blurryPhotos,
                                count: photoManager.blurryPhotos.count,
                                assets: photoManager.blurryPhotos
                            )

                            CategoryCard(
                                category: .duplicates,
                                count: photoManager.duplicates.count,
                                assets: photoManager.duplicates
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("ClearSpace")
            .refreshable {
                await photoManager.scanLibrary()
            }
        }
    }
}

// MARK: - Scanning Progress

struct ScanningView: View {
    let progress: Double
    let phase: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: progress)
                .tint(.blue)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.blue)
                Text(phase.isEmpty ? "Scanning your library..." : phase)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
