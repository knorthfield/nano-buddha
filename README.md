# Nano Buddha

An iPhone meditation timer that quietly lengthens your sits.

You choose a nominal duration, say 10 minutes. The app never times exactly that. It adds a
random offset of up to one minute either way, and a hidden base that grows by 15 seconds
after every completed sit. The sit screen shows no time at all, so there is nothing to
watch. A singing bowl rings when the time is up, and the sit carries on until you end it.
Each sit is saved locally and written to Apple Health as Mindful Minutes.

SwiftUI, iOS 26+, no third-party packages.

## Requirements

- Xcode 26 with the matching iOS simulator runtime
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

The Xcode project is generated from `project.yml` and is not committed. The scripts point at
`/Applications/Xcode.app` themselves, so `xcode-select` does not need changing.

## Build and run

```bash
scripts/build.sh   # generate the project and build for the simulator
scripts/run.sh     # build, then install and launch on the simulator
scripts/test.sh    # unit tests and a UI test of a full sit
```

Set `SIM_NAME` to use a different simulator, for example `SIM_NAME="iPhone 17 Pro" scripts/run.sh`.

## Run on a real iPhone

1. The scripts create `Local.xcconfig` in the repo root. Uncomment `DEVELOPMENT_TEAM` there
   and set it to your team ID (Apple Developer > Membership).
2. Pair the phone with your Mac once.
3. `scripts/device.sh` lists paired devices; `scripts/device.sh "<device name>"` builds,
   installs, and launches.

## Layout

- `NanoBuddha/Model` — `DurationPlanner` (hidden duration), `Store` (JSON persistence),
  `HealthWriter`, `Bell` (bowl sound, haptic, and the local notification used when locked)
- `NanoBuddha/Views` — Home, Sit, Done, History
- `NanoBuddhaTests`, `NanoBuddhaUITests`

## Credits

Singing bowl: "Tibetan Bowl Struck #1" from [BigSoundBank](https://bigsoundbank.com/detail-1110-tibetan-bowl-struck.html), CC0.

## Licence

MIT. See `LICENSE`.
