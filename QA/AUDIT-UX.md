# UX / Visual / Accessibility Audit — Finger Picker (single screen)

Scope: `PRODUCT/PRODUCT-SPEC.md` (§3, §7, §8), `DESIGN/DESIGN-NOTES.md`, `PlayScreen.swift`, `SettingsSheet.swift`, `Animation/*`, `TouchSessionModel.swift`, `HapticsService.swift`, `SoundService.swift`, `Palette.swift`, `SelectorRoute.swift`.
Method: static code review plus computed numbers (WCAG contrast and colour-vision-deficiency simulation, Python, Machado 2009 matrices, CIELAB ΔE76). No device or simulator run: the CI xcresult was not rendered (the last CI runs on the branch were failing and the bundle is not viewable here). Everything about "feel" is inferred from code and needs a device pass. Finger-size numbers are estimates.
Read-only: no source edited.

Severity: **S1** = breaks a spec requirement or a real-use failure; **S2** = visible polish or accessibility gap; **S3** = minor.

## 0. Verdict

The skeleton is right: one screen, no chrome, a dark base, a single takeover. The weak points are not in the big structure but in these four places:

1. The winner halo and the result text partly fail contrast on the very colours they were designed for.
2. The reveal has a ~0.5 s gap with no marker at the winning point, and the haptic and sound arrive about 0.9 s after the visual impact.
3. The gear can start or disturb a round.
4. The marker is likely smaller than a real fingertip.

Everything below is low-risk and stays within the "one task" philosophy.

## 1. Computed data (for reference)

### 1a. Text on each winner colour (current rule: `luminance > 0.40` → dark ink, else white)

Dark ink is `#0A0A12` at 92% alpha.

| Colour | Lum | White CR | Dark-ink CR | Current choice | Result |
|---|---|---|---|---|---|
| coral | 0.262 | 3.36 | **5.50** | white | white fails AA (<4.5) for non-large text |
| cyan | 0.487 | 1.95 | 9.06 | dark | ok |
| amber | 0.646 | 1.51 | 11.51 | dark | ok |
| lime | 0.601 | 1.61 | 10.83 | dark | ok |
| violet | 0.269 | 3.30 | **5.55** | white | white fails AA |
| orange | 0.380 | 2.44 | **7.39** | white | **white fails even 3:1** |
| pink | 0.351 | 2.62 | **6.92** | white | **white fails even 3:1** |
| mint | 0.605 | 1.60 | 10.91 | dark | ok |
| indigo | 0.254 | 3.46 | **5.29** | white | white fails AA |
| chartreuse | 0.868 | 1.14 | 14.78 | dark | ok |

The 0.40 threshold is wrong for this purpose. The crossover where white and black have equal contrast is about L≈0.18, and these hues are all above it. Dark ink beats white on all ten colours; its worst case is 5.29:1 on indigo.

### 1b. Winner halo (white ring, white dot, white glow, 28% black under-ring)

| Colour | White vs fill CR | White vs under-ring CR |
|---|---|---|
| chartreuse | **1.14** | 2.26 |
| amber | 1.51 | 2.91 |
| mint | 1.60 | 3.08 |
| lime | 1.61 | 3.10 |
| cyan | 1.95 | 3.68 |
| orange | 2.44 | 4.47 |
| pink | 2.62 | 4.76 |
| violet | 3.30 | 5.77 |
| coral | 3.36 | 5.91 |
| indigo | 3.46 | 6.00 |

Five of ten winners (chartreuse, amber, mint, lime, cyan) give the ring less than 2:1 against the fill. The spec says the halo "must stay visible on any colour" (§3, §7), and the 5pt white line on chartreuse is nearly invisible. The only thing saving it is the thin dark under-ring, which is itself only 28% black.

### 1c. Secondary text and gear (on `#0B0B10`)

| Element | Effective alpha | Contrast |
|---|---|---|
| Secondary text (white 55%) | 0.55 | 6.2:1, ok |
| Gear (55% × `.opacity(0.6)`) | 0.33 | **2.9:1**, below 3:1 for UI components |
| Faint ghost ring (proposed, 20%) | 0.20 | 1.8:1, decorative only |

### 1d. Colour-blind distinguishability (ΔE76 in Lab; ≈ 20+ is easy, below ≈ 15 is a problem)

Worst pairs by simulation:

| Simulation | Worst pairs (ΔE) |
|---|---|
| Deuteranopia | violet/indigo 8.4, amber/chartreuse 10.8, amber/orange 16.2, **coral/lime 18.1**, pink/mint 21.5 |
| Protanopia | violet/indigo 4.4, amber/chartreuse 14.6, cyan/pink 19.7, amber/lime 21.1 |
| Tritanopia | lime/mint 8.5, cyan/mint 11.9, cyan/lime 14.2 |
| Normal vision | violet/indigo 31, lime/chartreuse 38, amber/chartreuse 41 |

Minimum ΔE among the first N fingers, deuteranopia/protanopia combined (the common case is 2–5 fingers):

| N | Current order | Greedy-reordered |
|---|---|---|
| 2 | 56.9 | 83.1 |
| 3 | 44.9 | 44.9 |
| 4 | **18.1** (coral vs lime) | **37.4** |
| 5 | 18.1 | 23.9 |
| 6 | 16.2 | 19.7 |

Normal-vision minimum stays ≥ 56 up to N=5 with the new order (≥ 41.7 for N=6–8).

Recommended order (indices into the current array): `[0, 4, 2, 7, 1, 6, 3, 5, 9, 8]` = coral, violet, amber, mint, cyan, pink, lime, orange, chartreuse, indigo.

## 2. Findings

| ID | Sev | Area | What | Why it matters | Concrete fix |
|---|---|---|---|---|---|
| UX-01 | S1 | Result / contrast | `Theme.overlayText` uses white on coral, violet, orange, pink and indigo (table 1a). White is 2.44:1 on orange and 2.62:1 on pink. The "Winner" title (34pt bold) passes the large-text 3:1 rule on only some of them, and "Finger N of M" (title3) and the footnote copy fail 4.5:1 on all five. | Spec §7: "text legible against every possible winner color." This is the screen people look at last and longest. | Always use dark ink: `static func overlayText(onColorIndex: Int) -> Color { Color(.sRGB, red: 0.04, green: 0.04, blue: 0.07, opacity: 0.92) }` (worst case 5.29:1). If white is wanted for aesthetics, change the threshold in `Palette.prefersDarkText` to `luminance > 0.18`. Update `Palette` tests if they pin 0.40. |
| UX-02 | S1 | Winner halo | The white halo has 1.1–2:1 contrast on chartreuse, amber, mint, lime and cyan (table 1b). | The winning point is the entire payoff of the app. On 5 of 10 colours the marker nearly vanishes. | Make the halo from `ink` (see UX-01) instead of white: ring `ink` 5pt, dot `ink`, glow `GlowDisc(color: ink, intensity: 0.35)`. Replace the dark under-ring with a thin 2pt white outside rim at 60% so it also separates on dark-ish winners (coral, violet, indigo): `Circle().strokeBorder(.white.opacity(0.6), lineWidth: 2).frame(width: 70, height: 70)`. Pass `ink` into `WinnerTakeoverView`. |
| UX-03 | S1 | Reveal choreography | The takeover circle is the last ZStack child, so it covers the winner's own ring almost immediately (the curve reaches 30pt radius in a few tens of ms). The halo only starts fading in at `d*0.55` (≈0.5 s) and is full at 0.8 s. For about 0.5 s the winning point has no marker at all. | Spec §3, §7: the origin must stay clear through the reveal. This is the one moment of maximum attention, and the "where did it start" cue blinks out. | Start the halo at the same instant as the wave: `withAnimation(.easeOut(0.18)) { haloOpacity = 1 }` (no delay), or at most `.delay(0.06)`. Add a quick scale-in so it reads as the ring "becoming" the halo: `.scaleEffect(0.7 + 0.3 * haloOpacity)`. |
| UX-04 | S1 | Haptic / sound timing | `revealCompleted()` runs after `Task.sleep(0.9 s)`, and it is where `haptics.winner()` and `sound.winner()` fire. The colour wave starts at `selectorFinished`. The tap therefore lands about 0.9 s after the visual impact, when the screen is already settled (the wave is 90% done by roughly 0.4 s). | Cues that trail the visual feel broken. Best-in-class apps fire the haptic on the frame of impact. | Fire `haptics.winner()` and `sound.winner()` where `selectorFinished = true` is set (end of the `selectorTask`, and in the early-finish branch of `revealCompleted`). Keep only the accessibility announcement and `controller.finishReveal()` in `revealCompleted`. If a tail is wanted, add a soft `notification(.success)` there. Make the win sound start at wave t=0. |
| UX-05 | S1 | Gear / round integrity | The gear is shown in `.collecting` (one finger down). A finger that lands on the gear is swallowed by the Button, so it silently isn't a participant. If it lifts there, Settings opens mid-round. Opening the sheet does not interrupt the model, so the round can settle, lock and reveal behind the sheet, with haptics firing. | A mis-tap in the top-right corner (a common place for a group's thumb) breaks the round. The spec says nonessential controls are hidden when touches are active. | (a) `showsGear` true only for `.idle`. (b) Fade the gear: `.opacity(showsGear ? 0.7 : 0).animation(.easeOut(0.15), value: showsGear)` with `.allowsHitTesting(showsGear)`. (c) In `PlayScreen`: `.onChange(of: showSettings) { _, open in if open { model.interrupt() } }`. |
| UX-06 | S1 | Marker size vs finger | Marker ring is 56pt, centre dot 10pt, glow 96pt. A fingertip's visible pad is about 14–18 mm, roughly 85–105pt on a 460 ppi iPhone, so the finger likely covers the whole ring and dot; only the faint glow edge shows. (Estimate; confirm on a device.) | The visible feedback that a finger was registered, and the selector hopping, depend on seeing the ring. | Enlarge: ring diameter 88pt, stroke 5pt, glow frame 144pt, drop the centre dot (it is always hidden). Keep an 8% ring-to-finger gap so it reads as a halo around the fingertip. Neighbouring glows at 144pt can overlap; they are additive and soft, so this is fine. `RingMarkerView` frame to 144, `.frame(width: 144, height: 144)` in `PlayScreen`. Re-check crowding with 5–6 fingers on a 6.1" phone. |
| UX-07 | S2 | Result layout | The result stack (Winner, detail, Play Again, optional footnote) is hard-anchored to the bottom. It can sit on top of the winner halo and the fingers when the winner is in the lower half. In landscape (390pt tall) the stack is about 40% of the height. | The reveal's origin gets partly hidden by the very UI meant to complement it. | Place the stack on the side opposite the winner: in `PlayScreen` pass `winnerY = round.winnerPoint.y` and use `.frame(maxHeight: .infinity, alignment: winnerY > 0.55 ? .top : .bottom)`. In landscape use `ViewThatFits` with an `HStack` variant (label left, button right). |
| UX-08 | S2 | Result layout jump | `if !model.canReplay { Text("Lift your fingers…") }` removes a 16pt line (plus 12pt spacing) when fingers lift. The stack is bottom-anchored, so Winner and Play Again visibly drop about 28pt exactly when the user is about to tap. The opacity change on the button (0.45→1) is also unanimated. | A target that moves under a finger is a bad tap target. | Always reserve the line: `.opacity(model.canReplay ? 0 : 1)` instead of `if`. Add `.animation(.easeOut(duration: 0.2), value: model.canReplay)` to the VStack. |
| UX-09 | S2 | Gating copy | "Lift your fingers, then tap Play Again" is accurate but long, and it is shown next to a disabled button. It also reads wrong at a table, where the person tapping is not the one holding the screen. The VO version is hidden (`accessibilityHidden(true)`), so only the hint carries the meaning. | Copy should be shorter, one voice, and not need a second element. | Shorter copy: "Lift fingers to play again". Show it as the button's disabled label instead of a second element: `Text(model.canReplay ? "Play Again" : "Lift fingers")`. Keep the button disabled until then. Remove the extra footnote entirely (also fixes UX-08). |
| UX-10 | S2 | Result entrance | The `.result` branch of `bottomContent` has no transition; "Winner" and the button pop in on the frame the wave completes (0.9 s), after about 0.5 s of empty fill. | Abrupt. Also later than needed (the wave is visually done by ~0.45 s). | Add `.transition(.opacity.combined(with: .offset(y: 12)))` and `.animation(.easeOut(0.25), value: model.phase)`. Optionally fire `revealCompleted` at `d * 0.6` (≈0.55 s) so the label arrives as the wave settles; the wave still finishes visually to 0.9 s. Reduce Motion: opacity only. |
| UX-11 | S2 | Selector hop crispness | The emphasis animation is `.easeOut(0.12)`, but early dwells are shorter (2.4 s total, 14–22 steps, cubic weights: the first dwell is ≈ 0.04–0.06 s). The animation cannot finish before the next hop, so the highlight smears and the ring never fully reaches 1.25×. The tick is also skipped when `dwell < 0.06`, so the fast opening hops are silent and tickless, then ticks start mid-sequence. | The "crisp hop" claim in DESIGN-NOTES is only true for the slow hops. | Use a dwell-aware duration: `.animation(.easeOut(duration: 0.07), value: emphasis)`. Remove the 0.06 gate and instead throttle to at most one tick per 45 ms (`if now - lastTick > 0.045`). Add a rising pitch for the last 3 hops (`player.rate` 1.0 → 1.15 with `enableRate = true`). |
| UX-12 | S2 | Winner ring emphasis | During the reveal the winner scales 1.15× and others fade to 38%, while the selector's final hop sits at 1.25×. The ring therefore shrinks from 1.25× to 1.15× at the instant of the win. | The moment of selection should feel like a peak, not a release. | Winner emphasis scale 1.35× with a spring: `.animation(.spring(response: 0.25, dampingFraction: 0.55), value: emphasis == .winner)`. |
| UX-13 | S2 | Countdown affordance | The only countdown cue is a 120×4pt bar at the bottom edge. Eyes are on the fingers, and the bottom is often under the palm; in landscape or flat on a table it is off to one side. The "settling" phase (0.7 s) has no cue at all, so the whole ~1.7 s wait appears as "nothing happening". | Users don't know whether the app is waiting, broken or counting down, and may lift early. | Move the progress onto the rings: add `Circle().trim(from: 0, to: progress).stroke(color, style: .init(lineWidth: 5, lineCap: .round)).rotationEffect(.degrees(-90)).frame(width: 100)` around each ring, driven by `model.countdownProgress`. Keep the bar only as a VO value. For settling, pulse the ring glow at 2× speed. |
| UX-14 | S2 | Idle first impression | Idle is a flat grey title3 line on an empty field. Nothing moves, so it reads as "static" rather than "alive but calm". The line also vanishes without animation on the first touch (`if case .idle`), and the same copy reappears as a footnote at the bottom (double-writing). | It is the first and most-seen frame, and the screenshot frame. | Add one barely-there cue: a 72pt 1.5pt ring in white at 12–16% opacity, 4 s ease-in-out breathing (scale 1.0↔1.06, opacity 0.10↔0.18), centred 56pt above the hint; static when Reduce Motion is on. Fade the hint out over 0.2 s on first touch (`.transition(.opacity)` + `.animation`). Keep the hint and drop the bottom copy (see UX-15). |
| UX-15 | S2 | Copy: collecting | While collecting with 2+ fingers, the footnote still says "Place 2 or more fingers", and below it the count. | It is wrong once there are 2 or more fingers. | With n < 2: "Add another finger". With n ≥ 2: show only the count, or "Hold still" during settling and countdown. |
| UX-16 | S2 | Contrast: gear | The gear is `secondaryText` (0.55) then `.opacity(0.6)`, effectively 0.33 alpha = 2.9:1 (below 3:1 for UI components). | Discreet is good; unfindable is not. 44pt target is fine (`frame(44, 44)`, `contentShape`). | Remove the extra `.opacity(0.6)`; use `.foregroundStyle(.white.opacity(0.55))` (6.2:1). Keep the 44pt hit area. Also add `.padding(.trailing, 4)` so it clears the rounded corners in landscape. |
| UX-17 | S2 | Dynamic Type | Result stack uses `.largeTitle` and `.title3` with no cap and no scale factor. At AX3–AX5, "Winner" is about 70–88pt and "Finger 3 of 4" wraps; the stack can cover most of the screen. Idle and count text also scale, uncapped. | Spec §8 requires Dynamic Type "while keeping the play surface minimal". | Cap overlays: `.dynamicTypeSize(...DynamicTypeSize.accessibility1)` on `overlayLayer`; add `.minimumScaleFactor(0.7)` and `.lineLimit(2)` to the result labels. The gear is a fixed 44pt frame, so scale the symbol only with `.imageScale(.large)`. |
| UX-18 | S2 | Settings sheet | `Form` plus `.presentationDetents([.medium])` only. Four short rows fit at default size, but at Dynamic Type XXL and above the toggle labels wrap and the content exceeds a medium sheet, so it scrolls inside a sheet with no way to expand. No drag indicator. | The "no needless scrolling" bar is met at default size only. | `.presentationDetents([.medium, .large])` and `.presentationDragIndicator(.visible)`. Optional: a fit-to-content detent via `.height(...)` measured with a `PreferenceKey`. Keep `Form` (native, free VoiceOver and Dynamic Type), not a custom layout. Keep Done (confirmationAction); it is a good fallback for VoiceOver users. |
| UX-19 | S2 | Settings feedback | Toggling Sound or Haptics gives no confirmation. Sound defaults off, so the user cannot hear what they are enabling. | Users test toggles; a silent response feels broken. | `onChange(of: settings.soundEnabled)`: when turned on, play `tick`; for Haptics, call `touchRegistered()` when turned on. Add Form footers: Sound: "Plays short sounds. Follows your iPhone's Silent switch." (the ambient category does this); Haptics: "Feel each finger and the winner." |
| UX-20 | S3 | Settings rows | The Privacy Policy `Link` has no affordance that it leaves the app. `LabeledContent("Version")` text is not selectable. | Minor trust and clarity gap. | `Link(destination: ...) { HStack { Text("Privacy Policy"); Spacer(); Image(systemName: "arrow.up.right").font(.footnote).foregroundStyle(.secondary) } }`. Add `.textSelection(.enabled)` on the version value. |
| UX-21 | S2 | Palette order / colour-blind | Slots 0 and 3 (coral and lime) collapse to ΔE 18 under deuteranopia, and a 4-finger round is a very common size. Amber/chartreuse and violet/indigo are nearly identical under protan/deutan, but only appear at ≥ 9 fingers. | Colour identity matters for "who's got the colour" and for the final fill; the spec says colour must not be the only cue (§7). | Reorder `Palette.colors` per table 1d: `[0, 4, 2, 7, 1, 6, 3, 5, 9, 8]` (coral, violet, amber, mint, cyan, pink, lime, orange, chartreuse, indigo). N=4 min ΔE goes 18.1 → 37.4; N=5 → 23.9; normal-vision stays ≥ 56 up to N=5. Check `PaletteTests` for any order assumption. Consider capping at 8 distinct colours before wrap. |
| UX-22 | S2 | Non-colour cues | The only non-colour cue for the winner is the halo plus dimming of others. Dimmed rings (38%) keep their hue; the final state has no per-finger shape or number. Selection itself does not depend on hue, so the risk is moderate, not high. | Spec §7 asks for "position, shape/halo emphasis, and VoiceOver announcement". Halo + dimming meets the letter, but UX-02 makes the halo invisible on 5 colours. | After UX-02, the spec is met. If a stronger cue is wanted at low cost, add a tiny 12pt numeral or shape badge (circle, triangle, square, diamond, …) at the ring's top-right (offset 38pt, −38pt) so it sits outside the fingertip. This is optional; see the "do NOT add" list for what to avoid. |
| UX-23 | S2 | Increase Contrast / Bold Text | `Theme.secondaryText` is a fixed 55% white; no response to `colorSchemeContrast`. Bold Text applies automatically to system fonts and SF Symbols, which is fine. Reduce Transparency: no materials used on the play surface (glows are decorative); the sheet uses system materials. | HIG expects the settings to be honoured. | `@Environment(\.colorSchemeContrast) var contrast` → alpha 0.75 when `.increased`. Gear alpha to 0.85. Ring stroke +1pt when increased. No change needed for Reduce Transparency. |
| UX-24 | S2 | Reduce Motion | Reduce Motion path is good: no selector travel (single 0.3 s dwell), 0.35 s crossfade, no pulse. Gaps: the marker `.transition(.opacity)` animation is removed (fine); no gap. One issue: with Reduce Motion the result still pops in (UX-10), and the idle ghost ring (UX-14) must be static. | Keeps the promise in §8. | Make UX-10 and UX-14 respect `reduceMotion`. Also respect Prefer Cross-Fade Transitions for sheet-related changes if added. |
| UX-25 | S2 | VoiceOver flow | Good: touch surface has `.allowsDirectInteraction`; counts and the winner are announced; fingers hidden from VO; the result is a header. Gaps: (1) The idle hint element and the "Play area" touch surface both have hints with similar text, so VO reads them twice. (2) The announcement "Finger 3 of 4 selected" uses touch order, which a VO user cannot know. (3) When Play Again becomes enabled, nothing is announced. (4) A VO user with one finger has no fallback. (5) Announcements posted at 30 Hz of count changes can overlap. | A blind or low-vision user cannot tell which finger won. | (1) Hide the idle `Text` from VO (`.accessibilityHidden(true)`) and keep the surface label. (2) Announce "The third finger placed won" and add "tap the screen with your fingers to feel the result" only if you add a distinct haptic. Better: announce "Winner: the finger that landed third" to match the visible label. (3) Post `.layoutChanged`/announcement "Ready. Play Again is available" when `canReplay` flips. (4) Optional, small: an accessibility custom action on the Play area, "Pick randomly from 2–5 fingers", that runs a no-touch demo; skip unless demanded. (5) Debounce `announceCount` by 400 ms. |
| UX-26 | S2 | Orientation / text reading | Text (hint, count, Winner, Play Again) is always oriented to one side. At a table the group sits around the phone, so most players read it upside-down or sideways. | The product is explicitly a "gather round" device. | Don't rely on text. Make the colour fill, the halo and the haptic carry the result (already true). Keep text short and big; do not add more of it. Optionally let "Winner" sit at the opposite side from the winner (UX-07). |
| UX-27 | S2 | System gestures | Touches near the bottom edge can trigger the Home swipe, and at the top edge Control Centre or Notification Centre, cancelling touches (`touchesCancelled`) and the round. `.statusBarHidden(true)` is set; the home indicator is not hidden. | Spec §11 lists the notification gesture as an interruption. Edge fingers are common with 5+ players. | `PlayScreen`: `.persistentSystemOverlays(.hidden)` (hides the home indicator). For gesture deferral, host in a `UIHostingController` subclass that overrides `preferredScreenEdgesDeferringSystemGestures` to `.all`. Document that the first system swipe is deferred, and test on device. |
| UX-28 | S3 | Safe area, Dynamic Island, landscape | Overlay respects safe areas, the play layer ignores them (correct: fingers go anywhere). The status bar is hidden, so the gear sits just below the island (about y = 67pt on 15/16 Pro) and clear of it. In landscape the gear is inset by the 59pt side safe area; fine. The only issue is the stack padding (`.padding(.bottom, 24)`) on top of a 21pt landscape home-indicator inset, which pushes the stack higher than needed. | Looks fine; just check on device. | After UX-27 hides the home indicator, reduce to `.padding(.bottom, 16)`. Verify the gear is not under the island on an iPhone 16 Pro Max in landscape; add `.padding(.trailing, 8)` if it touches the rounded corner. |
| UX-29 | S3 | Pulse phase | Each `RingMarkerView` starts its own `repeatForever` pulse on appear, so fingers pulse out of phase. | Asynchronous breathing looks noisy; synchronized looks designed. | Drive the pulse from a shared `TimelineView(.animation)` phase, or a single `@State` in `PlayScreen` passed to each ring. 1.6 s is fine; consider 2.4 s for calmer. |
| UX-30 | S3 | Takeover curve | `timingCurve(0.16, 0.84, 0.3, 1.0, 0.9 s)` is front-loaded: most of the area is covered in the first ~0.4 s, so the last ~0.5 s is an imperceptible tail while the screen waits for `onCompleted`. Good feel, but wasteful. | The user waits through a visually finished screen. | Duration 0.7 s with `timingCurve(0.2, 0.8, 0.2, 1.0)`; keep the 0.35 s Reduce Motion fade. Fire `onCompleted` at 0.6 × duration (see UX-10). |
| UX-31 | S3 | Flash safety | One monotonic full-screen change per round; selector hops are at roughly 5–25 Hz on a single small ring with an area far under 25% of the screen, so no WCAG 2.3.1 general-flash issue. The idle ring pulse is slow. | Spec §8: avoid flashing patterns. | No change. Keep the rule: the hop-rate cap in UX-11 must not exceed 3 per second at full-screen scale (it doesn't). |
| UX-32 | S3 | Empty / error states | No empty, loading or error states exist, by design. Edge cases to verify: a single touch for a long time (no message beyond the footnote); touches over the device limit (silently ignored; the count is honest, which is right); haptics unavailable (silent no-op, correct); sound failure (silent no-op, correct); interruption returns to idle without explanation. | Nothing needs to be added. | After `interrupt()` returns to idle, the idle hint is enough. Do not add an error toast. |
| UX-33 | S3 | Selector flow vs `winnerPosition` copy | "Finger 3 of 4" is the order of touch ids, which the group does not perceive (the ordering isn't visible anywhere). | It adds a line of hierarchy that does not inform. | Replace the detail line with nothing (the halo says which finger), or "Third finger down" if ordinal is wanted. Keeping the line for VO only is acceptable. |
| UX-34 | S3 | Typography scale | Type scale is: title3 hint, footnote count, largeTitle bold winner, title3 detail, headline button. Reasonable and system-based. One style per role is good. RTL: `multilineTextAlignment(.center)`, `HStack` + `Spacer` and SF Symbols mirror correctly; the gear uses `HStack { Spacer(); gear }` which will mirror to the leading edge in RTL, which is fine. The result and the touch geometry are not mirrored (they should not be). | English-only for launch; nothing blocks localisation. | Use `.leading`/`.trailing` only (already true). When localising, avoid `frame(width:)` on text containers; the CountdownBar is a fixed-width capsule, which is fine. |

## 3. Polish backlog (ranked by impact ÷ effort)

1. **Swap overlay ink to dark everywhere and make the halo ink-coloured** (UX-01, UX-02). About 10 lines in `Theme` and `WinnerTakeoverView`. Highest visible quality gain and closes the contrast failures.
2. **Start the halo with the wave and fire the winner haptic and sound at impact** (UX-03, UX-04). About 10 lines in `WinnerTakeoverView` and `TouchSessionModel`. Single biggest "feel" improvement.
3. **Hide the gear outside idle; interrupt when Settings opens** (UX-05). 6 lines. Removes a round-breaking path.
4. **Reorder the palette** (UX-21). Array reorder; no new UI. Fixes colour-blind pairs in the common 4-finger case.
5. **Enlarge the ring and drop the centre dot** (UX-06). Constants only; needs a quick device check.
6. **Reserve the "Lift fingers" line, merge it into the button, animate the state change** (UX-08, UX-09). Removes the layout jump.
7. **Result entrance transition and earlier `onCompleted`** (UX-10, UX-30). 3 lines each.
8. **Ring-attached countdown arc** (UX-13). About 15 lines; makes the wait self-explanatory.
9. **Selector animation 0.07 s and tick throttle** (UX-11). 3 lines.
10. **Settings: `.medium` + `.large` detents, footers, preview feedback on toggle** (UX-18, UX-19).
11. **Dynamic Type cap and Increase Contrast** (UX-17, UX-23).
12. **Idle ghost ring** (UX-14). Small, but subjective: ship behind a design review.
13. **Hide home indicator / defer edge gestures** (UX-27). Needs device testing.
14. **Synchronised ring pulse** (UX-29).

## 4. Do NOT add (protect the single-purpose simplicity)

- No tab bar, navigation bar, toolbar or persistent bottom bar (spec §3).
- No onboarding, tutorial overlay, coach marks or "how to play" screen. The idle line is enough.
- No score, history, win counts, streaks, leaderboards or "who won last time" memory.
- No player names, avatars, per-finger labels typed by users, or team modes.
- No colour or theme picker, no light mode toggle, no "ring style" option; every extra Settings row is a regression against §9.
- No confetti, particles, screen shake, blur stacks or long victory animations; one wave and one halo is the whole payoff (and keeps flash safety trivial).
- No full-screen interstitials, rate-this-app prompts, permission pre-prompts or in-round banners.
- No persistent count or timer widgets while fingers are down; the count and arc are enough.
- No text-heavy result screen ("Congratulations", rankings, share sheets). A Share button would also pull in screenshots of other people's hands.
- No second screen for results; the winner state stays a state of the same surface.
- No auto-restart of rounds and no "tap anywhere to play again"; held-finger safety (§4.10) depends on the explicit Play Again.
- No decorative numerals inside the ring where the finger sits; any numeral or shape badge (UX-22) must sit outside the fingertip area and stay optional.
- No music, no continuous haptics, no looping ambient audio.
