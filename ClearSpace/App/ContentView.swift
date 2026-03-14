import SwiftUI
import Photos

struct ContentView: View {
    @Environment(PhotoManager.self) private var photoManager

    var body: some View {
        Group {
            switch photoManager.authorizationStatus {
            case .notDetermined:
                PermissionView()
            case .authorized, .limited:
                MainTabView()
            case .denied, .restricted:
                SettingsRedirectView()
            @unknown default:
                PermissionView()
            }
        }
        .animation(.easeInOut, value: photoManager.authorizationStatus)
    }
}

// MARK: - Settings Redirect (when permission denied)

struct SettingsRedirectView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Photo Access Required")
                .font(.title2.bold())

            Text("ClearSpace needs access to your photos to find junk files. Please enable access in Settings.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}
