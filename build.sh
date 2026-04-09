#!/bin/bash
set -e

cd "$(dirname "$0")/swift"

echo "==> Generating Xcode project..."
xcodegen generate

echo "==> Building Ember (Release)..."
xcodebuild \
  -project Ember.xcodeproj \
  -scheme Ember \
  -configuration Release \
  -derivedDataPath build \
  clean build \
  2>&1 | tail -20

APP_PATH="build/Build/Products/Release/Ember.app"

if [ ! -d "$APP_PATH" ]; then
  echo "ERROR: Build failed — app not found at $APP_PATH"
  exit 1
fi

echo "==> Copying to /Applications..."
rm -rf /Applications/Ember.app
cp -R "$APP_PATH" /Applications/Ember.app

echo "==> Done! Ember is now in /Applications."
echo "    Open it with: open /Applications/Ember.app"
