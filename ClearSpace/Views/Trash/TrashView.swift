import SwiftUI
import Photos

struct TrashView: View {
    @Environment(PhotoManager.self) private var photoManager
    @State private var isDeleting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if photoManager.trashQueue.isEmpty {
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

            Text("Trash is Empty")
                .font(.title2.bold())

            Text("Swipe left on photos to mark them\nfor deletion, then come back here.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Trash Content

    private var trashContent: some View {
        VStack(spacing: 20) {
            Spacer()

            // Trash icon with count
            ZStack {
                Circle()
                    .fill(.red.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "trash.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)
            }

            Text("\(photoManager.trashQueue.count) Items")
                .font(.title.bold())

            Text("Ready to be permanently deleted")
                .foregroundStyle(.secondary)

            Spacer()

            // THE BIG BUTTON — single batched deletion
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

            // Clear trash without deleting
            Button("Remove All from Trash") {
                photoManager.trashQueue.removeAll()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Deletion

    private func performDeletion() async {
        isDeleting = true
        do {
            try await photoManager.emptyTrash()
            HapticManager.emptyTrash()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isDeleting = false
    }
}
