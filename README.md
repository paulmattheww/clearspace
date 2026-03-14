# ClearSpace: AI Photo Sweeper

**Free up gigabytes of iPhone storage by swiping away junk photos.**

ClearSpace scans your photo library 100% on-device and categorizes junk into actionable buckets. A gamified Tinder-style swipe UI makes cleanup fast and satisfying.

## Features

- **Screenshot Detection** — Finds all screenshots via PhotoKit metadata
- **Large Video Finder** — Surfaces videos over 50MB eating your storage
- **Blur Detection** — CoreImage edge analysis identifies out-of-focus shots
- **Duplicate Detection** — Vision framework feature prints find near-identical photos
- **Batched Deletion** — Swipe to mark, then delete all at once (single iOS permission popup)
- **Paywall** — Free scan, Pro required to swipe/delete (RevenueCat-ready)
- **Monthly Reminders** — Push notifications to re-engage users

## Architecture

| Concern | Solution |
|---------|----------|
| Memory Safety | `PHCachingImageManager` with `fastFormat` thumbnails, `autoreleasepool` in analysis loops |
| Alert Fatigue | Swipe adds to `trashQueue`; single `PHAssetChangeRequest.deleteAssets` call on "Empty Trash" |
| Zero Cloud | 100% on-device — no server costs, no API keys, no data leaves the phone |
| Swift 6 | Full strict concurrency compliance with `@Observable`, `Sendable`, detached tasks |

## Tech Stack

- **SwiftUI** + iOS 17+
- **PhotoKit** (`PHFetchResult`, `PHCachingImageManager`)
- **Vision** (`VNGenerateImageFeaturePrintRequest`)
- **CoreImage** (edge detection for blur scoring)
- **XcodeGen** for project generation

## Getting Started

```bash
# Generate the Xcode project
brew install xcodegen  # if not installed
xcodegen generate

# Open in Xcode
open ClearSpace.xcodeproj
```

Set your development team in Xcode signing settings, then build & run on a **physical device** (the Simulator doesn't have a real photo library for testing).

## Project Structure

```
ClearSpace/
├── App/
│   ├── ClearSpaceApp.swift          # Entry point
│   └── ContentView.swift            # Auth-based routing
├── Core/
│   ├── PhotoManager.swift           # Library scanning & trash management
│   ├── PhotoAnalyzer.swift          # Blur & duplicate detection
│   ├── SubscriptionManager.swift    # RevenueCat placeholder
│   ├── NotificationManager.swift    # Monthly review reminders
│   └── HapticManager.swift          # Tactile feedback
├── Models/
│   └── JunkCategory.swift           # Category enum
└── Views/
    ├── Dashboard/                   # Storage summary & category cards
    ├── Swipe/                       # Tinder-style card interface
    ├── Trash/                       # Batched deletion UI
    ├── Onboarding/                  # Permission request
    └── Paywall/                     # Subscription gate
```

## Business Model

See [`docs/financials.md`](docs/financials.md) for detailed 36-month projections.

- **Free tier:** Scan & see junk totals
- **Pro ($29.99/yr or $4.99/wk):** Swipe UI + deletion

## Next Steps

1. Integrate [RevenueCat](https://revenuecat.com) for subscription management
2. Add App Store screenshots and ASO metadata
3. Record TikTok-style demo for organic UA
4. Test on devices with 10K+ photo libraries for performance tuning
