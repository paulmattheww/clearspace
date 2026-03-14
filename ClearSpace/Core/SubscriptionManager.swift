import SwiftUI

/// Tracks subscription state. Replace with RevenueCat in production.
@Observable
@MainActor
final class SubscriptionManager {
    var isPro = false

    #if DEBUG
    /// Dev mode: toggle Pro status for testing the full flow without RevenueCat.
    var isDevModeEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "clearspace.devModePro") }
        set {
            UserDefaults.standard.set(newValue, forKey: "clearspace.devModePro")
            isPro = newValue
        }
    }
    #endif

    /// Placeholder for RevenueCat initialization.
    /// In production: Purchases.shared.getCustomerInfo { info in ... }
    func checkSubscriptionStatus() async {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "clearspace.devModePro") {
            isPro = true
            return
        }
        #endif

        // TODO: Replace with RevenueCat
        // let customerInfo = try? await Purchases.shared.customerInfo()
        // isPro = customerInfo?.entitlements["pro"]?.isActive ?? false
    }
}
