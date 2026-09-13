#!/bin/bash
# Build signed for a real iPhone and install it. Needs DEVELOPMENT_TEAM in Local.xcconfig
# and the phone paired once. Usage: scripts/device.sh <device-udid> (see xcrun devicectl list devices)
set -euo pipefail
source "$(dirname "$0")/env.sh"
DEVICE="${1:-}"
if [ -z "$DEVICE" ]; then
  echo "Paired devices:"; xcrun devicectl list devices; echo "Usage: $0 <udid>"; exit 1
fi
if ! grep -qE '^[[:space:]]*DEVELOPMENT_TEAM[[:space:]]*=' Local.xcconfig; then
  echo "Set DEVELOPMENT_TEAM = <team id> in Local.xcconfig (Apple Developer > Membership)."; exit 1
fi
build_scheme NanoBuddha "platform=iOS,id=$DEVICE" -allowProvisioningUpdates -allowProvisioningDeviceRegistration
xcrun devicectl device install app --device "$DEVICE" "$DEVICE_APP_PATH"
xcrun devicectl device process launch --device "$DEVICE" "$BUNDLE_ID"
