#!/bin/bash
# Build, then install and launch on the simulator.
set -euo pipefail
source "$(dirname "$0")/env.sh"
"$ROOT/scripts/build.sh"
xcrun simctl boot "$SIM_NAME" 2>/dev/null || true
open -a Simulator
xcrun simctl install "$SIM_NAME" "$APP_PATH"
xcrun simctl launch "$SIM_NAME" "$BUNDLE_ID"
