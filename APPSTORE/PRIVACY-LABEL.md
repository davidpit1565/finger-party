# App Privacy ("nutrition label") answers for App Store Connect

Status: draft for the owner to enter in App Store Connect > App Privacy. Must be re-verified against the final binary and dependency list before submission (PRODUCT-SPEC section 12). The questions in App Store Connect may be reworded; the substance below should still map.

## Answers

| Question | Answer |
|---|---|
| Do you or your third-party partners collect data from this app? | **No, we do not collect data from this app** |
| Resulting label | **Data Not Collected** |
| Does the app use data for tracking (App Tracking Transparency definition)? | **No** |
| Privacy Policy URL | https://davidpit1565.github.io/finger-party/privacy.html |

Because the first answer is "No", App Store Connect will not ask for data types, purposes, or linkage. Do not add any data type.

## Why "Data Not Collected" is accurate (tied to the app)
Apple defines "collect" as transmitting data off the device in a way that lets the developer or a third-party partner access it for longer than needed to service the request in real time. The app transmits nothing.

| Item in the app | Where it lives | Collected? |
|---|---|---|
| Touch positions (finger coordinates) | In memory only, for the current round; never written to disk, never sent | No |
| Sound on/off, Haptics on/off | UserDefaults on the device; never sent | No (local, on-device only) |
| Network access | None. The app makes no network calls and has no backend, accounts, API, or analytics | n/a |
| Third-party SDKs | None. No analytics, ads, attribution, crash-reporting, or social SDKs. Only Apple system frameworks (SwiftUI, UIKit, Core Haptics, AVFoundation) and the project's own local Swift package FingerPickerCore | n/a |
| Permissions / sensors | None requested: no camera, microphone, location, contacts, photos, tracking | n/a |
| Identifiers | No IDFA, no IDFV use, no device ID, no user ID | No |
| Purchases, health, financial, contacts, user content, diagnostics, usage data | None | No |

## Verification steps before entering the answer (owner or release lead)
1. Confirm `project.yml` / the final Xcode project lists no remote Swift packages, CocoaPods, or xcframeworks beyond `FingerPickerCore` (local).
2. `grep -rE "URLSession|URLRequest|NWConnection|WebKit|WKWebView|SFSafariViewController|ASIdentifierManager|AppTrackingTransparency"` over `App/` and `Packages/` returns nothing relevant. (The Settings Privacy Policy link, if it opens in Safari via `openURL`, is a link out to a web page, not data collection by the app; note it in review notes if reviewers ask.)
3. Info.plist contains no `NSUserTrackingUsageDescription` and no usage-description keys for sensors.
4. `PrivacyInfo.xcprivacy`: Apple requires declaring use of "required reason APIs". UserDefaults is one of them. The app should ship a privacy manifest with `NSPrivacyTracking = false`, no tracking domains, no collected data types, and an `NSPrivacyAccessedAPITypes` entry for `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1` (access info from the app's own UserDefaults). **This is a build task for the app agent; I did not verify whether it exists in the repo.**
5. After the first TestFlight upload, check the build's processing email/App Store Connect warnings for missing-manifest or API-reason notices.

## If this changes
Adding analytics, ads, accounts, cloud sync, crash reporting, or any SDK requires updating this label, the Privacy Policy (docs/privacy.html), and the release notes before that version ships.
