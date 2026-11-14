-- Turns the images in art_inbox/ into game sprites in art/.
-- Run by make_sprites.bat (Windows) or make_sprites.sh (Mac, Linux) through
-- Aseprite's command line:  aseprite -b --script-param root=<project> --script tools/sprite_pipeline.lua
--
-- For each image in art_inbox/<kind>/<id>.png (or .jpg, .bmp, .gif, .webp):
--   1. a plain background touching the edges is made transparent
--   2. the empty border is trimmed
--   3. the picture is shrunk to the sprite size for its folder
--   4. colours are snapped to art_inbox/palette.png if that file exists
--   5. the result is saved as art/<kind>/<id>.png, plus an editable copy in art_src/
-- A .aseprite file in art_inbox is treated as finished work and exported unchanged.

-- Sprite sizes per folder: width, height, output folder.
local KINDS = {
  tiles      = { w = 64, h = 32, out = "tiles" },
  players    = { w = 64, h = 64, out = "players" },
  npcs       = { w = 64, h = 64, out = "npcs" },
  pets       = { w = 48, h = 48, out = "pets" },
  mobs       = { w = 64, h = 64, out = "mobs" },
  mobs_large = { w = 128, h = 128, out = "mobs" },
  items      = { w = 24, h = 24, out = "items" },
  fx         = { w = 64, h = 32, out = "fx" },
}
-- Tiles with their own size (a wall is a 64 x 32 footprint that rises 26 px).
local TILE_SIZES = { wall = { w = 64, h = 58 } }
local WORK_MAX = 384          -- large paintings are reduced to this before processing
local BG_TOLERANCE = 28       -- how close to the corner colour counts as background
local IMAGE_EXT = { png = true, jpg = true, jpeg = true, bmp = true, gif = true, webp = true, tga = true }
local ASE_EXT = { aseprite = true, ase = true }

local root = app.params["root"]
local fs = app.fs
local pc = app.pixelColor
local report = {}
local function say(line) report[#report + 1] = line end

local function write_report()
  local f = io.open(fs.joinPath(root, "art_inbox", "last_run.txt"), "w")
  if f then
    f:write(table.concat(report, "\n") .. "\n")
    f:close()
  end
  print(table.concat(report, "\n"))
end

-- Read a sprite's first frame into a plain table of {r,g,b,a} rows, reduced so
-- the longest side is at most WORK_MAX.
local function read_pixels(spr)
  if spr.colorMode ~= ColorMode.RGB then
    app.activeSprite = spr
    app.command.ChangePixelFormat { format = "rgb" }
  end
  spr:flatten()
  local cel = spr.cels[1]
  if not cel then return nil end
  local img, ox, oy = cel.image, cel.position.x, cel.position.y
  local sw, sh = spr.width, spr.height
  local step = math.max(1, math.ceil(math.max(sw, sh) / WORK_MAX))
  local w, h = math.ceil(sw / step), math.ceil(sh / step)
  local px = {}
  for y = 0, h - 1 do
    local row = {}
    for x = 0, w - 1 do
      local r, g, b, a, n = 0, 0, 0, 0, 0
      for yy = y * step, math.min(sh, (y + 1) * step) - 1 do
        for xx = x * step, math.min(sw, (x + 1) * step) - 1 do
          local ix, iy = xx - ox, yy - oy
          n = n + 1
          if ix >= 0 and iy >= 0 and ix < img.width and iy < img.height then
            local c = img:getPixel(ix, iy)
            local ca = pc.rgbaA(c)
            r = r + pc.rgbaR(c) * ca
            g = g + pc.rgbaG(c) * ca
            b = b + pc.rgbaB(c) * ca
            a = a + ca
          end
        end
      end
      if a > 0 then
        row[x + 1] = { r / a, g / a, b / a, a / n }
      else
        row[x + 1] = { 0, 0, 0, 0 }
      end
    end
    px[y + 1] = row
  end
  return px, w, h
end

local function close_to(p, q)
  return math.abs(p[1] - q[1]) <= BG_TOLERANCE and math.abs(p[2] - q[2]) <= BG_TOLERANCE
    and math.abs(p[3] - q[3]) <= BG_TOLERANCE
end

-- If all four corners are opaque and the same colour, clear that colour
-- inwards from the edges. Colour enclosed by the drawing is left alone.
local function remove_background(px, w, h)
  local corners = { px[1][1], px[1][w], px[h][1], px[h][w] }
  local bg = corners[1]
  for _, c in ipairs(corners) do
    if c[4] < 250 or not close_to(c, bg) then return false end
  end
  local seen, stack = {}, {}
  local function push(x, y)
    if x < 1 or y < 1 or x > w or y > h then return end
    local k = (y - 1) * w + x
    if seen[k] then return end
    seen[k] = true
    local p = px[y][x]
    if p[4] > 0 and close_to(p, bg) then
      p[4] = 0
      stack[#stack + 1] = x
      stack[#stack + 1] = y
    end
  end
  for x = 1, w do push(x, 1) push(x, h) end
  for y = 1, h do push(1, y) push(w, y) end
  while #stack > 0 do
    local y = table.remove(stack)
    local x = table.remove(stack)
    push(x + 1, y) push(x - 1, y) push(x, y + 1) push(x, y - 1)
  end
  -- Shave the blended fringe: edge pixels still tinted with the background colour.
  local fringe = {}
  for y = 1, h do
    for x = 1, w do
      local p = px[y][x]
      if p[4] > 0 and math.abs(p[1] - bg[1]) + math.abs(p[2] - bg[2]) + math.abs(p[3] - bg[3]) < BG_TOLERANCE * 6 then
        local edge = (x > 1 and px[y][x - 1][4] == 0) or (x < w and px[y][x + 1][4] == 0)
          or (y > 1 and px[y - 1][x][4] == 0) or (y < h and px[y + 1][x][4] == 0)
        if edge then fringe[#fringe + 1] = p end
      end
    end
  end
  for _, p in ipairs(fringe) do p[4] = 0 end
  return true
end

local function bounds(px, w, h)
  local x0, y0, x1, y1 = w + 1, h + 1, 0, 0
  for y = 1, h do
    for x = 1, w do
      if px[y][x][4] > 24 then
        if x < x0 then x0 = x end
        if x > x1 then x1 = x end
        if y < y0 then y0 = y end
        if y > y1 then y1 = y end
      end
    end
  end
  if x1 == 0 then return nil end
  return x0, y0, x1, y1
end

-- Average the source rectangle (fractional, 0-based) into one colour.
local function sample(px, w, h, fx0, fy0, fx1, fy1)
  local r, g, b, a, n = 0, 0, 0, 0, 0
  local xa, xb = math.floor(fx0), math.max(math.floor(fx0), math.ceil(fx1) - 1)
  local ya, yb = math.floor(fy0), math.max(math.floor(fy0), math.ceil(fy1) - 1)
  xa, ya = math.max(0, math.min(xa, w - 1)), math.max(0, math.min(ya, h - 1))
  xb, yb = math.max(xa, math.min(xb, w - 1)), math.max(ya, math.min(yb, h - 1))
  for y = ya, yb do
    for x = xa, xb do
      n = n + 1
      if x >= 0 and y >= 0 and x < w and y < h then
        local p = px[y + 1][x + 1]
        r = r + p[1] * p[4]
        g = g + p[2] * p[4]
        b = b + p[3] * p[4]
        a = a + p[4]
      end
    end
  end
  if a <= 0 then return { 0, 0, 0, 0 } end
  return { r / a, g / a, b / a, a / n }
end

local function load_palette()
  for _, name in ipairs { "palette.png", "palette.gpl", "palette.pal", "palette.aseprite" } do
    local path = fs.joinPath(root, "art_inbox", name)
    if fs.isFile(path) then
      local ok, pal = pcall(function() return Palette { fromFile = path } end)
      if ok and pal then
        local colours = {}
        for i = 0, #pal - 1 do
          local c = pal:getColor(i)
          if c.alpha > 0 then colours[#colours + 1] = { c.red, c.green, c.blue } end
        end
        if #colours > 1 then return colours, name end
      end
    end
  end
  return nil
end

local function snap(p, palette)
  local best, best_d = palette[1], math.huge
  for _, c in ipairs(palette) do
    local dr, dg, db = p[1] - c[1], p[2] - c[2], p[3] - c[3]
    local d = dr * dr * 0.30 + dg * dg * 0.59 + db * db * 0.11
    if d < best_d then best, best_d = c, d end
  end
  return best
end

-- Build the output pixels for one image. Returns a table of rows of {r,g,b,a}.
local function build(px, w, h, tw, th, as_floor_tile)
  local out = {}
  if as_floor_tile then
    -- A flat square texture is laid down as an isometric diamond.
    for y = 0, th - 1 do
      local row = {}
      for x = 0, tw - 1 do
        local sx = (x + 0.5 - tw / 2) / (tw / 2)
        local sy = (y + 0.5) / (th / 2)
        local u, v = (sx + sy) / 2, (sy - sx) / 2
        -- Standard pixel diamond: rows are 2, 4, 6 ... pixels wide per half, so tiles meet without gaps.
        local half = (tw / th) * (math.min(y, th - 1 - y) + 1)
        if math.abs(x + 0.5 - tw / 2) < half then
          u = math.min(math.max(u, 0), 0.999)
          v = math.min(math.max(v, 0), 0.999)
          local span = math.max(1, w / tw)
          row[x + 1] = sample(px, w, h, u * w, v * h, u * w + span, v * h + span)
        else
          row[x + 1] = { 0, 0, 0, 0 }
        end
      end
      out[y + 1] = row
    end
    return out
  end
  local x0, y0, x1, y1 = bounds(px, w, h)
  if not x0 then return nil end
  local bw, bh = x1 - x0 + 1, y1 - y0 + 1
  local scale = math.min(tw / bw, th / bh, 1)
  local dw, dh = math.max(1, math.floor(bw * scale + 0.5)), math.max(1, math.floor(bh * scale + 0.5))
  local left, top = math.floor((tw - dw) / 2), th - dh     -- feet at the bottom centre
  for y = 0, th - 1 do
    local row = {}
    for x = 0, tw - 1 do
      local ix, iy = x - left, y - top
      if ix >= 0 and iy >= 0 and ix < dw and iy < dh then
        row[x + 1] = sample(px, w, h, (x0 - 1) + ix * bw / dw, (y0 - 1) + iy * bh / dh,
          (x0 - 1) + (ix + 1) * bw / dw, (y0 - 1) + (iy + 1) * bh / dh)
      else
        row[x + 1] = { 0, 0, 0, 0 }
      end
    end
    out[y + 1] = row
  end
  return out
end

local function save(out, tw, th, palette, png_path, ase_path)
  local spr = Sprite(tw, th, ColorMode.RGB)
  local img = Image(tw, th, ColorMode.RGB)
  for y = 0, th - 1 do
    for x = 0, tw - 1 do
      local p = out[y + 1][x + 1]
      if p[4] >= 128 then
        local c = palette and snap(p, palette) or p
        img:drawPixel(x, y, pc.rgba(math.floor(c[1] + 0.5), math.floor(c[2] + 0.5), math.floor(c[3] + 0.5), 255))
      else
        img:drawPixel(x, y, pc.rgba(0, 0, 0, 0))
      end
    end
  end
  spr.cels[1].image = img
  spr.cels[1].position = Point(0, 0)
  spr:saveCopyAs(png_path)
  spr:saveCopyAs(ase_path)
  spr:close()
end

local function run()
  if not root or root == "" then
    say("No project folder given. Run make_sprites.bat instead of this script.")
    return
  end
  local palette, palette_name = load_palette()
  say(palette and ("Colours will be snapped to art_inbox/" .. palette_name .. " (" .. #palette .. " colours).")
    or "No art_inbox/palette.png found, so colours are kept as drawn.")
  local made, failed = 0, 0
  local kinds = {}
  for kind in pairs(KINDS) do kinds[#kinds + 1] = kind end
  table.sort(kinds)
  for _, kind in ipairs(kinds) do
    local spec = KINDS[kind]
    local dir = fs.joinPath(root, "art_inbox", kind)
    if fs.isDirectory(dir) then
      local files = fs.listFiles(dir)
      table.sort(files)
      for _, name in ipairs(files) do
        local ext = string.lower(fs.fileExtension(name))
        local id = string.lower(fs.fileTitle(name)):gsub("[^%w_]+", "_")
        local src = fs.joinPath(dir, name)
        local out_dir = fs.joinPath(root, "art", spec.out)
        local src_dir = fs.joinPath(root, "art_src", spec.out)
        fs.makeAllDirectories(out_dir)
        fs.makeAllDirectories(src_dir)
        local marker = fs.joinPath(root, "art_src", ".gdignore")   -- keeps Godot from importing working files
        if not fs.isFile(marker) then
          local m = io.open(marker, "w")
          if m then m:close() end
        end
        local png = fs.joinPath(out_dir, id .. ".png")
        if IMAGE_EXT[ext] or ASE_EXT[ext] then
          local ok, err = pcall(function()
            local spr = app.open(src)
            if not spr then error("Aseprite could not open it") end
            if ASE_EXT[ext] then
              spr:saveCopyAs(png)
              spr:close()
              say("  exported  " .. kind .. "/" .. name .. "  ->  art/" .. spec.out .. "/" .. id .. ".png (unchanged)")
              return
            end
            local px, w, h = read_pixels(spr)
            spr:close()
            if not px then error("the image is empty") end
            local tw, th = spec.w, spec.h
            local floor_tile = false
            if kind == "tiles" then
              local special = TILE_SIZES[id]
              if special then
                tw, th = special.w, special.h
              else
                floor_tile = (w / h) < 1.5     -- square texture: lay it flat as a diamond
              end
            end
            local cleared = false
            if not floor_tile then cleared = remove_background(px, w, h) end
            local out = build(px, w, h, tw, th, floor_tile)
            if not out then error("nothing left after removing the background") end
            save(out, tw, th, palette, png, fs.joinPath(src_dir, id .. ".aseprite"))
            local notes = tw .. " x " .. th
            if floor_tile then notes = notes .. ", laid flat as a floor diamond" end
            if cleared then notes = notes .. ", background removed" end
            say("  made      " .. kind .. "/" .. name .. "  ->  art/" .. spec.out .. "/" .. id .. ".png (" .. notes .. ")")
          end)
          if ok then
            made = made + 1
          else
            failed = failed + 1
            say("  FAILED    " .. kind .. "/" .. name .. ": " .. tostring(err))
          end
        end
      end
    end
  end
  say("")
  say(made .. " sprite(s) made, " .. failed .. " failed.")
  if made == 0 and failed == 0 then
    say("Nothing to do. Put images in the folders inside art_inbox and run this again.")
  end
end

local ok, err = pcall(run)
if not ok then say("The sprite script stopped with an error: " .. tostring(err)) end
write_report()
