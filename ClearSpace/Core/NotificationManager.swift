import UserNotifications

/// Manages "Monthly Review" push notifications to retain users.
enum NotificationManager {

    /// Request notification permission and schedule monthly review reminder.
    static func scheduleMonthlyReview() async {
        let center = UNUserNotificationCenter.current()

        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
        }

        guard settings.authorizationStatus == .authorized else { return }

        // Remove old scheduled notifications
        center.removePendingNotificationRequests(withIdentifiers: ["monthly-review"])

        let content = UNMutableNotificationContent()
        content.title = "Time for a Cleanup!"
        content.body = "Your phone has been collecting new photos. Swipe through them and free up space."
        content.sound = .default

        // Trigger on the 1st of every month at 10am
        var dateComponents = DateComponents()
        dateComponents.day = 1
        dateComponents.hour = 10
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "monthly-review", content: content, trigger: trigger)

        try? await center.add(request)
    }
}
