# Nano Buddha

An iPhone, iPad, Apple Watch, Apple TV and Mac meditation timer that quietly lengthens your sits.

You choose a duration on the first run, say 10 minutes, and nudge it by a minute after that. The app never times exactly that. It adds a
random offset of up to one minute either way, and a hidden base that grows by 15 seconds
after every completed sit. The sit screen shows no time at all, so there is nothing to
watch. A singing bowl rings when the time is up, and the sit carries on until you end it.
After Begin the app stays silent for 30 seconds so you can put the phone down; then the bowl
rings to open the sit, and the time is measured from there.
Each sit is saved locally and written to Apple Health as Mindful Minutes, and the sits sync
between your devices over iCloud (and WatchConnectivity for the watch). A sit can also be
started from a widget, Control Centre, Siri ("Begin a sit in Nano Buddha") or the Shortcuts app.
The watch has the same widget as a complication and in the Smart Stack.

SwiftUI, iOS 26+ (watchOS 26, tvOS 26 and macOS 26 for the watch, TV and Mac apps), no third-party packages.

## Requirements

- Xcode 27 with the iOS and watchOS simulator runtimes (the iOS scheme builds the embedded
  watch app; `xcodebuild -downloadPlatform watchOS`), plus tvOS for `scripts/tv.sh`
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

The Xcode project is generated from `project.yml` and is not committed. The scripts point at
`/Applications/Xcode.app` themselves, so `xcode-select` does not need changing.

## Build and run

```bash
scripts/build.sh   # generate the project and build for the simulator
scripts/run.sh     # build, then install and launch on the simulator
scripts/test.sh    # unit tests and the UI tests (a full sit; End from the Dynamic Island)
scripts/watch.sh   # build, then install and launch the watch app on the watch simulator
scripts/tv.sh      # build, then install and launch the Apple TV app on the Apple TV simulator
scripts/mac.sh     # signed build of the Mac app, then open it (needs DEVELOPMENT_TEAM, see below)
```

Set `SIM_NAME` to use a different simulator, for example `SIM_NAME="iPhone 17 Pro" scripts/run.sh` or
`SIM_NAME="iPad Air 11-inch (M4)" scripts/run.sh`; `WATCH_SIM_NAME` and `TV_SIM_NAME` do the same for
the watch and TV scripts. Extra arguments go to the app.

## Run on a real iPhone

1. The scripts create `Local.xcconfig` in the repo root. Uncomment `DEVELOPMENT_TEAM` there
   and set it to your team ID (Apple Developer > Membership).
2. Pair the phone with your Mac once.
3. `scripts/device.sh` lists paired devices with their UDIDs; `scripts/device.sh <udid>` builds,
   installs, and launches.

## Layout

- `NanoBuddha/Model` — `DurationPlanner` (hidden duration), `Sit` (settling silence and the two
  bells), `Store` and `Session` (JSON persistence), `Sync` and `CloudSync` (WatchConnectivity and
  iCloud), `HealthWriter`, `WeekLog`, `Bell` (bowl sound, haptic, and the local notification used
  when locked)
- `NanoBuddha/Views` — Home, Sit, Done, History
- `NanoBuddhaWidgets`, `NanoBuddhaWatch`, `NanoBuddhaWatchWidgets`, `NanoBuddhaTV`, `NanoBuddhaMac`
  — the widget extension, the watch app, its complication extension, the Apple TV app and the
  Mac app, each compiling the shared model files it can use
- `NanoBuddhaTests`, `NanoBuddhaUITests`

## Credits

Singing bowl: "Tibetan Bowl Struck #1" from [BigSoundBank](https://bigsoundbank.com/detail-1110-tibetan-bowl-struck.html), CC0.

## Licence

MIT. See `LICENSE`.
