# Art

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
| players | default | 32 x 48 | One look for every player for now |
| npcs | dolores, gus, vex, or default | 32 x 48 | The companion's name in lower case |
| mobs | sump_rat, drain_leech | 32 x 32 | The monster's id |
| mobs_large | scrap_golem | 64 x 64 | The monster's id |
| items | oil_flask, rag, flint ... | 16 x 16 | The item's id |
| pets, fx | anything | 32 x 32, 64 x 32 | Converted and kept, not shown in the game yet |

Ids are in the tables in `05-monsters-items-companions.md`. Names are not case sensitive, and spaces become
underscores.

### Limits to know about

- One still picture per thing. Walking and attacking animation, and separate pictures per facing direction, are
  not read yet.
- Sprites are small. A detailed painting shrunk to 32 x 48 loses most of its detail, so bold shapes and few
  colours work best. If you want bigger sprites, say so and the sizes can change in one place.
- The background is only removed when it is one flat colour that reaches all four corners.

## Decisions for you

| Question | Your answer |
| --- | --- |
| Palette: about 32 colours, grimy dungeon with neon pink, cyan and yellow kept for the show's UI? |  |
| How many player looks should character creation offer at first? |  |
| Should each race get its own sprite, or a recolour of the player sprite to start? |  |
| Are the sprite sizes above right for your style? |  |
