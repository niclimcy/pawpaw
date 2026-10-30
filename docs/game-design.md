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

## For owners

- First launch shows an intro and cat setup.
- Exits, stats reset and cat deletion need a 1.5 s hold.
- Interruptions pause the round; the screen stays awake during play.
- Each cat has a name, face, scores, stats and its own critter list (at least one all-background critter stays on).
- Session length and background are shared by all cats.
- Data is stored in `UserDefaults`.
