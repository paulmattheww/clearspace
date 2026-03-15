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

    /// Device free space in bytes, updated on scan.
    var deviceFreeBytes: Int64 = 0
    var deviceTotalBytes: Int64 = 0

    var deviceFreeFormatted: String {
        ByteCountFormatter.string(fromByteCount: deviceFreeBytes, countStyle: .file)
    }

    var deviceUsedPercent: Double {
        guard deviceTotalBytes > 0 else { return 0 }
        return Double(deviceTotalBytes - deviceFreeBytes) / Double(deviceTotalBytes)
    }

    // MARK: - Analyzers

    private let analyzer = PhotoAnalyzer()

    // MARK: - Image Loading

    private let cachingManager = PHCachingImageManager()
    static let thumbnailSize = CGSize(width: 300, height: 300)

    // MARK: - Authorization

    /// Requests read-only access for scanning. Write access is escalated at deletion time.
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

        // Snapshot device storage
        refreshDeviceStorage()

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

        // Validate trash queue — remove stale IDs that no longer exist in library
        validateTrashQueue()

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
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = 500
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let results = PHAsset.fetchAssets(with: .image, options: options)
        var candidates: [PHAsset] = []
        results.enumerateObjects { asset, _, _ in
            if !asset.mediaSubtypes.contains(.photoScreenshot) {
                candidates.append(asset)
            }
        }

        blurryPhotos = await analyzer.detectBlurryPhotos(from: candidates)
        await accumulateFileSize(for: blurryPhotos)
    }

    private func scanDuplicates() async {
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

    /// Estimates file size using PHAssetResource metadata.
    /// Falls back to a pixel/duration-based estimate if metadata isn't available.
    static func estimatedFileSize(for asset: PHAsset) -> Int64 {
        let resources = PHAssetResource.assetResources(for: asset)
        var total: Int64 = 0
        for resource in resources {
            if let size = resource.value(forKey: "fileSize") as? Int64 {
                total += size
            }
        }
        if total > 0 { return total }

        // Fallback estimates
        if asset.mediaType == .video {
            return Int64(Double(asset.duration) * 2_000_000) // ~2MB/sec
        }
        let pixels = Int64(asset.pixelWidth) * Int64(asset.pixelHeight)
        return pixels * 3 // ~3 bytes/pixel JPEG estimate
    }

    private func recalculateJunkBytes() {
        totalJunkBytes = 0
        let allJunk = screenshots + largeVideos + blurryPhotos + duplicates
        for asset in allJunk {
            totalJunkBytes += Self.estimatedFileSize(for: asset)
        }
    }

    // MARK: - Device Storage

    func refreshDeviceStorage() {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let freeSpace = attrs[.systemFreeSize] as? Int64,
              let totalSpace = attrs[.systemSize] as? Int64 else { return }
        deviceFreeBytes = freeSpace
        deviceTotalBytes = totalSpace
    }

    // MARK: - Trash Management

    func addToTrash(_ asset: PHAsset) {
        trashQueue.insert(asset.localIdentifier)
    }

    func removeFromTrash(_ asset: PHAsset) {
        trashQueue.remove(asset.localIdentifier)
    }

    func removeFromTrash(identifier: String) {
        trashQueue.remove(identifier)
    }

    func isInTrash(_ asset: PHAsset) -> Bool {
        trashQueue.contains(asset.localIdentifier)
    }

    /// Validates trash queue by removing IDs for assets that no longer exist.
    private func validateTrashQueue() {
        guard !trashQueue.isEmpty else { return }
        let fetched = PHAsset.fetchAssets(withLocalIdentifiers: Array(trashQueue), options: nil)
        var validIds = Set<String>()
        fetched.enumerateObjects { asset, _, _ in
            validIds.insert(asset.localIdentifier)
        }
        let staleCount = trashQueue.count - validIds.count
        if staleCount > 0 {
            trashQueue = validIds
        }
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
            trashQueue.removeAll()
            return
        }

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

        recalculateJunkBytes()
        refreshDeviceStorage()
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
    private static let scanCacheTimestampKey = "clearspace.scanCacheTimestamp"

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
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.scanCacheTimestampKey)
    }

    func invalidateScanCache() {
        UserDefaults.standard.removeObject(forKey: Self.scanCacheKey)
        UserDefaults.standard.removeObject(forKey: "clearspace.totalJunkBytes")
        UserDefaults.standard.removeObject(forKey: Self.scanCacheTimestampKey)
    }

    /// Restores cached scan results from a previous session.
    /// Returns true if cache was found, is fresh, and restored.
    func restoreCachedScan() -> Bool {
        // Invalidate cache older than 7 days
        let timestamp = UserDefaults.standard.double(forKey: Self.scanCacheTimestampKey)
        if timestamp > 0 {
            let cacheAge = Date().timeIntervalSince1970 - timestamp
            if cacheAge > 7 * 24 * 3600 {
                invalidateScanCache()
                return false
            }
        }

        guard let data = UserDefaults.standard.data(forKey: Self.scanCacheKey),
              let cache = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            return false
        }

        let screenshotIds = cache["screenshots"] ?? []
        let videoIds = cache["largeVideos"] ?? []
        let blurryIds = cache["blurryPhotos"] ?? []
        let dupeIds = cache["duplicates"] ?? []

        guard !screenshotIds.isEmpty || !videoIds.isEmpty || !blurryIds.isEmpty || !dupeIds.isEmpty else {
            return false
        }

        screenshots = Self.fetchAssets(identifiers: screenshotIds)
        largeVideos = Self.fetchAssets(identifiers: videoIds)
        blurryPhotos = Self.fetchAssets(identifiers: blurryIds)
        duplicates = Self.fetchAssets(identifiers: dupeIds)
        totalJunkBytes = Int64(UserDefaults.standard.integer(forKey: "clearspace.totalJunkBytes"))

        refreshDeviceStorage()

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
        guard changeObserver == nil else { return }
        let observer = LibraryChangeObserver { [self] in
            Task { @MainActor in
                let newStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                if newStatus != self.authorizationStatus {
                    self.authorizationStatus = newStatus
                }
                // Invalidate cache when library changes externally
                self.invalidateScanCache()
            }
        }
        PHPhotoLibrary.shared().register(observer)
        changeObserver = observer
    }

    func stopObservingLibrary() {
        if let observer = changeObserver {
            PHPhotoLibrary.shared().unregisterChangeObserver(observer)
            changeObserver = nil
        }
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

    // Note: Observer cleanup handled by stopObservingLibrary() called from SwiftUI lifecycle.
    // deinit cannot access @MainActor-isolated properties in Swift 6.
}

// MARK: - Library Change Observer

final class LibraryChangeObserver: NSObject, PHPhotoLibraryChangeObserver, Sendable {
    private let onChange: @Sendable () -> Void

    init(onChange: @escaping @Sendable () -> Void) {
        self.onChange = onChange
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        onChange()
    }
}
