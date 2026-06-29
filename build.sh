#!/bin/bash
set -euo pipefail

# Buddian iOS build script
# Usage: ./build.sh [clean]
# Requires: Xcode 16+, xcodebuild

SCHEME="Buddian"
PROJECT="Buddian.xcodeproj"
DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=latest"
CONFIG="Debug"

# Require GoogleService-Info.plist
if [ ! -f Buddian/GoogleService-Info.plist ]; then
    echo "ERROR: Buddian/GoogleService-Info.plist not found."
    echo "Download it from Firebase Console > Project Settings > iOS app."
    exit 1
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
echo "--- Building ($CONFIG, iOS Simulator) ---"
set -o pipefail
xcodebuild build \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -configuration "$CONFIG" \
    -clonedSourcePackagesDirPath .spm-packages \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    2>&1 | while IFS= read -r line; do
        # Highlight errors and warnings
        if [[ "$line" == *"error:"* ]]; then
            echo -e "\033[0;31m$line\033[0m"
        elif [[ "$line" == *"warning:"* ]]; then
            echo -e "\033[0;33m$line\033[0m"
        elif [[ "$line" == *"BUILD SUCCEEDED"* ]]; then
            echo -e "\033[0;32m$line\033[0m"
        elif [[ "$line" == *"BUILD FAILED"* ]]; then
            echo -e "\033[0;31m$line\033[0m"
        else
            echo "$line"
        fi
    done

BUILD_EXIT=$?

echo ""
if [ $BUILD_EXIT -eq 0 ]; then
    echo -e "\033[0;32mBuild succeeded.\033[0m"
else
    echo -e "\033[0;31mBuild failed with exit code $BUILD_EXIT.\033[0m"
fi

exit $BUILD_EXIT
