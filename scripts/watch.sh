#!/bin/bash
# Build the watch app, then install and launch it on the watch simulator
# (WATCH_SIM_NAME env var overrides the device).
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
xcodegen generate --quiet
xcodebuild -project NanoBuddha.xcodeproj -scheme NanoBuddhaWatch \
  -destination "platform=watchOS Simulator,name=$WATCH_SIM_NAME,OS=latest" \
  -derivedDataPath build build | grep -E "error:|warning:|BUILD" || true
xcrun simctl boot "$WATCH_SIM_NAME" 2>/dev/null || true
open -a Simulator
xcrun simctl install "$WATCH_SIM_NAME" "$WATCH_APP_PATH"
xcrun simctl launch "$WATCH_SIM_NAME" "$WATCH_BUNDLE_ID" "$@"
