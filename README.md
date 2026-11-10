# DCC-MUD

A multiplayer pixel-art dungeon game-show crawler (working title: **Crawl Show**).
Players descend through levels that collapse on a timer while a sardonic system
narrator and a simulated audience watch. The world, names and narrator are original.

![Vertical slice screenshot](docs/screenshot.png)

## What works now (vertical slice)

- **Multiplayer**: a dedicated server runs all the rules. Each player has their
  own isometric view of one shared, persistent level. Players who meet can form a
  party (shared XP, party health list) and chat.
- **Invention engine**: every item has tags. Combine up to three items and throw
  them; tag rules decide what happens. Use a combination on purpose three times
  (or do something dramatic with it) and the engine turns it into a named ability
  whose traits come from *how you found it*: where you stood, what you first hit,
  how hurt you were, who was with you. No AI model is involved; it is plain,
  deterministic code.
- **Game show layer**: collapse timer, viewer count driven by how exciting you
  are, achievements with loot boxes, narrator lines.
- **Basics**: melee, monsters with simple AI, skills that grow with use, levels,
  safe rooms, death and respawn, item pickups.

All art is placeholder shapes. See [docs/sprite-spec.md](docs/sprite-spec.md) for
the sprite sizes real art should follow.

## Running it

Install [Godot 4.3 or newer](https://godotengine.org/download) (standard build, free).

- **Try it alone**: open the project in Godot, press Play, click **Host and play**.
- **Play together**: one machine runs the server, everyone else clicks
  **Join server** and types its address.

```
# dedicated server (default port 24555, UDP)
godot --headless --path . -- --server

# optional: --port=24555 --seed=42
```

### Controls

| Key | Action |
| --- | --- |
| WASD or arrows | Move |
| Space, or click with nothing selected | Melee attack |
| Click items in the pack (up to 3), then click the floor | Throw that combination |
| 1-5 | Use an invention at the mouse position |
| P / Y / L | Invite nearest player / accept invite / leave party |
| Enter | Chat |

Try this: leave the safe room, select Lamp-Oil Flask + Greasy Rag + Flint Chip and
throw it at monsters three times. Do it in a flooded room and then in a doorway
with a second character and compare the two abilities.

## Layout

| Path | What it is |
| --- | --- |
| `data/` | All content as JSON: items and tags, tag rules, context rules, monsters, achievements, boxes, narrator lines, the level map |
| `engine/invention.gd` | The invention engine (pure functions) |
| `server/world.gd` | The authoritative game simulation |
| `server/net.gd` | Networking: validates client requests, sends snapshots and events |
| `client/game_client.gd` | Isometric renderer and HUD |
| `client/bot.gd` | Scripted player for automated multiplayer tests |
| `tests/` | Rules tests and a two-player smoke test |

## Tests

```
godot --headless --path . --import          # once, builds the class cache
godot --headless --path . -s tests/run_tests.gd
GODOT=godot tests/multiplayer_smoke.sh      # server + two bot players
```

## Adding content

New items only need an entry in `data/items.json` with tags. New interactions
are rows in `data/tag_rules.json`. New discovery traits are rows in
`data/context_rules.json`. No code changes are needed for any of these.
