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
- The conversion now picks the most common colour in each block when shrinking a picture, which keeps AI
  pictures crisp instead of blurry. It does not yet detect a fake pixel grid that is off-square.

### Dropping in animation

An animated character is a folder named for the character, inside the kind folder:

```
art_inbox/npcs/vex/walk_sw.png      one picture holding all frames side by side, or
art_inbox/npcs/vex/walk_sw_01.png   one picture per frame, numbered
art_inbox/npcs/vex/walk_sw_02.png
```

- The name is the action, then the direction the character faces on screen: `s` is toward the camera, then
  `sw`, `w`, `nw`, `n`, `ne`, `e`, `se`.
- Actions the game plays: `idle`, `walk`, `attack`, `dead`. It plays 8 frames a second.
- All frames of a character are cropped and shrunk together, so the character does not jump between frames.
- You can start with one direction. The game fills a missing direction from the nearest one it has and mirrors
  left and right, and uses `idle` when an action is missing. A folder with only `idle_sw.png` already works.
- A single picture (`art_inbox/npcs/vex.png`) still works for anything that does not move.

## Decisions for you

| Question | Your answer |
| --- | --- |
| Palette: about 32 colours, grimy dungeon with neon pink, cyan and yellow kept for the show's UI? |  |
| How many player looks should character creation offer at first? |  |
| Should each race get its own sprite, or a recolour of the player sprite to start? |  |
| Are the sprite sizes above right for your style? |  |
