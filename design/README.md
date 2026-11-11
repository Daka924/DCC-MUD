# Design files

These files are the game written down in plain words and tables. They are yours to change.

| File | What it covers |
| --- | --- |
| `00-identity.md` | Game name, narrator, world, tone |
| `01-core-rules.md` | How a run goes, stats, the numbers |
| `02-character-creation.md` | Past lives and starting locations |
| `03-classes-and-races.md` | The class generator, hand-written classes, races |
| `04-levels.md` | Level maps, the map legend, set pieces |
| `05-monsters-items-companions.md` | Items and their tags, monsters, companions |
| `06-show.md` | Achievements, loot boxes, narrator lines |
| `07-art.md` | How to turn pictures into sprites |

## How changes reach the game

The game reads the files in `data/`. These design files are the readable version. When you have edited any of
them, say so, and the differences are carried into `data/` (or into code, for rules that are not data yet).
You can edit them on GitHub in the browser with the pencil button, or in any text editor on your computer.

You do not need to keep the tables tidy. A sentence such as "dying on level 1 should be permanent" anywhere in the
right file is enough.

The starting contents were written out from the game's data by `tools/export_design.py`.
