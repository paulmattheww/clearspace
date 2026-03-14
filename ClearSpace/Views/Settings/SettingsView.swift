import SwiftUI

struct SettingsView: View {
    @Environment(PhotoManager.self) private var photoManager
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Subscription status
                Section("Subscription") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(subscriptionManager.isPro ? "Pro" : "Free")
                            .foregroundStyle(subscriptionManager.isPro ? .green : .secondary)
                    }

                    if !subscriptionManager.isPro {
                        Button("Upgrade to Pro") {
                            // TODO: Show paywall
                        }
                    }

                    Button("Restore Purchases") {
                        // TODO: RevenueCat restore
                    }
                }

                // App info
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Processing")
                        Spacer()
                        Text("100% On-Device")
                            .foregroundStyle(.secondary)
                    }
                }

                // Debug section (only in debug builds)
                #if DEBUG
                Section("Developer") {
                    @Bindable var sm = subscriptionManager
                    Toggle("Dev Mode (Pro)", isOn: $sm.isDevModeEnabled)

                    Button("Clear Scan Cache") {
                        UserDefaults.standard.removeObject(forKey: "clearspace.scanCache")
                        UserDefaults.standard.removeObject(forKey: "clearspace.totalJunkBytes")
                    }

                    Button("Force Rescan") {
                        Task {
                            await photoManager.scanLibrary()
                        }
                    }

                    HStack {
                        Text("Cached Trash Items")
                        Spacer()
                        Text("\(photoManager.trashQueue.count)")
                            .foregroundStyle(.secondary)
                    }
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
