# Lessons from other games

What other games do well that fits our game, and the rule each one becomes here. Everything on this page is
**Proposed** until Daka marks it. "Where it goes" names the page the rule would join once it is accepted.

Written from general knowledge of these games, not from fresh research. Exact numbers in those games are not
the point and are not copied; only the shape of each idea is.

## Which ideas to adopt first

| Priority | Idea | From | Why first |
| --- | --- | --- | --- |
| 1 | Every class has its own resource that fills by fighting its way | Draw Steel, Diablo IV | Makes each class feel different from the first fight, and gives the "hook" a real shape |
| 2 | Abilities level into small upgrade trees, with modifiers | Last Epoch, Diablo III and IV, Path of Exile | Daka wants abilities to level; this makes levelling a choice, not just bigger numbers |
| 3 | Elite monsters carry visible affixes | Diablo II to IV | Daka wants elites marked; affixes make them dangerous in readable ways |
| 4 | Achievements can grant titles with small effects | Draw Steel | Achievements become part of the build, not only loot boxes |
| 5 | Gear with named powers, sets and combinations | Diablo II to IV | Daka wants Diablo-style gear with its own abilities |

## Diablo

The series our game looks and plays most like. Ideas from across Diablo II, III and IV.

### Class mechanics — Diablo IV

Each class has one system nobody else has: one class keeps a rack of weapons and swaps between them, one infuses
spells with a chosen effect, one picks a page from a book of the dead to shape its minions.

- **Rule:** every class has one **class mechanic**, a small system of its own on top of its abilities. It is the
  "hook" in `04b-class-framework.md`, made bigger and given its own panel on screen.
- Example: the **Toll Booth Warden** chooses what its booth charges (slow, damage or a stun), and swapping costs a
  moment out of the fight.
- Where it goes: `04b-class-framework.md`, step 3.

### Ability modifiers — Diablo III runes, Diablo IV skill tree

In Diablo III each skill has a set of runes, and choosing one changes how the skill works (a frost version, a
splitting version). In Diablo IV, points spent in a skill unlock a choice between enhancements.

- **Rule:** at ability levels 5, 10 and 15, the player picks **one of two modifiers** for that ability. A modifier
  changes how it works, not just how hard it hits: it splits, chains, leaves a patch, gains an element, or turns
  into a short channel.
- Two players with the same ability end up using it differently.
- Where it goes: `05-abilities-and-combat.md`.

### Skills that strengthen each other — Diablo II synergies

In Diablo II, points in one skill made related skills stronger.

- **Rule:** skills (not abilities) carry **synergies**. Levelling the Fire Magic skill makes every fire ability
  stronger, and levelling Cooking makes food-based healing stronger. This is how the many skills a crawler picks
  up on floors 1 and 2 stay useful after they take a class.
- Where it goes: `05-abilities-and-combat.md`, Skills.

### Elite affixes — the whole series

Elite and champion monsters spawn with random named traits: fast, fire-enchanted, teleporting, shielded, splits
when hit. Their name plate lists them.

- **Rule:** elite monsters carry **1 to 3 visible affixes**, listed on their name plate under Daka's elite warning.
  Every affix has a clear visual tell and a counter.
- The System AI names the affixes in its own voice, and sometimes lies about one.
- Example affixes, Jersey flavoured: **Turnpike Speed** (fast), **Shore Burn** (leaves fire), **Jughandle** (circles
  behind you), **Union Break** (stops to heal itself at half health).
- Where it goes: `09-multiplayer.md`, warnings, and a new monsters page.

### Item tiers and named powers — Diablo II to IV

Common, magic, rare, set and unique items; Diablo IV's legendary powers (aspects) that can be pulled out of one
item and put into another.

- **Rule:** item tiers follow Diablo: **Common, Magic, Rare, Legendary, Set, Unique**.
  - Legendary items carry a **named power** that changes an ability or class mechanic.
  - A crafter at the right station can **pull a named power out** of an item (destroying it) and put it into
    another. This gives crafting a real job in the endgame.
  - **Set items** give extra powers when you wear several pieces of the same set.
  - **Unique items** are hand-made, one-of-a-kind, and full of System AI jokes.
- Where it goes: `06-progression.md`, Gear and loot.

### Runewords — Diablo II

Socket the right runes in the right order into the right base item, and it becomes a named, powerful item.

- **Rule:** gear can have **sockets**. Certain combinations of socketed items, in the right order, form a **named
  combination** with its own power. Recipes are rare finds or faction secrets.
- This is the item side of Daka's "rules engine reacts to combinations nobody scripted".
- Where it goes: `06-progression.md`.

### Hardcore — Diablo II to IV

Diablo's hardcore mode is permadeath. Players love it because every risk is real, and the loot dropped by
the dead becomes a story.

- **Rule:** borrow two habits from hardcore communities:
  - A **memorial board** in every safe room listing the dead, their class, floor and killer, written by the System
    AI.
  - **Rare escape items**: one-use items that pull you out of a fight to the nearest safe room. They are precious,
    never guaranteed, and fit "permadeath, ish".
- Where it goes: `02-crawler-and-death.md`.

### World events — Diablo IV

Helltides and world bosses: timed events that pull everyone on the map toward one place.

- **Rule:** each floor has **timed world events** announced by the System AI, for example a faction raid on an
  attraction or a giant moving through an area. They draw the 2 to 20 players toward each other, which is how
  strangers meet and form parties.
- Where it goes: `03-floors.md`.

### Paragon — Diablo III and IV

After the level cap, experience still earns small permanent bonuses.

- **Open question for Daka:** is there a level cap? If so, a Paragon-style track keeps experience meaningful.

## Draw Steel

A tactical tabletop RPG with very strong class and character building.

| Idea there | Rule here | Where it goes |
| --- | --- | --- |
| Each class has a **heroic resource** that fills during a fight through its signature behaviour (taking hits, landing blows) and pays for big abilities | Every class has its own resource, filled by doing the class's fantasy. The Gym Bro's Pump fills by hitting; the Personal Injury Paladin's Settlement fills by taking hits | `04b-class-framework.md` |
| **Titles** earned by specific deeds, each with a small benefit | Some achievements grant a **title**: one equipped at a time, each with a small effect. Example: "Seventeen Bodies in a Food Court", +5% damage in crowded areas | `07-the-show.md` |
| **Complications**: optional at creation, a benefit and a drawback together | Each past job comes with an optional **complication**. Example: Night-Shift Worker: see in the dark, but weaker in daylight | `06-progression.md`, character creation |
| **Ancestries** with a signature trait plus a budget of points for optional traits | Each race has a **signature trait** and **3 picks from a menu of traits**, so two players of the same race can differ | `04-classes-and-races.md` |
| **Careers**: a background that grants skills, a perk and an inciting incident | The past job grants **2 starting skills, 1 perk and 1 starting item** | `06-progression.md` |

## Path of Exile

| Idea there | Rule here | Where it goes |
| --- | --- | --- |
| **Support gems**: link one to an ability and it changes it (more projectiles, chains, adds an element) | Found items called **modifiers** that slot onto an ability. The hotbar shows which modifiers each ability carries | `05-abilities-and-combat.md` |
| A huge **passive tree** every class shares, starting from different points | Probably too big for us. A small version: each archetype has a short passive track | Open |
| **Ascendancy**: a stronger subclass unlocked by beating a trial | Tier 2 classes are unlocked by a **class trial**, a short challenge on floor 4 or 5 built around the class's hook | `04-classes-and-races.md` |

## Last Epoch

| Idea there | Rule here | Where it goes |
| --- | --- | --- |
| Every ability has its own **small upgrade tree**, filled as the ability levels | Combine with the Diablo modifier rule: each ability has a small tree of choices, opened by levelling it | `05-abilities-and-combat.md` |
| Choose a **mastery** partway through, which shapes the rest of the class | Matches our tier system already | — |

## Grim Dawn

| Idea there | Rule here | Where it goes |
| --- | --- | --- |
| Pick **two masteries**; each pair has its own class name | The class generator combines **two parts** (a job and a fantasy school) into one named class, with each pair given its own name | `04b-class-framework.md`, generator |
| **Devotion**: a constellation map of god-like powers you unlock with points | A possible shape for **god worship**: each god has a small constellation of granted powers that open with devotion | `08-factions.md` |

## Darkest Dungeon

| Idea there | Rule here | Where it goes |
| --- | --- | --- |
| **Quirks**, good and bad, gained from what happens to a character | The show's hidden file on each crawler can award **quirks** on floors 1 and 2: "Afraid of Water", "Fryer-Scarred". They show up in class offers and AI jokes | `06-progression.md` |
| **Stress** and breaking points | Probably not: it slows an ARPG down | — |

## Hades

| Idea there | Rule here | Where it goes |
| --- | --- | --- |
| Each god offers **boons** from their own pool | Each god has a pool of granted powers, offered a few at a time as devotion grows | `08-factions.md` |
| **Duo boons**: a combined power when you hold boons from two gods | If multi-god worship is ever allowed, two gods' powers can combine. Otherwise: party members who worship different gods unlock a shared combined power | `08-factions.md` |

## Final Fantasy Tactics and Final Fantasy V

| Idea there | Rule here | Where it goes |
| --- | --- | --- |
| **Job system**: levelling one job unlocks others, and you can carry abilities from an old job | The class offer list can show **locked classes with their conditions**, so players can aim for one on floors 1 and 2 | `04-classes-and-races.md` |

## Vampire Survivors

| Idea there | Rule here | Where it goes |
| --- | --- | --- |
| **Evolutions**: an item plus a matching passive at max level evolves into something stronger | An ability at level 15 plus a matching item or skill can **evolve** into a named stronger version | `05-abilities-and-combat.md` |

## Open

- Does Daka want a level cap, and a Paragon-style track after it?
- Which of these does Daka want in, out or changed?
