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
                        // Last scanned info
                        if let lastScan = photoManager.lastScanDate {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundStyle(.tertiary)
                                Text("Scanned \(lastScan, style: .relative) ago")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                        }

                        // Category cards — sorted by item count
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
                    .accessibilityLabel("Settings")
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
        return all.sorted { $0.1 > $1.1 }
    }

    private var allCleanView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green.gradient)
                .accessibilityHidden(true)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Scanning: \(phase.isEmpty ? "in progress" : phase). \(Int(progress * 100))% complete")
    }
}
