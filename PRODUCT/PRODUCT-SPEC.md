# Product Specification — Finger Picker MVP

Status: Ready for implementation planning; product name and visual identity remain provisional.
Repository: davidpit1565/finger-party
Date: 2026-11-04

## 1. Product decision
Build one excellent, extremely simple iPhone utility: a multi-touch random finger picker. Do not turn the first release into a party-game platform.

The product promise: a group places fingers on one iPhone screen; the app fairly selects one of those active touches; a polished animation reveals the winner; the winning finger's color takes over the screen from the exact touch location.

The current repository name and working label “FINGER PARTY” are not approved final App Store branding. A competing app with a confusingly similar name exists. Brand/trademark clearance remains open.

## 2. MVP scope

### Included
- One primary experience: Finger Picker.
- Detect simultaneous finger touches and show a visible ring at each active touch coordinate.
- Give each active touch a distinct, high-contrast color from a controlled palette.
- Start a short, clear selection sequence when at least two fingers are down and the touch set has settled.
- Choose the winner randomly and independently from the visual animation.
- Animate a selector between active touch points, slowing down before revealing the preselected winner.
- Highlight the winner and animate a color expansion from the winner's exact touch coordinate until that participant's color fills the screen.
- Keep the winner's touch location as the origin of the final halo/radial glow even if the finger is lifted after selection.
- Provide a clear way to start another round.
- Optional sound and haptics, both independently switchable.
- Responsive layout for supported iPhone orientations.
- Local-only operation, no account, no backend, no ads, no analytics, no tracking.
- Accessible labels/announcements and reduced-motion alternative.

### Explicitly excluded from MVP
- Truth or Dare, dares, challenges, voting, team games, leaderboards.
- Accounts, profiles, social features, cloud sync, multiplayer over network.
- Subscriptions, paywalls, in-app purchases, coins, reward systems.
- Ads, third-party analytics, tracking SDKs.
- iPad-specific layout (can be considered after iPhone validation).
- User-created color packs and arbitrary custom colors; three curated color moods are included.
- Claims of unlimited players or guaranteed maximum simultaneous touches.

## 3. Navigation and information architecture

### Decision: no tab bar / no navigation bar
This app has one core task and no separate top-level sections. A tab bar would imply multiple destinations that do not exist and would add visual weight without helping users. Apple's HIG describes tab bars as navigation between top-level sections, not as a place for actions. A single-screen app should not invent tabs.

### Screen structure
1. Main play surface — the app opens directly here. No splash/onboarding screen beyond the native launch experience.
2. Settings sheet — opened by one small gear icon in a safe top corner. This is a temporary settings panel, not a destination requiring a tab.
3. Winner state — not a separate page; it is a state of the same full-screen play surface.

### Main screen visual hierarchy
- Full-bleed, calm, solid base background (initial visual direction: near-black / deep charcoal; final color token to be approved during visual design).
- No logo header, marketing text, cards, bottom navigation, or persistent toolbar.
- When idle: one short instruction, e.g. “Place 2 or more fingers”.
- When touches are active: glowing rings centered exactly on each touch; subtle count text may appear away from touch targets.
- Settings gear is discreet and never competes with touch interaction. It must not obstruct common touch areas.
- During selection: hide/disable settings and nonessential controls.
- Winner state: winner color becomes the dominant full-screen background via a radial/expanding reveal originating at the selected touch coordinate. Keep a visible halo/ring at that coordinate so the selected origin remains clear.
- After reveal: show a minimal “Play again” affordance. Avoid a permanent bottom bar.

## 4. Interaction flow
1. App opens directly to the play surface.
2. First touch appears as a ring at its precise location. The app does not select with only one touch.
3. When at least two simultaneous touches are present, show all touch rings and a subtle live count.
4. Once the touch set has been stable for approximately 600–800 ms, begin a short countdown (target around 1 second; tune through device testing). New touches during the settling/countdown window should be incorporated and restart the settle timer, so the group has a fair chance to place fingers.
5. At the start of the reveal sequence, freeze the participant set. Later touches are ignored until the round finishes.
6. Generate the winning participant using a uniform random choice from the frozen participant set. Do this before the reveal animation starts. Do not let animation timing, screen position, color, or visual path affect the result.
7. Animate the selector among participant positions with a quick, energetic movement and gradual deceleration. End exactly on the already-selected winner.
8. Winner ring intensifies. A colored radial/expanding wave begins at the winner's recorded coordinate and fills the entire screen with that participant's assigned color. The origin coordinate must remain stable for the whole reveal.
9. Show a minimal “Winner” state and a “Play again” action.
10. On replay, clear the previous round only after the user has initiated replay and all old touches have ended. Prevent a still-held finger from accidentally becoming a participant in the next round.

### Replay behavior
Preferred simplest behavior: after result, show “Lift fingers, then tap to play again”. Once the old touches are all released, enable replay. Tapping Play Again resets the surface to idle. Do not auto-start a new round while old fingers remain down.

## 5. Fairness and random selection
- Treat the set of touches present at the selection lock as the complete participant set.
- Assign each touch a stable internal identifier for the duration of the round.
- Select uniformly from that frozen set using Swift's system random source (e.g. SystemRandomNumberGenerator / unbiased integer range).
- Select winner before the animation; store winner ID and immutable final coordinate/color.
- The animation is a presentation of the result, never the source of the result.
- Do not bias based on touch order, screen position, color, finger size, or animation route.
- Add deterministic injectable randomness in tests so fairness and winner mapping can be verified.
- Never claim mathematically perfect randomness; describe it as random selection using the system random generator.

## 6. Touch and multi-touch behavior
- Use a UIKit-backed custom UIView with multiple-touch enabled, hosted inside SwiftUI. Do not rely solely on SwiftUI's standard tap gesture for simultaneous touch capture.
- Track each touch identity from began through moved/ended/cancelled.
- Store coordinates in a normalized coordinate space and map them to the visible play surface, accounting for safe areas and orientation changes.
- Update marker positions when a finger moves before the participant set is locked. Once locked, freeze each participant's captured coordinate for the reveal.
- Handle began, moved, ended, and cancelled touch events; clear cancelled touches safely.
- Clear touch state on app interruption/backgrounding, view teardown, orientation changes if the coordinate mapping becomes invalid, and system cancellation.
- No fixed maximum player count in marketing. The actual simultaneous touch limit must be tested on representative iPhone hardware. If the system/device limit is reached, show only detected touches and do not crash or imply additional participants were registered.
- Only physical finger touches are part of the intended experience; test accidental palm/edge contacts and accessibility interaction behavior.

## 7. Color system and visual design
- Base play background: one solid, dark neutral color (avoid busy gradients behind the touch markers).
- Each active touch gets a distinct color chosen from a curated accessible palette. Avoid assigning indistinguishable adjacent hues in a single round.
- Each marker: clear ring, soft glow, and restrained center treatment; avoid oversized markers that obscure neighboring touches.
- Winning color takeover: full-screen radial/expanding reveal originating at the winner's exact captured coordinate. Use a performant mask/shape or shader only if it remains stable on supported devices; a simple expanding radial gradient/mask is preferred over an unnecessarily complex rendering pipeline.
- Preserve a visible winner marker/halo after the fill animation.
- Ensure text and controls remain legible against every possible winner color; use adaptive contrast or a stable neutral overlay.
- Do not communicate winner identity by color alone: pair color with position, shape/halo emphasis, and VoiceOver announcement.
- Do not use color names as the only way to identify a participant.
- Final palette, typography, icon, and brand are not yet locked; visual identity must be reviewed before asset production.

## 8. Motion, sound, haptics, accessibility
- Motion should feel fast, playful, premium, and readable; no long wait or excessive flashing.
- Target reveal duration: roughly 2–3 seconds, adjustable after real-device testing.
- Sound effects should be short, original/licensed, bundled locally, and never streamed.
- Haptics should reinforce touch registration, selector ticks (sparingly), and final selection. Avoid continuous vibration or excessive repeated haptics.
- Provide separate Sound and Haptics toggles in Settings. Initial defaults: Sound off, Haptics on; confirm through user testing. Persist settings locally.
- Respect system Reduce Motion: replace rapid selector travel and expanding wave with a shorter fade/scale reveal while preserving the same selected result.
- VoiceOver: announce number of fingers detected where practical and announce selected/winner result. Ensure settings and replay controls have accessibility labels and adequate hit targets.
- Support Dynamic Type for any visible text, while keeping the play surface visually minimal.
- Avoid flashing patterns that could be uncomfortable or unsafe.

## 9. Settings
Only a small sheet with:
- Sound: On/Off.
- Haptics: On/Off.
- Color mood: Vivid / Cool / Warm (persisted locally).
- No general appearance or light/dark selector. Keep one consistent dark base play surface; the winner's assigned color defines the reveal.
- Privacy Policy link.
- Version/build number.

Do not add account, support chat, language selection, themes, or premium options to MVP. The launch language is English.

## 10. Platform and implementation direction
- iPhone-first native iOS app.
- Swift + SwiftUI for app structure and visual state.
- UIKit custom UIView for reliable multi-touch event capture, bridged into SwiftUI.
- SwiftUI / Core Animation for rings and winner reveal; prefer native performant primitives.
- Core Haptics when available, with UIKit haptic fallback where appropriate.
- AVFoundation or a simple local audio playback mechanism for bundled sound effects.
- UserDefaults or a small local settings store for two preferences; no database needed.
- No network calls required for core app behavior.
- Provisional minimum iOS target: iOS 17+ pending Xcode/current device compatibility and App Store deployment review. Do not silently change this without documenting why.

## 11. Reliability and edge cases
- Fewer than two touches: never start a selection.
- A finger lifts before participant lock: remove it from the candidate set.
- A finger lifts after lock: keep its frozen participant record and coordinate; the round continues.
- A finger moves before lock: update its marker position.
- A finger moves after lock: ignore movement for the locked participant.
- New finger during settle/countdown: include it and restart settling.
- New finger after lock: ignore until next round.
- All fingers lifted before minimum two touches: return to idle.
- System interruption / phone call / notification gesture / app background: cancel round safely, clear stale touch state, return to idle on resume.
- Rapid repeated taps or repeated replay: guard against duplicate state transitions.
- Screen rotation: keep coordinates correct or cancel current round and return to idle if safe mapping cannot be maintained.
- Low-power / reduced-motion: animations must still complete and reveal the same stored winner.
- Haptics unavailable: app still works silently.
- Sound playback unavailable/interrupted: app still works.
- No network: every feature in MVP remains fully functional.

## 12. Privacy and App Store readiness
- No account, no personal data collection, no analytics, no advertising, no third-party SDKs in MVP.
- Touch coordinates exist only in transient in-memory state for the current round; do not persist or transmit them.
- Store only local Sound and Haptics preferences.
- Publish a real Privacy Policy and Support page on GitHub Pages or another stable public host. The privacy policy must accurately describe actual shipped behavior, not planned behavior.
- Complete App Store Connect privacy declarations based on the final binary and all included SDKs; do not assume “no data collected” until dependency and binary review confirms it.
- Complete age rating questionnaire based on the actual app content. MVP contains no user-generated content, no dares, no adult content.
- Do not select the Kids category merely because children can use the app. Re-evaluate Kids category and parental gate requirements before choosing it.
- App Store screenshots must show the real app in use and accurately represent shipped features.
- App name must be distinctive and within Apple's 30-character limit. Do not use “Finger Party” as final name without clearance.
- App Review approval cannot be guaranteed.

## 13. Quality gates / acceptance criteria
The MVP is not considered complete until all are true:
1. Two or more real simultaneous touches are registered reliably on physical iPhones.
2. Each touch marker remains aligned with the actual finger across portrait and landscape supported layouts.
3. Touches are added/removed/moved/cancelled without stale participants.
4. Winner is selected uniformly from the frozen participant set before animation.
5. Automated tests verify winner mapping and no dependence on animation position/order.
6. Animation always ends on the stored winner.
7. Winner color reveal starts at the stored winner coordinate and fills the screen without visible seams or frame drops on target devices.
8. Replay cannot reuse a held touch or trigger accidentally.
9. Sound and haptics toggles work and persist.
10. Reduce Motion alternative works.
11. VoiceOver labels/announcements and contrast are checked.
12. No crash or stuck state after interruptions, orientation changes, or rapid repeated interaction.
13. Offline test passes with networking disabled.
14. Privacy policy, support page, app metadata, icon, screenshots, and privacy declarations match the actual build.
15. Test on physical hardware, not simulator alone.

## 14. Research basis
- Apple HIG: tab bars are for navigating among top-level sections; they are not needed for this one-task MVP. https://developer.apple.com/design/human-interface-guidelines/tab-bars
- Apple UIKit: UIView multi-touch must be enabled to receive more than one touch in a multi-touch sequence. https://developer.apple.com/documentation/uikit/uiview/ismultipletouchenabled
- Apple UIKit: handle system-cancelled touch sequences and clean up touch state. https://developer.apple.com/documentation/uikit/uiresponder/touchescancelled%28_%3Awith%3A%29
- Apple Core Haptics: supports custom transient and continuous haptic patterns. https://developer.apple.com/documentation/CoreHaptics
- Apple App Review Guidelines: app completeness, accurate metadata, name length, in-app purchases, privacy policy, and review requirements. https://developer.apple.com/app-store/review/guidelines/

## 15. Open decisions before public launch (not blockers for starting implementation)
- Final app name and trademark clearance.
- Final icon and visual identity.
- Exact color palette and motion curve after device prototype.
- Final minimum iOS version after checking target-device coverage.
- Final sound default can be tuned during device/user testing; initial implementation default: sound off to avoid unexpected public audio, haptics on.
- Exact App Store age rating after final questionnaire.
- Public support/privacy URLs after GitHub Pages is enabled and verified.
