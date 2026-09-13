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
completed; one ended before it does not. Sessions are saved to `store.json` in the app group
container `group.com.krisnorthfield.NanoBuddha` (`Store.swift` moves an old `Documents/store.json`
there on first launch and still reads the old `lastNominalMinutes` + `growthSeconds` keys) and to
Apple Health as Mindful Minutes (`HealthWriter.swift`). History has a Copy week button that puts a
markdown log of the last 7 days on the pasteboard (`WeekLog.swift`).
`NanoBuddhaWidgets` is a WidgetKit extension: one widget (small home screen, lock screen
circular/rectangular/inline) with the intended minutes and the last 7 days, and a Control Centre
button "Begin sit" (`BeginSitIntent`, `openAppWhenRun`). `NanoBuddhaWatchWidgets` is the watchOS
widget extension embedded in the watch app: it compiles the same `SitWidget.swift` (plus `Store`,
`Session`, `DurationPlanner`) as complications and Smart Stack widget, families corner (watch
only, `#if os(watchOS)`), circular, rectangular and inline; the bundle id is prefixed by the watch
app's (`...watchkitapp.NanoBuddhaWatchWidgets`). The intent writes a timestamp file
`sitRequest` in the app group; `RootView` consumes it on scene activation or on
`SitRequest.didPost` and starts a sit. (A flag in app-group `UserDefaults` lost writes on the
simulator, hence the file.) `Model/AppShortcuts.swift` registers the same intent as an App
Shortcut, so Siri ("Begin a sit in Nano Buddha"), Spotlight, the Shortcuts app and the Action
button can begin a sit on the iPhone and the watch (`WatchRootView` consumes the request the
same way). The provider is compiled into the two apps only, not the widget extension or the TV.
The store calls `WidgetCenter.reloadAllTimelines()` on every save.
A running sit has a Live Activity (`Model/SitActivity.swift`, `NanoBuddhaWidgets/SitActivityWidget.swift`,
`NSSupportsLiveActivities` in `project.yml`): lock screen banner and Dynamic Island show "Sitting"
and an End button, never the time. `EndSitIntent` is a `LiveActivityIntent`, so it runs in the app
process and posts `SitActivity.endRequested`, which `SitView` handles like a tap on End. If the app
was killed mid-sit nobody hears it; the intent still ends the activity and removes the pending bell
notifications, and the sit is lost (the phase was never persisted). `SitActivity.swift` is compiled
into the iPhone app and the widget extension only.
`NanoBuddhaWatch` is the Apple Watch app (single-target, embedded under `Watch/` in the iOS
bundle, bundle id `com.krisnorthfield.NanoBuddha.watchkitapp`). It runs the same sit through the
shared `Sit` model (`Model/Sit.swift`: settling silence, opening bell, target bell, End). Bells
on the watch are a wrist tap (`WKInterfaceDevice.play(.notification)` in `Bell.swift`); the bowl
sound plays only when the Sound toggle on the watch home screen is on (`UserDefaults`
`bellSound`, off by default, for retreats). A mindfulness `WKExtendedRuntimeSession`
(`WatchSitView.swift`, `WKBackgroundModes: [mindfulness]`) keeps the app running with the wrist
down for up to an hour; after that, or after a crown press, the scheduled notifications ring
the bells as on a locked phone. The watch has its own `store.json` in its app group container
(same group id as the iPhone, but a separate device; `Store.defaultFileURL` moved the old
Documents copy there) so the watch complication can read it, and it saves to Health itself.
`Model/Sync.swift` keeps the two stores the same over WatchConnectivity: every save sends the
snapshot as the application context, the other side merges it (`Store.merge`: union of sits by
id, the more recently changed intended duration wins). The widget targets do not compile
`Sync.swift`.
`Model/CloudSync.swift` does the same for every device on one iCloud account (iPhone, iPad,
watch, TV) over the iCloud key-value store (`NSUbiquitousKeyValueStore`, key `snapshot`, the
last 4000 sits, merged with `Store.merge`; the entitlement
`com.apple.developer.ubiquity-kvstore-identifier` is the iPhone bundle id in all three apps so
they share one store). The apps set `Store.didSave` themselves to push to both syncs. The
widget targets do not compile it. The App IDs need the iCloud key-value capability for device
builds; the simulator only syncs when an iCloud account is signed in via Settings (no CLI for
that), and without one the key-value calls are silent no-ops.
`NanoBuddhaTV` is the Apple TV app (`NanoBuddhaTV/`, tvOS 26, same bundle id as the iPhone app
for universal purchase, not embedded in it). It compiles the shared `Sit`, `Store`, `Bell`,
`CloudSync`, `PrimaryButton` and `Starfield`, and nothing else: tvOS has no HealthKit, WatchConnectivity,
WidgetKit, pasteboard or alert notifications, so the TV store lives in Documents and syncs only
over iCloud (`CloudSync`, no WatchConnectivity), there is no Health write, no Copy week, and the
bowl is audio only
(`Bell.swift` skips notifications and haptics with `#if os(tvOS)`; `Store.swift` guards
WidgetKit with `canImport`). The home screen has no first-run picker, only the nudge row. The
sit screen keeps the TV awake (`isIdleTimerDisabled`) and the remote's Menu button ends the sit
(`.onExitCommand`) so a sit cannot run on behind the tvOS home screen.
The app follows the system appearance: dark mode is the spiral galaxy on black, light mode is
grains of sand on old paper (`Starfield.swift`, one `Palette` per scheme; `GlassTint` and
`AccentColor` colour sets carry light and dark variants).

## Build and run
- `project.yml` is the source of truth; `NanoBuddha.xcodeproj` is generated and git-ignored.
- `scripts/build.sh` — xcodegen + simulator build.
- `scripts/run.sh` — build, then install and launch on the simulator (`SIM_NAME` env var overrides the device).
- `scripts/test.sh` — unit tests and UI test.
- `scripts/watch.sh` — build, then install and launch the watch app on the watch simulator
  (`WATCH_SIM_NAME` env var overrides the device). Extra arguments go to the app (`-quickSit`).
- `scripts/tv.sh` — build, then install and launch the Apple TV app on the Apple TV simulator
  (`TV_SIM_NAME` env var overrides the device). Extra arguments go to the app (`-quickSit`).
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
- The iOS scheme builds the embedded watch app, so it needs the watchOS simulator runtime too:
  `xcodebuild -downloadPlatform watchOS`. Without it even the iPhone build fails with "This
  scheme builds an embedded Apple Watch app. watchOS 26.5 must be installed".
- The TV target needs the tvOS simulator runtime: `xcodebuild -downloadPlatform tvOS`. An older
  runtime (tvOS 26.2) is not enough; Xcode 26.6 refuses the destination until 26.5 is installed.
- The tvOS app icon is not the Icon Composer bundle: tvOS wants an
  `App Icon & Top Shelf Image.brandassets` catalog (`NanoBuddhaTV/Assets.xcassets`) of layered
  images, 400x240 (@1x, @2x) and 1280x768. The two layers are `stars.svg` on black (Back) and
  `hole.svg` (Front) from `AppIcon.icon/Assets`, rendered with `rsvg-convert` at the square size
  and cropped to height with `sips -c`. `ASSETCATALOG_COMPILER_APPICON_NAME` on the TV target
  names the brandassets. Top Shelf images are not provided.
- `xcrun simctl ui <tv udid> appearance light` fails on the tvOS simulator ("Runtime does not
  support userInterfaceStyle"); the TV light palette has only been checked on the iPhone. There
  is no CLI for the Siri Remote either: `osascript` key codes to the Simulator app do it
  (36 = select, 53 = Menu, 125 = down) after `tell application "Simulator" to activate`.
- Running the watch app alone needs no paired simulators. Testing sync does: `xcrun simctl pair
  <watch udid> <iphone udid>` (`simctl list pairs`). The simulator has no haptics.
- `WKExtendedRuntimeSession.notifyUser(hapticType:)` works only for `alarm` sessions started
  with `startAtDate`, not for mindfulness ones. A mindfulness session is frontmost-only: it
  ends when the user presses the crown.
- Every test target needs `GENERATE_INFOPLIST_FILE: YES` in `project.yml` or signing fails.
- The widget extension's bundle id must be prefixed by the app's
  (`com.krisnorthfield.NanoBuddha.NanoBuddhaWidgets`), set explicitly in `project.yml`; xcodegen's
  default `com.krisnorthfield.NanoBuddhaWidgets` makes iOS ignore the extension silently.
- No CLI can place a widget or control on the simulator. Add it by hand in the Simulator app
  (long-press the Home Screen > Edit > Add Widget; Control Centre > + > Add a Control) or drive
  SpringBoard from a throwaway XCUITest (`XCUIApplication(bundleIdentifier: "com.apple.springboard")`,
  long-press an empty spot by coordinate, tap Edit, "Add Widget", search "Nano"), then screenshot
  with `simctl io`. To exercise the Control Centre path without the control, write the current
  Unix time to `<group container>/sitRequest` (`xcrun simctl get_app_container <udid>
  com.krisnorthfield.NanoBuddha groups`) and launch the app: it opens on the sit screen.
- Watch complications: after a fresh install the face editor and the Smart Stack picker do not
  list the app (chronod has the descriptor, the pickers cache the app list). Reboot the watch
  simulator (`simctl shutdown` + `boot`) and it appears. The scroll wheel does nothing on the
  watch simulator and osascript cannot hold or drag the mouse, so the face editor was driven
  with a small CGEvent tool (`swiftc` a script that posts mouseDown/mouseUp/drag with
  `CGEvent(mouseEventSource:mouseType:mouseCursorPosition:mouseButton:)`; needs Accessibility
  for the terminal). Map watch pixels to Mac points from a `screencapture -R` of the window,
  not from the window frame: the screen sits low inside the bezel. Long press on the face,
  Edit, swipe to Complications, tap a slot, scroll to N; Smart Stack: swipe up on the face,
  Edit, +, pick the app.
- `osascript` keystrokes to Simulator.app (cmd+shift+H, cmd+L) did nothing here, so the Live
  Activity is checked from the UI test (`testEndFromTheLiveActivity`): `XCUIDevice.shared.press(.home)`,
  a 1 s press on the island at normalized (0.5, 0.03) expands it, and `springboard.buttons["End"]`
  is tappable there. Coordinates take a `CGVector`, not a `CGPoint`.
- Right after `simctl install`, `simctl launch` can fail with "Application failed preflight checks"
  while the extension registers. Wait a few seconds or uninstall and reinstall.
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
- `NanoBuddhaTests` — unit tests for `DurationPlanner`, `Store` (including merge), `Sit`, `WeekLog`
  and `SitRequest`.
- `NanoBuddhaUITests/SitFlowUITests.swift` — launches with `-quickSit` (a 5 s sit), taps Begin,
  answers the notification prompt (lives in SpringBoard) and the Health prompt (part of the
  app's hierarchy, identifier `UIA.Health.DoNotAllow.Button`), then checks Done and History, and that Copy week puts the week log on the pasteboard.
  A second test ends the sit from the expanded Dynamic Island.

## Git
- Commits use the GitHub noreply address set in the repo-local git config. The GitHub account
  blocks pushes that expose the real email.
- `TODO.md` (roadmap) and `FIXME.md` (notes and crash logs) are git-ignored and local only.
