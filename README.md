# Finger Party — Working Project

> Working repository name only. The final product name is not approved yet.

An iPhone-first, offline-capable, single-purpose multi-touch finger picker. The core experience is a fair random selection with a distinctive winner-color takeover animation that expands from the selected finger's exact screen position.

## Product principles
- One excellent core experience in the first release; no unnecessary game modes.
- No tab bar: one main play surface, with a small optional settings sheet.
- Finger Picker remains free.
- No account or backend in the MVP.
- English-only launch.
- Fair random selection: the winner is determined independently of the visual animation.
- No ads, analytics, tracking, or third-party SDKs in the MVP.
- No paywall or subscription in the MVP.
- Privacy-by-design and age-appropriate presentation.

## Product and build documents
- [Product specification](PRODUCT/PRODUCT-SPEC.md)
- [Technical plan and build contract](PRODUCT/TECHNICAL-PLAN.md)

## Research
- [Market and competitor research](RESEARCH/01-market-and-competitors.md)
- [Apple, privacy, age ratings and App Store research](RESEARCH/02-apple-platform-and-privacy.md)
- [Expanded competitor map and naming risk](RESEARCH/03-expanded-competitor-map.md)

## Current implementation status
The native SwiftUI/UIKit iPhone app is implemented on the working branch `claude/finger-picker-mvp`. It includes simultaneous multi-touch capture, fair random selection, animated winner reveal, sound and haptics settings, three locally persisted color moods (Vivid, Cool, Warm), replay safety, accessibility support, and simulator screenshot tests including a 10-participant visual stress scenario. CI and visual review are still required before calling the app release-ready.

## Important
The repository name finger-party is not the final App Store name. A close product name, Finger's Party, already exists on the App Store, so naming and trademark clearance are required before public branding.
