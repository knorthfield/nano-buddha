#!/bin/bash
# Generate the Xcode project and build for the simulator. Extra arguments go to xcodebuild.
set -euo pipefail
source "$(dirname "$0")/env.sh"
build_scheme NanoBuddha "$SIM_DEST" "$@"
