# Prompt for Claude Code on the MacBook (copy everything in the block)

Do these in order, once, on the Mac, before running the prompt:
1. App Store Connect > Business/Agreements: the Account Holder accepts any pending agreements.
2. App Store Connect > Apps > "+" > New App: platform iOS, a name, primary language English,
   Bundle ID `com.davidpit.fingerpicker` (appears in the list after step 3 if it is missing),
   SKU any unique string (e.g. `fingerpicker-001`). The app record cannot be created by API.
3. If the Bundle ID is missing from that list: developer.apple.com > Certificates, IDs & Profiles >
   Identifiers > "+" > App IDs > App > Bundle ID (Explicit) `com.davidpit.fingerpicker`.
4. Have these four values ready (never paste the contents of the .p8 anywhere):
   Team ID, API Key ID, Issuer ID, and the path to AuthKey_XXXX.p8 on this Mac.

```
You are working on the iOS app "Finger Picker" on this Mac. Goal: build it, test it, and upload
a build to App Store Connect / TestFlight for INTERNAL testing. Do the work; don't just plan it.

REPO: https://github.com/davidpit1565/finger-party  branch: main (the MVP is already merged there)
1. Clone it (or `git pull` if already cloned) and stay on main. Make any fixes on a NEW branch and
   never push to main directly. Read README.md and APPSTORE/TESTFLIGHT-RUNBOOK.md first.
2. Check the toolchain: Xcode (`xcodebuild -version`), `brew install xcodegen` if missing.
3. Run `swift test --package-path Packages/FingerPickerCore`, then `xcodegen generate`, then the
   app tests on an iPhone simulator. If anything fails to compile or a test fails, find the root
   cause and fix it with a small commit on a NEW branch `mac-fixes` (never skip or delete tests).
4. Ask me for: APPLE_TEAM_ID, ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_PATH (a file path only).
   Export them as environment variables in this shell only. Never print, copy, log or commit the
   .p8 contents. Never put any key in the repo.
5. Confirm the bundle ID in project.yml (`com.davidpit.fingerpicker`) matches the app record I
   created in App Store Connect. If it doesn't, stop and ask me.
6. Dry run: `VALIDATE_ONLY=1 ./scripts/testflight.sh`. Fix problems (signing, team, provisioning)
   and report anything that needs me.
7. Real upload: `./scripts/testflight.sh`. It uploads a build only.
8. Verify: tell me the version/build number, and check that the build shows up in App Store
   Connect > TestFlight (processing takes 5-30 minutes). If you can, create an Internal Testing
   group and add me; otherwise tell me the exact clicks.
9. Final report: what ran, what passed, the build number, and what still needs me.

HARD RULES: do NOT submit the app for App Review or public release. Do NOT accept agreements,
change payment/tax/banking details, or invent business/personal details. Do NOT bypass two-factor
authentication or ask me to paste passwords in chat. Do NOT push or merge into main. If an action needs
my approval, stop at that action and explain exactly what is needed.
```
