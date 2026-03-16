import SwiftUI
import Photos

struct TrashView: View {
    @Environment(PhotoManager.self) private var photoManager
    @Environment(StreakManager.self) private var streakManager
    @State private var isDeleting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showConfirmation = false
    @State private var deletedCount = 0
    @State private var deletedBytes: Int64 = 0

    private var shareText: String {
        let sizeStr = ByteCountFormatter.string(fromByteCount: deletedBytes, countStyle: .file)
        return "I just cleaned \(deletedCount) junk photos and freed up \(sizeStr) on my iPhone with ClearSpace!"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if deletedCount > 0 && photoManager.trashQueue.isEmpty {
                    deletionSuccessView
                } else if photoManager.trashQueue.isEmpty {
                    emptyState
                } else {
                    trashContent
                }
            }
            .navigationTitle("Trash")
            .alert("Deletion Failed", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .confirmationDialog(
                "Delete \(photoManager.trashQueue.count) items permanently?",
                isPresented: $showConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) {
                    Task { await performDeletion() }
                }
            } message: {
                Text("This will move these items to your Recently Deleted album. You can recover them within 30 days.")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "trash.slash")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("Trash is Empty")
                .font(.title2.bold())

            Text("Swipe left on photos to mark them\nfor deletion, then come back here.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Deletion Success

    private var deletionSuccessView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green.gradient)
                .accessibilityHidden(true)

            Text("Cleaned!")
                .font(.title.bold())

            Text("Deleted **\(deletedCount) items** and freed up **\(ByteCountFormatter.string(fromByteCount: deletedBytes, countStyle: .file))**")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            // ShareLink directly in the view — not wrapped in a sheet
            ShareLink(item: shareText) {
                Label("Share Your Results", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Trash Content

    private var trashContent: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.red.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "trash.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)
            }
            .accessibilityHidden(true)

            Text("\(photoManager.trashQueue.count) Items")
                .font(.title.bold())
                .contentTransition(.numericText())
                .accessibilityLabel("\(photoManager.trashQueue.count) items in trash")

            Text("Ready to be permanently deleted")
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                showConfirmation = true
            } label: {
                HStack(spacing: 10) {
                    if isDeleting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "trash.fill")
                    }
                    Text(isDeleting ? "Deleting..." : "Empty Trash (\(photoManager.trashQueue.count) Items)")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(isDeleting)
            .padding(.horizontal, 24)
            .accessibilityHint("Permanently deletes all items in trash")

            Button("Remove All from Trash") {
                photoManager.trashQueue.removeAll()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.bottom, 24)
            .accessibilityHint("Removes items from trash without deleting them")
        }
    }

    // MARK: - Deletion

    private func performDeletion() async {
        let count = photoManager.trashQueue.count
        let identifiers = Array(photoManager.trashQueue)
        let fetched = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        var bytes: Int64 = 0
        fetched.enumerateObjects { asset, _, _ in
            bytes += PhotoManager.estimatedFileSize(for: asset)
        }

        isDeleting = true
        do {
            try await photoManager.emptyTrash()
            HapticManager.emptyTrash()
            streakManager.recordCleanup(itemCount: count)
            deletedCount = count
            deletedBytes = bytes
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isDeleting = false
    }
}
