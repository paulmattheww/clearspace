# ClearSpace: AI Photo Sweeper

**Free up gigabytes of iPhone storage by swiping away junk photos.**

ClearSpace scans your photo library 100% on-device and categorizes junk into actionable buckets. A gamified Tinder-style swipe UI makes cleanup fast and satisfying.

## Features

### Scanning & Detection
- **Screenshot Detection** — Finds all screenshots via PhotoKit metadata
- **Large Video Finder** — Surfaces videos over 50MB eating your storage
- **Blur Detection** — CoreImage edge analysis identifies out-of-focus shots
- **Duplicate Detection** — Vision framework feature prints find near-identical photos
- **Scan Caching** — Results persist across launches; auto-invalidate after 7 days

### Swipe Interface
- **Tinder-Style Cards** — Swipe left to trash, right to keep
- **Sort Options** — View by newest, oldest, or largest first
- **Undo Support** — Revert last swipe with one tap
- **Trash All** — Bulk-mark remaining items (Pro)
- **Free Preview** — First 5 swipes free per category; paywall after
- **First-Use Tutorial** — Animated overlay teaches swipe gestures

### Deletion & Storage
- **Batched Deletion** — Single iOS permission popup for all items
- **Device Storage Gauge** — Visual bar showing used/free/reclaimable space
- **Share Results** — "I freed X GB with ClearSpace!" viral share sheet
- **Trash Queue Persistence** — Survives app restarts

### Gamification & Retention
- **Cleanup Streaks** — Track consecutive days of cleaning
- **Lifetime Stats** — Total photos cleaned across all sessions
- **Monthly Reminders** — Push notifications on the 1st of each month (local timezone)

### Privacy & Compliance
- **100% On-Device** — Zero server costs, no data leaves the phone
- **PrivacyInfo.xcprivacy** — App Store privacy manifest included
- **No Tracking** — No analytics, no third-party SDKs (yet)

## Architecture

| Concern | Solution |
|---------|----------|
| Memory Safety | `PHCachingImageManager` with `fastFormat` 300x300 thumbnails, `autoreleasepool` in analysis loops |
| Alert Fatigue | Swipe adds to `trashQueue` (Set of localIdentifiers); single `PHAssetChangeRequest.deleteAssets` on "Empty Trash" |
| Zero Cloud | 100% on-device — no server costs, no API keys |
| Swift 6 | Full strict concurrency: `@Observable`, `Sendable`, `Task.detached`, `nonisolated(unsafe)` only where proven safe |
| Persistence | Trash queue + scan cache + streak data in UserDefaults |
| Accessibility | VoiceOver labels on all interactive elements |

## Tech Stack

- **SwiftUI** + iOS 17+ / Swift 6
- **PhotoKit** (`PHFetchResult`, `PHCachingImageManager`)
- **Vision** (`VNGenerateImageFeaturePrintRequest` for duplicate detection)
- **CoreImage** (`CIEdges` filter for blur scoring)
- **XcodeGen** for project generation

## Getting Started

```bash
# Clone and open (xcodeproj included)
open ClearSpace.xcodeproj

# Or regenerate from spec
brew install xcodegen
xcodegen generate
open ClearSpace.xcodeproj
```

Set your development team in Xcode signing settings, then build & run on a **physical device** (the Simulator doesn't have a real photo library for testing).

### Debug Mode

In Debug builds, go to **Settings > Developer** and toggle "Dev Mode (Pro)" to test the full Pro flow without RevenueCat.

## Project Structure

```
ClearSpace/
├── App/
│   ├── ClearSpaceApp.swift          # Entry point, environment setup
│   └── ContentView.swift            # Auth-based routing
├── Core/
│   ├── PhotoManager.swift           # Library scanning, trash, cache, storage
│   ├── PhotoAnalyzer.swift          # Blur & duplicate detection (Vision + CI)
│   ├── SubscriptionManager.swift    # RevenueCat placeholder + dev toggle
│   ├── StreakManager.swift          # Cleanup streak tracking
│   ├── NotificationManager.swift    # Monthly review reminders
│   └── HapticManager.swift          # Tactile feedback
├── Models/
│   └── JunkCategory.swift           # Category enum
├── Views/
│   ├── Dashboard/                   # Storage summary, gauge, streak, categories
│   ├── Swipe/                       # Card deck, tutorial, sort, undo
│   ├── Trash/                       # Batched deletion, success, share
│   ├── Settings/                    # Subscription, debug, privacy policy
│   ├── Onboarding/                  # Permission request
│   └── Paywall/                     # Plan selector (RevenueCat-ready)
├── PrivacyInfo.xcprivacy            # App Store privacy manifest
└── Info.plist
```

## Business Model

See [`docs/financials.md`](docs/financials.md) for detailed 36-month projections.

- **Free tier:** Scan + see junk totals + 5 free swipes per category + delete trashed items
- **Pro ($29.99/yr or $4.99/wk):** Unlimited swiping + Trash All bulk action

## Next Steps

1. Integrate [RevenueCat](https://revenuecat.com) for subscription management
2. Design app icon and App Store screenshots
3. Record TikTok-style demo for organic UA
4. Test on devices with 10K+ photo libraries for performance tuning
5. Add background app refresh for automatic monthly scans
6. Host privacy policy at clearspace.app/privacy
