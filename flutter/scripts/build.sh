#!/bin/bash
# Build script for CompostKaki Flutter app

set -e

echo "🔨 Building CompostKaki Flutter App"
echo "===================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Navigate to flutter directory
cd "$(dirname "$0")/.."

# Parse arguments
BUILD_TYPE=${1:-debug}
PLATFORM=${2:-android}

echo -e "${BLUE}Build type: $BUILD_TYPE${NC}"
echo -e "${BLUE}Platform: $PLATFORM${NC}"
echo ""

# Clean build
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Run tests first
echo ""
echo "🧪 Running tests..."
if flutter test; then
    echo -e "${GREEN}✓ Tests passed${NC}"
else
    echo -e "${RED}✗ Tests failed, aborting build${NC}"
    exit 1
fi

# Build based on platform and type
echo ""
echo "🔨 Building app..."

if [ "$PLATFORM" == "android" ]; then
    if [ "$BUILD_TYPE" == "debug" ]; then
        echo "Building Android APK (Debug)..."
        flutter build apk --debug
        echo -e "${GREEN}✓ Debug APK built successfully${NC}"
        echo "Location: build/app/outputs/flutter-apk/app-debug.apk"
    elif [ "$BUILD_TYPE" == "release" ]; then
        echo "Building Android APK (Release)..."
        flutter build apk --release --split-per-abi
        echo -e "${GREEN}✓ Release APKs built successfully${NC}"
        echo "Location: build/app/outputs/flutter-apk/"
        ls -lh build/app/outputs/flutter-apk/*.apk
    elif [ "$BUILD_TYPE" == "appbundle" ]; then
        echo "Building Android App Bundle (Release)..."
        flutter build appbundle --release
        echo -e "${GREEN}✓ App bundle built successfully${NC}"
        echo "Location: build/app/outputs/bundle/release/app-release.aab"
    fi
elif [ "$PLATFORM" == "ios" ]; then
    if [ "$BUILD_TYPE" == "debug" ]; then
        echo "Building iOS (Debug)..."
        flutter build ios --debug
        echo -e "${GREEN}✓ Debug iOS build completed${NC}"
    elif [ "$BUILD_TYPE" == "release" ]; then
        echo "Building iOS (Release)..."
        flutter build ios --release --no-codesign
        echo -e "${GREEN}✓ Release iOS build completed${NC}"
        echo -e "${YELLOW}Note: You'll need to code sign in Xcode for distribution${NC}"
    fi
else
    echo -e "${RED}Unknown platform: $PLATFORM${NC}"
    echo "Usage: ./build.sh [debug|release|appbundle] [android|ios]"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Build completed successfully!${NC}"

