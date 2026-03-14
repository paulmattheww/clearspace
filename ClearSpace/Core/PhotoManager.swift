import SwiftUI
import Photos

/// The core engine. Manages photo library access, scanning, and batched deletion.
/// Uses PHFetchResult (lazy-loading) to avoid OOM on large libraries.
@Observable
@MainActor
final class PhotoManager {

    // MARK: - Authorization

    var authorizationStatus: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

    // MARK: - Scan State

    var isScanning = false
    var scanProgress: Double = 0

    // MARK: - Junk Buckets

    var screenshots: [PHAsset] = []
    var largeVideos: [PHAsset] = []
    var blurryPhotos: [PHAsset] = []
    var duplicates: [PHAsset] = []

    // MARK: - Trash Queue (batched deletion)

    var trashQueue: Set<String> = []  // Store localIdentifiers, not PHAsset directly

    // MARK: - Storage Stats

    var totalJunkBytes: Int64 = 0
    var totalJunkFormatted: String {
        ByteCountFormatter.string(fromByteCount: totalJunkBytes, countStyle: .file)
    }

    var totalJunkCount: Int {
        screenshots.count + largeVideos.count + blurryPhotos.count + duplicates.count
    }

    // MARK: - Analyzers

    private let analyzer = PhotoAnalyzer()

    // MARK: - Image Loading

    private let cachingManager = PHCachingImageManager()
    static let thumbnailSize = CGSize(width: 300, height: 300)

    // MARK: - Authorization

    func requestAuthorization() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status
        if status == .authorized || status == .limited {
            await scanLibrary()
        }
    }

    // MARK: - Library Scan

    func scanLibrary() async {
        guard !isScanning else { return }
        isScanning = true
        scanProgress = 0

        // Reset buckets
        screenshots = []
        largeVideos = []
        blurryPhotos = []
        duplicates = []
        totalJunkBytes = 0

        // Phase 1: Screenshots (fast, metadata-only)
        await scanScreenshots()
        scanProgress = 0.25

        // Phase 2: Large videos (fast, metadata-only)
        await scanLargeVideos()
        scanProgress = 0.50

        // Phase 3: Blurry photos (CoreImage analysis)
        await scanBlurryPhotos()
        scanProgress = 0.75

        // Phase 4: Duplicates (Vision framework)
        await scanDuplicates()
        scanProgress = 1.0

        isScanning = false
    }

    private func scanScreenshots() async {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaSubtypes & %d != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let results = PHAsset.fetchAssets(with: .image, options: options)
        var batch: [PHAsset] = []
        batch.reserveCapacity(min(results.count, 5000))

        results.enumerateObjects { asset, _, _ in
            batch.append(asset)
        }

        screenshots = batch
        await accumulateFileSize(for: batch)
    }

    private func scanLargeVideos() async {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let results = PHAsset.fetchAssets(with: .video, options: options)
        var batch: [PHAsset] = []

        // Filter videos > 50MB by checking resource file sizes
        results.enumerateObjects { asset, _, _ in
            let resources = PHAssetResource.assetResources(for: asset)
            let totalSize = resources.compactMap { $0.value(forKey: "fileSize") as? Int64 }.reduce(0, +)
            if totalSize > 50_000_000 { // 50MB threshold
                batch.append(asset)
            }
        }

        largeVideos = batch
        await accumulateFileSize(for: batch)
    }

    private func scanBlurryPhotos() async {
        // Analyze recent photos (last 500) for blur — keeps scan time reasonable
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = 500
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let results = PHAsset.fetchAssets(with: .image, options: options)
        var candidates: [PHAsset] = []
        results.enumerateObjects { asset, _, _ in
            // Skip screenshots — they're already categorized
            if !asset.mediaSubtypes.contains(.photoScreenshot) {
                candidates.append(asset)
            }
        }

        blurryPhotos = await analyzer.detectBlurryPhotos(from: candidates)
        await accumulateFileSize(for: blurryPhotos)
    }

    private func scanDuplicates() async {
        // Analyze recent photos for duplicates
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = 500
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let results = PHAsset.fetchAssets(with: .image, options: options)
        var candidates: [PHAsset] = []
        results.enumerateObjects { asset, _, _ in
            candidates.append(asset)
        }

        duplicates = await analyzer.detectDuplicates(from: candidates)
        await accumulateFileSize(for: duplicates)
    }

    private func accumulateFileSize(for assets: [PHAsset]) async {
        for asset in assets {
            let resources = PHAssetResource.assetResources(for: asset)
            let size = resources.compactMap { $0.value(forKey: "fileSize") as? Int64 }.reduce(0, +)
            totalJunkBytes += size
        }
    }

    // MARK: - Trash Management

    func addToTrash(_ asset: PHAsset) {
        trashQueue.insert(asset.localIdentifier)
    }

    func removeFromTrash(_ asset: PHAsset) {
        trashQueue.remove(asset.localIdentifier)
    }

    func isInTrash(_ asset: PHAsset) -> Bool {
        trashQueue.contains(asset.localIdentifier)
    }

    /// Batched deletion — triggers ONE system permission dialog for all items.
    func emptyTrash() async throws {
        guard !trashQueue.isEmpty else { return }

        let identifiers = Array(trashQueue)
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)

        var assetsToDelete: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assetsToDelete.append(asset)
        }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assetsToDelete as NSFastEnumeration)
        }

        // Clear the trash and remove deleted items from buckets
        let deletedIds = trashQueue
        trashQueue.removeAll()
        screenshots.removeAll { deletedIds.contains($0.localIdentifier) }
        largeVideos.removeAll { deletedIds.contains($0.localIdentifier) }
        blurryPhotos.removeAll { deletedIds.contains($0.localIdentifier) }
        duplicates.removeAll { deletedIds.contains($0.localIdentifier) }
    }

    // MARK: - Image Loading (Memory-Safe)

    func loadThumbnail(for asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isNetworkAccessAllowed = false
            options.resizeMode = .fast

            cachingManager.requestImage(
                for: asset,
                targetSize: Self.thumbnailSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}
