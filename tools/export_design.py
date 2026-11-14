#!/usr/bin/env python3
"""Writes the design/ files from the game data, so the design files start out
matching the game. Existing files are left alone unless --force is given,
because the design files are meant to be edited by hand afterwards."""
import json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FORCE = "--force" in sys.argv

def data(name):
    with open(os.path.join(ROOT, "data", name + ".json")) as f:
        return json.load(f)

def table(headers, rows):
    out = ["| " + " | ".join(headers) + " |", "| " + " | ".join("---" for _ in headers) + " |"]
    for r in rows:
        out.append("| " + " | ".join(str(c).replace("|", "/") for c in r) + " |")
    return "\n".join(out)

STAT = {"str": "Str", "dex": "Dex", "con": "Con", "int": "Int", "cha": "Cha"}
def stats(d):
    return ", ".join("%+d %s" % (v, STAT[k]) for k, v in d.items()) or "none"

PCT = {"melee_mult": "melee damage", "throw_mult": "thrown damage", "hp_mult": "health", "speed_mult": "movement speed",
       "xp_mult": "experience", "viewers_mult": "viewers", "companion_mult": "companion damage"}
def effects(m):
    out = []
    for k, v in m.items():
        if k in PCT: out.append("%+d%% %s" % (round((v - 1) * 100), PCT[k]))
        elif k == "aggro_mult": out.append("monsters notice you from %d%% %s" % (abs(round((v - 1) * 100)), "less far" if v < 1 else "further"))
        elif k == "party_aura": out.append("you and nearby allies deal +%d%% damage" % round((v - 1) * 100))
        elif k == "stun_chance": out.append("%d%% chance to stun on melee hits" % round(v * 100))
        elif k == "heal_on_melee": out.append("%d%% chance to heal on melee hits" % round(v * 100))
        elif k == "regen": out.append("regenerates %g health per second" % v)
        elif k == "thorns": out.append("attackers take %g damage" % v)
        elif k == "box_extra_roll": out.append("+%d loot box item%s" % (v, "" if v == 1 else "s"))
        elif k == "throw_range": out.append("+%g throwing range" % v)
        elif k == "crafting": out.append("can combine items into inventions")
    return "; ".join(out) or "none"

def needs(c):
    out = []
    if c.get("needs_past"): out.append("past life group: " + " or ".join(c["needs_past"]))
    for k, v in c.get("needs", {}).items(): out.append("%s at least %g" % (k, v))
    for k, v in c.get("needs_max", {}).items(): out.append("%s at most %g" % (k, v))
    return "; ".join(out) or "always"

HOW = """> **How to change this file.** Edit anything here: change a cell, add a row, delete a row, or just write a
> note in plain words anywhere. This file describes what the game should do. The game itself reads the
> matching file in `data/`, and those two are brought back in line each time you say you have made changes.
"""

def write(name, text):
    path = os.path.join(ROOT, "design", name)
    if os.path.exists(path) and not FORCE:
        print("kept     design/" + name)
        return
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(text.rstrip() + "\n")
    print("wrote    design/" + name)

def identity():
    return """# Identity and world

Nothing here is decided. The right-hand column is yours.

| Item | Current stand-in | Your answer |
| --- | --- | --- |
| Game name | Crawl Show |  |
| Name of the show inside the world | none |  |
| Narrator: name and what it is | unnamed, sardonic announcer |  |
| Narrator: voice in three adjectives | dry, corporate, mocking |  |
| World premise: who built the dungeon, why it is televised, who watches | none; the setting is a shabby back-of-house facility |  |
| Where the crawlers come from | ordinary present-day people with ordinary jobs |  |
| Tone limits: how dark, how crude, anything off the table | dark comedy, no gore detail |  |

## Notes

Write anything else about the world here.
"""

def rules():
    return "# Core rules\n\n" + HOW + """
Most of these numbers live in the game's code, not in a data file, so a change here means a small code change.
That is fine and expected. Write the rule the way you want it to play.

## Flow of a run

1. Create a character: name, past life, starting location.
2. Arrive alone in a safe room on level 1. A companion waits there and can be recruited.
3. Levels 1 and 2: no class. A hidden dossier counts what you do. Stat points are saved up and cannot be spent.
4. On arriving at level 3 the show presents a personal list of races and classes, with 120 seconds to choose.
   If time runs out, the first of each is chosen.
5. After choosing, saved stat points can be spent in safe rooms.

## Stats

Every character starts with 4 in each stat and gains 3 points per level.

| Stat | What it does now | How you want it |
| --- | --- | --- |
| Strength | +8% melee damage per point above 4 |  |
| Dexterity | +6% thrown damage and +2% movement speed per point above 4 |  |
| Constitution | +5 health per point |  |
| Intelligence | Sets mana (3 per point). Nothing uses mana yet |  |
| Charisma | +10% viewers per point above 4 |  |

## Numbers

| Rule | Now | How you want it |
| --- | --- | --- |
| Health | 20 + 5 per Constitution + 4 per level above 1, then class and race multipliers |  |
| Experience to next level | 20 x level to the power 1.5 (20, 57, 104, 160 ...) |  |
| Melee | 4 damage, reach 1.3 tiles, one swing every 0.45 seconds |  |
| Throwing | Range 7 tiles, one throw every 0.5 seconds |  |
| Movement | 4 tiles per second |  |
| Monsters notice you from | 5 tiles |  |
| Monster toughness | +60% health per level down |  |
| Monsters and items return after | 20 and 25 seconds |  |
| Death | Back at your arrival point after 5 seconds at full health. No lasting penalty |  |
| Level timer runs out | The level resets and everyone on it returns to their arrival point |  |
| Safe rooms | No fighting, heal 3 health per second, loot boxes open here, stat points are spent here |  |
| Party | Shared experience within 10 tiles |  |
| Viewers | Rise with kills, deaths, discoveries, teaming up and descending; fade over time. They do nothing yet |  |
| Skills | Brawling, throwing, tinkering, set by past life. Throwing adds 5% thrown damage per level. Skills do not train yet |  |
| Past life perk | Not active on levels 1 and 2. It becomes part of any generated class |  |

## Not in the game yet

Spells and mana use, equipment, shops and gold, sponsors and the leaderboard, bosses, pets, personal spaces,
player-versus-player, specialisations, saving progress.

## Your rules

Write how you want the game to play here, in any form.
"""

def creation():
    pl = data("past_lives")["past_lives"]
    starts = data("floors")["floors"][0]
    rows = [(p["id"], p["name"], ", ".join(p["tags"]), p["adj"], p["noun"],
             ", ".join("%s %d" % (k, v) for k, v in p["skills"].items()) or "none", p["perk"]) for p in pl]
    srows = [(i + 1, n, ", ".join(starts.get("start_tags", [[]] * 9)[i])) for i, n in enumerate(starts["starts"])]
    return "# Character creation\n\n" + HOW + """
A player picks a name, a past life and a starting location. Both picks feed the class generator through their tags
(see `03-classes-and-races.md`). More creation questions (a hobby, a fear, what you were doing when it happened)
would each add tags and widen the range of classes.

## Past lives

The first tag is the group that hand-written classes look for. The "as a describing word" form is used in
generated class names such as "Checkout Pit Boss".

""" + table(["Id", "Name", "Tags", "As a describing word", "As a noun", "Starting skills", "Perk"], rows) + """

## Starting locations

""" + table(["#", "Name", "Tags"], srows) + "\n"

def classes():
    cl = data("classes"); parts = data("class_parts"); races = data("races")["races"]
    rrows = [(r["id"], r["name"], needs(r), stats(r["stats"]), effects(r["mods"]), r["text"]) for r in races]
    crows = [(c["id"], c["name"], c["family"], needs(c), stats(c["stats"]), c["perk"], c["drawback"], c["quip"]) for c in cl["classes"]]
    srows = []
    for s in parts["signals"]:
        keys = " + ".join(s["keys"])
        rule = ("fewer than %g" % s["below"]) if "below" in s else ("every %g, up to %g" % (s["per"], s["cap"]))
        srows.append((keys, rule, s["tag"], s["why"]))
    corows = [(c["noun"], ", ".join(c["tags"]), effects(c["mods"]), c["quip"]) for c in parts["cores"]]
    trows = [(t["adj"], ", ".join(t["tags"]), effects(t["mods"])) for t in parts["twists"]]
    n_past = len(data("past_lives")["past_lives"])
    ap = data("ability_parts")
    frows = [(k, v["does"].replace("{power}", str(v.get("power", ""))).replace("{duration}", "%g" % v.get("duration", 0)),
              "%ds" % v["cooldown"], v["mana"], "; ".join(", ".join(n) for n in v["nouns"].values())) for k, v in ap["functions"].items()]
    drows = [(k, v["says"], ("%g tiles" % v["range"]) if v["range"] else "around you", "x%g" % v["radius_mult"], "x%g" % v["power_mult"]) for k, v in ap["deliveries"].items()]
    axrows = []
    for axis, key in (("Function", "tag_function"), ("Delivery", "tag_delivery"), ("Cost", "tag_cost")):
        groups = {}
        for t, v in ap[key].items(): groups.setdefault(v, []).append(t)
        for v, ts in groups.items(): axrows.append((axis, v, ", ".join(ts)))
    return "# Classes and races\n\n" + HOW + """
On arriving at level 3 each player is offered: the classics, up to %d hand-written classes they qualified for,
up to %d generated classes, and one joke class if they earned one.

## The class generator

Generated classes are built for one player from tags. Nothing is random and no AI model is involved: the same
history always gives the same offer.

1. **The player's tag profile.** Each tag of the past life counts %g. Each tag of the starting location counts %g.
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

There are %d jobs, %d describing words and %d past lives, which gives about %d possible
combinations. Adding one row to any of the three tables below widens the whole range, and needs no code.

Name patterns: %s

### Signals: how behaviour becomes tags

""" % (cl["offer"]["hand_written_max"], cl["offer"]["generated_max"], parts["past_weight"], parts["start_weight"],
       len(parts["cores"]), len(parts["twists"]), n_past, len(parts["cores"]) * (len(parts["twists"]) + 1) * n_past,
       ", ".join("`%s`" % p for p in sorted(set(parts["patterns"])))) + \
        table(["Dossier counters", "Adds weight", "Tag", "Reason shown to the player"], srows) + """

Counters the dossier keeps: kills, kills_melee, kills_above, throws, pickups, deaths, hits_taken, close_calls,
safe_seconds, chats, parties, recruits, descents, plus `threw_<item tag>`, `killed_<monster family>`,
`died_to_<monster family>` and `kills_in_<room type>`.

### Jobs (the noun)

""" + table(["Job", "Tags", "Effects", "Narrator's line"], corows) + """

### Describing words

""" + table(["Word", "Tags", "Effects"], trows) + """

### Signature abilities

Every generated class comes with one ability, built along the axes of the research reference: what it does
(function), how it arrives (delivery), its element or manner (flavour) and what it costs. The class's own tags
choose a value on each axis, weighed by the player's profile, and a player's six offers are pushed toward
different functions. The name is a flavour word plus a function word, for example "Scorching Fumigation" or
"Itemised Flop". In play it is used with Q, spends mana (Intelligence x 3, refilling over 40 seconds) and has a
cooldown. Intelligence adds 6% power per point above 4. Hand-written classes do not have abilities yet.

""" + table(["Function", "What it does", "Cooldown", "Mana", "Words used in names"], frows) + """

""" + table(["Delivery", "How it arrives", "Reach", "Area", "Power"], drows) + """

""" + table(["Cost", "What you pay", "Power"], [(k, v["says"].replace("{mana}", "its"), "%+d%%" % round((v.get("power_mult", 1) - 1) * 100)) for k, v in ap["costs"].items()]) + """

Which tags pull toward which value:

""" + table(["Axis", "Value", "Tags"], axrows) + """

Flavours that add an effect to attacks: """ + ", ".join("%s (%s)" % (k, v["status"]["says"].split(" for ")[0]) for k, v in ap["flavours"].items() if "status" in v) + """.
Every other tag has two flavour words of its own and no extra effect; they are listed in `data/ability_parts.json`.

### Effects that exist today

A job or describing word can use any of these without new code: melee damage, thrown damage, throwing range,
health, movement speed, experience, viewers, how far away monsters notice you, a damage boost for nearby allies,
chance to stun on a melee hit, chance to heal on a melee hit, regeneration, damage reflected to attackers,
extra loot box items, companion damage. Anything else (a summon, a transformation, a spell, a signature move)
is new work. Write the idea anyway; that is how the list of effects should grow.

## Hand-written classes

""" + table(["Id", "Name", "Kind", "Offered when", "Stats", "Perk", "Drawback", "Narrator's line"], crows) + """

## Races

""" + table(["Id", "Name", "Offered when", "Stats", "Effects", "Description"], rrows) + """

## Your class ideas

For each idea: a name, who should be offered it, what it does, its catch, and the narrator's line if you have one.
"""

def levels():
    fl = data("floors")["floors"]
    out = "# Levels\n\n" + HOW + """
Levels are drawn as text, one character per tile. You can sketch a level in any text editor or on grid paper.

| Character | Meaning |
| --- | --- |
| # | Wall |
| . | Open floor |
| , | Narrow doorway |
| ~ | Flooded floor |
| S | Safe room floor |
| 1 2 3 | Starting locations (level 1 only) |
| P | Arrival point from the stairs above |
| N | Companion |
| > | Stairs down |
| m | Monster (rat on dry floor, leech in water) |
| G | Large monster |
| i | Item spawn (random item) |

"""
    for i, f in enumerate(fl):
        out += "## Level %d: %s\n\nTimer: %d minutes." % (i + 1, f["name"], f["timer_seconds"] // 60)
        if f.get("starts"): out += " Starting locations: " + ", ".join(f["starts"]) + "."
        out += "\n\n```\n" + "\n".join(f["map"]) + "\n```\n\n"
    out += """## Set pieces

For each place you have in mind:

| Field | What to write |
| --- | --- |
| Name | What the show calls it |
| Level | Which level it is on, or "any" |
| Look | What the place looks like |
| The twist | The rule that makes this place different |
| Creatures | What lives there |
| Boss or goal | What ends it |
| Reward | What a crawler gets for finishing |

## Your level ideas

"""
    return out

def things():
    items = data("items"); mobs = data("mobs"); comp = data("companions")["companions"]; tr = data("tag_rules")
    starts = data("floors")["floors"][0]["starts"]
    irows = [(k, v["name"], ", ".join(v["tags"])) for k, v in items.items()]
    mrows = [(k, v["name"], v["family"], v["level"], v["hp"], v["damage"], v["speed"], v["xp"], "large" if v["size"] > 1 else "small") for k, v in mobs.items()]
    crows = [(c["id"], c["name"], starts[i] if i < len(starts) else "", c["blurb"], c["damage"], c["join"], c["leave"]) for i, c in enumerate(comp)]
    erows = [(e["id"], " and ".join(e["all"]) or "any item", e["kind"], e["power"], e.get("duration", ""), e.get("radius", "")) for e in tr["effects"]]
    return "# Monsters, items and companions\n\n" + HOW + """
## Items

All items are throwable junk. There is no equipment, food, potion or gold yet. Tags decide what an item does when
thrown, and what the class generator learns about a player who throws it.

""" + table(["Id", "Name", "Tags"], irows) + """

### What tags do when thrown

""" + table(["Effect", "Needs tags", "Kind", "Power", "Seconds", "Radius"], erows) + """

Only the Dumpster Alchemist class can combine items and invent named abilities from them.

## Monsters

Values are for level 1. Health grows 60% per level down. Monsters only walk at the nearest player and bite.

""" + table(["Id", "Name", "Family", "Level", "Health", "Damage", "Speed", "Experience", "Sprite"], mrows) + """

## Companions

One waits in each starting safe room, follows a solo player, and leaves when the player teams up with a real player.

""" + table(["Id", "Name", "Waits at", "Who they are", "Damage", "Says when joining", "Says when leaving"], crows) + """

## Your creatures, items and characters

"""

def show():
    ach = data("achievements"); boxes = data("boxes"); nar = data("narrator"); items = data("items")
    arows = [(a["id"], "%s reaches %d" % (a["event"], a["count"]), a["title"], a["text"], a["box"]) for a in ach]
    brows = [(k, v["name"], v["rolls"], ", ".join("%s (%d)" % (items[i]["name"], w) for i, w in v["table"].items())) for k, v in boxes.items() if k != "_doc"]
    nrows = [(k, " / ".join(v)) for k, v in nar.items() if isinstance(v, list)]
    qrows = [(k, " / ".join(v)) for k, v in nar["quips"].items()]
    return "# The show: achievements, loot boxes and the narrator\n\n" + HOW + """
## Achievements

Each fires once per player when a dossier counter reaches a number, and awards a loot box that opens in the next
safe room.

""" + table(["Id", "Earned when", "Title", "Narrator text", "Box"], arows) + """

## Loot boxes

The number after each item is its weight: higher turns up more often.

""" + table(["Id", "Name", "Items inside", "Possible contents"], brows) + """

## Narrator lines

Words in curly brackets are filled in by the game. Separate alternatives with " / "; one is picked at random.

""" + table(["Event", "Lines"], nrows) + """

Lines added to an invented ability, by what it does:

""" + table(["Ability kind", "Lines"], qrows) + """

Events with no line yet: entering a safe room, opening a loot box, a near-death escape, killing a large monster,
long stretches of doing nothing, viewer milestones, spending stat points, timer warnings.

## Your lines and achievements

"""

def art():
    return """# Art

## Turning your pictures into sprites

1. Save a picture into the right folder inside `art_inbox`, named after the thing it is for.
2. Double-click `make_sprites.bat` in the project folder.
3. Start the game. Anything that now has a sprite uses it. Everything else keeps its placeholder shape.

That is the whole routine. Run it as often as you like; it redoes every picture each time.

### What the conversion does

For each picture it removes a plain background (if the four corners are one flat colour), trims the empty border,
shrinks the picture to the sprite size for its folder, stands it on the bottom centre of the frame, and saves it to
`art/`. It also saves an editable Aseprite copy in `art_src/` for hand clean-up later. A report of what it made is
shown at the end and saved as `art_inbox/last_run.txt`.

If you add a file called `palette.png` to `art_inbox` (a small image containing every colour you want the game to
use), every sprite is snapped to those colours.

If you clean a sprite up by hand in Aseprite, save it as `.aseprite` into the same `art_inbox` folder. Aseprite
files are treated as finished and exported exactly as they are.

### Folders, names and sizes

| Folder in art_inbox | Name the file | Sprite size | Notes |
| --- | --- | --- | --- |
| tiles | floor, safe, water, doorway, stairs | 64 x 32 | A square picture of the ground is laid flat into the diamond shape for you. Types without a picture use `floor` |
| tiles | wall | 64 x 58 | A front view of a wall block |
| players | default | 64 x 64 | One look for every player for now |
| npcs | dolores, gus, vex, or default | 64 x 64 | The companion's name in lower case |
| mobs | sump_rat, drain_leech | 64 x 64 | The monster's id |
| mobs_large | scrap_golem | 128 x 128 | The monster's id |
| items | oil_flask, rag, flint ... | 24 x 24 | The item's id |
| pets, fx | anything | 48 x 48, 64 x 32 | Converted and kept, not shown in the game yet |

Ids are in the tables in `05-monsters-items-companions.md`. Names are not case sensitive, and spaces become
underscores.

### Limits to know about

- One still picture per thing. Walking and attacking animation, and separate pictures per facing direction, are
  not read yet.
- Sprites are small. A detailed painting shrunk to 64 x 64 loses most of its detail, so bold shapes, thick dark
  outlines and few colours work best.
- The background is only removed when it is one flat colour that reaches all four corners.

## Getting to the target look

The style target (the dungeon mock-up from 14 November) reads as: isometric stone floor, chunky characters with
big heads and thick dark outlines, about 52 logical pixels tall, a dark warm palette with a few hot accents
(lava orange, slime green, cold blue flame). Two things about it matter for the pipeline. It is not true pixel
art: it has about 125,000 colours and no clean pixel grid, which is normal for an image model. And it is one
picture, where a game needs every character from several angles in several poses.

What was researched (November 2026): a comparison guide of current AI sprite tools, three write-ups by developers
using Google's image model for sprites and animation, an independent trial of PixelLab, the Retro Diffusion
developer's own answers, and three open-source clean-up tools. Reddit itself could not be read directly, so this
rests on those write-ups, not on the threads. Several sources are vendors and are treated as claims.

### What works and what does not

| Approach | Reported result |
| --- | --- |
| Asking an image model for a whole sprite sheet in one go | Fails for characters: size jumps between frames, limbs vanish, choppy motion |
| Separate prompts per frame with the same reference picture | No real consistency control. Works for idle and walk with heavy re-rolling; attack combos fall apart |
| Relying on a seed or a prompt to keep a character the same | Does not hold |
| Each frame made as an edit of one fixed base picture, same scale and position, on a green screen | The most reliable do-it-yourself method. Slow: one frame at a time |
| A tool built for it: PixelLab (rotates one character to 4 or 8 directions, animates on a skeleton) | The only tool that does directions and animation as a feature. A trial found the 8 directions at 64 pixels clean, the walk stiff. Reports of props changing between directions and weak back views |
| Retro Diffusion inside Aseprite | Good single sprites and tiles in true pixel art, one-time price, runs on your graphics card. Its developer says it cannot do animation or keep a character consistent across poses |
| Cleaning any AI picture into true pixel art | Solved, and free: find the fake pixel grid, snap to it, lock the palette, cut out the background |

### Recommended pipeline: two lanes

**Lane 1, things that do not move** (floor, walls, props, items, UI frames, portraits). Use the image tool you
already use, give it the style target as a reference, ask for one thing on a plain green background, and drop the
result in `art_inbox`. The conversion then snaps it to a real pixel grid, locks it to the palette and removes the
background. This lane is cheap and you can start today.

**Lane 2, things that move** (the player, companions, monsters). Use PixelLab at 64 x 64: make one good
south-east-facing character, have it rotate that to 8 directions, then animate idle, walk and attack. Clean up
the stiff or wrong frames by hand in Aseprite, or re-roll them. It costs from about 12 dollars a month after a
free trial of 40 generations, and it can be driven from here once you have an account key, so you would not have
to click through it yourself.

If you would rather not pay for a tool, the fallback for Lane 2 is the base-picture method with your image tool.
It works but takes far longer per character.

A third route is worth knowing about because it is how the original Diablo games were made: build or generate a
3D model, play stock animations on it, and photograph it from 8 angles into small sprites. It gives perfect
consistency across directions and frames. It was not part of this research, so treat it as an option to test
later, not a recommendation.

### How many frames this really is

With east-facing frames mirrored from west, 8 directions need 5 drawn. Idle 4, walk 6 and attack 4 frames is 14
per direction, so 70 frames for one fully animated character. To keep that under control: 8 directions for
players and companions only, 4 directions for monsters (2 drawn), and idle, walk and attack only at first.

### First test: Vex

Vex, the boiler technician companion, is the best first candidate. Vex is a humanoid (which is what the animation
tools are built for), has one prop (a wrench, which tests whether props survive the turn to other directions), is
already in the game, and is lower stakes than the player character.

1. One floor tile and one wall block through Lane 1. This fixes the palette and proves the clean-up.
2. Vex standing, facing south-east, at 64 x 64, until the look matches the target.
3. Vex rotated to 8 directions.
4. Vex walking, 6 frames, in one direction, then all directions.

It passes if the wrench stays the same in every direction, the outline does not wobble when frames are laid over
each other, it uses only palette colours, and Vex reads clearly standing on the floor tile at normal game size.

### What changes in the game for this

- Sprite sizes are now 64 x 64 for characters and small monsters, 128 x 128 for large monsters, 24 x 24 for items.
- `art_inbox/palette_from_style_target.png` holds 48 colours taken from the style target. Rename it to
  `palette.png` to make the conversion lock every sprite to it.
- Still to build: reading animation strips and facing directions, and snapping fake pixel grids during conversion.

## Decisions for you

| Question | Your answer |
| --- | --- |
| Palette: about 32 colours, grimy dungeon with neon pink, cyan and yellow kept for the show's UI? |  |
| How many player looks should character creation offer at first? |  |
| Should each race get its own sprite, or a recolour of the player sprite to start? |  |
| Are the sprite sizes above right for your style? |  |
"""

def readme():
    return """# Design files

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
| `08-reference-to-game.md` | How the research reference maps onto the game, with proposed changes for you to accept or reject |

## How changes reach the game

The game reads the files in `data/`. These design files are the readable version. When you have edited any of
them, say so, and the differences are carried into `data/` (or into code, for rules that are not data yet).
You can edit them on GitHub in the browser with the pencil button, or in any text editor on your computer.

You do not need to keep the tables tidy. A sentence such as "dying on level 1 should be permanent" anywhere in the
right file is enough.

The starting contents were written out from the game's data by `tools/export_design.py`.
"""

write("README.md", readme()); write("00-identity.md", identity()); write("01-core-rules.md", rules())
write("02-character-creation.md", creation()); write("03-classes-and-races.md", classes()); write("04-levels.md", levels())
write("05-monsters-items-companions.md", things()); write("06-show.md", show()); write("07-art.md", art())
