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
    @State private var showTutorial = true
    @State private var sortOrder: SortOrder = .newest
    @State private var showTrashAllConfirm = false

    private let freeSwipeLimit = 5
    private let swipeThreshold: CGFloat = 100

    enum SwipeDirection {
        case left, right
    }

    enum SortOrder: String, CaseIterable {
        case newest = "Newest"
        case oldest = "Oldest"
        case largest = "Largest"
    }

    struct SwipeRecord {
        let index: Int
        let direction: SwipeDirection
    }

    private var sortedAssets: [PHAsset] {
        switch sortOrder {
        case .newest:
            return assets.sorted { ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast) }
        case .oldest:
            return assets.sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
        case .largest:
            return assets.sorted { PhotoManager.estimatedFileSize(for: $0) > PhotoManager.estimatedFileSize(for: $1) }
        }
    }

    private var isFreePreviewExhausted: Bool {
        !subscriptionManager.isPro && currentIndex >= freeSwipeLimit
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress header with undo
            SwipeProgressHeader(
                current: currentIndex,
                total: sortedAssets.count,
                trashCount: photoManager.trashQueue.count,
                canUndo: !swipeHistory.isEmpty,
                onUndo: undoLastSwipe
            )

            // Sort + Trash All toolbar
            if currentIndex < sortedAssets.count && !isFreePreviewExhausted {
                HStack {
                    // Sort picker
                    Menu {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Button {
                                sortOrder = order
                                currentIndex = 0
                                swipeHistory.removeAll()
                            } label: {
                                Label(order.rawValue, systemImage: sortOrder == order ? "checkmark" : "")
                            }
                        }
                    } label: {
                        Label(sortOrder.rawValue, systemImage: "arrow.up.arrow.down")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Free preview banner
                    if !subscriptionManager.isPro && currentIndex < freeSwipeLimit {
                        HStack(spacing: 4) {
                            Image(systemName: "gift.fill")
                            Text("\(freeSwipeLimit - currentIndex) free")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(.blue.opacity(0.1), in: Capsule())
                    }

                    Spacer()

                    // Trash All button
                    if subscriptionManager.isPro {
                        Button {
                            showTrashAllConfirm = true
                        } label: {
                            Label("Trash All", systemImage: "trash.fill")
                                .font(.caption.bold())
                                .foregroundStyle(.red)
                        }
                        .accessibilityHint("Mark all remaining items for deletion")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
            }

            // Card stack
            ZStack {
                if isFreePreviewExhausted {
                    freePreviewEndView
                } else if currentIndex < sortedAssets.count {
                    // Next card (underneath)
                    if currentIndex + 1 < sortedAssets.count {
                        SwipeCardView(asset: sortedAssets[currentIndex + 1], direction: nil)
                            .scaleEffect(0.95)
                            .opacity(0.5)
                    }

                    // Current card
                    SwipeCardView(asset: sortedAssets[currentIndex], direction: dragDirection)
                        .offset(dragOffset)
                        .rotationEffect(.degrees(Double(dragOffset.width / 20)))
                        .gesture(swipeGesture)
                        .animation(.interactiveSpring(response: 0.3), value: dragOffset)
                        .overlay {
                            if showTutorial && currentIndex == 0 {
                                SwipeTutorialOverlay {
                                    withAnimation { showTutorial = false }
                                }
                            }
                        }
                } else {
                    SwipeDoneView(trashCount: photoManager.trashQueue.count)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 20)

            // Action buttons
            if currentIndex < sortedAssets.count && !isFreePreviewExhausted {
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
        .confirmationDialog(
            "Trash all \(sortedAssets.count - currentIndex) remaining items?",
            isPresented: $showTrashAllConfirm,
            titleVisibility: .visible
        ) {
            Button("Trash All", role: .destructive) {
                trashAllRemaining()
            }
        } message: {
            Text("All remaining items will be added to your trash queue for batch deletion.")
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

            Text("You reviewed \(freeSwipeLimit) items and marked **\(photoManager.trashQueue.count)** for trash.\nUpgrade to swipe through all \(sortedAssets.count) items.")
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
                if showTutorial { showTutorial = false }
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
            photoManager.addToTrash(sortedAssets[currentIndex])
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

        if last.direction == .left {
            photoManager.removeFromTrash(identifier: sortedAssets[last.index].localIdentifier)
        }

        withAnimation(.spring(response: 0.3)) {
            currentIndex = last.index
            dragOffset = .zero
            dragDirection = nil
        }

        HapticManager.swipeKeep()
    }

    private func trashAllRemaining() {
        let remaining = sortedAssets.suffix(from: currentIndex)
        for asset in remaining {
            photoManager.addToTrash(asset)
        }
        currentIndex = sortedAssets.count
        HapticManager.swipeTrash()
    }
}

// MARK: - Swipe Tutorial Overlay

struct SwipeTutorialOverlay: View {
    let onDismiss: () -> Void

    @State private var arrowOffset: CGFloat = 0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.black.opacity(0.6))

            VStack(spacing: 24) {
                HStack(spacing: 40) {
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.left")
                            .font(.title.bold())
                            .offset(x: -arrowOffset)
                        Text("Trash")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.red)

                    VStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                            .font(.title.bold())
                            .offset(x: arrowOffset)
                        Text("Keep")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.green)
                }

                Text("Swipe or tap the buttons below")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))

                Button("Got it") {
                    onDismiss()
                }
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(.white.opacity(0.2), in: Capsule())
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                arrowOffset = 10
            }
        }
        .onTapGesture {
            onDismiss()
        }
        .accessibilityLabel("Swipe tutorial. Swipe left to trash, right to keep.")
        .accessibilityAddTraits(.isButton)
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
                .accessibilityLabel("Progress: \(current) of \(total)")

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
                    .accessibilityHint("Undo the last swipe")
                    .padding(.trailing, 8)
                }

                Label("\(trashCount)", systemImage: "trash.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.red)
                    .accessibilityLabel("\(trashCount) items in trash")
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
            .accessibilityLabel("Trash")
            .accessibilityHint("Mark this photo for deletion")

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
            .accessibilityLabel("Keep")
            .accessibilityHint("Keep this photo in your library")
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
                .accessibilityHidden(true)

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
