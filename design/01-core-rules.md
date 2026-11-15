# Core rules

> **How to change this file.** Edit anything here: change a cell, add a row, delete a row, or just write a
> note in plain words anywhere. This file describes what the game should do. The game itself reads the
> matching file in `data/`, and those two are brought back in line each time you say you have made changes.

Most of these numbers live in the game's code, not in a data file, so a change here means a small code change.
That is fine and expected. Write the rule the way you want it to play.

## Abilities are the centre of play

Every character fights with a kit of three abilities, one of each kind:

| Key | Kind | What it is for | What it can be today |
| --- | --- | --- | --- |
| Q | Offensive | Hurting or hindering monsters | Area damage; damage that also holds, burns, poisons, chills or dazzles |
| E | Defensive | Keeping yourself alive | Halving damage taken; a burst of speed; making monsters forget you; surviving a killing blow |
| R | Supportive | Helping you and your party | Healing; a damage boost for everyone nearby |

- You have a kit from the first minute. Your past life gives you a rough one (60% strength). The class you take on
  level 3 replaces it with a full-strength kit of its own.
- Abilities spend mana (Intelligence x 3, refilling over 40 seconds) and each has its own cooldown. Some cost
  health or an item from your pack instead and hit harder for it.
- Which kind you lean on is recorded in the dossier and shapes the classes you are offered.
- Hitting with your fists (Space) and throwing a piece of junk from your pack are still there as fallbacks. They
  are not what a character is built around. Only one class, the Dumpster Alchemist, is about items.

The full list of what abilities can do, and how each one is put together, is in `03-classes-and-races.md`.

## Flow of a run

1. Create a character: name, past life, starting location. The past life sets your starting kit of three abilities.
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
| Dexterity | Abilities recharge 3% faster and you move 2% faster per point above 4 |  |
| Constitution | +5 health per point |  |
| Intelligence | +6% ability power per point above 4, and sets mana (3 per point) |  |
| Charisma | +10% viewers per point above 4 |  |

## Numbers

| Rule | Now | How you want it |
| --- | --- | --- |
| Health | 20 + 5 per Constitution + 4 per level above 1, then class and race multipliers |  |
| Experience to next level | 20 x level to the power 1.5 (20, 57, 104, 160 ...) |  |
| Melee | 4 damage, reach 1.3 tiles, one swing every 0.45 seconds |  |
| Abilities | Three per character, each with its own cooldown (8 to 16 seconds; 60 for the killing-blow save) and a mana cost of 3 to 5 |  |
| Throwing junk | Range 7 tiles, one throw every 0.5 seconds. Uses ability power |  |
| Movement | 4 tiles per second |  |
| Monsters notice you from | 5 tiles |  |
| Monster toughness | +60% health per level down |  |
| Monsters and items return after | 20 and 25 seconds |  |
| Death | Back at your arrival point after 5 seconds at full health. No lasting penalty |  |
| Level timer runs out | The level resets and everyone on it returns to their arrival point |  |
| Safe rooms | No fighting, heal 3 health per second, loot boxes open here, stat points are spent here |  |
| Party | Shared experience within 10 tiles |  |
| Viewers | Rise with kills, deaths, discoveries, teaming up and descending; fade over time. They do nothing yet |  |
| Skills | Brawling, knack, tinkering, set by past life. Knack adds 5% ability power per level and grows as you use abilities |  |
| Past life perk | Not active on levels 1 and 2. It becomes part of any generated class |  |

## Not in the game yet

More kinds of ability (summons, traps, auras, transformations), learning extra abilities beyond the three, equipment, shops and gold, sponsors and the leaderboard, bosses, pets, personal spaces,
player-versus-player, specialisations, saving progress.

## Your rules

Write how you want the game to play here, in any form.
