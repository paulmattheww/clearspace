import SwiftUI

enum JunkCategory: String, CaseIterable, Identifiable {
    case screenshots = "Screenshots"
    case largeVideos = "Large Videos"
    case blurryPhotos = "Blurry Photos"
    case duplicates = "Duplicates"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .screenshots: "rectangle.on.rectangle"
        case .largeVideos: "video.fill"
        case .blurryPhotos: "camera.metering.unknown"
        case .duplicates: "doc.on.doc.fill"
        }
    }

    var color: Color {
        switch self {
        case .screenshots: .blue
        case .largeVideos: .purple
        case .blurryPhotos: .orange
        case .duplicates: .red
        }
    }

    var description: String {
        switch self {
        case .screenshots: "Screenshots cluttering your library"
        case .largeVideos: "Videos larger than 50 MB"
        case .blurryPhotos: "Out-of-focus and blurry shots"
        case .duplicates: "Near-identical photos"
        }
    }
}
