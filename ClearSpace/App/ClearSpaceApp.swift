import SwiftUI

@main
struct ClearSpaceApp: App {
    @State private var photoManager = PhotoManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(photoManager)
        }
    }
}
