#!/bin/bash
# Shared settings and steps for the build scripts.
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
if [ ! -f "$ROOT/Local.xcconfig" ]; then
  printf '// Team-specific settings. Not committed. Needed only for a real device.\n// DEVELOPMENT_TEAM = XXXXXXXXXX\n' > "$ROOT/Local.xcconfig"
fi
# iPhone, iPad, TV and Mac share the bundle id (universal purchase).
BUNDLE_ID="com.krisnorthfield.NanoBuddha"
SIM_NAME="${SIM_NAME:-iPhone 17}"
# OS=latest picks the newest of two simulators that share a name.
SIM_DEST="platform=iOS Simulator,name=$SIM_NAME,OS=latest"
APP_PATH="$ROOT/build/Build/Products/Debug-iphonesimulator/NanoBuddha.app"
DEVICE_APP_PATH="$ROOT/build/Build/Products/Debug-iphoneos/NanoBuddha.app"
WATCH_SIM_NAME="${WATCH_SIM_NAME:-Apple Watch Series 11 (46mm)}"
WATCH_BUNDLE_ID="com.krisnorthfield.NanoBuddha.watchkitapp"
WATCH_APP_PATH="$ROOT/build/Build/Products/Debug-watchsimulator/NanoBuddhaWatch.app"
TV_SIM_NAME="${TV_SIM_NAME:-Apple TV 4K (3rd generation)}"
TV_APP_PATH="$ROOT/build/Build/Products/Debug-appletvsimulator/NanoBuddhaTV.app"
MAC_APP_PATH="$ROOT/build/Build/Products/Debug/Nano Buddha.app"

# build_scheme <scheme> <destination> [xcodebuild args...]: regenerate the project and build.
build_scheme() {
  local scheme="$1" destination="$2"; shift 2
  xcodegen generate --quiet
  xcodebuild -project NanoBuddha.xcodeproj -scheme "$scheme" -destination "$destination" \
    -derivedDataPath build "$@" build | grep -E "error:|warning:|BUILD" || true
}

# install_and_launch <simulator> <app path> <bundle id> [app args...]
install_and_launch() {
  local sim="$1" app="$2" bundle="$3"; shift 3
  xcrun simctl boot "$sim" 2>/dev/null || true
  open -a Simulator
  xcrun simctl install "$sim" "$app"
  xcrun simctl launch "$sim" "$bundle" "$@"
}
