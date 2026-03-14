import SwiftUI

@main
struct ClearSpaceApp: App {
    @State private var photoManager = PhotoManager()
    @State private var subscriptionManager = SubscriptionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(photoManager)
                .environment(subscriptionManager)
                .task {
                    await subscriptionManager.checkSubscriptionStatus()
                    photoManager.startObservingLibrary()
                    await NotificationManager.scheduleMonthlyReview()
                }
        }
    }
}
