#!/bin/bash
set -euo pipefail

# Buddian iOS build script
# Usage: ./build.sh [clean]
# Requires: Xcode 16+, xcodebuild

SCHEME="Buddian"
PROJECT="Buddian.xcodeproj"
DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=latest"
CONFIG="Debug"

# Create stub GoogleService-Info.plist if missing (needed for CI)
if [ ! -f Buddian/GoogleService-Info.plist ]; then
    echo "--- Creating GoogleService-Info.plist stub ---"
    cat > Buddian/GoogleService-Info.plist << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>API_KEY</key>
	<string>CI_PLACEHOLDER</string>
	<key>GCM_SENDER_ID</key>
	<string>000000000000</string>
	<key>PLIST_VERSION</key>
	<string>1</string>
	<key>BUNDLE_ID</key>
	<string>com.humanratedai.Buddian</string>
	<key>PROJECT_ID</key>
	<string>human-rated-ai</string>
	<key>STORAGE_BUCKET</key>
	<string>human-rated-ai.appspot.com</string>
	<key>IS_ADS_ENABLED</key>
	<false/>
	<key>IS_ANALYTICS_ENABLED</key>
	<false/>
	<key>IS_APPINVITE_ENABLED</key>
	<false/>
	<key>IS_GCM_ENABLED</key>
	<false/>
	<key>IS_SIGNIN_ENABLED</key>
	<true/>
	<key>GOOGLE_APP_ID</key>
	<string>1:000000000000:ios:0000000000000000</string>
	<key>CLIENT_ID</key>
	<string>000000000000-placeholder.apps.googleusercontent.com</string>
	<key>REVERSED_CLIENT_ID</key>
	<string>com.googleusercontent.apps.000000000000-placeholder</string>
</dict>
</plist>
PLIST
    echo "Created stub. Replace with real file for device builds."
    echo ""
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
