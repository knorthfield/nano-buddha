#!/bin/bash
# Build the watch app, then install and launch it on the watch simulator
# (WATCH_SIM_NAME env var overrides the device). Extra arguments go to the app.
set -euo pipefail
source "$(dirname "$0")/env.sh"
build_scheme NanoBuddhaWatch "platform=watchOS Simulator,name=$WATCH_SIM_NAME,OS=latest"
install_and_launch "$WATCH_SIM_NAME" "$WATCH_APP_PATH" "$WATCH_BUNDLE_ID" "$@"
