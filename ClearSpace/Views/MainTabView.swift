import SwiftUI

struct MainTabView: View {
    @Environment(PhotoManager.self) private var photoManager

    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "gauge.with.dots.needle.33percent") {
                DashboardView()
            }

            Tab("Trash", systemImage: "trash.fill") {
                TrashView()
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
