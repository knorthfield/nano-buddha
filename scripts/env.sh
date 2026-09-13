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
WATCH_SIM_NAME="${WATCH_SIM_NAME:-Apple Watch Series 11 (46mm)}"
WATCH_BUNDLE_ID="com.krisnorthfield.NanoBuddha.watchkitapp"
WATCH_APP_PATH="$ROOT/build/Build/Products/Debug-watchsimulator/NanoBuddhaWatch.app"
TV_SIM_NAME="${TV_SIM_NAME:-Apple TV 4K (3rd generation)}"
TV_APP_PATH="$ROOT/build/Build/Products/Debug-appletvsimulator/NanoBuddhaTV.app"
MAC_APP_PATH="$ROOT/build/Build/Products/Debug/Nano Buddha.app"
