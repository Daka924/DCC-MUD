# Floors

## How every floor works — Decided

- **Dungeon-wide quests.** Each floor has a few key quests. They are shared by the whole dungeon: any player can
  pick them up or finish them. Some of them appear because of player choices, and may be tweaked to fit those
  players.
- **Collapse.** Once the floor's key quests are finished, a countdown starts. When it runs out the floor collapses.
  Players must find a stairwell before then.
- **The countdown is real time: 8 hours**, because this is a MUD and players come and go.
- **Instant collapse:** if every active player is in a stairwell, the floor collapses at once.
- **Announcement:** the system AI (a character in the fiction) announces the countdown. From then on it is shown
  on screen to every player who is not in a stairwell.
- **Layout.** Hand-built set pieces stitched into a rich generated fabric. The generator follows the floor's design
  (its theme, factions, terrain), so every floor has a fixed identity but the ground between set pieces varies.
- **Maps.** Players can get maps of the floor through skills or by defeating small-tier bosses.
- **Players.** Between 2 and 20 friends or a small community are active in the dungeon at once.

## Proposed

| Rule | Proposal |
| --- | --- |
| Anyone still on the floor at zero | Dies (subject to the death rules in `02-crawler-and-death.md`) |
| Going down early | Allowed once a stairwell is found; no coming back up |
| Offline players | A player who is logged out when the floor collapses is carried down with it if they last logged out in a safe room or stairwell, and dies otherwise |

## Floor 1 — Decided

**American Dream.** The New Jersey mega-mall and its surrounding area, twisted into a weird amalgam of dangerous
shops. Its people have been swapped into RPG-style races.

- The major attractions are **contested zones** where mini NPC factions battle for control.
- **The 4 major attractions:** the theme park, the water park, the indoor ski slope, and the ice rink.
- The mall's inhabitants are fantasy races based on the ideas within the mall. **Lego people are one of them.**
- **Collapse trigger:** once the quests of all **4 major attractions** are finished.
- **Exit:** a stairwell somewhere on the floor.

### Floor 1 races and factions — Proposed (brainstorm)

Races that grew out of what the mall sells. Any of these can also become a race offer at floor 3 for players who
earn their reputation.

| Race | Born from | What they are like | Strength | Weakness |
| --- | --- | --- | --- | --- |
| Brickfolk | The Lego centre | Blocky people who rebuild themselves and their walls on the spot; obsessed with instructions | Reassemble after being broken; build cover instantly | Hard hits knock pieces off; lost pieces are lost stats |
| Mascots | The theme park | Huge-headed costumed performers who never break character. Nobody knows what is inside | Enormous health; fear aura from the frozen smile | Cannot see well; cannot speak |
| Slide Nymphs | The water park | Chlorine-scented water spirits, fast and slippery | Quick, hard to grab, strong in water | Dry out away from water |
| Yeti | The ski slope | Lift operators gone feral in permanent winter | Cold immunity; great strength | Overheat anywhere warm |
| Rink Elves | The ice rink | Blade-footed, graceful, vicious about ice time | Speed and bleed attacks on ice | Clumsy off the ice |
| Mannequins | The fashion wing | Faceless, posed, swap parts and outfits with each other | Take over a new body when theirs breaks | No face: cannot use voice abilities |
| Plushkin | The toy and claw-machine arcades | Stuffed animals of every size, sweet until cornered | Blunt hits barely hurt | Fire and tearing |
| Sugarfolk | The candy store | Sticky candy golems, hyper and short-tempered | Heal from sugar; glue enemies in place | Melt in heat and water |
| Greaselings | The food court | Fryer goblins who run the black market | Cheap crafting, slippery escapes | Flammable |
| Kiosk Imps | The hallway kiosks | Relentless small salesmen who will not let you pass | Slow and debuff with offers | Fragile alone |
| Tankborn | The aquarium | Shark and jellyfish people who want out of the glass | Bite and sting | Need water nearby |
| Security Orcs | Mall security | Segway-riding enforcers of rules nobody remembers | Armour, stuns | Slow to change orders; easily misdirected |

Who is fighting over what:

| Attraction | Faction A | Faction B | The quest that settles it |
| --- | --- | --- | --- |
| Theme park | The Mascot Court | Brickfolk Builders' Guild, who want to rebuild the rides "properly" | Pick a side or play both; restart or wreck the big coaster |
| Water park | Slide Nymphs | The Tankborn, flooding in from the aquarium | Control the wave machine |
| Ski slope | The Yeti | Greaselings, who want the cold storage for their fryer empire | Seize or sabotage the snow machine |
| Ice rink | Rink Elves | Security Orcs, who have declared skating a violation | Win the rink in a match the System AI referees, badly |

The neutral ground between them (fashion wing, toy arcades, candy store, hallways) belongs to the Mannequins,
Plushkin, Sugarfolk and Kiosk Imps, who sell, scheme and give side quests.

## Floor 2 — Decided

**Pharmabelt to Shore.** Crawlers are dropped into the marshes and forest between New Jersey's pharmaceutical belt
and the southern shore.

- Tough terrain to navigate. Factions nest in alcoves through the wastes, and have spilled into the shore waters.
- **Factions:** cults devoted to the Jersey Devil; merpeople; reanimated corpses; animals pumped full of chemicals.
- **Super monsters** roam three areas: the Pine Barrens, near the big pharmaceutical plants, and in the ocean off
  the shore.
- **Stairwell access:** defeat one of the super monsters.
- **Collapse trigger:** once a giant has been defeated.

## Floor 3 — Decided

**The 3 Kingdoms.** A fantasy restructuring of the three major metropolises around New Jersey: New York City,
Newark and Philadelphia. Each city is its own codified kingdom with special knights, customs, food and trade, and there is
friction between them. A mix of high fantasy and Tri-State tropes.

- **Mystery:** someone is controlling the I-95 for their own secret goals. Reclaim the kingdom by opening the sealed
  exits to the towns along it.
- **Boss gates:** each town exit is guarded by a boss.
- **War:** once 5 exits on the I-95 path have been cleared, the kingdom with the most total exits open declares
  war on the other two. **The collapse countdown starts at that moment.**
- **Ways to escape:** defeat any other kingdom's leader, or find one of the hidden exit stairwells (follow the
  clues to find which exits hide one).
- Crawlers arrive here having already chosen their first race and class.

## Open

- Floor 2: is "a giant" the same thing as the super monsters, or a separate creature?
- Floor 3: what happens to a player who pledged to no kingdom?
- How many floors the game has in total.
