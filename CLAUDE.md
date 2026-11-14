# Project notes

Multiplayer isometric pixel-art dungeon game-show crawler in Godot 4.3 (GDScript).

- No paid or hosted AI. Everything "creative" is deterministic rules over data.
- The core loop: no class for two levels while a hidden dossier records what the
  player does, then a personal race and class offer on level 3
  (`engine/class_offers.gd`). Free-form crafting (`engine/invention.gd`) is one
  class's perk, not a universal mechanic. Keep both engines pure and testable.
- Players create their own characters. NPC companions help solo players until
  they party with real players. There is a pet slot; pets are not built yet.
- The server (`server/world.gd`) is authoritative. Clients only render and send
  requests; validate every request in `server/net.gd`.
- Content lives in `data/*.json`. Prefer adding data over adding code.
- All names, creatures, items and narrator lines must be original. Do not use
  names, characters or text from any book series.
- Generated classes come from `data/class_parts.json` (tag profile, jobs, describing
  words). Widen the range by adding rows there, not code. Each generated class gets a
  signature ability from `data/ability_parts.json` via `engine/ability_gen.gd`.
- Art: `make_sprites.bat` runs `tools/sprite_pipeline.lua` through Aseprite to turn
  `art_inbox/<kind>/<id>.*` into `art/<kind>/<id>.png`. `client/sprites.gd` loads those
  and falls back to placeholder shapes. Sizes are in `docs/sprite-spec.md`.
- `design/*.md` is the owner's readable version of the rules and content. When they
  edit it, carry the changes into `data/` or code, then keep the two in step.

## Checks before pushing

```
godot --headless --path . --import
godot --headless --path . -s tests/run_tests.gd
GODOT=godot tests/multiplayer_smoke.sh
```
