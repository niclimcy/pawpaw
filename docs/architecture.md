# Architecture

Each screen is a VIPER module (View, Interactor, Presenter, Entity, Router). Protocols live in `*Protocols.swift`; `Router.createModule()` wires the parts, with `weak` back references.

## Modules (`pawpaw/Modules/`)

- **Home**: round length and playground pickers, PLAY; routes to Game, Stats, Profiles.
- **Game**: `GameInteractor` (rules, spawning, scoring), `MovementPlanner` (paths, hiding spots), `DifficultyTuner`.
  - `Playfield/`: SpriteKit. `GameViewController` shows a transparent `GameScene`, which owns critters (`CritterNode`), hiding spots, taps and effects. `CritterActions` turns a target's normalized legs into `SKAction`s for the critter's nested nodes (path, heading, twitches, body), which SpriteKit adds together. `PlayfieldGeometry` maps the normalized field to scene points. The scene fills the screen, under the HUD too, so critters run off the real screen edge; its `topInset` keeps spawns, stops and hiding spots below the HUD. Everything that moves sits under the scene's `world` node, so pausing the round freezes critters in place.
  - Lure: between timed rounds `GameInteractor` plans loops for one unscored critter (`MovementPlanner.lureLegs`) using the results card as cover (`LureCover`, from `PlayfieldGeometry.lureCover`). `GameScene` keeps it apart from the round's critters, and `GameViewController+Lure` handles the start delay and idle timeout. The results overlay is a `PassthroughView`, so only the card takes touches.
- **Stats**: totals, per-critter catches, 7-day chart, best scores.
- **Profiles**: cat list and add/edit card (`ProfileEditorView`).
- **Onboarding**: hands-on intro and cat setup, shown by `SceneDelegate` on a new install. The presenter owns all copy, step flow (what Next, Skip and swipes do on each step) and practice state, including which critter comes next; the interactor builds the practice critters. The practice views (`OnboardingPlayfieldView`, `OnboardingCountdownView`, `OnboardingHoldPracticeView`, `OnboardingAmbientView`) report back through the view controller.

## Other folders

- `Entities/`: data models (`TargetKind`, `GameTarget`, `SessionMode`, `PlayfieldTheme`, `PlayfieldTuning`, `CatProfile`, ...).
- `Common/`: storage (`ProfileStorage`, `SettingsStorage`, `ScoreStorage`, `StatsStorage`), `Theme`, `SoundPlayer`, shared views, drawn backgrounds.

## Device tuning

`PlayfieldTuning.current` (`.pocket` on iPhone, `.standard` on iPad) is read by `GameRouter` and passed to `GameInteractor` (counts, pace), `GameViewController` (landscape lock) and `GameScene`/`PlayfieldGeometry`/`PlayfieldTextures` (sizes, hit areas). `HomeRouter` uses `OrientationNavigationController` so the game's orientation lock reaches the window. On iPhone every other screen is portrait-only (`UIInterfaceOrientationMask.menus`), so leaving the game always rotates back, on iOS 15 too.
- `Assets.xcassets/`: critter and cat SVGs.
