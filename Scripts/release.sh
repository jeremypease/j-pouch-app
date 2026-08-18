#!/bin/bash
#
# Archives and uploads J-Pouch to TestFlight without opening Xcode.
#
# The default release path is Xcode's own GUI (Product → Archive → Distribute App); this script
# is the command-line fallback, for when that isn't available or breaks again. It doesn't rely
# on an account added through Xcode's Accounts settings — an App Store Connect API key replaces
# it and lets xcodebuild create the distribution certificate and provisioning profile itself.
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

# Read saved settings so a fresh terminal doesn't need the exports repeated. Anything already
# exported wins, so a one-off run can still override. Gitignored: it names the key file's
# location, and the identifiers are nobody else's business even though the .p8 itself is the
# part that actually matters.
if [ -f .release-env ]; then
    set -a
    # shellcheck disable=SC1091
    . ./.release-env
    set +a
fi

: "${ASC_KEY_ID:?Set ASC_KEY_ID (App Store Connect API key ID), or put it in .release-env}"
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

# Pin the toolchain rather than trusting xcode-select. A beta Xcode reappeared on this machine
# and xcode-select silently pointed back at it, so an archive went up built against the iOS 27
# beta SDK — precisely the thing App Store Connect rejects. A global setting that anything can
# change is not something a release should depend on.
if [ -d /Applications/Xcode.app/Contents/Developer ]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
else
    echo "No released Xcode at /Applications/Xcode.app." >&2
    echo "A beta cannot be used: App Store Connect rejects builds made against beta SDKs." >&2
    exit 1
fi

case "$DEVELOPER_DIR" in
    *beta*|*Beta*)
        echo "DEVELOPER_DIR points at a beta Xcode ($DEVELOPER_DIR)." >&2
        echo "App Store Connect rejects builds made against beta SDKs." >&2
        exit 1
        ;;
esac

echo "==> Using $(xcodebuild -version | head -1) from $DEVELOPER_DIR"

BUILD_DIR=build
ARCHIVE="$BUILD_DIR/JPouch.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"

# Keep a full log. xcodebuild's final summary is just "Archiving project ... (1 failure)",
# which says nothing about the cause, and the useful line is usually thousands of lines back.
mkdir -p "$BUILD_DIR"
LOG="$BUILD_DIR/release-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee "$LOG") 2>&1
trap 'status=$?; echo; echo "Full log: $LOG"; if [ "$status" -ne 0 ]; then echo "Likely cause:"; grep -E "error:|No profiles|entitlement|iCloud|Provisioning" "$LOG" | tail -20; fi' EXIT

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

# Check what was actually produced rather than what was intended. A beta-SDK build uploads
# without complaint and is only rejected later during processing, so the failure arrives
# detached from its cause — catching it here keeps the reason next to the mistake.
# The SDK keys live in the built app's own Info.plist; the archive's ApplicationProperties
# carries only version, team and signing identity.
APP_RELATIVE_PATH=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:ApplicationPath" "$ARCHIVE/Info.plist" 2>/dev/null || echo "Applications/JPouch.app")
APP_PLIST="$ARCHIVE/Products/$APP_RELATIVE_PATH/Info.plist"
ARCHIVE_SDK=$(/usr/libexec/PlistBuddy -c "Print :DTSDKName" "$APP_PLIST" 2>/dev/null || echo unknown)
ARCHIVE_XCODE=$(/usr/libexec/PlistBuddy -c "Print :DTXcodeBuild" "$APP_PLIST" 2>/dev/null || echo unknown)
echo "==> Built against SDK $ARCHIVE_SDK (Xcode build $ARCHIVE_XCODE)"

RELEASED_SDK=$(xcodebuild -showsdks 2>/dev/null | sed -n 's/.*-sdk iphoneos\([0-9.]*\).*/\1/p' | head -1)
if [ "$ARCHIVE_SDK" = unknown ]; then
    echo "Could not read the SDK from $APP_PLIST — refusing to upload blind." >&2
    exit 1
fi
if [ -n "$RELEASED_SDK" ] && [ "$ARCHIVE_SDK" != "iphoneos$RELEASED_SDK" ]; then
    echo "" >&2
    echo "Refusing to upload: the archive was built against $ARCHIVE_SDK, but the pinned Xcode" >&2
    echo "ships iphoneos$RELEASED_SDK. That mismatch means a stale archive or a stray toolchain," >&2
    echo "and App Store Connect will reject it after upload rather than now." >&2
    exit 1
fi

# Manual signing, using the certificate and profile made by Scripts/create-signing-assets.sh.
# Automatic signing here asks Apple to mint them on demand ("cloud signing"), which fails on
# this account with a permission error even though the same API key can create both directly.
# Naming them explicitly avoids that path entirely.
#
# The method value was renamed between Xcode versions, so try the current spelling first and
# fall back rather than making the caller work out which one their Xcode wants.
export_with_method() {
  local method=$1
  cat > "$BUILD_DIR/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key><string>$method</string>
    <key>teamID</key><string>S6M9LCA6DC</string>
    <key>signingStyle</key><string>manual</string>
    <key>signingCertificate</key><string>Apple Distribution</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.jeremypease.jpouch</key><string>JPouch App Store</string>
    </dict>
    <key>uploadSymbols</key><true/>
</dict>
</plist>
PLIST
  # Deliberately no -allowProvisioningUpdates: that is what re-enters cloud signing.
  xcodebuild -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist"
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

# Set SKIP_UPLOAD=1 to build and validate without sending anything to App Store Connect —
# useful for checking the pipeline works without publishing a build.
if [ -n "${SKIP_UPLOAD:-}" ]; then
  echo "==> SKIP_UPLOAD set; stopping before upload. The .ipa is at $IPA"
  exit 0
fi

echo "==> Uploading to App Store Connect"
altool_run --upload-app

echo "==> Done. Build $BUILD_NUMBER is processing; TestFlight will email when it's ready."
