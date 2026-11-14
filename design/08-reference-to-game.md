# From the reference to our game

This file maps Daka's research reference (v3, 14 November 2026) onto the game. The reference itself is kept
outside this repository, because the repository is public and the reference describes someone else's books.
Entries are cited here by their record number only (for example CR01, AD07, FL05) so you can look them up.

What is taken from the reference: how systems work, and the patterns behind them. What is never taken: names,
characters, creatures, gods, places, item names or wording. Everything in the game stays original.

The right-hand column in each table is yours. Write "yes", "no", or how you want it instead.

## 1. Where the game disagrees with the reference today

| Topic | What the reference shows | The game today | Proposed change | Your call |
| --- | --- | --- | --- | --- |
| What earns a class offer | Offers have requirements: specific skill levels, specific achievements, and viewer counts reached by level 3 (CR01, CR02, FL01) | Requirements are dossier counts and past life only | Add achievements, skill levels and peak viewers as conditions, and feed all three into the generator's tag profile |  |
| What a class gives | A package: starting levels in named skills, stat changes, faster growth in some skills, an immunity, a spell or two, penalties to whole damage types or spell costs, and access to places others cannot enter (CR01, CR02, CR04) | A handful of percentage changes | Give every class a package: 2 to 4 skills, one signature ability, one penalty with teeth, and sometimes an access right |  |
| Making the choice | Permanent, on a long timer, and random if you do not answer (CR04) | 120 seconds, defaults to the first option | Longer timer, random default |  |
| Race | A separate package with its own requirements, bonuses, penalties and caps. Keeping your own body is a real option with a trade: slightly lower stats for a higher training ceiling. Race abilities are distinct from class abilities (CR06, CR07, CR10) | Six races, "stay as you are" does nothing | Give "stay as you are" a real trade; give each race one ability and one cap or weakness |  |
| Growth after the choice | A specialisation later (level 6), subclasses, and classes that upgrade into a renamed stronger form (CR01, CR04, class records marked with an arrow) | Nothing after level 3 | Add an `upgrades_to` step to class parts, so generated classes can grow a second name later |  |
| A class that changes every level | One class type draws a new temporary role each level, with a random share of that role's abilities. Trained skill experience survives; the temporary stat boosts do not (CR03, AX001) | Not present | A natural fit for the generator: one class whose job is re-rolled from the player's tags on each new level |  |
| Skills | Skills level by use, each level has a stated effect, training past 15 is hard and needs an unlock to reach 20 (CR07, AD01) | Three skills that never train | Make skills train by use and give each level a stated effect |  |
| Spells | Each has a mana cost, a duration that grows per level, a cooldown and a stated target type. Owning the book is not the same as knowing the spell (AD02, AD04) | Mana is shown, nothing uses it | Add spells as data rows with those five fields |  |
| Staying alive | Seven different ideas that should not be merged: avoid, reduce, resist, be immune, survive one lethal hit, heal afterwards, and be locked out of healing (AD07, AD02, AD03, CR10) | Only health and regeneration | Add reduce, survive-a-lethal-hit and healing lockout first; they create the best stories |  |
| Equipment | Gear can carry its own spell with its own level and cooldown, separate from what the wearer has learned (AD03, AD10) | No equipment | When equipment arrives, give it its own ability layer |  |
| Safe rooms | Boxes open only in safe areas; safe rooms show through the map fog; no time limit inside while the level timer still runs (SY01) | Matches, except there is no map fog | Keep. Add the fog when the map grows |  |
| A home base | A personal space with an owner and sharing settings, which merges with party members' spaces into a bigger shared one. Upgrades travel with their owner and are lost on death (SY02, SY03, SY08) | Not present | Later. Design it as owned rooms that merge |  |
| The guide | An advisor who explains the rules but cannot fight alongside you, and who loses some knowledge in exchange for being allowed to help more (SY09) | Companions fight; nobody explains | Split the two jobs: a guide who talks, companions who fight |  |
| Levels | Each level is built around one idea: learning then committing (1 to 3), transport and shared knowledge (4), linked objectives where order matters (5), being hunted (6), capturing and fielding creatures in squads (8), a war where votes change the rules (9), race heats with upgrades between them (10) (FL01 to FL08) | Three small maps with no idea of their own | Every level in `04-levels.md` gets a "core idea" and one rule that exists only there |  |
| Gods and sponsors | Worship grants access and creates obligations; a god's body, the one steering it and the god are three different things (GO01 to GO06) | Not present | Later system. Worth designing early because it gates places and abilities |  |
| The narrator | A character with appetites: plays favourites, insults while informing, is possessive, is sometimes wrong, performs for an audience, and its mood changes rewards (AP001 to AP013, AI01 to AI04) | A list of sarcastic lines | Give our narrator a favour score per player that shifts what boxes hold and how it speaks |  |

## 2. The ability taxonomy as the generator's next layer

**Built on 14 November** in a first form: function, delivery, flavour and cost. See "Signature abilities" in
`03-classes-and-races.md`. Target types beyond enemies and party members, timing rules other than cooldowns, and
the mind and body axes beyond "forget" are not built yet.

The reference describes any ability along several independent axes. That is exactly the shape a rules-based
generator needs: pick one value per axis, guided by the player's tags, and the result is a specific ability
rather than "bomb, tier 3".

| Axis | Values to start with |
| --- | --- |
| Origin | race, class, trained skill, learned spell, equipment, consumable, worship, companion, level rule |
| Function | damage, control, healing, protection, support, detection, movement, construction |
| Delivery | touch, thrown, cloud, song, speech, aura, trap, weapon, own body |
| Target | self, ally, enemy, pet, corpse, summoned creature, object, floor or wall |
| Defensive outcome | avoid, reduce, resist, immune, survive lethal hit, heal after, block healing |
| Timing | instant, lasts a while, cooldown, once per fight, only when a condition holds, this level only |
| Element or material | fire, ice, earth, wind, water, lightning, flesh, sound, light, made things (food, glue, scrap) |
| Mind | charm, compel, forget, detect, hide, mislead |
| Body | transform, possess, copy a look, copy a power, split |
| Cost or limit | mana, how well you perform, room shape, weight, an offering, cooldown, who can be targeted |

How it would work: each job in the class generator names two or three axis values it insists on, and the
player's strongest tags fill the rest. Three examples of what would come out, in our own words:

- A baker who kept throwing burning things, offered a fire job: **thrown, enemy, fire, lasts a while, cost:
  an item from the pack** becomes "Proofing Dough", a lump that swells where it lands and burns anything stuck in it.
- A librarian who hid in safe rooms, offered a quiet job: **speech, enemy, forget, cooldown** becomes "Overdue
  Notice", which makes one monster forget it was chasing you.
- A referee who took many hits, offered a punishment job: **own body, self, survive lethal hit, once per
  fight** becomes "Extra Time", which leaves you on one health the first time a hit would kill you.

The names and one-line descriptions come from word lists per axis value, the same way class names are built now.

## 3. Rules of thumb drawn from the reference's themes

1. An ordinary job becomes a battle role, and the joke has real effects.
2. Some power only works with an audience or a performance. Viewers should be a resource, not a score.
3. A role can change while what you learned stays.
4. Power is often held through others: pets, followers, partners, inherited knowledge.
5. Labels can be wrong. What the screen calls something is the narrator's opinion.
6. Bodies carry cost. Changing shape should hurt, limit or expose you.
7. Size, material and what counts as a legal target decide whether a clever idea works.

## 4. Proposed order of work

1. Class packages: skills, one signature ability, a real penalty, viewer and achievement requirements, random default.
2. The ability generator on the axes above, so every generated class gets its own ability.
3. Skills that train by use, with stated effects per level.
4. Reduce, survive-a-lethal-hit and healing lockout.
5. A "core idea" for each level, starting with a fourth level built around one.

## 5. What I have and have not read

Read closely: the themes, the ability taxonomy, build mechanics, abilities, systems, divine mechanics, level notes,
corrections and open questions, and a sample of class records. Skimmed by title only: most of the 123 class
records, the 78 race records, the 47 god records and the tag index. Those get read record by record as each
system above is built.
