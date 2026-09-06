#!/bin/bash
# Run the unit tests on the simulator.
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
xcodegen generate --quiet
xcodebuild -project NanoBuddha.xcodeproj -scheme NanoBuddha \
  -destination "platform=iOS Simulator,name=$SIM_NAME,OS=latest" \
  -derivedDataPath build test | grep -E "error:|Test Case|Executed|TEST" || true
