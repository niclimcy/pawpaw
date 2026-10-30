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

1. Pick a round length and a playground (background) on the home screen, then tap **PLAY**. A 3-2-1 countdown starts the round.
2. Tap the critters as they move across the screen. A round lasts **30 seconds**, **60 seconds** (the default) or **2 minutes**. **Relaxed** mode has no timer and never ends.
3. Each catch gives points, with a sparkle, ring and "+points" animation.
4. When time is up, you see your score and your best score for that session length. Choose **Play Again**, or press and hold **Hold to go Home**.

| Critter | Points | Notes |
|---|---|---|
| Mouse | 10 | Medium speed |
| Ladybug | 5 | Slowest, most common |
| Butterfly | 20 | Fastest and rare |
| Cricket | 15 | Short sudden hops with brief stops |
| Feather | 5 | Slow, gentle drifting curves |
| Laser dot | 25 | Silent glowing red dot that streaks across the field and stops dead |
| Fish | 15 | A koi seen through the water. It rises from the depths with a ripple, glides in gentle curves with a swishing tail, then sinks away. It can only be caught while near the surface. Only appears on the **Pond** background |

Game design choices that suit cats:

- At most **2 critters** on screen at once, so a cat can focus on one thing.
- Critters stay on screen for several seconds. Land critters and fliers never fade: they run in from beyond the screen edge and run off it again. Only the fish fades, as it rises from and sinks back into the pond. The views are reused for the next critter.
- Critters are large, drawn from above, and turn to face the direction they move.
- The background is dark so the animations stand out.
- Critters animate at up to 120 Hz on ProMotion screens. Cats follow motion closely and can notice flicker that people miss, so smoother movement looks more like real prey.
- Critters move like real prey: mice dart and freeze, bugs wander, butterflies flutter in arcs.
- Critters emerge from the screen edge, and some run off the nearest edge during a freeze, wait out of sight, then run back. Critters that are off-screen can't be caught.
- Short prey sounds (squeak, rustle, flutter, chirp, swish, catch) are synthesized in code by `SoundPlayer`. The laser dot is silent, like a real laser pointer.
- Every paw counts: several touches at once are handled, and the hit area around each critter is generous.
- Dragging a paw across a critter catches it, and leaves a trail of small ripples.
- A missed tap makes the nearest critter jump away with a squeak, so the cat always gets a reaction.
- Each round places two hiding spots that suit the background: a cardboard box on the crate, a leaf pile on grass, a lily pad on the pond and a snow mound on snow. On land, mice, bugs and crickets sometimes run under one during a freeze. On the pond only fish glide under the lily pads, and the land critters keep moving past them. The laser dot, butterflies and feathers never hide, so they always pass over the hiding spots. A hiding critter peeks out twice before moving on. A critter tucked under a spot can't be caught, but one that is peeking out can.
- The pace adapts to the cat (`DifficultyTuner`): each catch makes critters a little quicker, and escapes or missed taps slow them down, within 0.75× to 1.3× of normal speed. Every round starts at normal speed.
- Session lengths suit different cats: short rounds for kittens and seniors, and relaxed play with no timer for cats that like to take their time.
- Backgrounds: wooden crate, grass, pond and snow. All are dark so the critters stand out. Some critters only live on one background (`TargetKind.exclusiveTheme`), such as the fish in the pond.

For owners:

- The first launch on a new install shows a short intro: the game is for your cat, set up a round and then step back, and hold 🏠 to leave. The last step names your cat and picks its face. Every critter starts on, and you can change that later in Your Cats. You can skip the intro, and you can skip the cat setup too (the cat stays "My Cat"). Devices that already have cats, scores or stats go straight to Home.
- Leaving the game needs a 1.5 second press-and-hold on the Home buttons, so paws can't exit by accident. A ring fills around the button while it's held, so you can see the hold working.
- Every round starts with a short 3-2-1 countdown, which gives you time to set the device down. Until you've left a round once with the hold, the countdown also shows an "Owners: press and hold 🏠 to leave" tip pointing at the house button. A quick tap on an exit button shows a short reminder.
- The Home screen is for owners, so everything on it is a normal tap: the cat chip and the Stats button in the top bar, the round length and playground picker, and PLAY.
- The **Play Stats** screen shows total rounds and catches, catches per critter, a favorite critter, rounds over the last 7 days and the best score for each session length. Changes in play can hint at a change in mood or energy.
- Resetting Play Stats needs a 1.5 second press-and-hold and also asks for confirmation. Resetting keeps the best scores.
- Leaving a round early (always the case in relaxed mode) still counts the critters caught in the stats.
- A phone call, Control Center or switching apps pauses the round: the clock stops, the critters on screen slip away and the catches so far are saved, in case the app is closed. Play picks up where it left off when you come back, and the round still counts once in the stats.
- Rotating the device or resizing the app mid-round moves the hiding spots to match. Critters already running slip away (they don't count as escapes) and new ones come in.
- The edge swipe back is turned off during a round, so a sweeping paw can't leave the game.
- Text follows the Dynamic Type size setting. VoiceOver reads the Stats chart and critter counts, and stays on the result card or the add/edit card while it is open.
- The screen stays on during a round, so it won't dim or lock while the cat plays. When the result card appears, the device can sleep normally again.

Cat profiles for multi-cat households:

- Each cat has a name and a drawn headshot (orange tabby, gray tabby, black, white, calico or Siamese), and its own best scores and play stats. The first launch after the update creates a "My Cat" profile that keeps your existing scores and stats.
- The Home screen shows the active cat. Tap it to switch cats, or to add or edit one. Adding and editing use a themed card on the wood panel with a name field and a face picker, not a system alert. Deleting a cat needs a 1.5 second hold, erases its scores and stats, and the last cat can't be deleted.
- The cat chip on Home shows "Loves butterflies" under the name once that cat has caught something, and the Stats screen is titled with the cat's name.
- The session length and background are device settings shared by all cats.
- Each cat can have its own critters. The add/edit card has a **Critters to play with** grid: tap a critter to turn it off for that cat (for example, Luna only likes mice and feathers). At least one critter that lives on every background (anything but the fish) always stays on, so every background has something to play with, and critters you turned off never come back. A short note explains this if you try to turn off the last one.

Settings, best scores and stats are saved on the device using `UserDefaults`. Each session length has its own best score for each cat. Relaxed mode has none.

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
| `HomeViewController` | Top bar (cat chip, Stats button), title, setup card (round length and playground), PLAY and best score |
| `ThemePickerView` | The playground picker: a row of background thumbnails |
| `HomePresenter` | Passes the picks to the interactor, and handles the PLAY, cat and Stats taps |
| `HomeInteractor` | Reads and saves the picked session length and background, and reads the active cat, its best score and its favorite critter |
| `HomeRouter` | Creates the module and pushes the Game, Stats or Profiles screen |

### Game module

| File | Role |
|---|---|
| `GameViewController` (+ `+Layout`, `+Countdown`, `+ExitTip`) | Score and timer labels, home button, 3-2-1 countdown, owner exit tip, results card |
| `GameAreaView` (+ `+Effects`, `+Rings`) | The play field: moves critters, detects taps, plays catch animations |
| `GamePresenter` | Formats score, time and result text, and forwards taps |
| `GameInteractor` | Game rules: the session clock (if any), spawning (max 2 critters), scoring, saving the best score and recording stats |
| `DifficultyTuner` | Speeds critters up or slows them down based on catches, escapes and misses |
| `MovementPlanner` | Builds each critter's stop-and-go path, places the hiding spots and sends critters under them |
| `HidingSpotView` | Draws the box, leaf pile, lily pad or snow mound that critters hide under |
| `GameRouter` | Creates the module for a session length and returns to Home |

### Stats module

| File | Role |
|---|---|
| `StatsViewController` (+ `+Builders`) | Totals, catches per critter, 7 day chart, best scores and the hold-to-reset button |
| `StatsPresenter` | Turns the stats into display text |
| `StatsInteractor` | Reads the stats and best scores, and resets the stats |
| `StatsRouter` | Creates the module and returns to Home |

### Profiles module

| File | Role |
|---|---|
| `ProfilesViewController` (+ `+Builders`) | List of cats with their headshots and the active one checked |
| `ProfileEditorView` (+ `+Layout`, `+Builders`) | The themed add/edit card: name field, face picker (`CatNameField`, `CatFacePicker`), critter on/off grid, Save, Cancel and hold-to-delete |
| `ProfilesPresenter` | Turns the cats into display rows ("Loves butterflies") |
| `ProfilesInteractor` | Selects, adds, renames and deletes cats, and reads each cat's favorite critter |
| `ProfilesRouter` | Creates the module and returns to Home |

### Onboarding module

| File | Role |
|---|---|
| `OnboardingViewController` | One card with page dots, Next, Skip, and a Back button in the corner. The intro pages come first, then the cat setup (name field and face picker) |
| `OnboardingPresenter` | The intro text and the current step. It checks that a name was entered. Skip goes to the cat setup, not past it |
| `OnboardingInteractor` | Renames the first cat, sets its face, and marks onboarding as done |
| `OnboardingRouter` | Creates the module. `SceneDelegate` shows it instead of Home on a new install, then swaps to Home when it finishes |

### Data flow example (catching a critter)

1. `GameAreaView` detects a tap on a critter and calls `onTapTarget`.
2. `GameViewController` passes it to `GamePresenter.didTapTarget`.
3. The presenter calls `GameInteractor.catchTarget`, which adds the points.
4. The interactor reports back to the presenter, which updates the score text and tells the view to play the catch animation.

## Project structure

```
pawpaw/
├── AppDelegate.swift, SceneDelegate.swift   App start (opens Onboarding on a new install, otherwise Home)
├── Entities/
│   ├── TargetKind.swift      Critter types: points, speed, spawn weight, image name
│   ├── GameTarget.swift      A critter on screen (kind, path, lifetime)
│   ├── MovementPath.swift    Path legs and each critter's movement style
│   ├── GameResult.swift      Final score summary
│   ├── SessionMode.swift     Session lengths (30 s, 60 s, 2 min, relaxed)
│   ├── PlayfieldTheme.swift  Background choices
│   ├── PlayStats.swift       Lifetime play history
│   ├── CatProfile.swift      A cat's name and headshot
│   └── CatFace.swift         The drawn cat headshots, one per coat colour
├── Common/
│   ├── ProfileStorage.swift  Cats and the active cat, with first-launch migration (protocol + UserDefaults)
│   ├── SettingsStorage.swift Session length, background and onboarding/tip flags, shared by all cats (protocol + UserDefaults)
│   ├── ScoreStorage.swift    Best scores per cat and session length (protocol + UserDefaults)
│   ├── StatsStorage.swift    Play stats per cat (protocol + UserDefaults)
│   ├── Log.swift             Unified logging for storage failures the app recovers from
│   ├── CatFace+Image.swift   Draws a headshot at a given size
│   ├── Theme.swift           Colours, fonts, card and button styles, the hold-to-confirm duration
│   ├── CatNameField.swift    Themed name field that limits name length (shared by the add/edit card and onboarding)
│   ├── CatFacePicker.swift   Grid of cat headshots to pick from
│   ├── HoldToConfirm.swift   Press-and-hold buttons with a filling progress ring
│   ├── ScrollingLayout.swift Centered, scrolling column used by every menu screen
│   ├── SoundPlayer.swift     Synthesized prey sounds
│   ├── SeededGenerator.swift Repeatable random numbers for the drawn backgrounds
│   ├── CachedBackgroundView.swift      Renders a background once per size and reuses the image
│   ├── WoodCrateBackgroundView.swift   Drawn wooden crate background
│   └── NatureBackgroundView.swift      Drawn grass, pond and snow backgrounds
├── Modules/
│   ├── Home/                 Home screen (VIPER)
│   ├── Game/                 Game screen (VIPER)
│   ├── Stats/                Play stats screen (VIPER)
│   ├── Profiles/             Cat profiles screen (VIPER)
│   └── Onboarding/           First-run intro and cat setup (VIPER)
└── Assets.xcassets/          App assets, including the critter SVGs
```

## Art

The critter images (`critter_mouse`, `critter_bug`, `critter_butterfly`, `critter_cricket`, `critter_feather`, `critter_laser`, `critter_fish`) and the cat headshots (`cat_orange`, `cat_gray`, `cat_black`, `cat_white`, `cat_calico`, `cat_siamese`) are original SVGs drawn for this project, as is the Home screen logo (`logo_paw`), which matches the paw on the app icon. To use your own art, replace the SVG file inside each `.imageset` folder and keep the same filename. The backgrounds are drawn in code.

## Tweaking the game

| What | Where |
|---|---|
| Session lengths | `SessionMode.duration` |
| Background colours | `PlayfieldTheme.baseColor` |
| Max critters on screen | `GameInteractor.maxActiveTargets` |
| How often new critters spawn | `GameInteractor.spawnInterval` |
| Points, time on screen and spawn odds per critter | `TargetKind.swift` |
| Critter size | `GameAreaView.targetSize` |
| Sparkle amount | `count:` values in `GameAreaView+Effects.swift` |
| Colours | `Theme.swift` |
| Press-and-hold time for exits, resetting stats and deleting | `Theme.holdDuration` |

## Limitations

- There are no unit tests yet.
- The app has not been tested on a physical device.
- Sounds are simple synthesized tones. Phone speakers can't play the ultrasonic range that cats hear.
