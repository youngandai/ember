#!/bin/bash
set -e

# Build first
bash "$(dirname "$0")/build.sh"

echo "==> Packaging Ember.dmg..."

APP_PATH="/Applications/Ember.app"
DMG_STAGING="/tmp/EmberDMG"
DMG_OUTPUT="$(dirname "$0")/Ember.dmg"

if [ ! -d "$APP_PATH" ]; then
  echo "ERROR: $APP_PATH not found. Run ./build.sh first."
  exit 1
fi

# Clean staging
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"

# Copy app
cp -R "$APP_PATH" "$DMG_STAGING/Ember.app"

# Symlink to Applications so users can drag-install
ln -s /Applications "$DMG_STAGING/Applications"

# Create DMG
hdiutil create \
  -volname "Ember" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDZO \
  "$DMG_OUTPUT"

rm -rf "$DMG_STAGING"

echo "==> Done! DMG ready at: $DMG_OUTPUT"
echo "    Upload this file as a GitHub Release asset named Ember.dmg"
echo "    Permalink: https://github.com/youngandai/ember/releases/latest/download/Ember.dmg"
