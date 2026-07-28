#!/bin/bash
#
# Archives and uploads J-Pouch to TestFlight without opening Xcode.
#
# Written because macOS 27 refuses to launch the Xcode 26.6 GUI, while its command line tools
# work fine. Signing normally relies on an account added through Xcode's Accounts settings,
# which isn't reachable — an App Store Connect API key replaces it and lets xcodebuild create
# the distribution certificate and provisioning profile itself.
#
# One-time setup, in App Store Connect → Users and Access → Integrations → App Store Connect
# API → Team Keys. Generate a key with the "App Manager" role (needed to create signing
# assets), download the .p8 — Apple only lets you download it once — and note the Key ID and
# Issuer ID.
#
# Then:
#   export ASC_KEY_ID=XXXXXXXXXX
#   export ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
#   export ASC_KEY_PATH=~/private_keys/AuthKey_XXXXXXXXXX.p8
#   ./Scripts/release.sh
#
# Keep the .p8 outside the repo. It is a credential that can sign and upload as you.

set -euo pipefail

cd "$(dirname "$0")/.."

: "${ASC_KEY_ID:?Set ASC_KEY_ID (App Store Connect API key ID)}"
: "${ASC_ISSUER_ID:?Set ASC_ISSUER_ID (App Store Connect issuer ID)}"
: "${ASC_KEY_PATH:?Set ASC_KEY_PATH (path to the .p8 key file)}"

KEY_PATH=${ASC_KEY_PATH/#\~/$HOME}
[ -f "$KEY_PATH" ] || { echo "No key file at $KEY_PATH" >&2; exit 1; }

# altool doesn't take a key path: it looks for AuthKey_<KEYID>.p8 in a handful of fixed
# directories or in API_PRIVATE_KEYS_DIR. Pointing that at wherever the key already lives
# avoids copying a credential into another location just to satisfy a lookup convention.
expected_name="AuthKey_${ASC_KEY_ID}.p8"
if [ "$(basename "$KEY_PATH")" != "$expected_name" ]; then
  echo "Key file must be named $expected_name for altool to find it (got $(basename "$KEY_PATH"))." >&2
  exit 1
fi
export API_PRIVATE_KEYS_DIR="$(cd "$(dirname "$KEY_PATH")" && pwd)"

BUILD_DIR=build
ARCHIVE="$BUILD_DIR/JPouch.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"

# Keep a full log. xcodebuild's final summary is just "Archiving project ... (1 failure)",
# which says nothing about the cause, and the useful line is usually thousands of lines back.
mkdir -p "$BUILD_DIR"
LOG="$BUILD_DIR/release-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee "$LOG") 2>&1
trap 'echo; echo "Full log: $LOG"; echo "Likely cause:"; grep -E "error:|No profiles|entitlement|iCloud|Provisioning" "$LOG" | tail -20' EXIT

AUTH=(
  -authenticationKeyPath "$KEY_PATH"
  -authenticationKeyID "$ASC_KEY_ID"
  -authenticationKeyIssuerID "$ASC_ISSUER_ID"
)

echo "==> Regenerating project"
xcodegen generate >/dev/null

echo "==> Archiving"
rm -rf "$ARCHIVE" "$EXPORT_DIR"
xcodebuild archive \
  -project JPouch.xcodeproj \
  -scheme JPouch \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  "${AUTH[@]}"

BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleVersion" "$ARCHIVE/Info.plist" 2>/dev/null || echo "?")
VERSION=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleShortVersionString" "$ARCHIVE/Info.plist" 2>/dev/null || echo "?")
echo "==> Archived version $VERSION build $BUILD_NUMBER"

# Xcode renamed this value; older versions want "app-store". Try the current spelling and fall
# back rather than making the caller guess which one their Xcode expects.
export_with_method() {
  local method=$1
  cat > "$BUILD_DIR/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key><string>$method</string>
    <key>teamID</key><string>37GS5LK7P7</string>
    <key>signingStyle</key><string>automatic</string>
    <key>uploadSymbols</key><true/>
</dict>
</plist>
PLIST
  xcodebuild -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist" \
    -allowProvisioningUpdates \
    "${AUTH[@]}"
}

echo "==> Exporting .ipa"
export_with_method "app-store-connect" || export_with_method "app-store"

IPA=$(find "$EXPORT_DIR" -name "*.ipa" | head -1)
[ -n "$IPA" ] || { echo "No .ipa produced" >&2; exit 1; }
echo "==> Built $IPA"

# This Xcode's help lists --api-key while the usage synopsis shows --apiKey; the accepted
# spelling has changed between versions, so try one and fall back rather than guessing.
altool_run() {
  local command=$1
  xcrun altool "$command" -f "$IPA" -t ios --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID" \
    || xcrun altool "$command" -f "$IPA" -t ios --api-key "$ASC_KEY_ID" --api-issuer "$ASC_ISSUER_ID"
}

echo "==> Validating before upload"
altool_run --validate-app

echo "==> Uploading to App Store Connect"
altool_run --upload-app

echo "==> Done. Build $BUILD_NUMBER is processing; TestFlight will email when it's ready."
