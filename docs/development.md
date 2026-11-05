# Development

## Build

Requires Xcode 26+ (iOS 26.0). Open `pawpaw.xcodeproj` and run the `pawpaw` scheme, or:

```sh
xcodebuild -project pawpaw.xcodeproj -scheme pawpaw \
  -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

## Test

Unit tests live in `pawpawTests/` (XCTest, hosted in the app). Run them with ⌘U, or:

```sh
xcodebuild test -project pawpaw.xcodeproj -scheme pawpaw \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Run on an iPad simulator too, since `PlayfieldTuning.current` depends on the device. The shared scheme collects code coverage.

- Mocks and spies are in `pawpawTests/Support/`; storage tests use a throwaway `UserDefaults` suite, never `.standard`.
- Tests are `@MainActor`, matching the app's default actor isolation.
- To record a known bug before fixing it, wrap its test in `XCTExpectFailure("Bug: …")`. Once the bug is fixed the test fails until the `XCTExpectFailure` is removed.
- App classes the tests create declare `nonisolated deinit {}`, marked `TODO: To remove after swift bug is resolved.` Without it, on an iOS 15 deployment target, freeing one inside a test can crash in the Swift runtime ("pointer being freed was not allocated"). Once the bug is fixed, delete them all (search for the TODO) and run the tests on both simulators.

## Tuning

| What | Where |
|---|---|
| Session lengths | `SessionMode.duration` |
| Background colours | `PlayfieldTheme.baseColor` |
| Max critters, hiding spots, sizes, hit areas, pace (iPad / iPhone) | `PlayfieldTuning.standard`, `.pocket` |
| Spawn rate | `GameInteractor.spawnInterval` |
| Points, lifetime, spawn odds | `TargetKind.swift` |
| Look-change streak | `GameInteractor.habituationStreak`, `CritterVariant.swift` |
| Colours, hold time | `Theme.swift`, `Theme.holdDuration` |

## Art

Critter and cat SVGs are original. To replace one, swap the SVG in its `.imageset` folder, keeping the filename. Backgrounds are drawn in code.

## Limitations

- No UI tests; views, SpriteKit scenes and routers aren't unit tested.
- Not tested on a physical device.
- Phone speakers can't play ultrasonic sounds.
