# Class writing guide

A complete brief for writing new classes for this game. It is written so it can be handed to another writer or
AI model with no other context. Everything here is how the first 33 classes in `04a-class-list.md` were made.

---

## 1. The game, in what matters for classes

- **What it is.** A Diablo / Path of Exile style isometric pixel-art ARPG, played online by 2 to 20 friends in one
  shared dungeon. Players are ordinary people dropped into a televised death dungeon. They survive floor by floor,
  turn into something absurd and powerful, and play to an alien audience.
- **The setting.** Real New Jersey places twisted into dungeon floors: the American Dream mall, the Pine Barrens,
  the Shore, the I-95 between New York, Newark and Philadelphia. Jersey attitude is welcome everywhere.
- **The System AI.** The dungeon's host and narrator. A sardonic showman who plays favourites, wants to see messed-up
  things happen, and makes jokes at the player's expense in names, descriptions, quests and rewards.
- **Permadeath, mostly.** When a crawler dies, it is gone unless something it has (a race, class or ability) brings
  it back.
- **How a crawler grows.** On floors 1 and 2 there are no classes. Players learn skills and abilities from what they
  use and find, and level up. On reaching **floor 3** each player is offered **10 classes**, chosen from what they
  did on floors 1 and 2. Later floors offer an upgrade to a stronger tier.
- **Abilities.** Players can know any number of abilities, and put them on a hotbar of 8 or more slots. Abilities
  level up as they are used. A class adds **three signature abilities** to whatever the crawler already knows.
- **Stats.** Strength, Dexterity, Constitution, Intelligence, Charisma.
- **Pets.** Anyone can adopt one pet if they find one. Pet classes add slots.

## 2. What a class is

Every class is **a real-world job with a fantasy flair**. Each one is a real part of the game with real strengths
and real weaknesses, however absurd it looks.

The class list covers the whole range from **outlandish** (a mage who shoots bees) to **painfully plain** (a regular
guy with a sword). Most sit in between: a recognisable job, played straight as a fighting style.

## 3. The rules every class must pass

These are the designer's rules. A class that breaks any of them is rejected.

1. **It plays like an ARPG.** Every mechanic is something you see on screen and do with the mouse and hotbar:
   hits, projectiles, areas, auras, summons, placed objects, marks, movement, terrain. Nothing needs voice chat,
   typing, dialogue or talking to work.
2. **It only measures what the game can count.** Hits, kills, damage dealt and taken, abilities used, items used or
   crafted, time, distance, positions, health levels, pets, reputation, achievements. Never "stays silent",
   "argues", "is polite", "tells a story".
3. **No vehicles.** Nothing that needs a drivable vehicle or mount to work or to be drawn.
4. **No joke classes.** If a class would not be worth picking, it is not finished.
5. **Not built on the audience.** Every class earns viewers by doing big, splashy, outrageous things. No class is
   about gaining viewers, followers or fame as its mechanic.
6. **Drawbacks hurt while you are alive.** "You lose it when you die" is not a drawback: you lose everything when
   you die. A drawback must matter in fights.
7. **Offers ask for one lean.** The condition that earns a class is one or two measures a player would hit by leaning
   that way for part of floors 1 and 2. Never "complete everything related to X on the floor".
8. **Taglines show the fight.** One line, in the present tense, showing what you do. Never "X as a Y", "X is a Y",
   "X, but Y", "a Y who is also an X", "part X, part Y". No paragraphs.
9. **Plain classes lean into being generic.** The System AI belittles anyone who picks one.
10. **Original names only.** Do not reuse class, ability or race names from the novels this game is inspired by,
    or from any other game. Use the jobs, not their names.
11. **The joke has teeth.** Every ability traces back to something the real job actually does, all day, every day.
    If you cannot say which part of the job an ability comes from, cut it.

## 4. How to build a class, step by step

### Step 1: pick the archetype

The archetype decides how the class plays. The theme only decides how it looks.

| Archetype | Plays like | Range | Toughness | Stats it leans on |
| --- | --- | --- | --- | --- |
| Bruiser | Wades in, hits hard, heals off the hitting | Melee | High | Strength, Constitution |
| Duelist | Darts in, bursts one target, gets out | Melee | Low | Dexterity |
| Guardian | Holds the line, soaks damage, protects allies | Melee | Very high | Constitution |
| Caster | Big ranged spell damage, often in areas | Long | Low | Intelligence |
| Marksman | Steady ranged weapon damage, positioning | Long | Low to medium | Dexterity |
| Summoner | Fights through short-lived minions | Medium | Low | Intelligence, Charisma |
| Handler | Fights alongside permanent pets that level up and can die | Medium | Medium | Charisma, Dexterity |
| Controller | Slows, stuns, roots, curses and zones | Medium | Medium | Intelligence |
| Healer | Keeps allies alive | Medium | Medium | Charisma, Intelligence |
| Enchanter | Makes allies stronger with buffs and auras | Medium | Medium | Charisma |
| Trapper | Wins by placing things: traps, turrets, explosives | Medium | Medium | Dexterity, Intelligence |

Check the archetype against the abilities when you are done. If a "Healer" mostly does damage, it is in the wrong
archetype.

### Step 2: pick the job, and how it turns into a fantasy

Choose a real job. Then pick one of three ways to make it a class:

| Way | What it means | Example |
| --- | --- | --- |
| The job, fought literally | What the job really does becomes what you do to monsters | A toll collector who makes every monster pay to cross a line |
| Magic made of the job's stuff | A school of magic built from something mundane | A mage who shoots bees; a mage who tears up the road into potholes and tar |
| The job's tool, in your hands | The tool becomes the weapon or focus | A crossing guard whose stop sign freezes a whole lane |

Then write down **three things the job really does all day**. Each signature ability comes from one of them.

Example, toll collector: takes money from everyone who passes; sits in a booth; waves people into the fast lane.
Abilities: a line that damages monsters each time they cross it; a booth that blocks all damage; a lane that speeds
allies and slows monsters.

Where to find good jobs:
- Jobs everyone has seen: retail, food service, delivery, office, trades, healthcare, schools, security,
  entertainment, sport, government counters, cleaning, funeral care.
- Jobs with a tool everyone recognises: stop sign, box cutter, mop, stapler, ladle, mic, whistle, net, leash.
- Jobs with a famous complaint or stereotype: the slow DMV clerk, the pushy salesman, the HOA enforcer. The
  stereotype becomes the mechanic.
- New Jersey and Tri-State jobs: diner cook, Shore lifeguard, boardwalk game operator, toll collector, rooftop
  pigeon keeper, fireworks seller.

### Step 3: pick the hook

One rule that makes this class play differently from others with the same archetype. Name the hook from this menu,
then say exactly how it works for this class. For example: *"Hook: Stacks. Every sting adds venom; at 10 the target
bursts."*

| Hook | How it works |
| --- | --- |
| Stacks | Hits add stacks to a target; at a number, something big happens |
| Meter | A bar that fills by doing something and is spent on a big move |
| Placed objects | Things you put on the ground: walls, traps, totems, booths |
| Minions | Short-lived creatures that fight for you |
| Pack | Permanent pets; the class adds pet slots and gives pets orders |
| Tame | Turn a weakened monster into a pet |
| Stance | Two or more modes you switch between, each changing your abilities |
| Charge-up | Hold to power up; release for more effect |
| Combo | Abilities get stronger used in a set order or condition |
| Terrain | You change the floor: tar, ice, water, holes, grease |
| Consume | Spend corpses, items, stolen buffs or your own health for power |
| Link | Tie yourself to an ally or enemy and share what happens to them |

Spread hooks out: within one archetype, avoid giving most classes the same hook.

### Step 4: write three signature abilities

| Slot | Purpose | Cooldown |
| --- | --- | --- |
| Core | The thing you do most. It must show the hook | Short or none |
| Answer | Gets you out of trouble, or deals with a threat | Medium |
| Big move | Splashy, room-sized, the moment that makes the audience roar | Long |

Ability rules:
- Name every ability after something from the job (a phrase, a tool, a sign, a procedure). Short names: one to
  three words.
- Say what it does in plain game terms: shape (cone, line, circle, single target, aura), what it does (damage,
  stun, slow, root, heal, shield, summon), and a number where it matters (seconds, tiles, how many hits).
- Use numbers as placeholders: 2 to 5 seconds for crowd control, 3 to 8 seconds for buffs, 8 to 30 seconds for
  minions.
- Do not invent new rules the game would need to build specially when an existing shape will do.

### Step 5: fill in the rest

| Part | How to fill it |
| --- | --- |
| Stats | One primary and one secondary, matching the archetype table |
| Skills | 2 to 4 skills the class boosts or grows faster. Use plain names: fire magic, earth magic, sound magic, death magic, holy magic, nature magic, time magic, sleep magic, control magic, curses, healing, summoning, runes, music, light blades, heavy weapons, ranged weapons, aim, unarmed, shields, armour, stealth, traps, tricks, explosives, crafting, cooking, swimming, mapping, animal handling, leadership, endurance, poison, whips |
| Drawback | Pick one type: a stat cap; weakness to one damage type; weaker on one kind of terrain; abilities cost health; cannot use one gear type; a shop or faction penalty; a mechanic limit (needs a straight line, must stand still, slows you after use). Make it come from the job too, when possible |
| Offered when | One or two measures with a number: abilities of one kind used N times; a skill at level N; N kills with one damage type or weapon; reputation with a faction; a gear type used for N minutes; an achievement; a pet surviving N fights. Numbers are placeholders |
| Tier 2 | A renamed stronger form that deepens the same hook. Never a different idea. One line saying what it adds |

## 5. Tone and writing style

- **Taglines** show the fantasy in one line. Good examples from the list:
  - *Plants a booth in the road and makes every monster pay to pass.*
  - *Opens a palm and lets the swarm out.*
  - *Gets bigger every rep and throws monsters like plates.*
  - *Makes monsters take a number and wait their turn to live.*
  - *Walks into the fight with six leashes in one hand.*
  - *Smuggles crates across the state line and lights the fuse under everything.*
- **Bad taglines**, never write these: *The diner waitress as a seer.* *A lawyer who is also a paladin.* *Part
  bouncer, part golem.* *Customer service, but make it holy.*
- **Class names** usually follow one of these shapes: `[Job] [Fantasy role]` (Toll Booth Warden, Funeral Director
  Necromancer), `[Thing]-mancer` or `[Thing] Mage` (Asphaltomancer, Bee Mage), or the job played straight
  (Rooftop Pigeon Keeper). Plain classes have deliberately bland names.
- **Tier 2 names** are bigger and grander versions of the first: Toll Booth Warden becomes Turnpike Authority; Bee
  Mage becomes Hive Archon.
- **Jokes** live in names, taglines and ability names, never in the mechanics' fairness. The effects are always
  stated plainly.
- **Satire is welcome.** A class can say something cynical about the real job.
- **Write plainly.** Short sentences. No filler, no "unleash", "harness", "embrace", "wield the power of".

## 6. Ideas from other sources that shape classes

From the source novels' patterns (used as patterns only, never as names):
- Ordinary professions become real battle roles: pest control becomes chemical warfare; plumbing becomes water
  and pipe control.
- A class is a package: skills, stat changes, abilities, a real penalty, sometimes special access.
- Classes are offered because of what the player did, including odd or gross things.
- Classes upgrade into renamed, stronger forms that build on the same idea (an ice caster adds earth, then wind).
- Power is often held through others: pets, followers, minions.
- Bodies carry cost: changing shape should hurt or limit you.

From other games:
- **Draw Steel:** each class builds its own resource during a fight by doing its signature thing. The Meter hook
  is this.
- **Diablo IV:** each class has one system of its own on top of its abilities. The hook is this.
- **Diablo III and Last Epoch:** abilities change how they work as they level, so two players' versions differ.
  Write abilities so they have obvious upgrade directions.
- **Grim Dawn:** two parts combine into one named class.
- **Final Fantasy Tactics:** classes have clear, visible unlock paths.

## 7. Coverage target

Aim for about 150 classes in total, spread so every archetype is well served:

| Archetype | Target count | Already written |
| --- | --- | --- |
| Bruiser | 14 | 2 |
| Duelist | 14 | 1 |
| Guardian | 14 | 4 |
| Caster | 16 | 4 |
| Marksman | 14 | 1 |
| Summoner | 13 | 4 |
| Handler | 13 | 3 |
| Controller | 14 | 5 |
| Healer | 14 | 2 |
| Enchanter | 12 | 3 |
| Trapper | 12 | 2 |
| Plain | 4 | 2 |

Already written: Gym Bro Berserker, Repo Knight, Overnight Stocker Assassin, Toll Booth Warden, Bouncer Golem,
Personal Injury Paladin, Customer Service Martyr, Dirty Water Pyromancer, Asphaltomancer, Bee Mage, Podcast Host
Seer, Skee-Ball Sharpshooter, Funeral Director Necromancer, Wedding Planner Summoner, Influencer Lich, Mall Santa
Warlord, Dog Walker Packmaster, Exotic Pet Shop Clerk, Rooftop Pigeon Keeper, HOA Inquisitor, DMV Clerk
Chronomancer, Crossing Guard Sentinel, Mattress Salesman Dreamweaver, Auctioneer Hexer, Diner Oracle, Lifeguard
Templar, Tattoo Artist Runecarver, Wedding Band Bard, Union Steward Warlock, Boardwalk Carny Trickster, Fireworks
Stand Operator, Regular Guy With a Sword, Wizard (Basic). Do not repeat these jobs.

Within each archetype, mix: a few outlandish, most grounded, and use different hooks and different jobs.

## 8. Output template

Write every class in exactly this format:

```
**[Class Name]** — *[Tagline]*
- Archetype: [one of the 11]
- Theme: [job] · [literally / magic of its stuff / tool in hand]
- Hook: [hook name]. [How it works for this class, one or two sentences]
- Core **[Name]**: [effect]. Answer **[Name]**: [effect]. Big move **[Name]**: [effect].
- Stats: [primary] / [secondary]. Skills: [2 to 4]
- Drawback: [one line]
- Offered when: [one or two measures with numbers]
- Tier 2: **[Name]**. [What it adds to the hook]
```

## 9. Worked example

**Bee Mage** — *Opens a palm and lets the swarm out.*
- Archetype: Caster
- Theme: beekeeper · magic of its stuff
- Hook: Stacks. Every bee sting adds venom; at 10 stacks the target swells and bursts.
- Core **Swarm**: a cloud of bees that chases the nearest monster. Answer **Hive Armour**: bees cover you, stinging
  anything that touches you. Big move **Queen**: summon a giant queen that releases swarms for 10 seconds.
- Stats: Intelligence / Dexterity. Skills: nature magic, poison
- Drawback: fire damage hurts you 50% more and kills your swarms.
- Offered when: 200 poison kills, or adopted an insect pet.
- Tier 2: **Hive Archon**. Bursting targets release a new swarm.

Why it works: the archetype matches what it does (ranged damage); the hook is named and defined; every ability
comes from bees and hives; the drawback is real in a fight and makes sense (smoke and fire against bees); the offer
is one lean; the tagline shows the fight.

## 10. Self-check before handing a class in

- [ ] Could you play it with only a mouse and hotbar, no talking or typing?
- [ ] Does the archetype match what the three abilities actually do?
- [ ] Is the hook named from the menu and defined?
- [ ] Does each ability come from something the job really does?
- [ ] Does the drawback hurt during a fight?
- [ ] Is the offer one lean with a number, not "do everything"?
- [ ] No vehicle, no audience mechanic, no reused names?
- [ ] Does the tagline avoid "X as a Y", "X is a Y" and "X, but Y"?
- [ ] Is it worth picking?

## 11. A prompt to start with

> You are writing classes for an isometric pixel-art ARPG in the style of Diablo and Path of Exile. Use the guide
> above exactly: its rules, its menus, its tone and its output template. Write 10 new classes for the [archetype]
> archetype. Use 10 different real jobs, not any already written, and at least 4 different hooks. Make 2 of them
> outlandish and the rest grounded. After writing them, run the self-check on each one and fix anything that
> fails before showing me the final list.

Ask for one archetype at a time, about 10 classes per request. Read each batch before asking for the next, and
tell the model what you liked and disliked so the next batch improves.
