# Nano Buddha

iPhone and iPad meditation timer. SwiftUI, iOS 26+, no third-party packages. The Xcode GUI is never opened.
Public repo: https://github.com/knorthfield/nano-buddha (MIT).

## What it does
The user picks a duration on the first run only. After that the start screen shows the intended
duration and lets the user nudge it by one minute. The intended duration grows by 15 s per
completed sit (`Store.intendedSeconds`). The real duration adds a hidden `random(-60...60)` s
(`NanoBuddha/Model/DurationPlanner.swift`). The sit screen shows no time.
After Begin the app stays silent for 30 s (`DurationPlanner.settlingSeconds`) so the user can put
the phone down; then a singing bowl rings to open the sit. The sit and the target are measured
from that opening bell. The bowl rings again when the target passes (`Bell.swift`: AVAudioPlayer
in the foreground, a local notification with the same sound if locked; one notification per
bell). The sit carries on until the user taps End. A sit ended after the target bell counts as
completed; one ended before it does not. Sessions are saved to `Documents/store.json`
(`Store.swift` still reads the old `lastNominalMinutes` + `growthSeconds` keys) and to Apple
Health as Mindful Minutes (`HealthWriter.swift`). History has a Copy week button that puts a
markdown log of the last 7 days on the pasteboard (`WeekLog.swift`).
The app follows the system appearance: dark mode is the spiral galaxy on black, light mode is
grains of sand on old paper (`Starfield.swift`, one `Palette` per scheme; `GlassTint` and
`AccentColor` colour sets carry light and dark variants).

## Build and run
- `project.yml` is the source of truth; `NanoBuddha.xcodeproj` is generated and git-ignored.
- `scripts/build.sh` — xcodegen + simulator build.
- `scripts/run.sh` — build, then install and launch on the simulator (`SIM_NAME` env var overrides the device).
- `scripts/test.sh` — unit tests and UI test.
- `.zed/tasks.json` (git-ignored, local only) — Zed tasks (Run on simulator, Build, Test) that call the scripts above.
- `scripts/device.sh <udid>` — signed build and install on a real iPhone (UDID from `xcrun devicectl list devices`). Needs
  `DEVELOPMENT_TEAM = <team id>` in `Local.xcconfig` (git-ignored; `scripts/env.sh` creates a stub).
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
- xcodegen does not set `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME`; without it in `project.yml`
  `Color.accentColor` is system blue, not the tan `AccentColor` colorset.
- The app icon is `NanoBuddha/AppIcon.icon`, a hand-written Icon Composer bundle (`icon.json`
  plus `Assets/`: `hole.svg` + `stars.svg` for dark, `hole-light.svg` + `sand.svg` for light).
  A per-appearance property is a `<key>-specializations` array that REPLACES the plain key:
  `[{"value": <light>}, {"appearance": "dark", "value": <dark>}]`. Keeping the plain key next to
  the array, or leaving out the unqualified `{"value": ...}` entry, makes ictool and actool drop
  the array silently. Check with `ictool <bundle> --export-intermediate-representation --platform iOS
  --output-directory <dir>`: every image the icon uses must appear as an imageset there.
  `scripts/icon-stars.swift` (and `--light`) regenerate the star SVGs. Do not add an `AppIcon.appiconset` next to it: two `AppIcon` assets
  conflict, and Xcode makes the flat fallbacks itself. Preview it with
  `"/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool"
  NanoBuddha/AppIcon.icon --export-image --output-file out.png --platform iOS --rendition Default
  --width 1024 --height 1024 --scale 1` (`--rendition Dark` for dark mode). `xcrun ictool` is a
  different binary and does not render.
- After changing the icon, the simulator's notification banners can keep showing the old icon
  even after `simctl uninstall`. Restart SpringBoard:
  `xcrun simctl spawn booted launchctl kickstart -k system/com.apple.SpringBoard`. To see a
  banner without waiting for a sit, `xcrun simctl push booted com.krisnorthfield.NanoBuddha
  payload.json` with an `aps` alert (notification permission must already be granted).
- To debug a failed UI test: `xcrun xcresulttool export attachments --path <xcresult> --output-path <dir>`
  gives a screen recording plus accessibility-hierarchy dumps. Attachments are only kept for
  failing tests.
- `NanoBuddhaUITests-Runner` stays installed on the simulator after a test run. Tapping its icon
  crashes at once with `Library not loaded: @rpath/lib_TestingInterop.dylib`. That is expected:
  only `xcodebuild test` supplies the DYLD paths the runner needs. Not a bug.

## Assets
`NanoBuddha/Resources/bowl.wav` — "Tibetan Bowl Struck #1", BigSoundBank, CC0,
https://bigsoundbank.com/detail-1110-tibetan-bowl-struck.html, trimmed to 28 s
(notification sounds must be under 30 s) with a 1 s fade-in so the strike does not startle:
`ffmpeg -i in.wav -af "afade=t=in:st=0:d=1:curve=hsin" -c:a pcm_s16le -ar 44100 -ac 1 out.wav`.
BigSoundBank serves HTML to plain curl; the
`/UPLOAD/bwf-en/<id>.wav` path with a browser User-Agent works.

## Tests
- `NanoBuddhaTests` — unit tests for `DurationPlanner` and `Store`.
- `NanoBuddhaUITests/SitFlowUITests.swift` — launches with `-quickSit` (a 5 s sit), taps Begin,
  answers the notification prompt (lives in SpringBoard) and the Health prompt (part of the
  app's hierarchy, identifier `UIA.Health.DoNotAllow.Button`), then checks Done and History, and that Copy week puts the week log on the pasteboard.

## Git
- Commits use the GitHub noreply address set in the repo-local git config. The GitHub account
  blocks pushes that expose the real email.
- `TODO.md` (roadmap) and `FIXME.md` (notes and crash logs) are git-ignored and local only.
