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
- Art is placeholder shapes for now; follow `docs/sprite-spec.md`.

## Checks before pushing

```
godot --headless --path . --import
godot --headless --path . -s tests/run_tests.gd
GODOT=godot tests/multiplayer_smoke.sh
```
