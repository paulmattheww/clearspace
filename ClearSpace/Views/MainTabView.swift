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
        }
        .tint(.blue)
        .task {
            if photoManager.screenshots.isEmpty && !photoManager.isScanning {
                await photoManager.scanLibrary()
            }
        }
    }
}
