#!/bin/bash
# Shared settings for the build scripts.
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ ! -f "$ROOT/Local.xcconfig" ]; then
  printf '// Team-specific settings. Not committed. Needed only for a real device.\n// DEVELOPMENT_TEAM = XXXXXXXXXX\n' > "$ROOT/Local.xcconfig"
fi
SIM_NAME="${SIM_NAME:-iPhone 17}"
BUNDLE_ID="com.krisnorthfield.NanoBuddha"
APP_PATH="$ROOT/build/Build/Products/Debug-iphonesimulator/NanoBuddha.app"
