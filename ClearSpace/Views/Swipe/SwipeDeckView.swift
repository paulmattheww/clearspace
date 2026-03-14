import SwiftUI
import Photos

struct SwipeDeckView: View {
    @Environment(PhotoManager.self) private var photoManager
    @Environment(\.dismiss) private var dismiss

    let category: JunkCategory
    let assets: [PHAsset]

    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var dragDirection: SwipeDirection? = nil

    private let swipeThreshold: CGFloat = 100

    enum SwipeDirection {
        case left, right
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress header
            SwipeProgressHeader(
                current: currentIndex,
                total: assets.count,
                trashCount: photoManager.trashQueue.count
            )

            // Card stack
            ZStack {
                if currentIndex < assets.count {
                    // Next card (underneath)
                    if currentIndex + 1 < assets.count {
                        SwipeCardView(asset: assets[currentIndex + 1], direction: nil)
                            .scaleEffect(0.95)
                            .opacity(0.5)
                    }

                    // Current card
                    SwipeCardView(asset: assets[currentIndex], direction: dragDirection)
                        .offset(dragOffset)
                        .rotationEffect(.degrees(Double(dragOffset.width / 20)))
                        .gesture(swipeGesture)
                        .animation(.interactiveSpring(response: 0.3), value: dragOffset)
                } else {
                    // Done state
                    SwipeDoneView(trashCount: photoManager.trashQueue.count)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 20)

            // Action buttons
            if currentIndex < assets.count {
                SwipeActionButtons(
                    onTrash: { performSwipe(.left) },
                    onKeep: { performSwipe(.right) }
                )
                .padding(.bottom, 20)
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Gesture

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                if value.translation.width > 30 {
                    dragDirection = .right
                } else if value.translation.width < -30 {
                    dragDirection = .left
                } else {
                    dragDirection = nil
                }
            }
            .onEnded { value in
                if value.translation.width < -swipeThreshold {
                    performSwipe(.left)
                } else if value.translation.width > swipeThreshold {
                    performSwipe(.right)
                } else {
                    withAnimation(.spring(response: 0.3)) {
                        dragOffset = .zero
                        dragDirection = nil
                    }
                }
            }
    }

    // MARK: - Actions

    private func performSwipe(_ direction: SwipeDirection) {
        let exitX: CGFloat = direction == .left ? -500 : 500

        withAnimation(.easeIn(duration: 0.2)) {
            dragOffset = CGSize(width: exitX, height: 0)
        }

        if direction == .left {
            photoManager.addToTrash(assets[currentIndex])
            HapticManager.swipeTrash()
        } else {
            HapticManager.swipeKeep()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            dragOffset = .zero
            dragDirection = nil
            currentIndex += 1
        }
    }
}

// MARK: - Progress Header

struct SwipeProgressHeader: View {
    let current: Int
    let total: Int
    let trashCount: Int

    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: Double(current), total: max(Double(total), 1))
                .tint(.blue)

            HStack {
                Text("\(current) / \(total)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                Spacer()

                Label("\(trashCount)", systemImage: "trash.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

// MARK: - Action Buttons

struct SwipeActionButtons: View {
    let onTrash: () -> Void
    let onKeep: () -> Void

    var body: some View {
        HStack(spacing: 48) {
            Button(action: onTrash) {
                ZStack {
                    Circle()
                        .fill(.red.opacity(0.15))
                        .frame(width: 64, height: 64)
                    Image(systemName: "trash.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
            }

            Button(action: onKeep) {
                ZStack {
                    Circle()
                        .fill(.green.opacity(0.15))
                        .frame(width: 64, height: 64)
                    Image(systemName: "checkmark")
                        .font(.title2.bold())
                        .foregroundStyle(.green)
                }
            }
        }
    }
}

// MARK: - Done View

struct SwipeDoneView: View {
    let trashCount: Int

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(.blue.gradient)

            Text("All Done!")
                .font(.title.bold())

            if trashCount > 0 {
                Text("You marked **\(trashCount) items** for deletion.\nHead to the Trash tab to clear them.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            } else {
                Text("Everything looks clean!")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
