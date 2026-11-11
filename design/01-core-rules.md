# Core rules

> **How to change this file.** Edit anything here: change a cell, add a row, delete a row, or just write a
> note in plain words anywhere. This file describes what the game should do. The game itself reads the
> matching file in `data/`, and those two are brought back in line each time you say you have made changes.

Most of these numbers live in the game's code, not in a data file, so a change here means a small code change.
That is fine and expected. Write the rule the way you want it to play.

## Flow of a run

1. Create a character: name, past life, starting location.
2. Arrive alone in a safe room on level 1. A companion waits there and can be recruited.
3. Levels 1 and 2: no class. A hidden dossier counts what you do. Stat points are saved up and cannot be spent.
4. On arriving at level 3 the show presents a personal list of races and classes, with 120 seconds to choose.
   If time runs out, the first of each is chosen.
5. After choosing, saved stat points can be spent in safe rooms.

## Stats

Every character starts with 4 in each stat and gains 3 points per level.

| Stat | What it does now | How you want it |
| --- | --- | --- |
| Strength | +8% melee damage per point above 4 |  |
| Dexterity | +6% thrown damage and +2% movement speed per point above 4 |  |
| Constitution | +5 health per point |  |
| Intelligence | Sets mana (3 per point). Nothing uses mana yet |  |
| Charisma | +10% viewers per point above 4 |  |

## Numbers

| Rule | Now | How you want it |
| --- | --- | --- |
| Health | 20 + 5 per Constitution + 4 per level above 1, then class and race multipliers |  |
| Experience to next level | 20 x level to the power 1.5 (20, 57, 104, 160 ...) |  |
| Melee | 4 damage, reach 1.3 tiles, one swing every 0.45 seconds |  |
| Throwing | Range 7 tiles, one throw every 0.5 seconds |  |
| Movement | 4 tiles per second |  |
| Monsters notice you from | 5 tiles |  |
| Monster toughness | +60% health per level down |  |
| Monsters and items return after | 20 and 25 seconds |  |
| Death | Back at your arrival point after 5 seconds at full health. No lasting penalty |  |
| Level timer runs out | The level resets and everyone on it returns to their arrival point |  |
| Safe rooms | No fighting, heal 3 health per second, loot boxes open here, stat points are spent here |  |
| Party | Shared experience within 10 tiles |  |
| Viewers | Rise with kills, deaths, discoveries, teaming up and descending; fade over time. They do nothing yet |  |
| Skills | Brawling, throwing, tinkering, set by past life. Throwing adds 5% thrown damage per level. Skills do not train yet |  |
| Past life perk | Not active on levels 1 and 2. It becomes part of any generated class |  |

## Not in the game yet

Spells and mana use, equipment, shops and gold, sponsors and the leaderboard, bosses, pets, personal spaces,
player-versus-player, specialisations, saving progress.

## Your rules

Write how you want the game to play here, in any form.
