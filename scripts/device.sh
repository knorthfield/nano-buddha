#!/bin/bash
# Build signed for a real iPhone and install it. Needs DEVELOPMENT_TEAM in Local.xcconfig
# and the phone paired once. Usage: scripts/device.sh [device-name-or-udid]
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
DEVICE="${1:-}"
if [ -z "$DEVICE" ]; then
  echo "Paired devices:"; xcrun devicectl list devices; echo "Usage: $0 <name-or-udid>"; exit 1
fi
xcodegen generate --quiet
xcodebuild -project NanoBuddha.xcodeproj -scheme NanoBuddha \
  -destination 'generic/platform=iOS' -allowProvisioningUpdates \
  -derivedDataPath build build | grep -E "error:|BUILD" || true
xcrun devicectl device install app --device "$DEVICE" \
  "$ROOT/build/Build/Products/Debug-iphoneos/NanoBuddha.app"
xcrun devicectl device process launch --device "$DEVICE" "$BUNDLE_ID"
