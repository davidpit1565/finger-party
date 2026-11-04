# UI tests and screenshots

`FingerPickerUITests` drives the real app in the simulator. `ScreenshotTests` saves real simulator
screenshots as `XCTAttachment`s (`01-idle`, `02-fingers`, `03-winner`, `04-settings`, lifetime
`.keepAlways`), which can be exported from the `.xcresult` bundle.

## Debug launch hook (not a mockup)

XCUITest cannot synthesize four simultaneous raw touches, so the app has a **DEBUG-only** launch
argument handled in `App/Sources/TouchSessionModel.swift`:

- `-ui-scenario collecting` feeds four touch-began events into the real `TouchSessionModel`
  (timers set very long, so it stays in the settling phase).
- `-ui-scenario winner` feeds the same four touches, runs the real round controller to lock with a
  fixed picker, skips the animation wait, then lifts the fingers so the result screen shows.

The real SwiftUI screen renders from that real model state. The hook only replaces the physical
fingers. Nothing is drawn by the tests, and the hook is compiled out of Release builds.
`01-idle` and `04-settings` use no hook at all.

These screenshots show real app states, but they are simulator captures. Final App Store screenshots
and the physical-device checks in PRODUCT-SPEC section 13 are still required.
