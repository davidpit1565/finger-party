#!/usr/bin/env bash
# Local TestFlight upload for Finger Picker. Run on a Mac with Xcode installed.
#
# Required environment (values only — never paste the .p8 contents anywhere):
#   APPLE_TEAM_ID    10-character Apple Developer Team ID
#   ASC_KEY_ID       App Store Connect API Key ID
#   ASC_ISSUER_ID    App Store Connect Issuer ID (UUID)
#   ASC_KEY_PATH     path to your AuthKey_XXXX.p8 on this machine
# Optional:
#   BUILD_NUMBER     CFBundleVersion; default = UTC timestamp (YYYYMMDDHHMM, always increasing)
#   SKIP_TESTS=1     skip the simulator test run
#   VALIDATE_ONLY=1  archive + export but do not upload (dry run)
#
# This uploads a build to App Store Connect / TestFlight only. It never submits to App Review.
set -euo pipefail
cd "$(dirname "$0")/.."

die() { echo "error: $*" >&2; exit 1; }

[[ "$(uname)" == "Darwin" ]] || die "must run on macOS with Xcode"
for v in APPLE_TEAM_ID ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_PATH; do
  [[ -n "${!v:-}" ]] || die "missing env var $v (see header of this script)"
done
[[ -f "$ASC_KEY_PATH" ]] || die "ASC_KEY_PATH does not point to a file"
command -v xcodebuild >/dev/null || die "xcodebuild not found (install Xcode)"
command -v xcodegen  >/dev/null || die "xcodegen not found (brew install xcodegen)"

BUILD_NUMBER="${BUILD_NUMBER:-$(date -u +%Y%m%d%H%M)}"
OUT="build/testflight"
rm -rf "$OUT"; mkdir -p "$OUT"
AUTH=(-allowProvisioningUpdates
      -authenticationKeyPath "$ASC_KEY_PATH"
      -authenticationKeyID "$ASC_KEY_ID"
      -authenticationKeyIssuerID "$ASC_ISSUER_ID")

echo "==> Core logic tests"
swift test --package-path Packages/FingerPickerCore

echo "==> Generate Xcode project"
xcodegen generate

if [[ "${SKIP_TESTS:-0}" != "1" ]]; then
  echo "==> App unit + UI tests (iOS Simulator)"
  SIM=$(xcrun simctl list devices available -j | python3 -c "
import json,sys
d=json.load(sys.stdin)['devices']
print(next(x['udid'] for k,v in d.items() if 'iOS' in k for x in v if 'iPhone' in x['name'] and x['isAvailable']))")
  xcodebuild test -project FingerPicker.xcodeproj -scheme FingerPicker \
    -destination "id=$SIM" -resultBundlePath "$OUT/Tests.xcresult" CODE_SIGNING_ALLOWED=NO \
    > "$OUT/test.log" 2>&1 || { tail -40 "$OUT/test.log"; die "tests failed (full log: $OUT/test.log)"; }
  grep -E "Executed [0-9]+ tests" "$OUT/test.log" | tail -1
fi

echo "==> Archive (build $BUILD_NUMBER)"
xcodebuild archive -project FingerPicker.xcodeproj -scheme FingerPicker \
  -configuration Release -destination "generic/platform=iOS" \
  -archivePath "$OUT/FingerPicker.xcarchive" \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  "${AUTH[@]}" > "$OUT/archive.log" 2>&1 || { tail -40 "$OUT/archive.log"; die "archive failed (log: $OUT/archive.log)"; }

DEST=upload; [[ "${VALIDATE_ONLY:-0}" == "1" ]] && DEST=export
cat > "$OUT/ExportOptions.plist" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>$DEST</string>
  <key>teamID</key><string>$APPLE_TEAM_ID</string>
  <key>signingStyle</key><string>automatic</string>
  <key>uploadSymbols</key><true/>
</dict></plist>
PL

echo "==> Export ($DEST)"
xcodebuild -exportArchive -archivePath "$OUT/FingerPicker.xcarchive" \
  -exportOptionsPlist "$OUT/ExportOptions.plist" -exportPath "$OUT/export" \
  "${AUTH[@]}" > "$OUT/export.log" 2>&1 || { tail -40 "$OUT/export.log"; die "export/upload failed (log: $OUT/export.log)"; }

if [[ "$DEST" == "upload" ]]; then
  echo "Done: build $BUILD_NUMBER uploaded. It appears in App Store Connect > TestFlight after processing (usually 5-30 min)."
  echo "Not submitted for App Review."
else
  echo "Done (dry run): exported to $OUT/export, nothing uploaded."
fi
