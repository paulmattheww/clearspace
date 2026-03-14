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
    var scanPhase: String = ""

    // MARK: - Junk Buckets

    var screenshots: [PHAsset] = []
    var largeVideos: [PHAsset] = []
    var blurryPhotos: [PHAsset] = []
    var duplicates: [PHAsset] = []

    // MARK: - Trash Queue (batched deletion, persisted across launches)

    var trashQueue: Set<String> = [] {
        didSet { persistTrashQueue() }
    }

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

        scanPhase = "Finding screenshots..."
        await scanScreenshots()
        scanProgress = 0.25

        scanPhase = "Checking large videos..."
        await scanLargeVideos()
        scanProgress = 0.50

        scanPhase = "Detecting blurry photos..."
        await scanBlurryPhotos()
        scanProgress = 0.75

        scanPhase = "Finding duplicates..."
        await scanDuplicates()
        scanProgress = 1.0
        scanPhase = ""

        cacheScanResults()
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
            let totalSize = Self.estimatedFileSize(for: asset)
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
            totalJunkBytes += Self.estimatedFileSize(for: asset)
        }
    }

    /// Estimates file size using the public PHAssetResource API.
    /// Falls back to a pixel-based estimate if resource metadata isn't available.
    static func estimatedFileSize(for asset: PHAsset) -> Int64 {
        let resources = PHAssetResource.assetResources(for: asset)
        var total: Int64 = 0
        for resource in resources {
            if let size = resource.value(forKey: "fileSize") as? Int64 {
                total += size
            }
        }
        if total > 0 { return total }

        // Fallback: estimate from pixel dimensions (~3 bytes per pixel for JPEG, ~6 for HEIC)
        let pixels = Int64(asset.pixelWidth) * Int64(asset.pixelHeight)
        if asset.mediaType == .video {
            return Int64(Double(asset.duration) * 2_000_000) // ~2MB/sec estimate
        }
        return pixels * 3
    }

    private func recalculateJunkBytes() {
        totalJunkBytes = 0
        let allJunk = screenshots + largeVideos + blurryPhotos + duplicates
        for asset in allJunk {
            totalJunkBytes += Self.estimatedFileSize(for: asset)
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
    /// Only clears trash queue and buckets after confirmed successful deletion.
    func emptyTrash() async throws {
        guard !trashQueue.isEmpty else { return }

        let identifiers = Array(trashQueue)
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)

        var assetsToDelete: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assetsToDelete.append(asset)
        }

        guard !assetsToDelete.isEmpty else {
            // Assets no longer exist (deleted via another app) — just clear the stale queue
            trashQueue.removeAll()
            return
        }

        // This triggers ONE iOS system permission dialog
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assetsToDelete as NSFastEnumeration)
        }

        // Only clear AFTER successful deletion
        let deletedIds = Set(assetsToDelete.map(\.localIdentifier))
        trashQueue.subtract(deletedIds)
        screenshots.removeAll { deletedIds.contains($0.localIdentifier) }
        largeVideos.removeAll { deletedIds.contains($0.localIdentifier) }
        blurryPhotos.removeAll { deletedIds.contains($0.localIdentifier) }
        duplicates.removeAll { deletedIds.contains($0.localIdentifier) }

        // Recalculate total junk bytes
        recalculateJunkBytes()

        persistTrashQueue()
    }

    // MARK: - Trash Queue Persistence

    private static let trashQueueKey = "clearspace.trashQueue"

    private func persistTrashQueue() {
        UserDefaults.standard.set(Array(trashQueue), forKey: Self.trashQueueKey)
    }

    private func restoreTrashQueue() {
        if let saved = UserDefaults.standard.stringArray(forKey: Self.trashQueueKey) {
            trashQueue = Set(saved)
        }
    }

    // MARK: - Scan Result Cache

    private static let scanCacheKey = "clearspace.scanCache"

    /// Persists scan result identifiers so cold starts don't require a full rescan.
    private func cacheScanResults() {
        let cache: [String: [String]] = [
            "screenshots": screenshots.map(\.localIdentifier),
            "largeVideos": largeVideos.map(\.localIdentifier),
            "blurryPhotos": blurryPhotos.map(\.localIdentifier),
            "duplicates": duplicates.map(\.localIdentifier),
        ]
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: Self.scanCacheKey)
        }
        UserDefaults.standard.set(totalJunkBytes, forKey: "clearspace.totalJunkBytes")
    }

    /// Restores cached scan results from a previous session.
    /// Returns true if cache was found and restored.
    func restoreCachedScan() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: Self.scanCacheKey),
              let cache = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            return false
        }

        let screenshotIds = cache["screenshots"] ?? []
        let videoIds = cache["largeVideos"] ?? []
        let blurryIds = cache["blurryPhotos"] ?? []
        let dupeIds = cache["duplicates"] ?? []

        // Only use cache if it has content
        guard !screenshotIds.isEmpty || !videoIds.isEmpty || !blurryIds.isEmpty || !dupeIds.isEmpty else {
            return false
        }

        // Re-fetch actual PHAssets from cached identifiers
        screenshots = Self.fetchAssets(identifiers: screenshotIds)
        largeVideos = Self.fetchAssets(identifiers: videoIds)
        blurryPhotos = Self.fetchAssets(identifiers: blurryIds)
        duplicates = Self.fetchAssets(identifiers: dupeIds)
        totalJunkBytes = Int64(UserDefaults.standard.integer(forKey: "clearspace.totalJunkBytes"))

        return totalJunkCount > 0
    }

    private static func fetchAssets(identifiers: [String]) -> [PHAsset] {
        guard !identifiers.isEmpty else { return [] }
        let result = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        var assets: [PHAsset] = []
        assets.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }

    // MARK: - Photo Library Change Observer

    private var changeObserver: LibraryChangeObserver?

    /// Start observing photo library changes to detect permission changes and deletions.
    func startObservingLibrary() {
        let observer = LibraryChangeObserver { [weak self] in
            Task { @MainActor in
                self?.authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            }
        }
        PHPhotoLibrary.shared().register(observer)
        changeObserver = observer
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

    // MARK: - Initialization

    init() {
        restoreTrashQueue()
    }
}

// MARK: - Library Change Observer

/// Bridges PHPhotoLibraryChangeObserver (ObjC protocol) to a Swift closure.
final class LibraryChangeObserver: NSObject, PHPhotoLibraryChangeObserver, Sendable {
    private let onChange: @Sendable () -> Void

    init(onChange: @escaping @Sendable () -> Void) {
        self.onChange = onChange
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        onChange()
    }
}
