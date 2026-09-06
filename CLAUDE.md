# Nano Buddha

iPhone meditation timer. SwiftUI, iOS 17+, no third-party packages. The Xcode GUI is never opened.
Public repo: https://github.com/knorthfield/nano-buddha (MIT).

## What it does
The user picks a nominal duration. The real duration is hidden:
`nominal + growthSeconds + random(-60...60)`. `growthSeconds` rises by 15 s per completed sit
(`NanoBuddha/Model/DurationPlanner.swift`, `Store.swift`). The sit screen shows no time.
A singing bowl rings at the end (`Bell.swift`: AVAudioPlayer in the foreground, a local
notification with the same sound if locked). Sessions are saved to `Documents/store.json`
and to Apple Health as Mindful Minutes (`HealthWriter.swift`).

## Build and run
- `project.yml` is the source of truth; `NanoBuddha.xcodeproj` is generated and git-ignored.
- `scripts/build.sh` — xcodegen + simulator build.
- `scripts/run.sh` — build, then install and launch on the simulator (`SIM_NAME` env var overrides the device).
- `scripts/test.sh` — unit tests and UI test.
- `scripts/device.sh <name-or-udid>` — signed build and install on a real iPhone. Needs
  `DEVELOPMENT_TEAM = <team id>` in `Local.xcconfig` (git-ignored).
- The scripts set `DEVELOPER_DIR` to /Applications/Xcode.app, so `xcode-select` does not need changing.
- Screenshots: `xcrun simctl io booted screenshot shot.png`.

## Toolchain gotchas (learned the hard way)
- Simulator builds keep ad-hoc code signing on. Do not add `CODE_SIGNING_ALLOWED=NO`: it drops
  the HealthKit entitlement and Health calls fail.
- Xcode 26.6 needs the iOS 26.5 simulator runtime. If `xcodebuild` says no destination matches,
  run `xcodebuild -downloadPlatform iOS` (about 8.5 GB).
- Two simulators can share the name "iPhone 17" (one per runtime). The scripts pass `OS=latest`
  to pick the newest one.
- Every test target needs `GENERATE_INFOPLIST_FILE: YES` in `project.yml` or signing fails.
- The app icon PNG must be exactly 1024x1024. Rendering it with AppKit on a Retina Mac
  produces 2048x2048; fix with `sips -z 1024 1024`.
- To debug a failed UI test: `xcrun xcresulttool export attachments --path <xcresult> --output-path <dir>`
  gives a screen recording plus accessibility-hierarchy dumps. Attachments are only kept for
  failing tests.

## Assets
`NanoBuddha/Resources/bowl.wav` — "Tibetan Bowl Struck #1", BigSoundBank, CC0,
https://bigsoundbank.com/detail-1110-tibetan-bowl-struck.html, trimmed to 28 s
(notification sounds must be under 30 s). BigSoundBank serves HTML to plain curl; the
`/UPLOAD/bwf-en/<id>.wav` path with a browser User-Agent works.

## Tests
- `NanoBuddhaTests` — unit tests for `DurationPlanner` and `Store`.
- `NanoBuddhaUITests/SitFlowUITests.swift` — launches with `-quickSit` (a 5 s sit), taps Begin,
  answers the notification prompt (lives in SpringBoard) and the Health prompt (part of the
  app's hierarchy, identifier `UIA.Health.DoNotAllow.Button`), then checks Done and History.

## Git
- Commits use the GitHub noreply address set in the repo-local git config. The GitHub account
  blocks pushes that expose the real email.
- `TODO.md` (roadmap) and `FIXME.md` (notes and crash logs) are git-ignored and local only.
