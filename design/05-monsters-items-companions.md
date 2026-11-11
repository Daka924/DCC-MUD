# Monsters, items and companions

> **How to change this file.** Edit anything here: change a cell, add a row, delete a row, or just write a
> note in plain words anywhere. This file describes what the game should do. The game itself reads the
> matching file in `data/`, and those two are brought back in line each time you say you have made changes.

## Items

All items are throwable junk. There is no equipment, food, potion or gold yet. Tags decide what an item does when
thrown, and what the class generator learns about a player who throws it.

| Id | Name | Tags |
| --- | --- | --- |
| oil_flask | Lamp-Oil Flask | glass, fragile, flammable, liquid |
| rag | Greasy Rag | cloth, flammable, wick |
| flint | Flint Chip | stone, spark, small |
| scrap | Scrap Plate | metal, sharp, heavy |
| nails | Bent Nails | metal, sharp, small |
| glue_pot | Glue Pot | fragile, liquid, sticky |
| frost_moss | Frost Moss | plant, cold |
| glowcap | Glowcap | plant, luminous, toxic |
| rope | Frayed Rope | cloth, binding, long |
| bone | Knuckle Bone | bone, blunt, heavy |

### What tags do when thrown

| Effect | Needs tags | Kind | Power | Seconds | Radius |
| --- | --- | --- | --- | --- | --- |
| thump | any item | damage | 2 |  |  |
| burn | flammable and spark | dot | 3 | 4 |  |
| pierce | sharp | damage | 4 |  |  |
| shrapnel | sharp and small | damage | 3 |  | 1.5 |
| bash | heavy | stun | 0 | 0.8 |  |
| gum | sticky | slow | 0.5 | 4 |  |
| snare | binding | root | 0 | 2.5 |  |
| chill | cold | slow | 0.6 | 3 |  |
| poison | toxic | dot | 2 | 6 |  |
| dazzle | luminous | stun | 0 | 1.2 |  |

Only the Dumpster Alchemist class can combine items and invent named abilities from them.

## Monsters

Values are for level 1. Health grows 60% per level down. Monsters only walk at the nearest player and bite.

| Id | Name | Family | Level | Health | Damage | Speed | Experience | Sprite |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| sump_rat | Sump Rat | vermin | 2 | 12 | 2 | 2.6 | 6 | small |
| drain_leech | Drain Leech | ooze | 3 | 18 | 3 | 1.6 | 9 | small |
| scrap_golem | Scrap Golem | construct | 8 | 70 | 7 | 1.4 | 40 | large |

## Companions

One waits in each starting safe room, follows a solo player, and leaves when the player teams up with a real player.

| Id | Name | Waits at | Who they are | Damage | Says when joining | Says when leaving |
| --- | --- | --- | --- | --- | --- | --- |
| dolores | Dolores | The Break Room | A former contestant who now mops the Break Room and resents it. | 3 | Fine. But I walk behind you, and if you die I keep your shoes. | You have real friends now. Try not to get them killed. I'll be mopping. |
| gus | Gus | The Lost Property Office | Lost Property clerk. Has been looking for his own stapler since last season. | 3 | I'll come. Somebody has to carry the paperwork. | Two's company, three's an insurance problem. Good luck out there. |
| vex | Vex | The Boiler Lounge | Boiler technician. Will not say what the boiler is for. | 4 | I hit things with a wrench. That's the whole offer. | You found your people. I'm going back to the boiler. Don't ask about the boiler. |

## Your creatures, items and characters
