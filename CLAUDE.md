# Project notes

Multiplayer isometric pixel-art dungeon game-show crawler in Godot 4.3 (GDScript).

- No paid or hosted AI. The "creative brain" is `engine/invention.gd`: deterministic
  rules over item tags and player history. Keep it pure and testable.
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
