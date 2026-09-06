# Nano Buddha

iPhone meditation timer. SwiftUI, iOS 17+, no third-party packages. The Xcode GUI is never opened.

## What it does
The user picks a nominal duration. The real duration is hidden:
`nominal + growthSeconds + random(-60...60)`. `growthSeconds` rises by 15 s per completed sit
(`NanoBuddha/Model/DurationPlanner.swift`, `Store.swift`). The sit screen shows no time.
A singing bowl rings at the end (`Bell.swift`: AVAudioPlayer in the foreground, a local
notification with the same sound if locked). Sessions are saved to `Documents/store.json`
and to Apple Health as Mindful Minutes (`HealthWriter.swift`).

## Build and run
- `project.yml` is the source of truth; `NanoBuddha.xcodeproj` is generated and git-ignored.
- `scripts/build.sh` — xcodegen + simulator build (unsigned).
- `scripts/run.sh` — build, then install and launch on the simulator (`SIM_NAME` env var overrides the device).
- `scripts/test.sh` — unit tests.
- `scripts/device.sh <name-or-udid>` — signed build and install on a real iPhone. Needs
  `DEVELOPMENT_TEAM = <team id>` in `Local.xcconfig` (git-ignored).
- The scripts set `DEVELOPER_DIR` to /Applications/Xcode.app, so `xcode-select` does not need changing.
- Screenshots: `xcrun simctl io booted screenshot shot.png`.

## Assets
`NanoBuddha/Resources/bowl.wav` — "Tibetan Bowl Struck #1", BigSoundBank, CC0,
https://bigsoundbank.com/detail-1110-tibetan-bowl-struck.html, trimmed to 28 s
(notification sounds must be under 30 s).
