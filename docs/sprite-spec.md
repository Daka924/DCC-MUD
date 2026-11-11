# Sprite spec

The client currently draws placeholder shapes. Real art should follow these
sizes so it can replace the shapes without layout changes. The pipeline is:
source image, then Aseprite (CLI batch export), then a sprite sheet plus JSON
in `art/`.

## View and tiles

- Isometric, 2:1 diamond tiles: **64 x 32 px** per floor tile.
- Wall blocks sit on one tile and rise **26 px** (may grow once real art exists).
- No texture filtering (nearest neighbour). Base resolution 960 x 540.

## Characters and monsters

| Thing | Frame size | Anchor (feet) | Directions | Animations (frames) |
| --- | --- | --- | --- | --- |
| Player | 32 x 48 | bottom centre, 4 px up | 8 (S, SW, W, NW, N, NE, E, SE) | idle 4, walk 6, attack 4, throw 4, hurt 2, dead 1 |
| Small monster | 32 x 32 | bottom centre, 4 px up | 4 (SW, NW, NE, SE) | idle 4, walk 4, attack 3, dead 1 |
| Large monster | 64 x 64 | bottom centre, 6 px up | 4 | idle 4, walk 6, attack 4, dead 1 |

Mirroring west-facing frames for east is fine to halve the work.

## Items, effects, UI

- Item icons: **16 x 16** (ground and pack use the same icon).
- Effects (fire, splash, frost, poison cloud): 64 x 32 footprint, 6 frames.
- UI: 9-slice frames with 4 px borders; show-style neon accents on dark panels.

## Palette

About 32 colours. Grimy dungeon tones for the world; bright neon (pink, cyan,
yellow) reserved for the UI, loot boxes and sponsor drops.

## File naming

`art/<kind>/<id>.png` plus `<id>.json` from Aseprite, where `<id>` matches the id
in the data files, for example `art/mobs/sump_rat.png`, `art/items/oil_flask.png`.
Aseprite tags name the animations: `idle_s`, `walk_sw`, and so on.

## Current pipeline

`make_sprites.bat` converts `art_inbox/<kind>/<id>.*` into `art/<kind>/<id>.png` (one still frame per thing)
using `tools/sprite_pipeline.lua`. Animation tags and facing directions above are the target, not yet read by
the game.
