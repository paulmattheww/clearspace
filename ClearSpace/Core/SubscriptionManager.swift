import SwiftUI

/// Tracks subscription state. Replace with RevenueCat in production.
@Observable
@MainActor
final class SubscriptionManager {
    var isPro = false

    /// Placeholder for RevenueCat initialization.
    /// In production: Purchases.shared.getCustomerInfo { info in ... }
    func checkSubscriptionStatus() async {
        // TODO: Replace with RevenueCat
        // let customerInfo = try? await Purchases.shared.customerInfo()
        // isPro = customerInfo?.entitlements["pro"]?.isActive ?? false
    }
}
