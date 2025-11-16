#!/bin/bash

# Build script for macOS
# Builds both Android and iOS targets

set -e

echo "🍎 Building CompostKaki on macOS..."
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: This script is for macOS only"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: Xcode is not installed"
    echo "   Please install Xcode from the App Store"
    exit 1
fi

# Enable iOS targets
echo "📱 Enabling iOS targets..."
if grep -q "kotlin.mpp.skipIosTargets=true" gradle.properties; then
    sed -i '' 's/kotlin.mpp.skipIosTargets=true/kotlin.mpp.skipIosTargets=false/' gradle.properties
    echo "   ✅ iOS targets enabled"
else
    echo "   ✅ iOS targets already enabled"
fi

# Accept Xcode license if needed
echo ""
echo "📝 Checking Xcode license..."
if ! xcodebuild -checkFirstLaunchStatus 2>/dev/null; then
    echo "   Accepting Xcode license..."
    sudo xcodebuild -license accept || true
fi

# Build
echo ""
echo "🔨 Building project..."
./gradlew clean build

echo ""
echo "✅ Build complete!"
echo ""
echo "📦 Outputs:"
echo "   Android APK: androidApp/build/outputs/apk/debug/androidApp-debug.apk"
echo "   iOS Framework: shared/build/framework/"
echo ""
echo "🚀 Next steps:"
echo "   Android: ./gradlew :androidApp:installDebug"
echo "   iOS: Open iosApp/iosApp/iosApp.xcodeproj in Xcode"

