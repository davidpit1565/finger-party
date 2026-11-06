# App Store / TestFlight metadata (provisional)

Status: draft for owner approval. Nothing here has been entered into App Store Connect. Character counts below were computed by script (Python `len`), against Apple's limits as I understand them (name 30, subtitle 30, promotional text 170, keywords 100, description 4000, what's new 4000, review notes 4000). Confirm limits in App Store Connect at entry time.

## 1. Name candidates and collision check

Why not the working names: "Finger Party" collides with existing apps (e.g. "Finger's Party", "Finger Party: Steady Challenge") and a Steam game (see RESEARCH/03). Descriptive names like "Finger Picker" / "Finger Chooser" are used by dozens of existing apps, so they are not distinctive.

### What I searched (2026-11-04)
1. Web search (WebSearch) for each candidate name plus "app store" / apps.apple.com.
2. Apple iTunes Search API (`itunes.apple.com/search?entity=software&country=us&limit=10`) for each candidate. **US storefront only, top-10 results, software only.** Not run for other countries.
3. For the two finalists, a web search for trademark-database aggregator pages (USPTO mirrors, not the official TSDR/EUIPO/WIPO tools).

### Findings
| Candidate | Result | Verdict |
|---|---|---|
| Glowpick | An existing iPhone app "Glowpick" (Korean beauty ranking, Lifestyle, id917232329) is on the App Store. | Collision. Reject. |
| Halo Pick / Halopick | No app by that name found. Results are "Halo"-branded games (Microsoft franchise) and unrelated apps. | No app found, but "Halo" trademark risk. Reject. |
| Fingerlight | No exact match; a similar app "Finger Light" (light-trail app, id6757989477) exists. | Too close. Reject. |
| Touchglow | No app by that name found (US API, 3 spellings). A TOUCHGLOW USPTO filing (Class 11, lighting) appears dead; "TOUCH GLOW" registrations exist in Class 10 (medical) and "TOUCH + GLOW"/"TOUCH & GLOW" in Class 3 (cosmetics). A similarly named app "TouchLuck" and "Touch Roulette: Finger Chooser" exist. | No app collision found, but more trademark noise. Backup only. |
| Lumapick / Luma Pick | No app, software or brand by that name found in 3 web searches and 2 iTunes searches (results were unrelated "Luma"/"Lume" apps). | **No obvious collision found in 5 searches.** |

"Pick a Finger: Picker", "PickMe - Finger Chooser", "FingerPick", "Touch & Pick", "Tap Roulette", "Chooser - Finger Picker", "Lucky Tap" etc. already exist (see RESEARCH/03), so any name built from "finger/pick/chooser/touch" alone is crowded.

**This is not clearance.** No official trademark search (USPTO TSDR, EUIPO eSearch, TMview, WIPO Global Brand Database), no non-US storefronts, no Google Play, no domain/social-handle check was done. "Luma" is a common word-part in other brands (e.g. other "Luma" software products), so a trademark search in Class 9/41 is needed. The only real availability test is creating the app record in App Store Connect.

## 2. Recommended provisional name

**Lumapick** (8/30). Fallback: Touchglow.

Note: the app's current `CFBundleDisplayName` is "Finger Picker" and the GitHub Pages site says "Finger Picker" (working title). If the name above is approved, update the display name in `project.yml` and the site text. The App Store name can differ from the on-device display name, but keeping them close avoids confusion.

## 3. Store listing fields

| Field | Value | Count |
|---|---|---|
| Subtitle | Fair finger picker for groups | 29/30 |
| Category | Primary: Entertainment. Secondary (optional): Utilities. Not Kids, not Made for Kids. | n/a |
| Support URL | https://davidpit1565.github.io/finger-party/support.html | n/a |
| Privacy Policy URL | https://davidpit1565.github.io/finger-party/privacy.html | n/a |
| Marketing URL (optional) | https://davidpit1565.github.io/finger-party/ | n/a |
| Copyright | 2026 <owner name - to be provided> | n/a |
| Price | Free, no in-app purchases | n/a |
| Languages | English (U.S.) | n/a |
| Platforms | iPhone only, iOS 17.0+ | n/a |

These URLs only work after GitHub Pages is enabled (see TESTFLIGHT-RUNBOOK.md). Do not paste them into App Store Connect until they return 200.

### Promotional text (155/170)
```text
Who goes first? Everyone puts a finger on the screen and one is picked at random, with the winner's color filling the screen. Offline, no ads, no accounts.
```

### Keywords (96/100, comma-separated, no spaces after commas)
```text
finger picker,finger chooser,who goes first,random,multi-touch,group,decide,choose,fair,pick one
```
Notes: the app name and category are already indexed, so they are not repeated. Words such as "game" are omitted because the app is a utility. Competitor names are deliberately not used (Guideline 2.3.7 / trademark).

### Description (1270/4000)
```text
Everyone puts a finger on the screen. One finger is picked at random.

Use it to decide who goes first, who pays, who takes the first turn, or any other everyday tie-break.

HOW IT WORKS
- Place two or more fingers on the screen. Each finger gets its own glowing ring.
- Hold still. A short countdown starts, and anyone who joins before it ends is included.
- When the countdown ends, the group is locked in and one finger is chosen at random from everyone who was touching.
- The winning finger's color spreads from where it touched and fills the screen.
- Lift your fingers and play again.

FAIR
The pick is made with the system random number generator after the group is locked, before the animation starts. It does not depend on touch order, screen position, or color.

SIMPLE
- One screen, no menus to learn.
- Works in portrait and landscape.
- Sound and haptics can each be switched on or off in Settings.
- Reduce Motion is respected with a simpler reveal.

PRIVATE
- Works fully offline.
- No accounts, no ads, no analytics, no third-party SDKs.
- Touch positions are used only during a round and are never saved or sent anywhere.

The number of fingers that can be tracked at once depends on your iPhone and iOS.

Requires iPhone with iOS 17 or later. English.
```

Accuracy checklist: every sentence maps to shipped MVP behavior (PRODUCT-SPEC sections 2, 4, 5, 8, 9, 12). No "unlimited players", no max-touch claim, no game modes, no themes, no ads/IAP claims beyond "none". Re-verify against the final build before submission.

## 4. TestFlight text

### What's New / Beta App Description note (188/4000)
```text
First TestFlight build. Core finger picker: place two or more fingers, a short countdown, one random winner, and the winner's color fills the screen. Sound and Haptics toggles and a finger color mood choice in Settings.
```

### What to Test (835/4000)
```text
Thanks for testing! Please try:
1. Place 2, 3, 4, 5 or more fingers (you can use several people). Do the rings stay under every finger?
2. Add a finger during the countdown. It should be included and the countdown should restart.
3. Add a finger after the winner reveal begins. It should be ignored.
4. Lift all fingers and tap Play again.
5. Rotate between portrait and landscape.
6. Turn Sound and Haptics on and off in Settings (gear icon). Check they stay as set after relaunching.
7. Turn on Reduce Motion (iOS Settings > Accessibility > Motion) and play a round.
8. Interrupt a round (pull down notifications, open Control Center, switch apps). The app should return to the start screen.
Please report: your iPhone model and iOS version, how many fingers were tracked at most, and any stuck screen, wrong ring position, or crash.
```

### Beta App Review information (needed for external testing only)
Internal testing (up to 100 internal testers, App Store Connect users) does not require Beta App Review. External testing does, and needs: Beta App Description, feedback email, contact info, and no sign-in info (none needed). Those contact details must be supplied by the owner; none are invented here.

## 5. App Review notes (1061/4000)
```text
Finger Picker is a single-screen utility. Two or more people place fingers on the screen; after a short countdown the app picks one touch at random and fills the screen with the winner's color.
No account or sign-in is needed, so no demo credentials are provided.
The app is fully offline: no network calls, no analytics, no ads, no third-party SDKs, no in-app purchases. It stores only three local on-device preferences (Sound, Haptics, finger color mood). Touch positions exist only in memory during a round and are never saved or sent.
It requests no permissions (no camera, microphone, location, contacts, photos).
To test: launch the app, place two or more fingers on the screen at the same time (a physical device is best; a single touch never starts a round), keep still for the countdown, and observe the winner reveal. Lift all fingers and tap Play again. Settings (gear icon) has Sound, Haptics, Privacy Policy link and version.
The app is not directed to children and is not in the Kids category. Contact for review: to be provided by the account holder in App Store Connect.
```

## 6. Export compliance
- Question: "Does your app use encryption?" The app makes no network calls and implements no cryptography of its own; it uses no encryption beyond what Apple's operating system provides (and in this app, nothing at all is transmitted).
- Answer: **No** to non-exempt encryption. Set `ITSAppUsesNonExemptEncryption = NO` (already present in `project.yml` as `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO`), so App Store Connect does not prompt for export documentation on each build.
- Re-check if any networking, third-party crypto library, or custom encryption is ever added.

## 7. Other App Store Connect answers
- App Privacy: see PRIVACY-LABEL.md.
- Age rating: see AGE-RATING.md.
- Content rights: does not contain, show, or access third-party content.
- Advertising identifier (IDFA): No.
- Sign-in required: No.
- Screenshots: see SCREENSHOTS.md.

## 8. Items the owner must supply
Copyright holder name, review contact (first name, last name, phone, email) and beta feedback email, app icon final art, final app name decision, trademark search.
