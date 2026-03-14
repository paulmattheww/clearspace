import SwiftUI

struct PermissionView: View {
    @Environment(PhotoManager.self) private var photoManager

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App icon / hero
            ZStack {
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 120, height: 120)

                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 12) {
                Text("ClearSpace")
                    .font(.largeTitle.bold())

                Text("Free up gigabytes of storage by\nswiping away junk photos")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Feature list
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "shield.checkmark.fill", color: .green,
                           title: "100% Private",
                           subtitle: "All analysis happens on your device")
                FeatureRow(icon: "hand.tap.fill", color: .blue,
                           title: "Swipe to Clean",
                           subtitle: "Tinder-style swiping makes it fun")
                FeatureRow(icon: "bolt.fill", color: .orange,
                           title: "Instant Results",
                           subtitle: "See exactly how much space you'll save")
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                Task {
                    await photoManager.requestAuthorization()
                }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)

            Text("We only need photo access to scan for junk.\nNothing leaves your device.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 24)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
