#!/bin/bash
# Run the unit tests and the UI tests on the simulator.
set -euo pipefail
source "$(dirname "$0")/env.sh"
xcodegen generate --quiet
xcodebuild -project NanoBuddha.xcodeproj -scheme NanoBuddha -destination "$SIM_DEST" \
  -derivedDataPath build test | grep -E "error:|Test Case|Executed|TEST" || true
