import Photos
import Vision
import CoreImage
import UIKit

/// On-device photo analysis engine.
/// Uses Vision framework for duplicate detection and CoreImage for blur detection.
/// All processing uses low-res images to prevent OOM on large libraries.
final class PhotoAnalyzer: Sendable {

    // MARK: - Blur Detection (Laplacian Variance)

    /// Scores image sharpness. Lower score = more blurry.
    /// Uses edge detection via CoreImage as a sharpness proxy.
    func detectBlurryPhotos(from assets: [PHAsset], threshold: Double = 50.0) async -> [PHAsset] {
        // Do all heavy work on a background thread
        let blurryIds: Set<String> = await Task.detached {
            let manager = PHCachingImageManager()
            var ids = Set<String>()

            for asset in assets {
                autoreleasepool {
                    guard let cgImage = Self.loadCGImageSync(for: asset, using: manager) else { return }
                    let ciImage = CIImage(cgImage: cgImage)
                    let sharpness = Self.laplacianVariance(of: ciImage)
                    if sharpness < threshold {
                        ids.insert(asset.localIdentifier)
                    }
                }
            }

            return ids
        }.value

        return assets.filter { blurryIds.contains($0.localIdentifier) }
    }

    private static func laplacianVariance(of image: CIImage) -> Double {
        let context = CIContext(options: [.useSoftwareRenderer: false])

        guard let edgeFilter = CIFilter(name: "CIEdges") else { return 999 }
        edgeFilter.setValue(image, forKey: kCIInputImageKey)
        edgeFilter.setValue(1.0, forKey: kCIInputIntensityKey)

        guard let outputImage = edgeFilter.outputImage else { return 999 }

        let extent = outputImage.extent
        let sampleSize = min(extent.width, extent.height, 256)
        let sampleRect = CGRect(
            x: extent.midX - sampleSize / 2,
            y: extent.midY - sampleSize / 2,
            width: sampleSize,
            height: sampleSize
        )

        guard let areaAverage = CIFilter(name: "CIAreaAverage") else { return 999 }
        areaAverage.setValue(outputImage, forKey: kCIInputImageKey)
        areaAverage.setValue(CIVector(cgRect: sampleRect), forKey: "inputExtent")

        guard let avgOutput = areaAverage.outputImage else { return 999 }

        var pixel = [UInt8](repeating: 0, count: 4)
        context.render(
            avgOutput,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        let luminance = Double(pixel[0]) * 0.299 + Double(pixel[1]) * 0.587 + Double(pixel[2]) * 0.114
        return luminance
    }

    // MARK: - Duplicate Detection (Vision Feature Prints)

    /// Groups visually similar photos using VNGenerateImageFeaturePrintRequest.
    /// Returns assets that are near-duplicates (keeping the "best" of each group).
    func detectDuplicates(from assets: [PHAsset], distanceThreshold: Float = 12.0) async -> [PHAsset] {
        guard assets.count > 1 else { return [] }

        let batchSize = min(assets.count, 1000)
        let batch = Array(assets.prefix(batchSize))

        // Do all Vision work + comparison on a background thread, return only String IDs
        let duplicateIds: Set<String> = await Task.detached {
            let manager = PHCachingImageManager()

            struct PrintEntry {
                let identifier: String
                let pixelCount: Int
                let creationDate: Date
                let featurePrint: VNFeaturePrintObservation
            }

            var prints: [PrintEntry] = []

            for asset in batch {
                autoreleasepool {
                    guard let cgImage = Self.loadCGImageSync(for: asset, using: manager) else { return }

                    let request = VNGenerateImageFeaturePrintRequest()
                    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

                    do {
                        try handler.perform([request])
                        if let result = request.results?.first {
                            prints.append(PrintEntry(
                                identifier: asset.localIdentifier,
                                pixelCount: asset.pixelWidth * asset.pixelHeight,
                                creationDate: asset.creationDate ?? .distantPast,
                                featurePrint: result
                            ))
                        }
                    } catch {
                        // Skip assets that fail analysis
                    }
                }
            }

            // Compare pairs
            var dupeIds = Set<String>()
            var processed = Set<String>()

            for i in 0..<prints.count {
                guard !processed.contains(prints[i].identifier) else { continue }

                for j in (i + 1)..<prints.count {
                    guard !processed.contains(prints[j].identifier) else { continue }

                    var distance: Float = 0
                    do {
                        try prints[i].featurePrint.computeDistance(&distance, to: prints[j].featurePrint)
                    } catch {
                        continue
                    }

                    if distance < distanceThreshold {
                        // Keep the higher-res or newer photo
                        let keepIdx: Int
                        if prints[i].pixelCount != prints[j].pixelCount {
                            keepIdx = prints[i].pixelCount > prints[j].pixelCount ? i : j
                        } else {
                            keepIdx = prints[i].creationDate > prints[j].creationDate ? i : j
                        }
                        let discardIdx = keepIdx == i ? j : i
                        dupeIds.insert(prints[discardIdx].identifier)
                        processed.insert(prints[discardIdx].identifier)
                    }
                }
            }

            return dupeIds
        }.value

        return batch.filter { duplicateIds.contains($0.localIdentifier) }
    }

    // MARK: - Image Loading (synchronous, for use in detached tasks)

    private static func loadCGImageSync(for asset: PHAsset, using manager: PHCachingImageManager) -> CGImage? {
        nonisolated(unsafe) var result: CGImage?

        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isSynchronous = true
        options.isNetworkAccessAllowed = false
        options.resizeMode = .fast

        let targetSize = CGSize(width: 512, height: 512)

        manager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            result = image?.cgImage
        }

        return result
    }
}
