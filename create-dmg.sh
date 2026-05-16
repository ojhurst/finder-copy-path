#!/usr/bin/env bash
# Build a styled, signed, notarized CopyPath.dmg ready for GitHub Releases.
# Must run on the MBP (Developer ID private key lives in MBP login keychain).
# Requires: xcodegen, xcodebuild, create-dmg (brew install create-dmg), notarytool creds.

set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO"

SIGNING_IDENTITY="Developer ID Application: Oliver Hurst (WG8568VB25)"
BUNDLE_SRC="CopyPathHelper"       # name produced by xcodebuild
APP_NAME="CopyPath"               # name shown in the DMG and in Finder
VOLNAME="Copy Path"
DMG_OUT="$REPO/dist/CopyPath.dmg" # GitHub Releases latest-download URL expects this exact name
STAGING="$REPO/dist/staging"
DERIVED="$REPO/build"

# --- Preflight ------------------------------------------------------------
command -v xcodegen     >/dev/null || { echo "xcodegen missing. brew install xcodegen"; exit 1; }
command -v create-dmg   >/dev/null || { echo "create-dmg missing. brew install create-dmg"; exit 1; }
security find-identity -v -p codesigning | grep -q "$SIGNING_IDENTITY" || {
    echo "Developer ID signing identity not in keychain. Run this on the MBP."
    exit 1
}
: "${APPLE_DEVELOPER_EMAIL:?APPLE_DEVELOPER_EMAIL must be set (see secrets.json)}"
: "${APPLE_TEAM_ID:?APPLE_TEAM_ID must be set (see secrets.json)}"
: "${APPLE_NOTARY_PASSWORD:?APPLE_NOTARY_PASSWORD must be set (see secrets.json)}"

# --- 1. Build release -----------------------------------------------------
echo ">>> Generating Xcode project"
xcodegen generate

echo ">>> Building Release configuration"
rm -rf "$DERIVED"
xcodebuild \
    -project CopyPathHelper.xcodeproj \
    -scheme CopyPathHelper \
    -configuration Release \
    -derivedDataPath "$DERIVED" \
    clean build

BUILT_APP="$DERIVED/Build/Products/Release/${BUNDLE_SRC}.app"
[ -d "$BUILT_APP" ] || { echo "Built app not found at $BUILT_APP"; exit 1; }

# --- 2. Stage with display name -------------------------------------------
echo ">>> Staging $APP_NAME.app"
rm -rf "$STAGING" "$DMG_OUT"
mkdir -p "$STAGING" "$(dirname "$DMG_OUT")"
cp -R "$BUILT_APP" "$STAGING/${APP_NAME}.app"

# --- 3. Re-sign after rename ---------------------------------------------
echo ">>> Re-signing renamed bundle"
codesign --force --deep --options runtime --timestamp \
    --sign "$SIGNING_IDENTITY" \
    "$STAGING/${APP_NAME}.app"
codesign --verify --deep --strict --verbose=2 "$STAGING/${APP_NAME}.app"

# --- 4. Build the styled DMG ---------------------------------------------
echo ">>> Building styled DMG"
create-dmg \
    --volname "$VOLNAME" \
    --volicon "$REPO/CopyPathHelper/AppIcon.icns" \
    --background "$REPO/dmg-resources/background.png" \
    --window-pos 200 120 \
    --window-size 540 380 \
    --icon-size 100 \
    --icon "${APP_NAME}.app" 150 220 \
    --app-drop-link 390 220 \
    --hide-extension "${APP_NAME}.app" \
    --codesign "$SIGNING_IDENTITY" \
    --no-internet-enable \
    "$DMG_OUT" \
    "$STAGING/"

# --- 5. Notarize ----------------------------------------------------------
echo ">>> Submitting to Apple notary service"
xcrun notarytool submit "$DMG_OUT" \
    --apple-id "$APPLE_DEVELOPER_EMAIL" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_NOTARY_PASSWORD" \
    --wait

# --- 6. Staple ------------------------------------------------------------
echo ">>> Stapling notary ticket"
xcrun stapler staple "$DMG_OUT"
xcrun stapler validate "$DMG_OUT"

echo ""
echo "Done: $DMG_OUT"
echo "Size: $(du -h "$DMG_OUT" | awk '{print $1}')"
