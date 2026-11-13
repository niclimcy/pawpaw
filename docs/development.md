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
| Practice field (onboarding) sizes, hit areas, pace | `PlayfieldTuning.onboarding` |
| How much of a hiding spot hides a critter | `PlayfieldTuning.coverRadiusFraction` |
| Spawn rate | `GameInteractor.spawnInterval` |
| Points, lifetime, spawn odds | `TargetKind.swift` |
| Look-change streak | `GameInteractor.habituationStreak`, `CritterVariant.swift` |
| Pace range, speed-up and slow-down steps | `DifficultyTuner.paceRange`, `.catchStep`, `.escapeStep`, `.missStep` |
| Per-critter path: legs, pause share, step length, turn angle, hide and cover chance, twitch size | `MovementStyle` in `MovementPath.swift` (`legCount`, `pauseFraction`, `distanceRange`, `turnRange`, `hideChance`, `coverChance`, `twitchAngle`, `twitchShift`) |
| Hide trips, flight, cover pauses, lead-in, early take-off | `MovementPlanner.hideTravel`, `.minimumHidePause`, `.exitTravel`, `.flightTravel`, `.earlyFlightChance`, `.minimumCoverPause`, `.leadInRange` |
| Entry from the edge: run-in time and distance, glide-in time, landing spot | `MovementPlanner.minimumEntryTravel`, `.entryDistance`, `.entrySpread`, `.flightEntryTravel`, `.flightLandingDistance` |
| Step pace against ground speed, wingbeats | `CritterActions.strideSlowdown`, `.wingbeat` |
| Ribbon ripple: width and speed at rest and running, tail swing on turns | `RibbonWave` |
| Hiding spot and surfacing-critter placement | `MovementPlanner.hidingSpotXRange`, `.hidingSpotYRange`, `.hidingSpotSpacing`, `.innerRange` |
| Lure legs, freezes, cover chance, exit speed | `MovementPlanner.lureLegCount`, `.lurePauseFraction`, `.finalLurePauseFraction`, `.lureCoverChance`, `.lureExitTravel`, `.lureFadeOutTravel` |
| Lure speed (seconds per leg) | `GameInteractor.lureLegDuration`, `.finalLureLegDuration` |
| Lure start delay, idle timeout | `GameViewController.lureReadyDelay`, `.lureIdleTimeout` |
| Rounds a catch can start in a row | `AfterRoundMode.roundLimit` |
| Field padding, off-screen margin, head-nod reach, lure peek and cover depth | `PlayfieldGeometry.edgePadding`, `.offscreenMarginFraction`, `.nodReach`, `.lureCoverDepthFraction`, `.lurePeekReachFraction` |
| Startle hop, trail ripple spacing | `CritterNode.startleDistance`, `.startleRecoil`, `GameScene.trailSpacing` |
| Colours, hold time | `Theme.swift`, `Theme.holdDuration` |

## Art

Critter and cat SVGs are original. To replace one, swap the SVG in its `.imageset` folder, keeping the filename. Backgrounds are drawn in code.

Critters are drawn from above, facing up. The animals have extra poses, named in `TargetKind`:

| Asset | Pose | Critters |
|---|---|---|
| `critter_<name>_move` | Mid-stride, mid-stroke or mid-hop | Mouse, ladybug, lizard, fish, cricket |
| `critter_<name>_move2` | The opposite step | Mouse, ladybug, lizard, fish |
| `critter_<name>_fly` | Wings spread, for flying off the field | Ladybug, bird |
| `critter_ribbon_strip` | Straight, for the game to ripple; menus keep the curled `critter_ribbon` | Ribbon |

Draw the opposite step rather than flipping the whole picture, so markings and shading stay on the same side. `CritterActions.poseCycle` sets which poses play and how fast.

## Limitations

- No UI tests; views, SpriteKit scenes and routers aren't unit tested.
- Not tested on a physical device.
- Phone speakers can't play ultrasonic sounds.
