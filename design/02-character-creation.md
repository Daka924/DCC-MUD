# Character creation

> **How to change this file.** Edit anything here: change a cell, add a row, delete a row, or just write a
> note in plain words anywhere. This file describes what the game should do. The game itself reads the
> matching file in `data/`, and those two are brought back in line each time you say you have made changes.

A player picks a name, a past life and a starting location. Both picks feed the class generator through their tags
(see `03-classes-and-races.md`). More creation questions (a hobby, a fear, what you were doing when it happened)
would each add tags and widen the range of classes.

## Past lives

The first tag is the group that hand-written classes look for. The "as a describing word" form is used in
generated class names such as "Checkout Pit Boss".

| Id | Name | Tags | As a describing word | As a noun | Starting skills | Perk |
| --- | --- | --- | --- | --- | --- | --- |
| baker | Night-Shift Baker | food, heat, night | Bakery | Baker | brawling 1 | Slowly regenerates health anywhere |
| cashier | Supermarket Cashier | retail, patience, money | Checkout | Cashier | throwing 1 | Every loot box holds one extra item |
| forklift | Warehouse Forklift Driver | warehouse, machines, lifting | Forklift | Forklift Driver | throwing 2 | +25% thrown damage |
| referee | Youth Soccer Referee | sports, rules, loud | Sideline | Referee | brawling 1 | +15% movement speed |
| magician | Failed Stage Magician | performer, tricks, hands | Stage | Magician | throwing 1 | Monsters notice you from 30% less far |
| karaoke | Karaoke Host | performer, loud, night | Karaoke | Karaoke Host | none | +60% viewers |
| plumber | Emergency Plumber | trades, water, tools | Pipe | Plumber | brawling 2 | +20% melee damage |
| nurse | Triage Nurse | medical, night, care | Triage | Nurse | none | Melee hits have a 20% chance to patch up you or an ally |
| accountant | Tax Accountant | office, money, rules | Tax | Accountant | none | +15% experience |
| guard | Mall Security Guard | security, patience, rules | Mall | Security Guard | brawling 1 | +20% health |
| dogwalker | Dog Walker | animals, outdoors, care | Dog-Park | Dog Walker | none | Companions deal +50% damage |
| tinkerer | Garage Tinkerer | tinkerer, tools, machines | Garage | Tinkerer | tinkering 2, throwing 1 | +1.5 throwing range |
| eater | Competitive Eater | food, guts, showoff | Buffet | Eater | none | +25% health |
| courier | Bike Courier | sports, speed, outdoors | Bike-Lane | Courier | none | +20% movement speed |
| dentist | Strip-Mall Dentist | medical, tools, pain | Dental | Dentist | brawling 1 | Melee hits have a 10% chance to stun |
| librarian | Reference Librarian | office, quiet, rules | Library | Librarian | none | Monsters notice you from 25% less far |
| lifeguard | Public Pool Lifeguard | sports, water, care | Poolside | Lifeguard | none | Slowly regenerates health anywhere |
| bouncer | Nightclub Bouncer | security, loud, night | Velvet-Rope | Bouncer | brawling 2 | +15% melee damage |
| florist | Supermarket Florist | retail, hands, care | Floral | Florist | none | +10% experience |
| exterminator | Pest Exterminator | trades, animals, chemicals | Pest-Control | Exterminator | throwing 1 | +15% thrown damage |
| teacher | Substitute Teacher | office, rules, patience, loud | Substitute | Teacher | none | You and nearby allies deal +10% damage |
| mime | Street Mime | performer, quiet, hands, tricks | Silent | Mime | none | Monsters notice you from 40% less far |
| barista | Drive-Through Barista | food, speed, patience | Espresso | Barista | none | +12% movement speed |
| taxidermist | Hobby Taxidermist | animals, hands, guts | Stuffed | Taxidermist | tinkering 1 | Companions deal +30% damage |
| telemarketer | Telemarketer | office, loud, patience | Cold-Call | Telemarketer | none | +40% viewers |
| dj | Wedding DJ | performer, loud, machines, night | Wedding | DJ | none | +30% viewers |

## Starting locations

| # | Name | Tags |
| --- | --- | --- |
| 1 | The Break Room | cautious, food |
| 2 | The Lost Property Office | greedy, office |
| 3 | The Boiler Lounge | heat, machines |
