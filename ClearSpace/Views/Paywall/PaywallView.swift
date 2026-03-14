import SwiftUI

/// Paywall shown when free users try to access the swipe UI or empty trash.
/// Designed for RevenueCat integration — currently a placeholder with pricing UI.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: Plan = .yearly

    enum Plan: String, CaseIterable {
        case weekly = "Weekly"
        case yearly = "Yearly"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Hero
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue.gradient)

                    Text("Unlock ClearSpace Pro")
                        .font(.title.bold())

                    Text("Clean unlimited photos and\nreclaim your storage")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)

                // Features
                VStack(alignment: .leading, spacing: 14) {
                    PaywallFeature(icon: "hand.tap.fill", text: "Unlimited swipe cleaning")
                    PaywallFeature(icon: "brain.head.profile.fill", text: "AI duplicate & blur detection")
                    PaywallFeature(icon: "bell.badge.fill", text: "Monthly cleanup reminders")
                    PaywallFeature(icon: "lock.shield.fill", text: "100% private, on-device")
                }
                .padding(.horizontal, 32)

                Spacer()

                // Plan selector
                VStack(spacing: 12) {
                    ForEach(Plan.allCases, id: \.self) { plan in
                        PlanCard(
                            plan: plan,
                            isSelected: selectedPlan == plan
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedPlan = plan
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)

                // CTA
                Button {
                    // TODO: RevenueCat purchase flow
                    // Packages.package(identifier: selectedPlan == .yearly ? "$rc_annual" : "$rc_weekly")
                    dismiss()
                } label: {
                    Text("Start Free Trial")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 24)

                Button("Restore Purchases") {
                    // TODO: RevenueCat restore
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text("Cancel anytime. No commitment.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 16)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Subviews

struct PaywallFeature: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct PlanCard: View {
    let plan: PaywallView.Plan
    let isSelected: Bool
    let onTap: () -> Void

    private var price: String {
        plan == .yearly ? "$29.99/year" : "$4.99/week"
    }

    private var savings: String? {
        plan == .yearly ? "Save 80%" : nil
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.rawValue)
                            .font(.headline)
                        if let savings {
                            Text(savings)
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.green.opacity(0.2), in: Capsule())
                                .foregroundStyle(.green)
                        }
                    }
                    Text(price)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
