import UserNotifications

/// Manages "Monthly Review" push notifications to retain users.
enum NotificationManager {

    /// Request notification permission and schedule monthly review reminder.
    static func scheduleMonthlyReview() async {
        let center = UNUserNotificationCenter.current()

        // Request authorization FIRST if not yet determined
        let initialSettings = await center.notificationSettings()
        if initialSettings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
        }

        // Re-check FRESH settings after potential authorization
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        // Remove old scheduled notifications
        center.removePendingNotificationRequests(withIdentifiers: ["monthly-review"])

        let content = UNMutableNotificationContent()
        content.title = "Time for a Cleanup!"
        content.body = "Your phone has been collecting new photos. Swipe through them and free up space."
        content.sound = .default

        // Trigger on the 1st of every month at 10am LOCAL time
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        dateComponents.timeZone = TimeZone.current
        dateComponents.day = 1
        dateComponents.hour = 10
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "monthly-review", content: content, trigger: trigger)

        try? await center.add(request)
    }
}
