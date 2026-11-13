# Previews

App Store screenshots and preview videos, plus the script that seeds a simulator for them.

## Files

| File | Device | Size | Playground |
| --- | --- | --- | --- |
| `iphone-{home,stats,profiles}.png` | iPhone 17 (6.3") | 1206×2622 | Crate |
| `iphone-gameplay.png` | iPhone 17 (6.3", landscape) | 2622×1206 | Crate |
| `ipad-{home,gameplay,stats,profiles}.png` | iPad Pro 13-inch (M5) | 2064×2752 | Pond |
| `ipad-home-crate.png`, `ipad-stats-grass.png`, `ipad-profiles-snow.png` | iPad Pro 13-inch (M5) | 2064×2752 | as named |
| `iphone-duo-{home,stats,profile}.png` | iPhone Duo, folded | 1398×2034 | Snow |
| `iphone-duo-gameplay.png` | iPhone Duo, folded (landscape) | 2034×1398 | Snow |
| `iphone-duo-*-unfolded.png` | iPhone Duo, unfolded | 2853×2007 | Snow |
| `pawpaw-preview-{ipad,iphone}.mp4` | App Preview videos, rendered by `promo/render.mjs` | | |

The site's "Four playgrounds" section uses one iPad shot per playground:
home on Crate, gameplay on Pond, stats on Grass and profiles on Snow.
Those are `site/assets/screens/*.webp`, resized from these PNGs (see [Site images](#site-images)).

## Seed data

`seed-screenshots.sh` writes the app's preferences so every device shows the same data:

- Three cats: Mochi (orange, active), Biscuit (gray) and Pepper (calico).
- Mochi's stats: 14 rounds, 117 catches (ladybug is the favorite), and rounds on 5 of the last 7 days, ending today.
- Best scores: 85 (30s), 215 (60s), 430 (2 min).
- Round length 60s, after a round "Keep going", onboarding and the hold-to-exit tip already done.

```sh
previews/seed-screenshots.sh <udid> [wood|grass|pond|snow] [critters]
```

- `wood|grass|pond|snow` picks the playground (`wood` is Crate). Default: `wood`.
- `critters` is an optional comma-separated list (`mouse,bug,butterfly,cricket,feather,laser,fish,ribbon,bird,lizard`).
  Only those critters are enabled for Mochi, to stage a gameplay shot (e.g. `fish,bug,bird` on Pond).
  Leave it out for the home, stats and profiles shots.

The script quits the app and overwrites its preferences plist, so the app must be installed first.
Run it again before each launch where you change the playground or critters.

## Taking screenshots

Use Xcode 27.2 (`DEVELOPER_DIR=/Applications/Xcode-27.2.0.app/Contents/Developer`): it has the iOS 27.2 runtime and the iPhone Duo.

1. Build for the simulator and install on each device:

   ```sh
   export DEVELOPER_DIR=/Applications/Xcode-27.2.0.app/Contents/Developer
   xcodebuild -project pawpaw.xcodeproj -scheme pawpaw -configuration Release \
     -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
     -derivedDataPath /tmp/pawpaw-shots build
   xcrun simctl install <udid> /tmp/pawpaw-shots/Build/Products/Release-iphonesimulator/pawpaw.app
   ```

2. Set a US locale and Apple's status bar: 9:41 on Tuesday 9 January (the iPhone keynote), full battery, not charging.
   The locale needs a reboot; status bar overrides are lost on reboot, so set them after:

   ```sh
   xcrun simctl spawn <udid> defaults write -g AppleLocale en_US
   xcrun simctl shutdown <udid> && xcrun simctl boot <udid>
   xcrun simctl status_bar <udid> override --batteryState discharging --batteryLevel 100 \
     --cellularBars 4 --wifiBars 3 --dataNetwork wifi
   xcrun simctl status_bar <udid> override --time "2024-01-10T09:41:00.000+08:00"
   xcrun simctl status_bar <udid> override --time "2024-01-09T09:41:00.000+08:00"
   ```

   Only iPad shows the date; every device shows the battery. Quirks:
   - `--batteryState charged` draws a green battery with a charging bolt. Use `discharging` at 100%.
   - `--time` needs a full ISO date with milliseconds; `9:41` alone shows today's date on iPad.
     The offset must match the Mac's time zone (`+08:00` here), or the clock shifts.
   - The weekday is wrong unless `--time` is sent on its own, and it only redraws when the day changes.
     Hence the separate commands, stepping through 10 Jan first.
     2024 is used because 9 Jan 2024 was a Tuesday, like 9 Jan 2007; the year isn't shown.

3. Seed, launch and capture:

   ```sh
   previews/seed-screenshots.sh <udid> pond
   xcrun simctl launch <udid> org.swiftinsg.np2026.pawpaw
   xcrun simctl io <udid> screenshot previews/ipad-home.png
   ```

4. Navigate with [serve-sim](https://www.npmjs.com/package/serve-sim). Taps use 0–1 coordinates of the screen as shown:

   ```sh
   npx serve-sim --detach --no-preview <udid>   # once per device
   npx serve-sim tap -d <udid> 0.962 0.049      # iPad: stats button
   npx serve-sim -k                             # stop all helpers when done
   ```

   | Screen | iPad | iPhone 17 | Duo folded | Duo unfolded |
   | --- | --- | --- | --- | --- |
   | Stats | 0.962, 0.049 | 0.900, 0.111 | 0.898, 0.381 | 0.95, 0.311 |
   | Profiles | 0.08, 0.049 | 0.21, 0.111 | 0.898, 0.291 | 0.95, 0.221 |
   | Play | 0.5, 0.714 | 0.5, 0.764 | 0.41, 0.764 | 0.247, 0.6 |

5. For gameplay, start a round and take a burst, then keep the best frame:

   ```sh
   for i in $(seq -w 1 24); do xcrun simctl io <udid> screenshot /tmp/game-$i.png; sleep 0.4; done
   ```

   Critters spawn every few seconds and the round ends after 60s, so start the burst ~5s after tapping Play.

### iPhone Duo

- Screenshot a display with `--display=1` (folded, 1398×2034) or `--display=3` (unfolded, 2007×2853).
  Landscape shots come out rotated; fix with `magick in.png -rotate -90 out.png`.
- Fold with `npx serve-sim fold -d <udid> 0` (closed) or `180` (open), then relaunch the app so it moves to that display.
- Open the device in Xcode 27.2's Device Hub, not the old Simulator app
  (`open -a /Applications/Xcode-27.2.0.app/Contents/Applications/DeviceHub.app`).
  While Xcode 26's `Simulator.app` is running at all, taps crash `backboardd` and folding fails with
  "guest HID support is required". Export `DEVELOPER_DIR` in every shell: `simctl` from Xcode 26 relaunches it.
  Quitting it shuts down every booted simulator.
- If taps stop working, run `npx serve-sim repair-input -d <udid>`, restart the serve-sim helper, reapply the status bar override, and relaunch.

## Site images

```sh
W=site/assets/screens
magick previews/ipad-home-crate.png    -resize 1100x1467 -quality 82 $W/ipad-home.webp
magick previews/ipad-gameplay.png      -resize 1100x1467 -quality 82 $W/ipad-gameplay.webp
magick previews/ipad-stats-grass.png   -resize 1100x1467 -quality 82 $W/ipad-stats.webp
magick previews/ipad-profiles-snow.png -resize 1100x1467 -quality 82 $W/ipad-profiles.webp
for n in home stats profiles; do magick previews/iphone-$n.png -resize 600x1304 -quality 82 $W/iphone-$n.webp; done
magick previews/iphone-gameplay.png -resize 1304x600 -quality 82 $W/iphone-gameplay.webp
```

Retake all screenshots whenever the cat or critter art changes.
