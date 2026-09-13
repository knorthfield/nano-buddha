#!/bin/bash
# Build the Mac app signed for this Mac, then open it. Extra arguments go to the app.
# Needs DEVELOPMENT_TEAM in Local.xcconfig for the iCloud entitlement.
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
xcodegen generate --quiet
xcodebuild -project NanoBuddha.xcodeproj -scheme NanoBuddhaMac \
  -destination "platform=macOS" -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
  -derivedDataPath build build | grep -E "error:|warning:|BUILD" || true
open "$MAC_APP_PATH" --args "$@"
