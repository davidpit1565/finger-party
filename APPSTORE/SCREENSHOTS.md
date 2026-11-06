# App Store screenshots plan

Rule (PRODUCT-SPEC section 12): screenshots must show the real app. No mock-ups, no composited fake UI, no claims beyond shipped behavior.

## Required sizes (verified 2026-11-04)
Source: Apple, App Store Connect Help, "Screenshot specifications" (developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications). Apple's page names display classes rather than inch labels; the inch labels below are my mapping.

| Display class (page wording) | ~Inches | Portrait px | Landscape px | Status per Apple |
|---|---|---|---|---|
| Dynamic Island, medium | 6.1-6.3" | 1179x2556 or 1206x2622 | 2556x1179 / 2622x1206 | **Required** (at least one) |
| Dynamic Island, large | 6.9" | 1320x2868 (also 1290x2796, 1260x2736) | 2868x1320 etc. | Optional; if absent, the 6.5" set below is required |
| Face ID, large | 6.5" | 1284x2778 (also 1242x2688) | 2778x1284 / 2688x1242 | Required if Dynamic Island (large) is not provided |

Other rules: 1 to 10 screenshots per size, .jpg/.jpeg/.png, no alpha channel/transparency. If the UI is consistent across sizes, supplying the largest and letting App Store Connect scale down is allowed.

Note: this differs from the common "6.9" and 6.5" both required" shorthand. Per Apple's current page, you need the 6.1/6.3" set plus **either** the 6.9" **or** the 6.5" set. Plan: produce 6.9" (1320x2868) and 6.3" (1206x2622) sets. Third-party guides mention other rules (e.g. a 2026 cutoff); I could not confirm those on Apple's pages. Re-check the live page and App Store Connect's upload slots at submission time. iPhone is the only platform (no iPad screenshots needed).

## Shot list (5, portrait; optional landscape later)
1. Idle: dark play surface with the "Place 2 or more fingers" prompt and the gear.
2. Fingers placed: 4-5 colored glowing rings.
3. Countdown / selector: rings with the selector running (mid-selection frame).
4. Winner takeover: winner color expanding or filling the screen with the halo at the winning point, plus "Play again".
5. Settings sheet: Sound, Haptics, Privacy Policy, version.

Text overlays or device frames are optional and, if used, must not misstate features. Simplest and safest: raw simulator captures.

## Capture method (CI, real app, no fakes)
Use an XCUITest target that launches the real app and calls `XCUIScreen.main.screenshot()` / `app.screenshot()`, saved as `XCTAttachment` (lifetime `.keepAlways`) and extracted from the `.xcresult` (`xcrun xcresulttool export attachments`, or `xcparse`). Run on simulators whose native sizes match the table: a 6.9" iPhone (1320x2868, e.g. iPhone 16/17 Pro Max class) and a 6.3" iPhone (1206x2622, e.g. iPhone 16/17 Pro class). Confirm the exact simulator names available on the `macos-15` runner and verify pixel dimensions with `sips -g pixelWidth -g pixelHeight`.

Caveat the owner should know: XCUITest cannot press N arbitrary fingers at once (it offers single-finger and a few two-finger gestures). Shots 2-4 therefore need a **test-only launch argument** in the app (for example `-UITestScenario fingers5`) that feeds a fixed set of touch points into the same touch-session model the real touch view feeds, then lets the real state machine, rings, countdown, selector and reveal render. The rendering is the real app; only the touch input source is injected. This seam must be compiled in a way that cannot alter shipped behavior (debug/UITest flag, no network, no data collection) and the shots should be described honestly if asked. The app agent owns this hook; I have not verified it exists. Optionally replace one or two shots later with captures from a physical iPhone with several real fingers.

Also set a deterministic winner/seed and `-UIAccessibilityReduceMotion NO` for repeatable frames; capture the reveal at a fixed time after the selector ends.

## Quality checks before upload
- No status bar clutter (the app hides it) and no simulator chrome.
- PNG without alpha: check `sips -g hasAlpha file.png`; if yes, flatten (e.g. `sips -s format jpeg`, or re-export as PNG without alpha).
- Dimensions exactly match the table; 1 to 10 images per size.
- Screens match the shipped build and the description. No sound/haptic claims shown that aren't in the build.
