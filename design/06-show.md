# The show: achievements, loot boxes and the narrator

> **How to change this file.** Edit anything here: change a cell, add a row, delete a row, or just write a
> note in plain words anywhere. This file describes what the game should do. The game itself reads the
> matching file in `data/`, and those two are brought back in line each time you say you have made changes.

## Achievements

Each fires once per player when a dossier counter reaches a number, and awards a loot box that opens in the next
safe room.

| Id | Earned when | Title | Narrator text | Box |
| --- | --- | --- | --- | --- |
| first_kill | kills reaches 1 | Pest Control Intern | You ended something smaller than your shoe. The audience is thrilled, in the strictly legal sense of the word. | tin |
| kills_15 | kills reaches 15 | Bulk Discount | Fifteen bodies. Somewhere an accountant just updated a spreadsheet with your name on it. | copper |
| first_death | deaths reaches 1 | Participation Trophy | You died. On camera. In the tutorial wing. We are waiving the cleanup fee this once. | tin |
| first_party | parties reaches 1 | Emergency Contact | You teamed up. Statistically, one of you is the bait. Do not ask which. | tin |
| first_disc | discoveries reaches 1 | Patent Pending | You invented something by doing the same reckless thing three times. Science! | copper |
| throws_20 | throws reaches 20 | Litterbug | Twenty objects hurled. The janitorial drones have filed a formal complaint. | tin |
| first_recruit | recruits reaches 1 | Outsourcing | You convinced a member of staff to risk their life for you. They are not paid enough. They are not paid at all. | tin |
| first_descent | descents reaches 1 | Going Down | You found the stairs and used them correctly on the first try. The bar remains on the floor. | copper |
| class_chosen | class_chosen reaches 1 | Identity Crisis Resolved | You are now officially something. Whether it is something good is between you and the viewers. | copper |
| kills_above | kills_above reaches 1 | Punching Up | You killed something that outranked you. Human Resources has been notified. | tin |

## Loot boxes

The number after each item is its weight: higher turns up more often.

| Id | Name | Items inside | Possible contents |
| --- | --- | --- | --- |
| tin | Tin Box | 2 | Lamp-Oil Flask (3), Greasy Rag (3), Flint Chip (3), Bent Nails (2), Knuckle Bone (2) |
| copper | Copper Box | 4 | Lamp-Oil Flask (3), Greasy Rag (3), Flint Chip (2), Bent Nails (3), Glue Pot (3), Frost Moss (2), Glowcap (2), Frayed Rope (2), Scrap Plate (2) |

## Narrator lines

Words in curly brackets are filled in by the game. Separate alternatives with " / "; one is picked at random.

| Event | Lines |
| --- | --- |
| welcome | Welcome, {name}. Thousands are watching. Try to die somewhere well lit. |
| death | {name} has been turned into content. / {name} is dead. Viewers rated it a six. |
| respawn | Tutorial mercy applied to {name}. This will not last. |
| discovery | NEW DISCOVERY: {name} has invented the {ability}. {quip} |
| levelup | {name} reached level {level}. The bar was on the floor, but still. |
| party | {a} and {b} have joined forces. Betrayal odds are now posted in the lobby. |
| collapse | Time is up. The level has been recycled. Everyone pretend that did not hurt. |
| ability_up | {name}'s {ability} is now level {level}. Practice makes carnage. |
| descend | {name} has descended to {floor}. The audience upstairs has already forgotten them. |
| choose_start | Congratulations on not dying, {name}. We have been keeping a file on you. Time to find out what you are. |
| chosen | {name} is now a {race} {klass}. {quip} |
| recruit | {npc}: "{line}" |
| npc_leave | {npc}: "{line}" |
| box_wait | Achievement earned. Prizes are handed out in safe rooms, like civilised people. |

Lines added to an invented ability, by what it does:

| Ability kind | Lines |
| --- | --- |
| dot | It keeps hurting long after the fun part is over. Sponsors love that. / Lingering harm, very on brand. |
| damage | Crude, loud and effective. Much like its inventor. / Legal has asked that we call it a 'device'. |
| slow | Nothing says teamwork like making the other team walk funny. / It makes things slow. You will relate. |
| root | It holds things still so you can make worse decisions at them. / Hands-free violence. |
| stun | A brief nap for whoever is on the receiving end. / Side effects include seeing stars and losing fights. |

Events with no line yet: entering a safe room, opening a loot box, a near-death escape, killing a large monster,
long stretches of doing nothing, viewer milestones, spending stat points, timer warnings.

## Your lines and achievements
