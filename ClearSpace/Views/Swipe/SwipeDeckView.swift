import SwiftUI
import Photos

struct SwipeDeckView: View {
    @Environment(PhotoManager.self) private var photoManager
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.dismiss) private var dismiss

    let category: JunkCategory
    let assets: [PHAsset]

    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var dragDirection: SwipeDirection? = nil
    @State private var isSwiping = false
    @State private var swipeHistory: [SwipeRecord] = []
    @State private var showPaywall = false

    /// Number of free swipes before paywall (free preview)
    private let freeSwipeLimit = 5

    private let swipeThreshold: CGFloat = 100

    enum SwipeDirection {
        case left, right
    }

    struct SwipeRecord {
        let index: Int
        let direction: SwipeDirection
    }

    private var isFreePreviewExhausted: Bool {
        !subscriptionManager.isPro && currentIndex >= freeSwipeLimit
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress header with undo
            SwipeProgressHeader(
                current: currentIndex,
                total: assets.count,
                trashCount: photoManager.trashQueue.count,
                canUndo: !swipeHistory.isEmpty,
                onUndo: undoLastSwipe
            )

            // Free preview banner
            if !subscriptionManager.isPro && currentIndex < freeSwipeLimit && currentIndex < assets.count {
                HStack(spacing: 6) {
                    Image(systemName: "gift.fill")
                    Text("Free preview: \(freeSwipeLimit - currentIndex) swipes remaining")
                }
                .font(.caption.bold())
                .foregroundStyle(.blue)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(.blue.opacity(0.1), in: Capsule())
                .padding(.bottom, 4)
            }

            // Card stack
            ZStack {
                if isFreePreviewExhausted {
                    freePreviewEndView
                } else if currentIndex < assets.count {
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
                    SwipeDoneView(trashCount: photoManager.trashQueue.count)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 20)

            // Action buttons
            if currentIndex < assets.count && !isFreePreviewExhausted {
                SwipeActionButtons(
                    onTrash: { performSwipe(.left) },
                    onKeep: { performSwipe(.right) }
                )
                .padding(.bottom, 20)
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Free Preview End

    private var freePreviewEndView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange.gradient)

            Text("Free Preview Complete")
                .font(.title2.bold())

            Text("You reviewed \(freeSwipeLimit) items and marked **\(photoManager.trashQueue.count)** for trash.\nUpgrade to swipe through all \(assets.count) items.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            Button {
                showPaywall = true
            } label: {
                Text("Unlock Unlimited Swiping")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
        }
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
        guard !isSwiping else { return }
        isSwiping = true

        let exitX: CGFloat = direction == .left ? -500 : 500

        withAnimation(.easeIn(duration: 0.2)) {
            dragOffset = CGSize(width: exitX, height: 0)
        }

        swipeHistory.append(SwipeRecord(index: currentIndex, direction: direction))

        if direction == .left {
            photoManager.addToTrash(assets[currentIndex])
            HapticManager.swipeTrash()
        } else {
            HapticManager.swipeKeep()
        }

        Task {
            try? await Task.sleep(for: .milliseconds(250))
            dragOffset = .zero
            dragDirection = nil
            currentIndex += 1
            isSwiping = false
        }
    }

    private func undoLastSwipe() {
        guard let last = swipeHistory.popLast() else { return }

        // If it was trashed, remove from trash
        if last.direction == .left {
            photoManager.removeFromTrash(identifier: assets[last.index].localIdentifier)
        }

        withAnimation(.spring(response: 0.3)) {
            currentIndex = last.index
            dragOffset = .zero
            dragDirection = nil
        }

        HapticManager.swipeKeep()
    }
}

// MARK: - Progress Header

struct SwipeProgressHeader: View {
    let current: Int
    let total: Int
    let trashCount: Int
    let canUndo: Bool
    let onUndo: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: Double(current), total: max(Double(total), 1))
                .tint(.blue)

            HStack {
                Text("\(current) / \(total)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                Spacer()

                if canUndo {
                    Button(action: onUndo) {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                    }
                    .padding(.trailing, 8)
                }

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
        .onAppear {
            HapticManager.emptyTrash()
        }
    }
}
