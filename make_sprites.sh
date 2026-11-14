#!/bin/sh
# Mac and Linux version of make_sprites.bat. Set ASEPRITE to the program's path if it is not found.
ROOT="$(cd "$(dirname "$0")" && pwd)"
ASE="${ASEPRITE:-}"
for c in aseprite "$HOME/Library/Application Support/Steam/steamapps/common/Aseprite/Aseprite.app/Contents/MacOS/aseprite" \
  "/Applications/Aseprite.app/Contents/MacOS/aseprite" "$HOME/.steam/steam/steamapps/common/Aseprite/aseprite"; do
  [ -z "$ASE" ] && command -v "$c" >/dev/null 2>&1 && ASE="$c"
done
[ -z "$ASE" ] && { echo "Could not find Aseprite. Set ASEPRITE=/path/to/aseprite and run again."; exit 1; }
rm -f "$ROOT/art_inbox/last_run.txt"
"$ASE" -b --script-param "root=$ROOT" --script "$ROOT/tools/sprite_pipeline.lua"
cat "$ROOT/art_inbox/last_run.txt" 2>/dev/null || echo "Aseprite ran but wrote no report."
