#!/bin/bash
# Build the Apple TV app, then install and launch it on the Apple TV simulator
# (TV_SIM_NAME env var overrides the device). Extra arguments go to the app.
set -euo pipefail
source "$(dirname "$0")/env.sh"
build_scheme NanoBuddhaTV "platform=tvOS Simulator,name=$TV_SIM_NAME,OS=latest"
install_and_launch "$TV_SIM_NAME" "$TV_APP_PATH" "$BUNDLE_ID" "$@"
