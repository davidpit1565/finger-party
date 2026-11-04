# TestFlight runbook

Legend: [OWNER] only the Apple Developer Account Holder / repo owner can do this. [AUTO] done by the GitHub Actions workflow. [LEAD] written by the release lead (code/workflow). Nothing here has been executed; no upload, signing, or App Store Connect action has been performed by the agents.

## 0. What the agents cannot do
- Accept agreements, create the app record, create API keys, set GitHub secrets, or enable GitHub Pages (all need the owner's logins).
- Submit to App Review. **App Review submission is NOT performed without the owner's explicit approval.** TestFlight internal testing needs no App Review.

## 1. Apple Developer prerequisites [OWNER]
1. Active Apple Developer Program membership (paid) for the account that will own the app.
2. The **Account Holder** signs in to App Store Connect (appstoreconnect.apple.com) and developer.apple.com and accepts any pending updated agreements (Apple Developer Program License Agreement, and the Paid Apps agreement banner if shown). Until this is done, uploads and app creation can fail with agreement errors. Banking and tax forms are **not needed** for a free app with no in-app purchases, and must be left untouched.
3. Note your **Team ID** (developer.apple.com > Membership details). It is a 10-character string; it goes into the secret `APPLE_TEAM_ID`.
4. Enrollment, legal entity name and seller name shown on the App Store come from the account; the "copyright" line in METADATA.md needs the owner's chosen name.

## 2. Bundle ID and app record [OWNER]
1. developer.apple.com > Certificates, IDs & Profiles > Identifiers > "+" > App IDs > App. Explicit Bundle ID: `com.davidpit.fingerpicker` (matches `project.yml`). No capabilities are needed (no push, iCloud, Sign in with Apple, etc.). With automatic signing the workflow can also register it, but doing it by hand is clearer.
2. App Store Connect > Apps > "+" > New App: Platform iOS; Name (the final/provisional name from METADATA.md; must be unique on the App Store); Primary language English (U.S.); Bundle ID `com.davidpit.fingerpicker`; SKU any internal string (e.g. `fingerpicker-001`); User Access: Full Access.
3. If the name is rejected as taken, pick the fallback or a new name; the app record can be renamed until first submission.

## 3. App Store Connect API key -> GitHub secrets [OWNER]
1. App Store Connect > Users and Access > Integrations > App Store Connect API > Team Keys > Generate. Name: `github-actions-testflight`. Access: Admin is the safest for automatic signing with `-allowProvisioningUpdates` (cloud-managed distribution certificate); App Manager may be enough, not verified. Only the Account Holder/Admin can create it.
2. Record the **Issuer ID** (top of the page) and the **Key ID**. Download the `.p8` file **once**; Apple will not show it again. Never commit it, paste it into chat, or email it.
3. Base64 it on your computer: `base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy` (macOS; no line wrapping needed, the workflow decodes with `base64 --decode`).
4. GitHub repo davidpit1565/finger-party > Settings > Secrets and variables > Actions > New repository secret, create exactly:

| Secret name | Value |
|---|---|
| `ASC_KEY_ID` | the Key ID |
| `ASC_ISSUER_ID` | the Issuer ID (UUID) |
| `ASC_KEY_P8_BASE64` | base64 of the .p8 file |
| `APPLE_TEAM_ID` | the 10-character Team ID |

Secrets exist only as GitHub Actions secrets (ideally in an Environment such as `testflight` with required reviewers, so the owner approves each upload). They must never appear in the repo, logs, or artifacts. Delete the local .p8 copy or store it in a password manager; revoke the key in App Store Connect if it leaks.

## 4. Enable GitHub Pages (privacy/support URLs) [OWNER]
1. Merge the branch containing `docs/` to `main` (the site is served from `main` /docs).
2. Repo > Settings > Pages > Build and deployment > Source: "Deploy from a branch" > Branch `main`, folder `/docs` > Save.
3. Wait a minute, then verify these return 200 and show the right content:
   - https://davidpit1565.github.io/finger-party/
   - https://davidpit1565.github.io/finger-party/privacy.html
   - https://davidpit1565.github.io/finger-party/support.html
4. Only then enter the Privacy Policy URL, Support URL, and Marketing URL in App Store Connect (App Information / version page).
Note: GitHub Pages on a private repo needs a paid GitHub plan; the repo must be public (or the plan must support it) for the URLs to be public. Unverified for this repo.

## 5. Release workflow `.github/workflows/testflight.yml` [LEAD writes; AUTO runs]
Expected behavior (runner `macos-15`, trigger: `workflow_dispatch`, optionally on tags like `v*`; environment `testflight` for approval):
1. Checkout; install XcodeGen (`brew install xcodegen`); `xcodegen generate`.
2. Decode the key: `base64 --decode <<< "$ASC_KEY_P8_BASE64" > "$RUNNER_TEMP/AuthKey_$ASC_KEY_ID.p8"`; `chmod 600`. Never `echo` secrets; rely on GitHub's masking and `set +x`.
3. Set a unique build number each run, e.g. `CURRENT_PROJECT_VERSION=${GITHUB_RUN_NUMBER}` passed to xcodebuild (App Store Connect rejects a repeated build number for the same version). `MARKETING_VERSION` comes from `project.yml`.
4. Archive with App Store Connect API authentication so Xcode can create/fetch signing assets:
   `xcodebuild archive -project FingerPicker.xcodeproj -scheme FingerPicker -configuration Release -destination 'generic/platform=iOS' -archivePath build/FingerPicker.xcarchive -allowProvisioningUpdates -authenticationKeyPath "$KEY" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID" DEVELOPMENT_TEAM="$APPLE_TEAM_ID" CURRENT_PROJECT_VERSION="$GITHUB_RUN_NUMBER"`
5. Export and upload in one step with an `ExportOptions.plist` containing `method` = `app-store-connect` (older Xcode: `app-store`), `destination` = `upload`, `teamID` = team, `signingStyle` = `automatic`, `uploadSymbols` = true:
   `xcodebuild -exportArchive -archivePath build/FingerPicker.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath build/export -allowProvisioningUpdates -authenticationKeyPath "$KEY" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID"`
   This uses `xcodebuild` itself (no `notarytool`, which is for macOS notarization and not relevant). Fallback if `destination=upload` is unavailable: export an `.ipa` (`destination=export`) and upload with `xcrun altool --upload-app -f build/export/FingerPicker.ipa -t ios --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"` (altool looks for `AuthKey_<KeyID>.p8` in `~/.private_keys`; Apple has been moving to the Transporter/`iTMSTransporter` tool, so verify current status).
6. Upload logs/xcresult as artifacts (never the key). Delete the key file in an `always()` step.
7. Fail loudly with the real command output; do not report success unless the upload step exits 0.
Uncertainties to verify on first run: exact Xcode version on `macos-15` (the `app-store-connect` method name needs Xcode 15.3+), whether API-key cloud signing succeeds with the chosen key role, and that `DEVELOPMENT_TEAM` empty in `project.yml` is overridden by the command-line value.

## 6. After upload: TestFlight setup [OWNER]
1. App Store Connect > the app > TestFlight. The build appears after processing (typically minutes, sometimes longer; you get an email). If "Missing Compliance" shows, the Info.plist key `ITSAppUsesNonExemptEncryption=NO` should already prevent it (see METADATA.md section 6).
2. Fill "What to Test" for the build (text in METADATA.md section 4).
3. Internal group: TestFlight > Internal Testing > "+" > name `Internal`; add App Store Connect users (people must first be added under Users and Access with an Apple ID; max 100 internal testers). Enable automatic distribution of new builds if wanted. Internal builds need no Beta App Review.
4. Testers install the TestFlight app on iPhone (iOS 17+ required by this app), accept the invite, and install the build. Builds expire after 90 days.
5. External testing (public link/groups) requires Beta App Review and owner-provided contact info; defer until the owner decides.

## 7. Owner checklist
- [ ] Account Holder accepted all current agreements (App Store Connect + developer.apple.com)
- [ ] Banking/tax left untouched (not required for a free app)
- [ ] Bundle ID `com.davidpit.fingerpicker` registered
- [ ] App record created; name decision made (METADATA.md)
- [ ] ASC API key created; `.p8` stored safely; 4 GitHub secrets set (`ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8_BASE64`, `APPLE_TEAM_ID`)
- [ ] GitHub Pages enabled from `main` /docs; three URLs verified 200
- [ ] Support email chosen and added to docs/privacy.html and docs/support.html (currently GitHub Issues only)
- [ ] Copyright holder name supplied
- [ ] Workflow run approved/triggered; build visible in TestFlight
- [ ] Internal testers added; "What to Test" entered
- [ ] Privacy label and age rating entered per PRIVACY-LABEL.md / AGE-RATING.md (needed before App Review, not for internal TestFlight)
- [ ] Screenshots captured from the real app (SCREENSHOTS.md)
- [ ] **Explicit owner approval before any App Review submission**. Agents will not submit.

## 8. Reference
Apple documentation to re-check at execution time: App Store Connect API keys; "Distributing your app for beta testing and releases"; `xcodebuild -help` for `-authenticationKey*` flags; Screenshot specifications; Age ratings values and definitions.
