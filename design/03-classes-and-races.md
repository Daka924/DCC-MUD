# Classes and races

> **How to change this file.** Edit anything here: change a cell, add a row, delete a row, or just write a
> note in plain words anywhere. This file describes what the game should do. The game itself reads the
> matching file in `data/`, and those two are brought back in line each time you say you have made changes.

On arriving at level 3 each player is offered: the classics, up to 6 hand-written classes they qualified for,
up to 6 generated classes, and one joke class if they earned one.

## The class generator

Generated classes are built for one player from tags. Nothing is random and no AI model is involved: the same
history always gives the same offer.

1. **The player's tag profile.** Each tag of the past life counts 3. Each tag of the starting location counts 1.
   Then the hidden dossier is read through the signals table below: what the player did adds weight to tags.
2. **Pick the jobs.** Every job (the noun of the class) has tags. The jobs whose tags weigh most in the profile
   are picked, one after another. After each pick its tags count for less, so the six offers are spread across
   different sides of the player and not six versions of the same thing.
3. **Pick a describing word** for each job the same way, preferring one that says something the job does not.
4. **Name it** by one of the patterns, using the past life's describing form: "Feral Night Manager",
   "Checkout Pit Boss", "Underpaid Checkout Bouncer".
5. **Effects** are the job's, the describing word's and the past life's perk added together. The perk and
   drawback text is written automatically from those effects.
6. **The reason** shown to the player ("Offered because you played with fire, and you used to be a baker")
   comes from the tags that matched.

There are 48 jobs, 33 describing words and 26 past lives, which gives about 42432 possible
combinations. Adding one row to any of the three tables below widens the whole range, and needs no code.

Name patterns: `{adj} {noun}`, `{adj} {past} {noun}`, `{past} {noun}`

### Signals: how behaviour becomes tags

| Dossier counters | Adds weight | Tag | Reason shown to the player |
| --- | --- | --- | --- |
| kills_melee | every 3, up to 4 | brawl | you settled things with your hands |
| throws | every 4, up to 4 | throw | you kept throwing things |
| deaths | every 1, up to 4 | doomed | you kept dying |
| hits_taken | every 6, up to 4 | punished | you got hit a lot |
| close_calls | every 1, up to 4 | lucky | you escaped with almost no health left |
| safe_seconds | every 45, up to 4 | cautious | you spent a long time in safe rooms |
| chats | every 3, up to 4 | loud | you would not stop talking |
| pickups | every 5, up to 4 | greedy | you picked up everything in sight |
| recruits + parties | every 1, up to 4 | social | you did not go it alone |
| kills_above | every 1, up to 4 | bold | you fought things above your level |
| threw_flammable + threw_spark | every 2, up to 4 | fire | you played with fire |
| threw_cold | every 2, up to 4 | cold | you kept throwing cold things |
| threw_toxic | every 2, up to 4 | poison | you threw poison around |
| threw_sticky | every 2, up to 4 | sticky | you glued things to the floor |
| threw_sharp | every 3, up to 4 | sharp | you threw sharp objects |
| threw_heavy | every 3, up to 4 | heavy | you threw heavy objects |
| threw_luminous | every 2, up to 4 | light | you threw glowing things |
| threw_binding | every 2, up to 4 | rope | you tied things up |
| threw_liquid + kills_in_wet | every 3, up to 4 | water | you made a mess in the water |
| killed_vermin + died_to_vermin | every 4, up to 4 | vermin | you spent your time among vermin |
| killed_ooze + died_to_ooze | every 3, up to 4 | slime | you got very familiar with slime |
| killed_construct | every 1, up to 4 | machines | you broke a machine |
| kills | fewer than 4 | pacifist | you barely killed anything |
| recruits + parties | fewer than 1 | loner | you never teamed up with anyone |

Counters the dossier keeps: kills, kills_melee, kills_above, throws, pickups, deaths, hits_taken, close_calls,
safe_seconds, chats, parties, recruits, descents, plus `threw_<item tag>`, `killed_<monster family>`,
`died_to_<monster family>` and `kills_in_<room type>`.

### Jobs (the noun)

| Job | Tags | Effects | Narrator's line |
| --- | --- | --- | --- |
| Arsonist | fire, heat | +25% thrown damage | We are not saying you started the fire. We have footage of you starting the fire. |
| Pit Boss | money, greedy, rules | +1 loot box item; +10% experience | The house always wins. You are not the house, but you dress like it. |
| Bouncer | security, brawl, night | +20% health; 10% chance to stun on melee hits | Your name is not on the list. Nobody's name is on the list. |
| Bonesetter | medical, brawl, pain | 25% chance to heal on melee hits; 10% chance to stun on melee hits | It only hurts until the screaming stops. |
| Plague Vendor | poison, food, chemicals | +20% thrown damage; regenerates 0.3 health per second | Free samples. No refunds. No survivors. |
| Hype Man | loud, performer, social | +80% viewers; you and nearby allies deal +15% damage | You cannot fight, but you can make it sound like someone else can. |
| Hermit | loner, quiet, cautious | monsters notice you from 50% less far; regenerates 0.5 health per second | You came to a televised death game to be left alone. Bold. |
| Pack Rat | greedy, vermin, retail | +2 loot box items | You might need that later. You will not need that later. |
| Ratcatcher | vermin, animals, trades | +20% melee damage; monsters notice you from 20% less far | The rats have a word for you. It is not a nice word. |
| Mop Knight | water, slime, trades | +15% health; +15% melee damage | Sworn to the bucket. Anointed with grey water. |
| Wrangler | animals, social, rope, care | +60% companion damage | You do not fight. You have people for that. Some of them are people. |
| Understudy | doomed, performer, punished | +30% health; +30% viewers | You know every death scene by heart, having rehearsed them all. |
| Crash Test Dummy | punished, doomed, machines | attackers take 3 damage; +20% health | Your job is to be hit so that we may learn from it. We have learned nothing. |
| Sprinter | speed, sports, lucky | +25% movement speed | Courage is a choice. So is leaving quickly. |
| Shot-Putter | heavy, lifting, throw, sports | +30% thrown damage; +1 throwing range | Technique is everything. Aim is more of a suggestion. |
| Knife Juggler | sharp, tricks, hands, throw | +35% thrown damage | Most of them were caught. By something. |
| Lamplighter | light, night, quiet | monsters notice you from 40% less far; +10% experience | You bring light to dark places, then stand well away from it. |
| Ice Cream Man | cold, food, loud | +15% thrown damage; +40% viewers | The jingle is the last thing they hear. |
| Glue Sniffer | sticky, chemicals, guts | +15% health; +15% thrown damage | You are stuck with this. And to this. |
| Knot Enthusiast | rope, patience, hands | +2 throwing range; 10% chance to stun on melee hits | There is a knot for every occasion, and you will describe each one. |
| Loss Adjuster | office, money, rules, cautious | +25% experience | You have assessed the damage. The damage is you. |
| Human Shield | punished, care, security, social | +35% health; you and nearby allies deal +10% damage | Somebody has to stand at the front. Everybody else voted. |
| Coward | pacifist, lucky, cautious, speed | +20% movement speed; monsters notice you from 50% less far | Alive, which is more than the brave ones can say. |
| Conscientious Objector | pacifist, rules, quiet | +30% experience; regenerates 0.5 health per second | You object. It has been noted. Nothing will change. |
| Daredevil | bold, lucky, showoff | +20% melee damage; +50% viewers | No helmet, no plan, excellent ratings. |
| Giant-Killer | bold, brawl, heavy | +30% melee damage | The bigger they are, the longer the paperwork. |
| Line Cook | food, heat, speed, hands | +15% melee damage; +10% movement speed | Fourteen orders behind and armed. Stay out of the kitchen. |
| Grease Monkey | machines, tools, tinkerer | +15% thrown damage; +1 throwing range; attackers take 1 damage | If it moves, you can break it. If it does not, you already did. |
| Scrap Baron | machines, greedy, warehouse, lifting | +1 loot box item; +15% health | One crawler's trash is still trash, but now it is yours. |
| Sewer Lifeguard | water, care, outdoors | regenerates 1 health per second; 15% chance to heal on melee hits | No running. No diving. No hope. |
| Leech Farmer | slime, medical, patience | 30% chance to heal on melee hits; regenerates 0.4 health per second | They are not parasites. They are colleagues. |
| Pallbearer | doomed, night, lifting, quiet | +25% health; +10% melee damage | You have carried heavier. Usually yourself. |
| Heckler | loud, showoff, throw | +60% viewers; +15% thrown damage | Everyone is a critic. You are the one with projectiles. |
| Cage Fighter | brawl, sports, guts, pain | +25% melee damage; +10% health | There is no cage. You asked for one anyway. |
| Street Dentist | pain, tools, medical, sharp | 25% chance to stun on melee hits; +10% melee damage | This will not hurt a bit. It will hurt all of it. |
| Card Sharp | tricks, money, lucky | +1 loot box item; monsters notice you from 30% less far | Pick a card. Any card. Now run. |
| Tour Guide | outdoors, social, loud, patience | you and nearby allies deal +20% damage; +10% movement speed | On your left, certain death. On your right, the gift shop. |
| Night Manager | night, retail, rules, patience | +15% experience; regenerates 0.5 health per second | You would like to speak to yourself. You are unavailable. |
| Taste Tester | guts, food, poison | +30% health; regenerates 0.3 health per second | If you are still standing, it is probably fine. |
| Stuntman | showoff, punished, speed | attackers take 2 damage; +15% movement speed; +30% viewers | Do not try this at home. Try it here, where we can film it. |
| Bin Diver | greedy, sticky, guts | +1 loot box item; regenerates 0.4 health per second | Dinner and a show, from the same bin. |
| Fire Marshal | fire, rules, security | +20% health; +15% thrown damage | You know every fire code. You are in breach of all of them. |
| Mail Carrier | cold, outdoors, speed | +15% movement speed; +10% health | Neither snow nor rain nor an audience of millions. |
| Spotlight Operator | light, performer, tools | +50% viewers; 15% chance to stun on melee hits | You make other people look good. Briefly. Then blind. |
| Mascot Wrangler | animals, performer, care | +40% companion damage; +30% viewers | The thing in the costume is not your friend, but it is on your payroll. |
| Bucket Brigadier | water, lifting, social | you and nearby allies deal +15% damage; +10% health | Many hands make light work. You brought the bucket. |
| Quiet Car Enforcer | quiet, rules, pain | 20% chance to stun on melee hits; monsters notice you from 30% less far | Shh. That was your warning. |
| Complaints Desk | patience, office, punished | attackers take 2 damage; +15% experience | Your suffering is important to us. Please hold. |

### Describing words

| Word | Tags | Effects |
| --- | --- | --- |
| Feral | brawl, animals | +15% melee damage; -25% thrown damage |
| Littering | throw | +15% thrown damage; -25% melee damage |
| Twice-Dead | doomed | +15% health; -10% experience |
| Jittery | lucky, speed | +10% movement speed; -15% health |
| Chatty | loud | +50% viewers; monsters notice you from 40% further |
| Loitering | cautious | regenerates 0.5 health per second; -10% movement speed |
| Hoarding | greedy | +1 loot box item; -10% movement speed |
| Clingy | social | +30% companion damage; -10% health |
| Singed | fire, heat | +15% thrown damage; -10% health |
| Damp | water, slime | regenerates 0.4 health per second; -8% movement speed |
| Frostbitten | cold | +10% health; -10% movement speed |
| Sticky-Fingered | sticky, tricks | +1 loot box item; -15% melee damage |
| Toxic | poison, chemicals | attackers take 2 damage; -10% health |
| Bruised | punished, pain | attackers take 2 damage; -8% movement speed |
| Reckless | bold | +20% melee damage; -15% health |
| Squeamish | pacifist | monsters notice you from 40% less far; -20% melee damage |
| Unsupervised | loner | +15% experience; -50% companion damage |
| Overqualified | office, rules, medical | +20% experience; -30% viewers |
| Underpaid | retail, trades, warehouse | +1 loot box item; -10% experience |
| Sleep-Deprived | night | +10% movement speed; monsters notice you from 30% further |
| Televised | showoff, performer | +60% viewers; -10% health |
| Rat-Bitten | vermin | monsters notice you from 20% less far; -8% health |
| Rust-Proof | machines, tools, tinkerer | +12% health; -7% movement speed |
| Heavy-Handed | heavy, lifting | 12% chance to stun on melee hits; -10% movement speed |
| Prickly | sharp | attackers take 1.5 damage; -20% viewers |
| Tangled | rope | +1.5 throwing range; -8% movement speed |
| Glowing | light | +30% viewers; monsters notice you from 40% further |
| Well-Fed | food, guts | +20% health; -10% movement speed |
| Patient | patience, quiet | regenerates 0.6 health per second; -10% melee damage |
| Nimble | hands, sports | +12% movement speed; -10% health |
| Outdoorsy | outdoors | regenerates 0.3 health per second; -20% viewers |
| Thrifty | money | +1 loot box item; -10% health |
| Bandaged | care, security | 15% chance to heal on melee hits; -10% melee damage |

### Effects that exist today

A job or describing word can use any of these without new code: melee damage, thrown damage, throwing range,
health, movement speed, experience, viewers, how far away monsters notice you, a damage boost for nearby allies,
chance to stun on a melee hit, chance to heal on a melee hit, regeneration, damage reflected to attackers,
extra loot box items, companion damage. Anything else (a summon, a transformation, a spell, a signature move)
is new work. Write the idea anyway; that is how the list of effects should grow.

## Hand-written classes

| Id | Name | Kind | Offered when | Stats | Perk | Drawback | Narrator's line |
| --- | --- | --- | --- | --- | --- | --- | --- |
| bruiser | Bruiser | classic | always | +2 Str, +1 Con | +25% melee damage | -20% thrown damage | You hit things. It is not a personality, but it is a plan. |
| slinger | Slinger | classic | always | +2 Dex | +30% thrown damage and +1 range | -10% health | Everything is a projectile if you believe in yourself. |
| hedge_medic | Hedge Medic | classic | always | +1 Int, +1 Con | Melee hits may heal; slow regeneration | -15% melee damage | Unqualified, uninsured, and the best they have got. |
| sneak | Sneak | classic | always | +2 Dex | Monsters notice you from half as far | -20% health | Brave of you to choose a class about not being seen on a television show. |
| coupon_paladin | Coupon Paladin | past | past life group: retail; pickups at least 6 | +1 Str, +1 Cha | One extra item in every loot box; +15% melee damage | -10% experience (you keep stopping to check prices) | A holy warrior of the clearance aisle. |
| karaoke_warlord | Karaoke Warlord | past | past life group: performer | +3 Cha | Double viewers; you and nearby allies deal +15% damage | Monsters hear you from 60% further away | Nobody asked for an encore. You are doing one anyway. |
| forklift_savant | Night-Shift Forklift Savant | past | past life group: warehouse | +2 Str | +40% thrown damage and +2 range | -15% movement speed | Certified to lift. Not certified to throw. And yet. |
| night_baker | Dough Sergeant | past | past life group: food | +2 Con | Strong regeneration; +10% health | -10% movement speed | You have been awake since 3 a.m. for nine years. Nothing here scares you. |
| whistle_tyrant | Whistle Tyrant | past | past life group: sports | +1 Dex, +1 Cha | +20% speed; melee hits may stun | -10% health | You once red-carded a nine-year-old. The dungeon respects that. |
| chiropractor | Unlicensed Chiropractor | behaviour | kills_melee at least 6 | +1 Str, +1 Int | Melee hits often stun and sometimes heal | -15% health | You have adjusted a lot of spines today. None of them consented. |
| bystander | Professional Bystander | behaviour | kills at most 3 | +1 Cha | Monsters barely notice you; +20% experience | -40% health | Two levels survived and almost nothing killed. Impressive, in a way we cannot air. |
| dumpster_alchemist | Dumpster Alchemist | behaviour | throws at least 6 | +2 Int | Can combine up to three items into one throw and invent named concoctions from what works | -30% melee damage | You kept throwing garbage at problems until one of them exploded. We made it official. |
| hall_monitor | Volunteer Hall Monitor | behaviour | parties at least 1 | +1 Con, +1 Cha | You and nearby allies deal +20% damage; slow regeneration | -20% thrown damage | Nobody elected you. You brought your own sash. |
| disgraced_mascot | Disgraced Mascot | joke | deaths at least 2 | +2 Con, +2 Cha | +40% health and +50% viewers | Every monster wants you first; -20% melee damage | You have died so often the audience made you a costume. |
| human_pinata | Human Pinata | joke | hits_taken at least 15 | +1 Con | Things that bite you get hurt; two extra items in every loot box | -30% health and monsters love you | Hit you enough and prizes fall out. We checked. |

## Races

| Id | Name | Offered when | Stats | Effects | Description |
| --- | --- | --- | --- | --- | --- |
| human | Stay as you are | always | none | none | No changes. Most crawlers keep their own body. |
| gutterkin | Gutterkin | always | +2 Dex, -1 Con | +10% movement speed | Wiry tunnel folk. +2 Dexterity, -1 Constitution, +10% speed. |
| slabfolk | Slabfolk | always | +3 Con, -2 Dex | none | Walking masonry. +3 Constitution, -2 Dexterity. |
| glimmerling | Glimmerling | always | +3 Cha, -2 Str | +30% viewers | Faintly luminous and very watchable. +3 Charisma, -2 Strength, +30% viewers. |
| mossback | Mossback | always | +1 Int, +1 Con | regenerates 0.4 health per second; -10% movement speed | Slow, damp and hard to kill. +1 Intelligence, +1 Constitution, slow regeneration, -10% speed. |
| ratblood | Rat-Blooded | kills at least 10 | +1 Dex, +1 Str | monsters notice you from 20% less far | Unlocked by killing ten things. The vermin have started to respect you. +1 Strength, +1 Dexterity, monsters notice you less. |

## Your class ideas

For each idea: a name, who should be offered it, what it does, its catch, and the narrator's line if you have one.
