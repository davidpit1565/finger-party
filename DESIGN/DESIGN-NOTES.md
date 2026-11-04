# Finger Picker - Design Notes (animation + visuals)

Code: `App/Sources/Animation/` (Theme, GlowRing, RingMarkerView, WinnerTakeoverView).

## Palette and background
- Background `#0B0B10`: near-black with slight blue; single solid color, no gradient behind markers.
- Marker/winner colors come only from `FingerPickerCore.Palette` (sRGB). `Theme.color` wraps indices.
- Overlay text: `Palette.prefersDarkText` picks near-black vs white, so "Play again" etc. stay legible on any winner color.
- Secondary text: white at 55%.

## Ring marker (96pt frame)
- Layers: radial-gradient halo (96pt), translucent wide stroke + crisp 4pt ring (56pt), 10pt center dot. No blur/shadow stacks.
- Appear: spring (response 0.35, damping 0.6) from scale 0.3. Idle pulse: 1.6s ease-in-out, scale 1.035 and glow breathing; disabled with Reduce Motion (then a 0.2s fade-in).
- Emphasis (0.12s ease-out, so rapid selector hops stay crisp): normal 1.0x; selectorOn 1.25x with glow 1.5; winner 1.15x with strongest glow; dimmed 0.94x at 38% opacity.

## Winner takeover
- A circle of the winner color, sized to `RevealGeometry.coverRadius + 24pt`, scales from ~0 to 1 about the origin: 0.9s, cubic-bezier(0.16, 0.84, 0.3, 1) (fast start, long ease-out). Single scaled shape: no blur, no particles.
- Halo (white ring over dark under-ring, soft glow, center dot) fades in at ~55% of the wave and persists, keeping the winner point clear on every color.
- Reduce Motion: full-size fill crossfades 0.35s; no expanding wave.
- `onCompleted` fires once after the duration via `.task(id: started)` + `Task.sleep` (auto-cancelled on removal/change); `started == false` resets state for replay.
- Not started: draws a transparent halo only at opacity 0; `allowsHitTesting(false)` always.
- Flash safety: one monotonic full-screen change per round, far below 3Hz.
