# FINGER PICKER — FULL VISUAL REDESIGN & RELEASE QUALITY BRIEF
Date: 2026-11-06
Target branch: claude/finger-picker-mvp
Status: owner-approved direction based on feedback: current UI feels robotic, lifeless and boring. Visual design is the top priority.

## 1. Product direction

Transform the current sterile finger-selection utility into a polished, energetic, premium-feeling party arcade experience.

The product must feel:
- Alive, playful, expressive and exciting.
- Instantly understandable without onboarding.
- Premium and intentional, not childish and not visually noisy.
- Fast and responsive, with tactile feedback.
- Distinctive enough to be recognizable in a crowded finger-picker category.

Do not add dares, truth-or-dare, missions, teams, voting, accounts, ads, subscriptions, backend, analytics or unnecessary navigation. Keep the single-purpose multi-touch picker.

## 2. New art direction: ELECTRIC PLAYROOM

This supersedes the previous requirement for a completely flat solid background. Keep the play field visually calm enough for fingers to be clearly visible, but give it depth and energy.

Palette direction:
- Deep midnight ink base: approximately #090D1C.
- Electric cyan, hot coral, vivid violet, acid lime and warm amber as participant colors.
- Use controlled radial light fields / soft aurora gradients, not a flat black void.
- Keep contrast and color distinction strong. Do not rely on hue alone.

Visual language:
- Layered light, crisp shapes, depth, kinetic motion and tactile feedback.
- Use SwiftUI Canvas / native Core Animation / gradients / efficient shapes where possible.
- Avoid expensive stacks of blur/shadow effects that cause frame drops or heat.
- Avoid generic stock graphics, emoji as primary UI, excessive glassmorphism, random decoration and childish cartoon characters.
- Keep the main play surface unobstructed. The fingers and their markers are the heroes.

## 3. Idle state — create anticipation

Replace the empty black screen with a designed, animated invitation:
- A distinctive central visual motif made from 3–5 orbiting / pulsing colored rings or energy nodes, representing multiple fingers converging.
- A strong, concise instruction such as “Bring everyone in” with secondary “Place 2 or more fingers”.
- A subtle living ambient movement: slow light drift, gentle ring breathing, small controlled orbit motion.
- The Settings control remains discreet and accessible.
- The idle illustration must disappear / gracefully transition as soon as real touches arrive; it must never block or intercept touches.
- No onboarding carousel or extra pages.

## 4. Touch state — make the screen come alive

When each finger touches:
- Marker appears with a satisfying spring/pop and a short expanding ripple.
- Its color is immediately distinct; ring has a crisp bright edge, layered halo and subtle inner energy.
- Each participant gets a unique color; maintain readable contrast.
- A participant count appears in a compact, attractive live indicator, e.g. “4 IN”.
- Add a subtle connecting energy cue only if it improves clarity; do not draw lines that imply a team or change fairness.
- Markers should have gentle breathing motion while waiting, but avoid distracting continuous movement.
- Movement and effects must remain smooth with 2–10 simultaneous touches; profile on a real device.

## 5. Countdown and selection — build tension

- Make the transition from collecting to countdown visually unmistakable.
- Use a bold kinetic countdown (3–2–1 or an equivalent short sequence) with a clear scale / opacity / light impact.
- Keep the entire experience fast. Measure the time from the last stable touch to result. Aim for a total reveal that feels snappy, and test alternatives rather than arbitrarily slowing it down.
- Selector should visibly travel between the real participant positions with a short luminous trail / pulse.
- Haptics and optional sound should be synchronized with selector steps, not delayed or noisy.
- Respect Sound and Haptics settings and Reduce Motion.
- Crucial fairness invariant: choose the winner uniformly and independently before the animation. The animation must only dramatize that already-selected winner. Never derive the result from position, touch order, color, or selector path.

## 6. Winner moment — signature experience

The winner reveal is the most important signature moment:
- Preserve the exact frozen coordinate of the selected touch, even if the finger lifts.
- Keep the expanding color wave originating from that exact coordinate.
- Improve the wave with a controlled energy edge / radial light / brief celebratory burst.
- The winner marker remains visible at the origin after the wave.
- The final state should feel like a celebration, not just a flat yellow screen.
- Present a strong result hierarchy: “WINNER”, a clear participant label such as “Finger 3”, and a visually compelling “Play Again” CTA.
- Keep the CTA readable and reachable, without covering the winner origin or creating a layout jump.
- Use restrained confetti / radial streaks / particles only during the reveal and winner moment. Keep performance and Reduce Motion safe. No endless confetti.
- Ensure text contrast automatically adapts to the winner color.
- Add a short, satisfying completion haptic; sound remains optional.

## 7. Motion and sound quality

Create a motion system with consistent timing and easing:
- Touch arrival: quick spring / pop.
- Ambient idle: slow and subtle.
- Countdown: clear, rhythmic and energetic.
- Selector: accelerating / decelerating rhythm with crisp stops.
- Winner: one decisive expanding wave and a short celebration.
- Replay: clear reset to idle, no stale touches and no abrupt flashes.

Avoid:
- Animations that run forever at high CPU/GPU cost.
- Repeated flashing, strobing, rapid high-contrast patterns.
- Random motion that distracts from the touch targets.
- Audio on by default in a public setting. Preserve the existing user setting / safe default.
- Haptics firing repeatedly at an uncomfortable intensity.

## 8. UX / accessibility

- Keep one screen and one primary action. No tab bar, no mode carousel, no unnecessary screens.
- Settings remain a small sheet for Sound, Haptics, Privacy Policy and version.
- Keep hit targets and text accessible.
- Support VoiceOver and Dynamic Type. Avoid announcing every tiny touch movement; announce meaningful state changes only.
- Respect Reduce Motion with a deliberate reduced-motion presentation, not a broken or empty screen.
- Ensure all participant colors remain distinguishable; use shape / halo / label cues where appropriate.
- Ensure winner copy and Play Again remain legible on every palette color.
- Test portrait and landscape; avoid controls overlapping active touch areas.

## 9. Technical audit and fixes

Inspect the current implementation before changing it. Keep the existing separation between FingerPickerCore selection logic and SwiftUI presentation unless a measured issue requires refactoring.

Must verify:
- isMultipleTouchEnabled = true and correct touch identity tracking.
- Began / moved / ended / cancelled touch paths.
- New touches during settling/countdown restart or update according to the product spec.
- Locked participant set is stable once reveal begins.
- Random winner selection is uniform and independent of animation.
- Frozen winner coordinate persists after touch-up.
- Interruptions, app backgrounding, rotation, view teardown and replay cannot leave stale touches or stuck phases.
- No view overlay blocks touches.
- Haptics/sound are cancellable and respect settings.
- No retain cycles or unbounded Tasks / Timers.
- No privacy data collection or new third-party SDKs.
- No regression to offline behavior.

## 10. QA and real-device acceptance

Run and report:
1. Swift package tests.
2. iOS Simulator build + unit tests + UI tests.
3. Snapshot tests for idle, 2 fingers, 4 fingers, countdown, selector, winner and settings.
4. Accessibility / Reduce Motion checks.
5. Performance checks for animation frame pacing and CPU/GPU usage.
6. Real iPhone tests for simultaneous 2, 3, 4, 5+ fingers, edge touches, fast lift/re-touch, interruption, rotation, replay, sound and haptics.

Simulator-injected touches are not proof of physical multi-touch. Mark physical-device tests as NOT RUN unless they were actually performed on a real iPhone. Never fabricate results.

## 11. App Store and release preparation

- Update design notes and screenshots to match the final implementation.
- Capture actual screenshots from the built app. Do not submit backdrops or mockups as app screenshots.
- Produce a short screen recording / GIF for internal review if practical.
- Verify app icon at small sizes and against competing icons; refine if it looks generic.
- Verify PrivacyInfo.xcprivacy and App Privacy claims against the final binary and dependencies.
- Verify Privacy Policy and Support pages are live and accurate.
- Verify bundle ID, signing, Release archive and App Store Connect metadata.
- Upload to internal TestFlight only when signing and App Store Connect access are actually available.
- Do not submit for public App Review or change legal, banking, tax or paid-app agreements without explicit owner approval.

## 12. Execution rules

Use parallel subagents for independent work:
- Visual design / motion system.
- SwiftUI implementation.
- Touch / state / fairness technical review.
- QA / accessibility / performance.
- App Store assets / metadata / privacy.

The lead agent owns integration, resolves conflicts, runs the full test suite after merging agent work, and verifies the final result. Do not have agents edit the same files simultaneously. If subagents are unavailable, state that honestly.

Do not stop after writing a plan or mockup. Implement the redesign in the existing project, generate real previews/screenshots, run CI, inspect the screenshots and iterate until they look polished. Commit the work to this branch and update the PR. Do not merge into main without owner approval.

## 13. Definition of done

The redesign is done only when:
- The idle screen no longer looks empty or generic.
- Touches visibly bring the app to life.
- Countdown and selector feel exciting and responsive.
- Winner reveal is a memorable signature moment.
- The UI remains clean, readable and usable with many fingers.
- All automated tests pass.
- Actual simulator screenshots have been inspected and updated.
- Physical-device and TestFlight status are reported truthfully, with any remaining blockers clearly listed.
