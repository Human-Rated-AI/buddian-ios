#!/bin/bash
set -euo pipefail

# Buddian iOS build script
# Usage: ./build.sh [clean] [destination]
# Examples:
#   ./build.sh                                    # auto-detect first available simulator
#   ./build.sh clean                              # clean + build
#   ./build.sh "" "platform=iOS,name=iPhone 17e"  # specific device

SCHEME="Buddian"
PROJECT="Buddian.xcodeproj"
CONFIG="Debug"

# Require GoogleService-Info.plist
if [ ! -f Buddian/GoogleService-Info.plist ]; then
    echo "ERROR: Buddian/GoogleService-Info.plist not found."
    echo "Download it from Firebase Console > Project Settings > iOS app."
    exit 1
fi

# Destination: use arg, or auto-detect first available simulator
if [ "${2:-}" != "" ]; then
    DESTINATION="$2"
else
    DESTINATION=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations 2>/dev/null \
        | grep "platform:iOS Simulator" | head -1 | sed 's/.*{ //' | sed 's/ }.*//')
    if [ -z "$DESTINATION" ]; then
        echo "ERROR: No iOS Simulator found. Install a simulator in Xcode > Settings > Platforms."
        exit 1
    fi
    echo "Auto-detected simulator: $DESTINATION"
fi

# Clean if requested
if [ "${1:-}" = "clean" ]; then
    echo "--- Cleaning build artifacts ---"
    xcodebuild clean \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -configuration "$CONFIG" \
        > /dev/null 2>&1
    echo "Clean complete."
    echo ""
fi

echo "--- Resolving SPM packages ---"
xcodebuild -resolvePackageDependencies \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -clonedSourcePackagesDirPath .spm-packages

echo ""
echo "--- Building ($CONFIG) ---"

# Build and capture exit code properly
set +e
xcodebuild build \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -configuration "$CONFIG" \
    -clonedSourcePackagesDirPath .spm-packages \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED|note:)"
BUILD_EXIT=${PIPESTATUS[0]}
set -e

echo ""
if [ $BUILD_EXIT -eq 0 ]; then
    echo -e "\033[0;32mBuild succeeded.\033[0m"
else
    echo -e "\033[0;31mBuild failed with exit code $BUILD_EXIT.\033[0m"
fi

exit $BUILD_EXIT
