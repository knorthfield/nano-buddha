#!/bin/bash
# Build signed for a real iPhone and install it. Needs DEVELOPMENT_TEAM in Local.xcconfig
# and the phone paired once. Usage: scripts/device.sh <device-udid> (see xcrun devicectl list devices)
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
DEVICE="${1:-}"
if [ -z "$DEVICE" ]; then
  echo "Paired devices:"; xcrun devicectl list devices; echo "Usage: $0 <udid>"; exit 1
fi
if ! grep -qE '^[[:space:]]*DEVELOPMENT_TEAM[[:space:]]*=' Local.xcconfig; then
  echo "Set DEVELOPMENT_TEAM = <team id> in Local.xcconfig (Apple Developer > Membership)."; exit 1
fi
xcodegen generate --quiet
xcodebuild -project NanoBuddha.xcodeproj -scheme NanoBuddha \
  -destination "platform=iOS,id=$DEVICE" -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
  -derivedDataPath build build | grep -E "error:|BUILD" || true
xcrun devicectl device install app --device "$DEVICE" \
  "$ROOT/build/Build/Products/Debug-iphoneos/NanoBuddha.app"
xcrun devicectl device process launch --device "$DEVICE" "$BUNDLE_ID"
