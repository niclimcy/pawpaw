# Game design

## Critters

| Critter | Points | Behavior |
|---|---|---|
| Ladybug | 5 | Slowest, most common |
| Feather | 5 | Slow drifting curves |
| Mouse | 10 | Darts and freezes |
| Ribbon | 10 | Snakes along, never stops |
| Cricket | 15 | Short hops |
| Fish | 15 | Rises near the surface; **Pond** only |
| Lizard | 15 | Dashes and freezes; **Grass** only |
| Butterfly | 20 | Fastest, rare |
| Bird | 20 | Hops, pecks, flies off |
| Laser dot | 25 | Silent red dot that streaks and stops |

## For cats

- Max 2 critters on screen; large, dark background, colours chosen for cat vision.
- Smooth motion (up to 120 Hz), prey-like movement, twitches during freezes.
- Panned prey sounds, synthesized in `SoundPlayer`, play from the side a critter enters.
- Multi-touch, generous hit areas, drag-to-catch; a missed tap scares the nearest critter.
- Hiding spots (box, leaf pile, lily pad, snow mound): critters under one can't be caught.
- `DifficultyTuner` adapts speed (0.75×–1.3×) within a round.
- After 3 catches in a row of one critter, it gets a new look (`CritterVariant`).

## Pocket Hunt (iPhone)

A phone screen is too small for the iPad field, so iPhone plays a tuned version (`PlayfieldTuning.pocket`):

| | iPad | iPhone |
|---|---|---|
| Critters on screen | 2 | 1 |
| Hiding spots | 2 × 170 pt | 1 × 130 pt |
| Hit slop (lure) | 28 pt (40) | 44 pt (56) |
| Missed-tap startle range | 220 pt | 140 pt |
| Pace | 1× | 0.85× |
| Orientation | Any | Game landscape, menus portrait |
| Default round | 60 s | 30 s |

Home and onboarding tell owners that Pocket Hunt plays best on a bigger screen. The game itself never shows this.

## Between rounds

When a timed round ends, the field stays in play. One critter (the lure) roams around the results card, which works like a big hiding spot: the critter disappears under it, peeks out from its edges, then runs into the open. The cat catches it to ask for another round, so a hunt never stops before the catch.

- The lure is one of the cat's enabled critters, never the laser dot (which can never truly be caught), and differs from the last one.
- It enters from the side away from the last touch, moves at about 0.7× normal pace with long freezes and twitches, and never leaves on its own. Under the card it can't be caught; hit areas are larger than in a round.
- Touches are ignored for 1 s after the round ends, so a late pounce doesn't count. After 45 s without a touch the lure wanders off and the screen may sleep.
- Lure catches score nothing and aren't counted in stats.
- **After a round** (Home, timed lengths only) sets what a catch does:
  - **Keep going**: every catch starts the next round after the countdown.
  - **3 rounds**: up to 3 rounds in a row start that way; then the lure is slower and never hides, and catching it shows "Great hunt! 😺" without starting a round.
  - **Stop**: only that final, easy catch.
- Owners hold **Play Again** on the card (a tap only shows a hint), which also resets the round count.

## For owners

- First launch shows an intro and cat setup.
- Exits, stats reset and cat deletion need a 1.5 s hold.
- Interruptions pause the round with critters frozen in place; the screen stays awake during play.
- Each cat has a name, face, scores, stats and its own critter list (at least one all-background critter stays on).
- Session length, background and the after-round choice are shared by all cats.
- Data is stored in `UserDefaults`.
