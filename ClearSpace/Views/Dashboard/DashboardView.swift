import SwiftUI
import Photos

struct DashboardView: View {
    @Environment(PhotoManager.self) private var photoManager
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero storage card
                    StorageSummaryCard()

                    if photoManager.isScanning {
                        ScanningView(progress: photoManager.scanProgress, phase: photoManager.scanPhase)
                    } else {
                        // Category cards — only show categories with items
                        VStack(spacing: 12) {
                            ForEach(categoryEntries, id: \.category) { entry in
                                CategoryCard(
                                    category: entry.category,
                                    count: entry.count,
                                    assets: entry.assets
                                )
                            }

                            if categoryEntries.allSatisfy({ $0.count == 0 }) {
                                allCleanView
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("ClearSpace")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .refreshable {
                await photoManager.scanLibrary()
            }
        }
    }

    private var categoryEntries: [(category: JunkCategory, count: Int, assets: [PHAsset])] {
        let all: [(JunkCategory, Int, [PHAsset])] = [
            (.screenshots, photoManager.screenshots.count, photoManager.screenshots),
            (.largeVideos, photoManager.largeVideos.count, photoManager.largeVideos),
            (.blurryPhotos, photoManager.blurryPhotos.count, photoManager.blurryPhotos),
            (.duplicates, photoManager.duplicates.count, photoManager.duplicates),
        ]
        // Show categories with items first, then empty ones
        return all.sorted { $0.1 > $1.1 }
    }

    private var allCleanView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green.gradient)
            Text("Your library is clean!")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 32)
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
