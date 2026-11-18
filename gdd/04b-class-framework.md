# How to build a class

A class is built from parts, in this order. Each part has a short menu, so a new class is mostly picking from
menus and then writing the fun bits. The list in `04a-class-list.md` is written in this format.

Status: the filters below are **Decided** (from Daka's notes of 17 November 2026). The menus and the template are
**Proposed**.

## The filters every class must pass — Decided

1. **It plays like an ARPG.** Every mechanic is something you see on screen and do with the mouse and hotbar:
   hits, projectiles, areas, auras, summons, placed objects, marks, movement. Nothing needs voice chat, typed
   text or talking to work.
2. **It only measures what the game can count.** Hits, kills, damage dealt and taken, abilities used, items used,
   time, distance, positions, health levels. "Staying silent" or "arguing" cannot be a rule.
3. **No vehicles.** Nothing that needs a drivable vehicle to be built or drawn.
4. **No joke classes.** Every class has real strengths and real weaknesses.
5. **The audience is not a class.** Any class earns viewers by doing big, splashy, outrageous things. No class is
   built around gaming the audience.
6. **Drawbacks fit permadeath.** A drawback must hurt while you are alive and fighting. "You lose it when you die"
   is not a drawback, because you lose everything when you die.
7. **Offers are earned by one lean, not by doing everything.** An *offered when* condition is one or two measures
   a player would hit by leaning that way for part of floors 1 and 2, never by completing a whole floor's worth of
   related activity.
8. **Taglines show the fantasy.** One line that shows what you do in a fight. No "X as a Y", no "X is a Y", no
   "X, but Y".
   - Bad: *The diner waitress as a seer.*
   - Good: *Keeps the party alive on bottomless coffee, and throws the pot when that fails.*
9. **Plain classes lean into being generic**, and the System AI belittles the choice every chance it gets.

## Step 1: pick the archetype

The archetype decides how the class plays. The theme only decides how it looks and what its abilities are called.

| Archetype | Plays like | Range | Toughness | Leans on |
| --- | --- | --- | --- | --- |
| Bruiser | Wades in, hits hard, heals off the hitting | Melee | High | Strength, Constitution |
| Duelist | Darts in, bursts one target, gets out | Melee | Low | Dexterity |
| Guardian | Holds the line, soaks damage, protects allies | Melee | Very high | Constitution |
| Caster | Big ranged spell damage, often in areas | Long | Low | Intelligence |
| Marksman | Steady ranged weapon damage, positioning | Long | Low to medium | Dexterity |
| Summoner | Fights through minions | Medium | Low | Intelligence, Charisma |
| Controller | Slows, stuns, roots, curses and zones | Medium | Medium | Intelligence |
| Healer | Keeps allies alive | Medium | Medium | Charisma, Intelligence |
| Enchanter | Makes allies stronger with buffs and auras | Medium | Medium | Charisma |
| Trapper | Wins by placing things: traps, turrets, explosives | Medium | Medium | Dexterity, Intelligence |

## Step 2: pick the theme

A real job with a fantasy flair, made one of three ways:

| Way | What it means | Example |
| --- | --- | --- |
| The job, fought literally | What the job really does becomes what you do to monsters | A toll collector who makes every monster pay to pass |
| Magic made of the job's stuff | A school of magic built from something mundane | A mage who shoots bees |
| The job's tool, in your hands | The tool becomes the weapon or focus | A crossing guard whose stop sign stops monsters |

Ask: what does this job actually do all day? Every ability must trace back to one of those things.

## Step 3: pick the hook

One rule that makes the class play differently from others with the same archetype.

| Hook | How it works |
| --- | --- |
| Stacks | Hits add stacks to a target; at a number, something big happens |
| Meter | A bar that fills by doing something and is spent on a big move |
| Placed objects | Things you put on the ground: walls, traps, totems, booths |
| Minions | Creatures that fight for you |
| Stance | Two modes you switch between, each changing your abilities |
| Charge-up | Hold to power up; release for more effect |
| Combo | Abilities get stronger used in a set order |
| Terrain | You change the floor: tar, ice, water, holes |
| Consume | Spend corpses, items or your own health for power |
| Link | Tie yourself to an ally or enemy and share what happens |

## Step 4: three signature abilities

A class adds three abilities to whatever the crawler already knows. One of each:

| Slot | Purpose |
| --- | --- |
| Core | The thing you do most; shows the hook |
| Answer | Gets you out of trouble, or deals with a threat |
| Big move | Long cooldown, splashy, the moment that earns viewers |

## Step 5: stats, skills, drawback, offer, tier 2

| Part | Menu |
| --- | --- |
| Stats | One primary, one secondary, from the archetype table |
| Skills | 2 to 4 skills the class boosts or grows faster |
| Drawback types | Stat cap; weakness to one damage type; weaker on one kind of terrain; abilities cost health; cannot use one gear type; shop or faction penalty; a mechanic limit (needs a straight line, must stand still) |
| Offer measures | Abilities of one kind used N times; a skill at level N; N kills with one damage type; reputation with a faction; a gear type used for N minutes; an achievement |
| Tier 2 | A renamed stronger form that deepens the same hook. Never a different idea |

## The template

```
Name:
Tagline:            one line, shows the fight
Archetype:
Theme:              job + which of the three ways
Hook:
Core:               name: effect
Answer:             name: effect
Big move:           name: effect
Stats:              primary / secondary
Skills:
Drawback:
Offered when:       one or two measures
Tier 2:             name: what it adds to the hook
```
