# Architecture

Each screen is a VIPER module (View, Interactor, Presenter, Entity, Router). Protocols live in `*Protocols.swift`; `Router.createModule()` wires the parts, with `weak` back references.

## Modules (`pawpaw/Modules/`)

- **Home**: round length and playground pickers, PLAY; routes to Game, Stats, Profiles.
- **Game**: `GameAreaView` (field, taps, effects), `GameInteractor` (rules, spawning, scoring), `MovementPlanner` (paths, hiding spots), `DifficultyTuner`.
- **Stats**: totals, per-critter catches, 7-day chart, best scores.
- **Profiles**: cat list and add/edit card (`ProfileEditorView`).
- **Onboarding**: intro and cat setup, shown by `SceneDelegate` on a new install.

## Other folders

- `Entities/`: data models (`TargetKind`, `GameTarget`, `SessionMode`, `PlayfieldTheme`, `CatProfile`, ...).
- `Common/`: storage (`ProfileStorage`, `SettingsStorage`, `ScoreStorage`, `StatsStorage`), `Theme`, `SoundPlayer`, shared views, drawn backgrounds.
- `Assets.xcassets/`: critter and cat SVGs.
