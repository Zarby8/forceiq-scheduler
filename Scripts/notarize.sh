#!/bin/bash

# ForceIQ Scheduler Notarization Script
# This script builds, signs, and notarizes the ForceIQ Scheduler app for distribution

set -e

# Configuration
APP_NAME="ForceIQ Scheduler"
BUNDLE_ID="com.forceiq.scheduler"
WORKSPACE_PATH="ForceIQScheduler.xcworkspace"
SCHEME="ForceIQScheduler"
CONFIGURATION="Release"
BUILD_DIR="build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
DMG_NAME="ForceIQ-Scheduler"
DMG_PATH="$BUILD_DIR/$DMG_NAME.dmg"

# Check for required environment variables
if [ -z "$DEVELOPMENT_TEAM" ]; then
    echo "❌ Error: DEVELOPMENT_TEAM environment variable not set"
    echo "Set it with: export DEVELOPMENT_TEAM=YOUR_TEAM_ID"
    exit 1
fi

if [ -z "$APPLE_ID" ]; then
    echo "❌ Error: APPLE_ID environment variable not set"
    echo "Set it with: export APPLE_ID=your.email@example.com"
    exit 1
fi

if [ -z "$APPLE_ID_PASSWORD" ]; then
    echo "❌ Error: APPLE_ID_PASSWORD environment variable not set"
    echo "Set it with: export APPLE_ID_PASSWORD=your-app-specific-password"
    exit 1
fi

echo "🚀 Starting build and notarization process..."

# Clean and create build directory
echo "📁 Preparing build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build the app
echo "🔨 Building $APP_NAME..."
xcodebuild -workspace "$WORKSPACE_PATH" \
           -scheme "$SCHEME" \
           -configuration "$CONFIGURATION" \
           -derivedDataPath "$BUILD_DIR/DerivedData" \
           -archivePath "$BUILD_DIR/$APP_NAME.xcarchive" \
           archive

# Export the app
echo "📦 Exporting app..."
xcodebuild -exportArchive \
           -archivePath "$BUILD_DIR/$APP_NAME.xcarchive" \
           -exportPath "$BUILD_DIR" \
           -exportOptionsPlist Scripts/ExportOptions.plist

# Move app to expected location
mv "$BUILD_DIR/$APP_NAME.app" "$APP_PATH" 2>/dev/null || true

# Verify code signing
echo "✅ Verifying code signature..."
codesign --verify --verbose=4 "$APP_PATH"
spctl --assess --verbose=4 --type execute "$APP_PATH"

# Create DMG
echo "💾 Creating DMG..."
hdiutil create -srcfolder "$APP_PATH" -volname "$APP_NAME" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDZO "$DMG_PATH"

# Sign the DMG
echo "✍️  Signing DMG..."
codesign --sign "Developer ID Application: $DEVELOPMENT_TEAM" --timestamp "$DMG_PATH"

# Notarize the DMG
echo "🔐 Submitting for notarization..."
NOTARIZATION_UUID=$(xcrun notarytool submit "$DMG_PATH" \
                                        --apple-id "$APPLE_ID" \
                                        --password "$APPLE_ID_PASSWORD" \
                                        --team-id "$DEVELOPMENT_TEAM" \
                                        --wait \
                                        --output-format json | jq -r '.id')

if [ "$NOTARIZATION_UUID" != "null" ]; then
    echo "✅ Notarization successful! UUID: $NOTARIZATION_UUID"

    # Staple the notarization to the DMG
    echo "📎 Stapling notarization ticket..."
    xcrun stapler staple "$DMG_PATH"

    echo "🎉 Build and notarization complete!"
    echo "📱 App: $APP_PATH"
    echo "💿 DMG: $DMG_PATH"

    # Verify stapling worked
    echo "🔍 Verifying stapled notarization..."
    xcrun stapler validate "$DMG_PATH"

else
    echo "❌ Notarization failed!"
    exit 1
fi

echo "✨ ForceIQ Scheduler is ready for distribution!"