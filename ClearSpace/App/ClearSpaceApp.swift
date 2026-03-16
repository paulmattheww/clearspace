import SwiftUI

@main
struct ClearSpaceApp: App {
    @State private var photoManager = PhotoManager()
    @State private var subscriptionManager = SubscriptionManager()
    @State private var streakManager = StreakManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(photoManager)
                .environment(subscriptionManager)
                .environment(streakManager)
                .task {
                    await subscriptionManager.checkSubscriptionStatus()
                    photoManager.startObservingLibrary()
                    await NotificationManager.scheduleMonthlyReview()
                }
        }
    }
}
