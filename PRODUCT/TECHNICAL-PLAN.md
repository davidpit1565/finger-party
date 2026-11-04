# Technical Plan and Build Contract — Finger Picker MVP

Status: Implementation plan; no app source code is claimed to exist yet.
Repository: davidpit1565/finger-party
Date: 2026-11-04

## 1. Architecture
Use a small native architecture. Avoid overengineering, third-party dependencies, server infrastructure, or multi-module frameworks.

Suggested structure (adapt names to the actual Xcode project):
- App entry / App lifecycle
- PlayScreen (SwiftUI composition)
- TouchCaptureView (UIKit UIView subclass; multiple-touch event source)
- TouchSessionModel (single source of truth for current round state)
- SelectionEngine (pure deterministic-testable random selection)
- SelectionAnimation (visual presentation only)
- WinnerRevealView (radial/expanding color takeover)
- SettingsStore (local Sound/Haptics preferences)
- HapticsService (Core Haptics with graceful fallback)
- SoundService (local bundled sounds)
- Accessibility support and tests

Do not create abstractions without a clear need. A single app target plus a test target is sufficient for MVP.

## 2. State machine
Define explicit states; do not let view booleans create contradictory states.

- idle: no active round; prompt user to place fingers.
- collecting: one or more active touches; no selection until at least two.
- settling: two or more touches are stable; new touches reset the settle timer.
- countdown: short countdown before lock; new touches within the allowed window reset to settling.
- locked: freeze participant IDs, coordinates, and colors; calculate winner exactly once.
- revealing: animate selector and winner color takeover.
- result: winner screen remains visible; wait for all previous touches to be released and user replay action.
- cancelled: system interruption or invalid coordinate/layout; clean up and return to idle.

All transitions must be explicit and testable. The selection engine must be called once per round only.

## 3. Touch capture contract
TouchCaptureView:
- Enable multiple simultaneous touch delivery on the UIView.
- Use UITouch identity for active touch map keys.
- On began: create touch record and normalized point.
- On moved: update normalized point while collection is open.
- On ended: mark ended/remove from active candidate set only before lock.
- On cancelled: same cleanup; never leave stale touches.
- Forward immutable snapshots to the model on main actor.
- Keep UIKit event handling separate from SwiftUI rendering.
- Never use screen-global coordinates; use the actual play surface bounds.
- Convert coordinate space consistently and test orientation/safe-area changes.
- Ignore stylus/pencil if distinguishable and out of product scope; verify expected device behavior.
- Avoid using a gesture recognizer that consumes the multi-touch stream.

Use UIViewRepresentable to host TouchCaptureView in SwiftUI. Do not put an opaque interactive overlay above it that intercepts touch delivery.

## 4. Selection engine
Pure function contract:
Input: frozen array of unique Participant records.
Output: one selected Participant ID.
Rules:
- Reject fewer than two participants or prevent the call at the state-machine layer.
- Use SystemRandomNumberGenerator with uniform integer selection over valid indices.
- Inject RNG in unit tests to test edge cases and mapping.
- Select before starting animation.
- Keep immutable winnerID, winnerColor, and winnerPoint for the round.
- Animation receives the precomputed result and cannot call random selection.

Test:
- zero/one participant is rejected or never passed to engine.
- every valid index can be returned by deterministic test RNG.
- duplicate touch IDs are not accepted.
- animation end target equals stored winner ID.
- touch order, color, and coordinate do not alter selection logic.

## 5. Animation contract
- Markers track touches during collection.
- On lock, freeze points.
- Selector route is a visual sequence across participant markers, generated after winner is already known.
- Selector must stop at winnerID.
- Use smooth deceleration, restrained glow and a short final emphasis.
- Winner reveal expands from winnerPoint using winnerColor and covers the whole play surface.
- Use a stable coordinate transform for winnerPoint. If view bounds change during reveal, either transform normalized coordinates into new bounds or cancel cleanly.
- Ensure no visible blank seam at screen edges.
- Avoid expensive blur stacks or per-frame full-screen particle systems until profiling proves they are safe.
- Add Reduce Motion path.
- Do not use random animation outcome to choose the winner.

## 6. Settings and persistence
- Persist only Sound and Haptics toggles (and appearance only if retained).
- Use UserDefaults / AppStorage; no database or cloud.
- Settings sheet has only the controls required for MVP plus Privacy Policy and version/build.
- Settings must not open over an active collection/selection round.
- Default sound/haptic behavior must be verified in user testing; do not play loud or repeated sounds automatically.

## 7. Privacy / network contract
- No backend, no account, no API, no network dependency for play.
- No analytics, ad SDK, attribution SDK, social SDK, or third-party SDK in MVP.
- No touch coordinate persistence.
- No personal data collection intended.
- Keep dependency list empty if possible.
- Privacy declarations must be checked against the final dependency graph and built binary, not just source-code intention.
- Privacy Policy must describe actual release behavior.
- If any dependency is introduced, document its purpose, data behavior, license, and App Store privacy implications before merging.

## 8. Testing plan

### Unit tests
- State machine transitions.
- Minimum participant threshold.
- Touch lifecycle and cancellation cleanup.
- Settling timer reset logic (inject a clock/scheduler rather than using real sleeps).
- Random selection mapping with deterministic RNG.
- Exactly one winner per round.
- Winner point/color immutable after lock.
- Replay gating and old-touch release behavior.
- Settings persistence.
- Reduce Motion route selection.

### UI / integration tests
- Idle prompt.
- Two+ participant markers.
- Countdown reset when a new participant joins.
- Locked round ignores late touches.
- Winner reveal from exact recorded coordinate.
- Replay disabled until old touches lift.
- Sound/Haptics controls.
- VoiceOver accessibility labels.
- App background/interruption returns safely to idle.

### Physical-device test matrix
At minimum:
- One current iPhone model.
- One older supported iPhone model.
- Portrait and landscape.
- Simultaneous 2, 3, 4, 5+ touches where hardware permits.
- Different screen sizes and Dynamic Island/notch safe areas.
- Reduce Motion enabled.
- Haptics disabled / unavailable.
- Sound muted / audio interruption.
- Incoming notification / app background / Control Center interruption.
- Fast repeated rounds and repeated replay.
Do not claim a maximum touch count until measured on the supported devices.

## 9. Performance and stability
- Keep touch handling responsive; avoid doing heavy animation or random work inside UIKit touch callbacks.
- Update state efficiently; coalesce visual updates if necessary.
- Profile animation on real hardware.
- Avoid memory leaks retaining UITouch objects beyond the round; retain stable IDs and coordinates only.
- Ensure animation completion cannot fire twice and state transitions are idempotent.
- Test app lifecycle interruptions and touch cancellation.

## 10. Build and repository safety
- Inspect repository contents before creating project files. Do not overwrite research docs.
- Confirm independent bundle identifier for this app; do not reuse bundle IDs or assets from the user's other projects.
- Keep signing assets, certificates, provisioning profiles, API tokens, App Store Connect keys, and personal data out of Git.
- Add appropriate .gitignore before Xcode build artifacts are generated.
- Keep public source repository free of secrets.
- Use a clear branch/commit strategy; do not rewrite history or force-push.
- Every implementation phase must end with build + relevant tests + concise report of changed files, commit SHA, test results, and unresolved issues.
- Never claim a build, simulator test, physical-device test, upload, or App Store submission succeeded unless the actual command/tool output confirms it.
- Keep the app UI copy in English. All project instructions and Claude Code prompts are written in Hebrew for the user.

## 11. Build phases
1. Repository and Xcode environment audit; verify existing files and toolchain.
2. Create minimal Xcode project and app skeleton; confirm clean build.
3. Implement multi-touch capture and state machine; add tests.
4. Implement fair random selection engine and deterministic tests.
5. Implement markers and collection UI.
6. Implement selector animation and winner color takeover.
7. Add replay flow, sound/haptics, settings.
8. Add accessibility, Reduce Motion, orientation and interruption handling.
9. Physical-device QA and performance pass.
10. Create privacy policy and support pages based on actual implementation; enable and verify public hosting.
11. Create icon, screenshots, metadata and App Store Connect privacy/age declarations.
12. Archive, validate, upload only with explicit owner authorization; owner reviews and submits to Apple.
13. Track App Review feedback and fix verified issues.

## 12. Definition of ready for App Store submission
Do not call the app ready merely because it compiles. Submission-ready requires:
- All product acceptance criteria in PRODUCT-SPEC.md pass.
- Unit/UI tests pass and physical-device QA documented.
- No known critical or high-severity bugs.
- Final name and trademark risk reviewed.
- Privacy policy and support URLs live and tested.
- App Store metadata, age rating, privacy declarations and screenshots complete and truthful.
- Release archive validated.
- App Store Connect record and build are correct.
- Account owner has reviewed and approved submission.

Apple approval is external and cannot be guaranteed.
