# Architecture

Each screen is a VIPER module (View, Interactor, Presenter, Entity, Router). Protocols live in `*Protocols.swift`; `Router.createModule()` wires the parts, with `weak` back references.

## Modules (`pawpaw/Modules/`)

- **Home**: round length and playground pickers, PLAY; routes to Game, Stats, Profiles.
- **Game**: `GameInteractor` (rules, spawning, scoring), `MovementPlanner` (paths, hiding spots), `DifficultyTuner`.
  - `Playfield/`: SpriteKit. `GameViewController` shows a transparent `GameScene`, which owns critters (`CritterNode`), hiding spots, taps and effects. `CritterActions` turns a target's normalized legs into `SKAction`s for the critter's nested nodes (path, heading, twitches, body), which SpriteKit adds together. `PlayfieldGeometry` maps the normalized field to scene points. The scene fills the screen, under the HUD too, so critters run off the real screen edge; its `topInset` keeps spawns, stops and hiding spots below the HUD. Everything that moves sits under the scene's `world` node, so pausing the round freezes critters in place.
- **Stats**: totals, per-critter catches, 7-day chart, best scores.
- **Profiles**: cat list and add/edit card (`ProfileEditorView`).
- **Onboarding**: intro and cat setup, shown by `SceneDelegate` on a new install.

## Other folders

- `Entities/`: data models (`TargetKind`, `GameTarget`, `SessionMode`, `PlayfieldTheme`, `CatProfile`, ...).
- `Common/`: storage (`ProfileStorage`, `SettingsStorage`, `ScoreStorage`, `StatsStorage`), `Theme`, `SoundPlayer`, shared views, drawn backgrounds.
- `Assets.xcassets/`: critter and cat SVGs.
