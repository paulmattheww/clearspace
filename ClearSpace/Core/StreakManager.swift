import SwiftUI

/// Tracks cleanup sessions for gamification.
/// A "streak" increments each calendar day the user cleans photos.
@Observable
@MainActor
final class StreakManager {
    var currentStreak: Int = 0
    var totalCleanups: Int = 0
    var totalItemsCleaned: Int = 0
    var lastCleanupDate: Date?

    private static let streakKey = "clearspace.streak"
    private static let totalCleanupsKey = "clearspace.totalCleanups"
    private static let totalItemsKey = "clearspace.totalItemsCleaned"
    private static let lastCleanupKey = "clearspace.lastCleanupDate"

    init() {
        restore()
    }

    /// Call after a successful trash empty.
    func recordCleanup(itemCount: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDay = lastCleanupDate.map { Calendar.current.startOfDay(for: $0) }

        if let lastDay {
            let daysBetween = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if daysBetween == 1 {
                // Consecutive day — extend streak
                currentStreak += 1
            } else if daysBetween > 1 {
                // Streak broken
                currentStreak = 1
            }
            // Same day — don't change streak
        } else {
            // First cleanup ever
            currentStreak = 1
        }

        totalCleanups += 1
        totalItemsCleaned += itemCount
        lastCleanupDate = Date()
        save()
    }

    private func save() {
        UserDefaults.standard.set(currentStreak, forKey: Self.streakKey)
        UserDefaults.standard.set(totalCleanups, forKey: Self.totalCleanupsKey)
        UserDefaults.standard.set(totalItemsCleaned, forKey: Self.totalItemsKey)
        if let date = lastCleanupDate {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Self.lastCleanupKey)
        }
    }

    private func restore() {
        currentStreak = UserDefaults.standard.integer(forKey: Self.streakKey)
        totalCleanups = UserDefaults.standard.integer(forKey: Self.totalCleanupsKey)
        totalItemsCleaned = UserDefaults.standard.integer(forKey: Self.totalItemsKey)

        let ts = UserDefaults.standard.double(forKey: Self.lastCleanupKey)
        if ts > 0 {
            lastCleanupDate = Date(timeIntervalSince1970: ts)

            // Check if streak is still valid (not more than 1 day gap)
            let today = Calendar.current.startOfDay(for: Date())
            let lastDay = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: ts))
            let gap = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if gap > 1 {
                currentStreak = 0
                save()
            }
        }
    }
}
