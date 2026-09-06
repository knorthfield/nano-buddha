#!/bin/bash
# Generate the Xcode project and build for the simulator.
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
xcodegen generate --quiet
xcodebuild -project NanoBuddha.xcodeproj -scheme NanoBuddha \
  -destination "platform=iOS Simulator,name=$SIM_NAME" \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build "$@" | grep -E "error:|warning:|BUILD" || true
