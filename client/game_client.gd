extends Node2D
## The game client: isometric view with placeholder shapes, plus the HUD.
## It only draws what the server says and sends requests; no rules run here.
## Sprite sizes follow docs/sprite-spec.md so real art can replace the shapes.

const TILE_W := 64.0
const TILE_H := 32.0
const WALL_H := 26.0
const FLOOR_COLORS := {
	".": Color("3a3640"), ",": Color("4a4450"), "~": Color("27485c"), "S": Color("5a4a2c"),
}
const WALL_TOP := Color("6b6475")
const WALL_LEFT := Color("4b4556")
const WALL_RIGHT := Color("38333f")
const NEON := Color("ff4fd8")
const PARTY_COLOR := Color("5cf2a6")

var db: Dictionary
var my_id := 0
var grid: Array = []
var timer_total := 1.0
var snap := {"timer": 0.0, "p": [], "m": [], "d": []}
var me := {}
var shown := {}
var fx: Array = []
var selected: Array = []
var invite_from := ""
var _last_input := Vector2.ZERO
var _banner_until := 0.0
var _clock := 0.0

var _stats: Label
var _top: Label
var _banner: Label
var _inv_box: VBoxContainer
var _hotbar: Label
var _log: RichTextLabel
var _chat: LineEdit
var _font: Font

func _ready() -> void:
	db = DB.load_all()
	_font = ThemeDB.fallback_font
	_build_hud()

# ------------------------------------------------------------------ HUD

func _label(parent: Node, preset: int, size := 12) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	l.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, 8)
	return l

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_stats = _label(layer, Control.PRESET_TOP_LEFT)
	_top = _label(layer, Control.PRESET_CENTER_TOP, 14)
	_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_top.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner = _label(layer, Control.PRESET_CENTER_TOP, 14)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner.custom_minimum_size = Vector2(520, 0)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.position.y = 64
	_banner.add_theme_color_override("font_color", NEON)

	_inv_box = VBoxContainer.new()
	layer.add_child(_inv_box)
	_inv_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 8)
	_inv_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_inv_box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_hotbar = _label(layer, Control.PRESET_CENTER_BOTTOM)
	_hotbar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hotbar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hotbar.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var help := _label(layer, Control.PRESET_BOTTOM_RIGHT, 10)
	help.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	help.grow_vertical = Control.GROW_DIRECTION_BEGIN
	help.text = "WASD move   Space attack\nClick items, then click floor to throw\n1-5 use invention   Esc clear\nP invite   Y accept   L leave party\nEnter chat"

	var chat_box := VBoxContainer.new()
	layer.add_child(chat_box)
	chat_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 8)
	chat_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	chat_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log = RichTextLabel.new()
	_log.custom_minimum_size = Vector2(380, 130)
	_log.scroll_following = true
	_log.bbcode_enabled = true
	_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log.add_theme_font_size_override("normal_font_size", 11)
	_log.add_theme_color_override("font_outline_color", Color.BLACK)
	_log.add_theme_constant_override("outline_size", 4)
	chat_box.add_child(_log)
	_chat = LineEdit.new()
	_chat.placeholder_text = "Press Enter to chat"
	_chat.custom_minimum_size = Vector2(380, 0)
	_chat.add_theme_font_size_override("font_size", 11)
	_chat.text_submitted.connect(_on_chat)
	chat_box.add_child(_chat)

func _on_chat(text: String) -> void:
	if text.strip_edges() != "":
		Net.send("chat", text)
	_chat.clear()
	_chat.release_focus()

func _say(text: String, color := "ffffff") -> void:
	_log.append_text("[color=#%s]%s[/color]\n" % [color, text.replace("[", "[lb]")])

func _show_banner(text: String, seconds := 6.0) -> void:
	_banner.text = text
	_banner_until = _clock + seconds

func _refresh_hud() -> void:
	var hp := 0.0
	var max_hp := 1.0
	for p in snap.p:
		if p[0] == my_id:
			hp = p[3]
			max_hp = p[4]
	var skills: Dictionary = me.get("skills", {})
	_stats.text = "HP %d/%d   Level %d   XP %d/%d\nBrawling %d  Throwing %d  Tinkering %d\nAchievements %d" % [
		ceil(hp), max_hp, me.get("level", 1), me.get("xp", 0), me.get("xp_needed", 0),
		skills.get("brawling", 0), skills.get("throwing", 0), skills.get("tinkering", 0),
		me.get("achievements", 0)]
	var t := int(snap.timer)
	_top.text = "LEVEL COLLAPSE IN %02d:%02d\nViewers: %d" % [t / 60, t % 60, me.get("viewers", 0)]
	var bar := []
	var abilities: Array = me.get("abilities", [])
	for i in abilities.size():
		bar.append("[%d] %s Lv%d" % [i + 1, abilities[i].name, abilities[i].level])
	_hotbar.text = "   ".join(bar) if not bar.is_empty() else "No inventions yet. Combine items and throw them at monsters."
	if invite_from != "":
		_hotbar.text += "\n%s invites you to a party. Press Y to accept." % invite_from

func _rebuild_inventory() -> void:
	for c in _inv_box.get_children():
		c.queue_free()
	var inv: Dictionary = me.get("inv", {})
	selected = selected.filter(func(item_id): return inv.has(item_id))
	var head := Label.new()
	head.add_theme_font_size_override("font_size", 11)
	head.text = "PACK (click up to 3 to combine)"
	_inv_box.add_child(head)
	for item_id in inv:
		var b := Button.new()
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.button_pressed = selected.has(item_id)
		b.add_theme_font_size_override("font_size", 11)
		b.text = "%s x%d" % [db.items[item_id].name, inv[item_id]]
		b.toggled.connect(_on_item_toggled.bind(item_id))
		_inv_box.add_child(b)
	var party: Array = me.get("party", [])
	if party.size() > 1:
		var pl := Label.new()
		pl.add_theme_font_size_override("font_size", 11)
		pl.add_theme_color_override("font_color", PARTY_COLOR)
		var names := []
		for p in snap.p:
			if party.has(p[0]):
				names.append("%s %d/%d" % [p[1], ceil(p[3]), p[4]])
		pl.text = "PARTY\n" + "\n".join(names)
		_inv_box.add_child(pl)

func _on_item_toggled(on: bool, item_id: String) -> void:
	if on and not selected.has(item_id) and selected.size() < 3:
		selected.append(item_id)
	elif not on:
		selected.erase(item_id)
	_rebuild_inventory()

# ------------------------------------------------------------------ network

func on_msg(kind: String, data: Dictionary) -> void:
	match kind:
		"welcome":
			my_id = data.id
			grid = data.grid
			timer_total = data.timer_total
			_say("You are in %s. Find other crawlers, or don't." % data.level, "ffd75c")
		"self":
			me = data
			_rebuild_inventory()
		"event":
			_on_event(data)

func on_snapshot(data: Dictionary) -> void:
	snap = data

func _on_event(ev: Dictionary) -> void:
	match ev.type:
		"narrator":
			_show_banner(ev.text)
			_say(ev.text, "ff4fd8")
		"log":
			_say(ev.text, "b0b0b0")
		"chat":
			_say("%s: %s" % [ev.from, ev.text])
		"invite":
			invite_from = ev.from
		"achievement":
			_show_banner("ACHIEVEMENT: %s\n%s\nReward: %s (%s)" % [ev.title, ev.text, ev.box, ", ".join(ev.loot)], 9.0)
			_say("Achievement: %s. %s contained %s." % [ev.title, ev.box, ", ".join(ev.loot)], "ffd75c")
		"discovery":
			var a: Dictionary = ev.ability
			_say("You invented %s:" % a.name, "5cf2a6")
			for t in a.traits:
				_say("   - %s" % t.text, "5cf2a6")
		"throw":
			fx.append({"type": "throw", "from": ev.from, "to": ev.to, "t0": _clock,
				"life": ev.flight, "color": Color(ev.color)})
			if ev.delay > 0.0:
				fx.append({"type": "fuse", "pos": ev.to, "t0": _clock + ev.flight, "life": ev.delay})
		"boom":
			var c := Color("ffb347")
			if ev.effects.has("burn"):
				c = Color("ff6a2a")
			elif ev.effects.has("chill"):
				c = Color("7fd6e8")
			elif ev.effects.has("poison"):
				c = Color("a6f25c")
			elif ev.effects.has("gum") or ev.effects.has("snare"):
				c = Color("e8e0b0")
			fx.append({"type": "boom", "pos": ev.pos, "radius": ev.radius, "t0": _clock, "life": 0.45, "color": c})
		"swing":
			fx.append({"type": "swing", "id": ev.id, "t0": _clock, "life": 0.18})
		"mob_dead":
			fx.append({"type": "boom", "pos": ev.pos, "radius": 0.5, "t0": _clock, "life": 0.3, "color": Color("c0392b")})

# ------------------------------------------------------------------ input

func iso(p: Vector2) -> Vector2:
	return Vector2((p.x - p.y) * TILE_W * 0.5, (p.x + p.y) * TILE_H * 0.5)

func uniso(s: Vector2) -> Vector2:
	var a := s.x / (TILE_W * 0.5)
	var b := s.y / (TILE_H * 0.5)
	return Vector2((a + b) * 0.5, (b - a) * 0.5)

func _my_pos() -> Vector2:
	return shown.get("p%d" % my_id, Vector2.ZERO)

func _process(delta: float) -> void:
	_clock += delta
	if my_id == 0:
		return
	var screen_dir := Vector2.ZERO
	if not _chat.has_focus():
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			screen_dir.y -= 1
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			screen_dir.y += 1
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			screen_dir.x -= 1
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			screen_dir.x += 1
	var dir := Vector2(screen_dir.x + screen_dir.y, screen_dir.y - screen_dir.x).normalized()
	if dir != _last_input:
		_last_input = dir
		Net.send("input", dir)

	var seen := {}
	for p in snap.p:
		seen["p%d" % p[0]] = p[2]
	for m in snap.m:
		seen["m%d" % m[0]] = m[2]
	for key in seen:
		var target: Vector2 = seen[key]
		var cur: Vector2 = shown.get(key, target)
		shown[key] = target if cur.distance_to(target) > 4.0 else cur.lerp(target, min(1.0, delta * 14.0))
	for key in shown.keys():
		if not seen.has(key):
			shown.erase(key)
	fx = fx.filter(func(f): return _clock < f.t0 + f.life)
	if _clock > _banner_until:
		_banner.text = ""
	position = get_viewport_rect().size * 0.5 - iso(_my_pos())
	_refresh_hud()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if my_id == 0:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if selected.is_empty():
			Net.send("melee")
		else:
			Net.send("throw", {"items": selected.duplicate(), "target": uniso(get_local_mouse_position()), "ability": -1})
	elif event is InputEventKey and event.pressed and not event.echo and not _chat.has_focus():
		match event.physical_keycode:
			KEY_SPACE:
				Net.send("melee")
			KEY_P:
				Net.send("invite")
			KEY_Y:
				Net.send("accept")
				invite_from = ""
			KEY_L:
				Net.send("leave")
			KEY_ESCAPE:
				selected.clear()
				_rebuild_inventory()
			KEY_ENTER, KEY_KP_ENTER:
				_chat.grab_focus()
				get_viewport().set_input_as_handled()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
				var idx: int = event.physical_keycode - KEY_1
				if idx < me.get("abilities", []).size():
					Net.send("throw", {"items": [], "target": uniso(get_local_mouse_position()), "ability": idx})

# ------------------------------------------------------------------ drawing

func _ellipse(center: Vector2, rx: float, ry: float, color: Color, filled := true, width := 2.0) -> void:
	var pts := PackedVector2Array()
	for i in 25:
		var a := TAU * i / 24.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	if filled:
		draw_colored_polygon(pts, color)
	else:
		draw_polyline(pts, color, width)

func _draw() -> void:
	if grid.is_empty():
		return
	var h := grid.size()
	var w: int = str(grid[0]).length()
	# Floor first (flat), then everything tall sorted back to front.
	for y in h:
		for x in w:
			var c: String = grid[y][x]
			if c == "#":
				continue
			var col: Color = FLOOR_COLORS.get(c, FLOOR_COLORS["."])
			if (x + y) % 2 == 0:
				col = col.lightened(0.04)
			draw_colored_polygon(PackedVector2Array([iso(Vector2(x, y)), iso(Vector2(x + 1, y)),
				iso(Vector2(x + 1, y + 1)), iso(Vector2(x, y + 1))]), col)
	for d in snap.d:
		var dp := iso(d[2])
		var dc := Color(db.items[d[1]].color)
		draw_colored_polygon(PackedVector2Array([dp + Vector2(0, -7), dp + Vector2(6, -2), dp + Vector2(0, 3), dp + Vector2(-6, -2)]), dc)
		draw_polyline(PackedVector2Array([dp + Vector2(0, -7), dp + Vector2(6, -2), dp + Vector2(0, 3), dp + Vector2(-6, -2), dp + Vector2(0, -7)]), Color.WHITE, 1.0)

	var tall := []
	for y in h:
		for x in w:
			if grid[y][x] == "#":
				tall.append([x + y + 1.0, 0, Vector2(x, y)])
	for p in snap.p:
		var pos: Vector2 = shown.get("p%d" % p[0], p[2])
		tall.append([pos.x + pos.y, 1, p, pos])
	for m in snap.m:
		var pos: Vector2 = shown.get("m%d" % m[0], m[2])
		tall.append([pos.x + pos.y, 2, m, pos])
	tall.sort_custom(func(a, b): return a[0] < b[0])
	var my_party: Array = me.get("party", [])
	for t in tall:
		match t[1]:
			0: _draw_wall(t[2])
			1: _draw_player(t[2], t[3], my_party)
			2: _draw_mob(t[2], t[3])
	for f in fx:
		_draw_fx(f)

func _draw_wall(tile: Vector2) -> void:
	var up := Vector2(0, -WALL_H)
	var top := iso(tile)
	var right := iso(tile + Vector2(1, 0))
	var bottom := iso(tile + Vector2(1, 1))
	var left := iso(tile + Vector2(0, 1))
	draw_colored_polygon(PackedVector2Array([left, bottom, bottom + up, left + up]), WALL_LEFT)
	draw_colored_polygon(PackedVector2Array([bottom, right, right + up, bottom + up]), WALL_RIGHT)
	draw_colored_polygon(PackedVector2Array([top + up, right + up, bottom + up, left + up]), WALL_TOP)

func _bar(at: Vector2, frac: float, color: Color) -> void:
	draw_rect(Rect2(at - Vector2(12, 0), Vector2(24, 3)), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(at - Vector2(12, 0), Vector2(24 * clamp(frac, 0.0, 1.0), 3)), color)

func _draw_player(p: Array, pos: Vector2, my_party: Array) -> void:
	var s := iso(pos)
	var dead: bool = p[6]
	var body := Color("4fa3ff") if p[0] == my_id else (PARTY_COLOR if my_party.has(p[0]) else Color("e0c060"))
	if dead:
		body = Color("555555")
	_ellipse(s, 10, 5, Color(0, 0, 0, 0.45))
	if dead:
		draw_rect(Rect2(s + Vector2(-10, -6), Vector2(20, 6)), body)
	else:
		draw_rect(Rect2(s + Vector2(-6, -22), Vector2(12, 20)), body)
		draw_circle(s + Vector2(0, -27), 6, body.lightened(0.3))
		var face: Vector2 = iso(p[7]).normalized() * 5.0
		draw_circle(s + Vector2(0, -27) + face, 2, Color.BLACK)
		_bar(s + Vector2(0, -40), p[3] / p[4], Color("5cf27a"))
	draw_string(_font, s + Vector2(-50, -44), p[1], HORIZONTAL_ALIGNMENT_CENTER, 100, 10, Color.WHITE)

func _draw_mob(m: Array, pos: Vector2) -> void:
	var def: Dictionary = db.mobs[m[1]]
	var s := iso(pos)
	var size: float = def.size
	var col := Color(def.color)
	if m[5]:
		col = col.lerp(Color("ff6a2a"), 0.5)
	elif m[4]:
		col = col.lerp(Color("7fd6e8"), 0.5)
	_ellipse(s, 11 * size, 5.5 * size, Color(0, 0, 0, 0.45))
	_ellipse(s + Vector2(0, -8 * size), 11 * size, 9 * size, col)
	draw_circle(s + Vector2(-4 * size, -10 * size), 1.5 * size, Color("ff3030"))
	draw_circle(s + Vector2(4 * size, -10 * size), 1.5 * size, Color("ff3030"))
	_bar(s + Vector2(0, -22 * size - 4), m[3] / float(def.hp), Color("f25c5c"))

func _draw_fx(f: Dictionary) -> void:
	var k: float = clamp((_clock - f.t0) / f.life, 0.0, 1.0)
	if _clock < f.t0:
		return
	match f.type:
		"throw":
			var a := iso(f.from) + Vector2(0, -20)
			var b := iso(f.to)
			var at := a.lerp(b, k) + Vector2(0, -40.0 * sin(k * PI))
			draw_circle(at, 4, f.color)
			draw_arc(at, 4, 0, TAU, 12, Color.WHITE, 1.0)
		"fuse":
			if int(_clock * 10.0) % 2 == 0:
				draw_circle(iso(f.pos) + Vector2(0, -3), 3, Color("ffe066"))
		"boom":
			var c: Color = f.color
			c.a = 1.0 - k
			var r: float = f.radius * (0.4 + 0.6 * k)
			_ellipse(iso(f.pos), r * TILE_W * 0.707, r * TILE_H * 0.707, Color(c.r, c.g, c.b, c.a * 0.35))
			_ellipse(iso(f.pos), r * TILE_W * 0.707, r * TILE_H * 0.707, c, false, 2.0)
		"swing":
			var pos: Vector2 = shown.get("p%d" % f.id, Vector2.ZERO)
			draw_arc(iso(pos) + Vector2(0, -14), 16, -1.0 + k * 2.0, 0.2 + k * 2.0, 8, Color.WHITE, 2.0)
