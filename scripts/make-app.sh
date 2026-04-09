#!/bin/bash
# Build, sign, notarize, and package Ember.app
#
# Usage:
#   scripts/make-app.sh              — build dev app and install to ~/Applications
#   scripts/make-app.sh generate     — generate Xcode project
#   scripts/make-app.sh build        — xcodebuild (Release)
#   scripts/make-app.sh sign         — code sign the .app bundle
#   scripts/make-app.sh notarize     — submit for notarization + staple
#   scripts/make-app.sh dmg          — create DMG installer
#   scripts/make-app.sh install      — copy to /Applications (local only)
#
# The default command builds a Debug configuration ("Ember Dev")
# with a separate bundle ID and data store, so it can run alongside the
# production app without interference.
#
# Individual steps (build, sign, notarize, dmg) use Release configuration
# and are designed for CI workflows.
#
# Environment variables:
#   EMBER_VERSION          — version string (default: 1.0.0)
#   SIGNING_IDENTITY       — override cert (use "-" for ad-hoc)
#   KEYCHAIN_PATH          — CI keychain with imported cert
#   KEYCHAIN_PASSWORD      — password to unlock CI keychain
#   APPLE_ID               — for notarization
#   APPLE_TEAM_ID          — for notarization
#   NOTARIZATION_PASSWORD  — app-specific password for notarization

set -e
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)" || true
cd "$(dirname "$0")/.."

# Load .env if present
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

VERSION="${EMBER_VERSION:-1.0.0}"
APP_NAME="Ember"
DEV_APP_NAME="Ember Dev"
BUILD_APP="build/DerivedData/Build/Products/Release/${APP_NAME}.app"
APP_DIR="build/${APP_NAME}.app"
CONTENTS="${APP_DIR}/Contents"
SPARKLE_FW="${CONTENTS}/Frameworks/Sparkle.framework"

# ── Resolve signing identity ──
resolve_identity() {
    IDENTITY="${SIGNING_IDENTITY:-}"
    if [ -z "$IDENTITY" ]; then
        if [ -n "$KEYCHAIN_PATH" ]; then
            # Use SHA-1 hash to avoid ambiguity when the same cert
            # exists in both the CI keychain and login keychain
            IDENTITY=$(security find-identity -v -p codesigning "$KEYCHAIN_PATH" | grep "Developer ID Application" | head -1 | awk '{print $2}' || true)
        else
            IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)".*/\1/' || true)
        fi
        if [ -z "$IDENTITY" ]; then
            echo "ERROR: No Developer ID Application certificate found."
            echo "Install one from https://developer.apple.com/account/resources/certificates"
            echo "or set SIGNING_IDENTITY=\"-\" for ad-hoc signing (Gatekeeper will block the app)."
            exit 1
        fi
    fi
}

# ── Steps ──

step_generate() {
    echo "Generating Xcode project..."
    cd swift
    xcodegen generate
    cd ..
}

step_build() {
    echo "Building Ember v${VERSION}..."
    xcodebuild \
      -project swift/Ember.xcodeproj \
      -scheme Ember \
      -configuration Release \
      -derivedDataPath build/DerivedData \
      -destination 'platform=macOS' \
      MARKETING_VERSION="$VERSION" \
      CURRENT_PROJECT_VERSION="$VERSION" \
      build 2>&1 | tail -5

    echo "Copying built .app bundle..."
    rm -rf "$APP_DIR"
    ditto "$BUILD_APP" "$APP_DIR"
}

step_sign() {
    resolve_identity

    # Unlock CI keychain if present
    if [ -n "$KEYCHAIN_PATH" ] && [ -n "$KEYCHAIN_PASSWORD" ]; then
        echo "Unlocking CI keychain..."
        security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
    fi

    if [ "$IDENTITY" = "-" ]; then
        echo "Code signing (ad-hoc)..."
    else
        echo "Code signing with: ${IDENTITY}"
    fi

    CODESIGN_ARGS=(--force --sign "$IDENTITY" --timestamp)
    if [ "$IDENTITY" != "-" ]; then
        CODESIGN_ARGS+=(--options runtime)
    fi
    if [ -n "$KEYCHAIN_PATH" ]; then
        CODESIGN_ARGS+=(--keychain "$KEYCHAIN_PATH")
    fi

    # Sign Sparkle framework components inside-out
    find "$SPARKLE_FW" -name "*.xpc" -type d | while read -r xpc; do
        codesign "${CODESIGN_ARGS[@]}" "$xpc"
    done

    find "$SPARKLE_FW" -name "*.app" -type d | while read -r app; do
        codesign "${CODESIGN_ARGS[@]}" "$app"
    done

    for helper in "$SPARKLE_FW"/Versions/B/Autoupdate; do
        [ -f "$helper" ] && codesign "${CODESIGN_ARGS[@]}" "$helper"
    done

    codesign "${CODESIGN_ARGS[@]}" "$SPARKLE_FW"
    codesign "${CODESIGN_ARGS[@]}" "$APP_DIR"

    echo "Verifying code signature..."
    codesign --verify --deep --strict "$APP_DIR"
}

step_notarize() {
    resolve_identity

    if [ "$IDENTITY" = "-" ]; then
        echo "Skipping notarization (ad-hoc signing)"
        return
    fi

    if [ -z "$APPLE_ID" ] || [ -z "$APPLE_TEAM_ID" ] || [ -z "$NOTARIZATION_PASSWORD" ]; then
        echo "Skipping notarization (set APPLE_ID, APPLE_TEAM_ID, NOTARIZATION_PASSWORD to enable)"
        return
    fi

    echo "Submitting for notarization..."
    ZIP_PATH="build/${APP_NAME}-notarize.zip"
    ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"
    NOTARY_OUTPUT=$(xcrun notarytool submit "$ZIP_PATH" \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --password "$NOTARIZATION_PASSWORD" \
        --wait 2>&1)
    echo "$NOTARY_OUTPUT"
    if echo "$NOTARY_OUTPUT" | grep -q "status: Invalid"; then
        SUBMISSION_ID=$(echo "$NOTARY_OUTPUT" | grep "id:" | head -1 | awk '{print $2}')
        echo "Notarization failed. Fetching log..."
        xcrun notarytool log "$SUBMISSION_ID" \
            --apple-id "$APPLE_ID" \
            --team-id "$APPLE_TEAM_ID" \
            --password "$NOTARIZATION_PASSWORD" 2>&1
        exit 1
    fi
    echo "Stapling notarization ticket..."
    xcrun stapler staple "$APP_DIR"
    rm -f "$ZIP_PATH"
    echo "Notarization complete."
}

step_dmg() {
    echo "Creating DMG..."
    DMG_PATH="build/${APP_NAME}-${VERSION}.dmg"
    rm -f "$DMG_PATH"
    create-dmg \
      --volname "$APP_NAME" \
      --window-pos 200 120 \
      --window-size 600 400 \
      --icon-size 100 \
      --icon "$APP_NAME.app" 150 190 \
      --app-drop-link 450 190 \
      "$DMG_PATH" \
      "$APP_DIR"
    echo "DMG created at ${DMG_PATH}"
}

step_install() {
    echo "Installing to /Applications..."
    rm -rf "/Applications/${APP_NAME}.app"
    ditto "$APP_DIR" "/Applications/${APP_NAME}.app"
    echo "Done! Installed at /Applications/${APP_NAME}.app"
}

# ── Dispatch ──

COMMAND="${1:-all}"

case "$COMMAND" in
    generate)  step_generate ;;
    build)     step_build ;;
    sign)      step_sign ;;
    notarize)  step_notarize ;;
    dmg)       step_dmg ;;
    install)   step_install ;;
    all)
        # Local dev build: Debug config → ~/Applications
        step_generate

        echo "Building ${DEV_APP_NAME} (Debug) v${VERSION}..."
        xcodebuild \
          -project swift/Ember.xcodeproj \
          -scheme Ember \
          -configuration Debug \
          -derivedDataPath build/DerivedData \
          -destination 'platform=macOS' \
          MARKETING_VERSION="$VERSION" \
          CURRENT_PROJECT_VERSION="$VERSION" \
          build 2>&1 | tail -5

        DEV_BUILD_APP="build/DerivedData/Build/Products/Debug/${DEV_APP_NAME}.app"
        DEV_INSTALL_DIR="$HOME/Applications"
        mkdir -p "$DEV_INSTALL_DIR"

        echo "Installing to ${DEV_INSTALL_DIR}..."
        rm -rf "${DEV_INSTALL_DIR}/${DEV_APP_NAME}.app"
        ditto "$DEV_BUILD_APP" "${DEV_INSTALL_DIR}/${DEV_APP_NAME}.app"
        echo "Done! Installed at ${DEV_INSTALL_DIR}/${DEV_APP_NAME}.app"
        ;;
    *)
        echo "Unknown command: $COMMAND"
        echo "Usage: $0 {generate|build|sign|notarize|dmg|install|all}"
        exit 1
        ;;
esac
