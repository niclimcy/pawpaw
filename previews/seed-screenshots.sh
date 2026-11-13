#!/bin/zsh
# Seeds a simulator with the App Store screenshot data: three cats (Mochi active),
# Mochi's stats and best scores, onboarding done, and the given playground.
#   previews/seed-screenshots.sh <udid> [wood|grass|pond|snow] [fish,bug,...]
# The optional critter list limits what Mochi plays with, to stage a gameplay shot.
# The app must already be installed. simctl `defaults write` can't reach the app
# domain, so this writes the plist in the data container directly.
set -euo pipefail

udid=$1
theme=${2:-wood}
only=${3:-}
bundle=org.swiftinsg.np2026.pawpaw

xcrun simctl terminate "$udid" "$bundle" 2>/dev/null || true
container=$(xcrun simctl get_app_container "$udid" "$bundle" data)
plist="$container/Library/Preferences/$bundle.plist"
mkdir -p "${plist:h}"

python3 - "$plist" "$theme" "$only" <<'EOF'
import json, plistlib, sys
from datetime import date, timedelta

path, theme, only = sys.argv[1], sys.argv[2], sys.argv[3]
kinds = ["mouse", "bug", "butterfly", "cricket", "feather",
         "laser", "fish", "ribbon", "bird", "lizard"]
disabled = [k for k in kinds if only and k not in only.split(",")]
mochi = "8C1F4A62-3E0B-4D8A-9F51-6A2B7C9D0E11"
cats = [
    {"id": mochi, "name": "Mochi", "face": "orange", "disabledKinds": disabled},
    {"id": "2D7E9B14-5A6C-4F3E-8B21-9C0D1E2F3A44", "name": "Biscuit", "face": "gray", "disabledKinds": []},
    {"id": "F3A8C5D7-1B2E-4C9F-A6D0-7E8F9A0B1C55", "name": "Pepper", "face": "calico", "disabledKinds": []},
]
catches = {"mouse": 18, "bug": 31, "butterfly": 12, "cricket": 9, "feather": 14,
           "laser": 6, "fish": 4, "ribbon": 11, "bird": 7, "lizard": 5}
today = date.today()
# Oldest first, ending today; plus older rounds so the total reads 14.
week = [2, 0, 3, 1, 2, 0, 1]
rounds = {(today - timedelta(days=6 - i)).isoformat(): n for i, n in enumerate(week) if n}
rounds[(today - timedelta(days=12)).isoformat()] = 14 - sum(week)
stats = {"totalRounds": 14, "totalCatches": sum(catches.values()),
         "catchesByKind": catches, "roundsByDay": rounds}

data = lambda v: json.dumps(v, separators=(",", ":")).encode()
prefs = {
    "pawpaw.profiles": data(cats),
    "pawpaw.activeProfile": mochi,
    "pawpaw.selectedMode": "standard",
    "pawpaw.selectedTheme": theme,
    "pawpaw.afterRound": "keepPlaying",
    "pawpaw.hasCompletedOnboarding": True,
    "pawpaw.hasLearnedHoldToExit": True,
    f"pawpaw.{mochi}.stats": data(stats),
    f"pawpaw.{mochi}.highScore.short": 85,
    f"pawpaw.{mochi}.highScore.standard": 215,
    f"pawpaw.{mochi}.highScore.long": 430,
}
with open(path, "wb") as f:
    plistlib.dump(prefs, f, fmt=plistlib.FMT_BINARY)
EOF

# cfprefsd caches the old plist; restart it so the app reads the seeded file.
xcrun simctl spawn "$udid" launchctl stop com.apple.cfprefsd.xpc.daemon 2>/dev/null || true
echo "Seeded $udid ($theme)"
