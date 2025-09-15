#!/bin/bash

# ForceIQ Scheduler Development Build with Code Signing
# Builds and signs the app for local testing with Developer ID

set -e

# Configuration
WORKSPACE_PATH="ForceIQScheduler.xcworkspace"
SCHEME="ForceIQScheduler"
CONFIGURATION="Release"

# Check for required environment variables
if [ -z "$DEVELOPMENT_TEAM" ]; then
    echo "❌ Error: DEVELOPMENT_TEAM environment variable not set"
    echo "Set it with: export DEVELOPMENT_TEAM=YOUR_TEAM_ID"
    exit 1
fi

echo "🔨 Building and signing ForceIQ Scheduler..."

# Build with proper code signing
xcodebuild -workspace "$WORKSPACE_PATH" \
           -scheme "$SCHEME" \
           -configuration "$CONFIGURATION" \
           DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
           CODE_SIGN_IDENTITY="Developer ID Application" \
           build

echo "✅ Build completed successfully!"

# Get the built app path
BUILT_PRODUCTS_DIR=$(xcodebuild -workspace "$WORKSPACE_PATH" \
                               -scheme "$SCHEME" \
                               -configuration "$CONFIGURATION" \
                               -showBuildSettings | \
                    grep "BUILT_PRODUCTS_DIR" | head -1 | cut -d'=' -f2 | xargs)

APP_PATH="$BUILT_PRODUCTS_DIR/ForceIQ Scheduler.app"

if [ -d "$APP_PATH" ]; then
    echo "📱 App built at: $APP_PATH"

    # Verify code signing
    echo "✅ Verifying code signature..."
    codesign --verify --verbose=4 "$APP_PATH"

    # Test Gatekeeper assessment
    echo "🔐 Testing Gatekeeper assessment..."
    spctl --assess --verbose=4 --type execute "$APP_PATH"

    echo "🎉 ForceIQ Scheduler built and signed successfully!"
    echo "📂 You can now run the app from: $APP_PATH"
else
    echo "❌ App not found at expected location: $APP_PATH"
    exit 1
fi