# Development

## Build

Requires Xcode 26+ (iOS 26.0). Open `pawpaw.xcodeproj` and run the `pawpaw` scheme, or:

```sh
xcodebuild -project pawpaw.xcodeproj -scheme pawpaw \
  -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

## Tuning

| What | Where |
|---|---|
| Session lengths | `SessionMode.duration` |
| Background colours | `PlayfieldTheme.baseColor` |
| Max critters, spawn rate | `GameInteractor.maxActiveTargets`, `spawnInterval` |
| Points, lifetime, spawn odds | `TargetKind.swift` |
| Critter size | `GameAreaView.targetSize` |
| Look-change streak | `GameInteractor.habituationStreak`, `CritterVariant.swift` |
| Colours, hold time | `Theme.swift`, `Theme.holdDuration` |

## Art

Critter and cat SVGs are original. To replace one, swap the SVG in its `.imageset` folder, keeping the filename. Backgrounds are drawn in code.

## Limitations

- No unit tests.
- Not tested on a physical device.
- Phone speakers can't play ultrasonic sounds.
