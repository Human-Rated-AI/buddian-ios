#!/bin/bash

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
    # Use xcrun simctl for reliable detection — skips placeholders
    DEVICE_ID=$(xcrun simctl list devices available | grep "iPhone" | grep -v "unavailable" | head -1 | grep -oE '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}')
    if [ -n "$DEVICE_ID" ]; then
        DESTINATION="platform=iOS Simulator,id=$DEVICE_ID"
        echo "Auto-detected simulator: $DESTINATION"
    else
        echo "ERROR: No iOS Simulator found. Install one in Xcode > Settings > Platforms."
        exit 1
    fi
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
xcodebuild build \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -configuration "$CONFIG" \
    -clonedSourcePackagesDirPath .spm-packages \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO
