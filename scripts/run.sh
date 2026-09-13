#!/bin/bash
# Build, then install and launch on the simulator. Extra arguments go to the app.
set -euo pipefail
source "$(dirname "$0")/env.sh"
build_scheme NanoBuddha "$SIM_DEST"
install_and_launch "$SIM_NAME" "$APP_PATH" "$BUNDLE_ID" "$@"
