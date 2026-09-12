#!/bin/bash
# Build the Apple TV app, then install and launch it on the Apple TV simulator
# (TV_SIM_NAME env var overrides the device). Extra arguments go to the app.
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
xcodegen generate --quiet
xcodebuild -project NanoBuddha.xcodeproj -scheme NanoBuddhaTV \
  -destination "platform=tvOS Simulator,name=$TV_SIM_NAME,OS=latest" \
  -derivedDataPath build build | grep -E "error:|warning:|BUILD" || true
xcrun simctl boot "$TV_SIM_NAME" 2>/dev/null || true
open -a Simulator
xcrun simctl install "$TV_SIM_NAME" "$TV_APP_PATH"
xcrun simctl launch "$TV_SIM_NAME" "$BUNDLE_ID" "$@"
