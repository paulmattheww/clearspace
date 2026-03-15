import SwiftUI

struct MainTabView: View {
    @Environment(PhotoManager.self) private var photoManager

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.with.dots.needle.33percent")
                }

            TrashView()
                .tabItem {
                    Label("Trash", systemImage: "trash.fill")
                }
                .badge(photoManager.trashQueue.isEmpty ? 0 : photoManager.trashQueue.count)
        }
        .tint(.blue)
        .task {
            // Try to restore cached results first for instant UI
            if photoManager.totalJunkCount == 0 && !photoManager.isScanning {
                let restored = photoManager.restoreCachedScan()
                if !restored {
                    await photoManager.scanLibrary()
                }
            }
        }
    }
}
