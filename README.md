# Paw Paw 🐾

Paw Paw is a simple iOS game made **for cats**. Critters wander across a dark wooden crate, and the cat taps them with a paw to catch them before time runs out.

Built with **Swift** and **UIKit** (no storyboards or SwiftUI), following the **VIPER** architecture.

## Preview

### iPhone

| Home | Gameplay | Video
|:---:|:---:|:---:|
| <img src="previews/iphone-home.png" alt="Paw Paw home screen on iPhone" width="280"> | <img src="previews/iphone-gameplay.png" alt="Paw Paw gameplay on iPhone" width="280"> | https://github.com/user-attachments/assets/42b09ec8-3e3a-4238-8e96-210aef7c2d1a |



### iPad

| Home | Gameplay | Video
|:---:|:---:|:---:|
| <img src="previews/ipad-home.png" alt="Paw Paw home screen on iPad" width="380"> | <img src="previews/ipad-gameplay.png" alt="Paw Paw gameplay on iPad" width="380"> | https://github.com/user-attachments/assets/deded609-790c-484b-b927-a53345a3e72b |

## How to play

1. Tap **PLAY** on the home screen.
2. You have **60 seconds**. Tap the critters as they move across the screen.
3. Each catch gives points, with a sparkle, ring and "+points" animation.
4. When time is up, you see your score and your best score. Choose **Play Again** or **Home**.

| Critter | Points | Notes |
|---|---|---|
| Mouse | 10 | Medium speed |
| Ladybug | 5 | Slowest, most common |
| Butterfly | 20 | Fastest and rare |

Game design choices that suit cats:

- At most **2 critters** on screen at once, so a cat can focus on one thing.
- Critters stay on screen for several seconds and fade in and out slowly to catch the cat's attention.
- Critters are large, drawn from above, and turn to face the direction they move.
- The background is dark so the animations stand out.

The best score is saved on the device using `UserDefaults`.

## Requirements

- Xcode 26 or later
- iOS 26.0 deployment target (set in the Xcode project)

## Running the project

1. Open `pawpaw.xcodeproj` in Xcode.
2. Select the `pawpaw` scheme and an iOS simulator or device.
3. Press Run (⌘R).

Or build from the command line:

```sh
xcodebuild -project pawpaw.xcodeproj -scheme pawpaw \
  -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

## Architecture (VIPER)

Each screen is a module made of five parts:

- **View**: draws the UI and reports user actions. It has no game logic.
- **Interactor**: holds the business logic and data.
- **Presenter**: connects the view and interactor, and turns data into display text.
- **Entity**: plain data models.
- **Router**: builds the module and handles navigation.

Each module's protocols are declared in a `*Protocols.swift` file. The `createModule()` function on each router wires the parts together. The presenter and interactor reference the view and each other through protocols, and the back references are `weak` to avoid retain cycles.

### Home module

| File | Role |
|---|---|
| `HomeViewController` | Title, best score and the PLAY button |
| `HomePresenter` | Asks for the best score and handles the PLAY tap |
| `HomeInteractor` | Reads the best score from storage |
| `HomeRouter` | Creates the module and pushes the Game screen |

### Game module

| File | Role |
|---|---|
| `GameViewController` (+ `+Layout`) | Score and timer labels, home button, results card |
| `GameAreaView` (+ `+Effects`, `+Rings`) | The play field: moves critters, detects taps, plays catch animations |
| `GamePresenter` | Formats score, time and result text, and forwards taps |
| `GameInteractor` | Game rules: 60 s clock, spawning (max 2 critters), scoring, saving the best score |
| `GameRouter` | Creates the module and returns to Home |

### Data flow example (catching a critter)

1. `GameAreaView` detects a tap on a critter and calls `onTapTarget`.
2. `GameViewController` passes it to `GamePresenter.didTapTarget`.
3. The presenter calls `GameInteractor.catchTarget`, which adds the points.
4. The interactor reports back to the presenter, which updates the score text and tells the view to play the catch animation.

## Project structure

```
pawpaw/
├── AppDelegate.swift, SceneDelegate.swift   App start (opens the Home module)
├── Entities/
│   ├── TargetKind.swift      Critter types: points, speed, spawn weight, image name
│   ├── GameTarget.swift      A critter on screen (kind, path, lifetime)
│   └── GameResult.swift      Final score summary
├── Common/
│   ├── ScoreStorage.swift    Best score protocol + UserDefaults implementation
│   ├── Theme.swift           Colours and fonts
│   └── WoodCrateBackgroundView.swift   Drawn wooden crate background
├── Modules/
│   ├── Home/                 Home screen (VIPER)
│   └── Game/                 Game screen (VIPER)
└── Assets.xcassets/          App assets, including the critter SVGs
```

## Art

The critter images (`critter_mouse`, `critter_bug`, `critter_butterfly`) are original top-down SVGs drawn for this project. To use your own art, replace the SVG file inside each `.imageset` folder and keep the same filename. The wooden crate background is drawn in code.

## Tweaking the game

| What | Where |
|---|---|
| Round length | `GameInteractor.roundDuration` |
| Max critters on screen | `GameInteractor.maxActiveTargets` |
| How often new critters spawn | `GameInteractor.spawnInterval` |
| Points, time on screen and spawn odds per critter | `TargetKind.swift` |
| Critter size | `GameAreaView.targetSize` |
| Sparkle amount | `count:` values in `GameAreaView+Effects.swift` |
| Colours | `Theme.swift` |

## Limitations

- There are no unit tests yet.
- The app has not been tested on a physical device.
- There is no sound.
