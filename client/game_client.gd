extends Node2D
## The game client: isometric view with placeholder shapes, plus the HUD.
## It only draws what the server says and sends requests; no rules run here.
## Sprite sizes follow docs/sprite-spec.md so real art can replace the shapes.

const TILE_W := 64.0
const TILE_H := 32.0
const WALL_H := 26.0
const FLOOR_COLORS := {
	".": Color("3a3640"), ",": Color("4a4450"), "~": Color("27485c"), "S": Color("5a4a2c"),
	">": Color("2f6b4f"),
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
var snap := {"timer": 0.0, "p": [], "m": [], "d": [], "n": []}
var level_name := ""
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
var _spend_box: HBoxContainer
var _choice: PanelContainer
var _choice_races: ItemList
var _choice_classes: ItemList
var _choice_detail: RichTextLabel
var _choice_timer: Label
var _choice_shown := false
var _sprites := Sprites.new()
const TILE_ART := {".": "floor", ",": "doorway", "~": "water", "S": "safe", ">": "stairs"}

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
	_spend_box = HBoxContainer.new()
	layer.add_child(_spend_box)
	_spend_box.position = Vector2(8, 112)
	_spend_box.visible = false
	for stat in ["str", "dex", "con", "int", "cha"]:
		var b := Button.new()
		b.text = "+" + stat.to_upper()
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 10)
		b.pressed.connect(func(): Net.send("spend", stat))
		_spend_box.add_child(b)
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
	help.text = "WASD move   Space attack\nClick an item, then click the floor to throw\n1-5 use invention   Esc clear\nP invite player or recruit NPC\nY accept   L leave party   Enter chat\nGreen tiles are stairs down"

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

	_build_choice(layer)

## The level 3 race and class choice.
func _build_choice(layer: CanvasLayer) -> void:
	_choice = PanelContainer.new()
	layer.add_child(_choice)
	_choice.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_choice.custom_minimum_size = Vector2(760, 400)
	_choice.position = Vector2(100, 70)
	_choice.visible = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("1b1822")
	bg.border_color = NEON
	bg.set_border_width_all(2)
	bg.set_content_margin_all(12)
	_choice.add_theme_stylebox_override("panel", bg)
	var v := VBoxContainer.new()
	_choice.add_child(v)
	var title := Label.new()
	title.text = "WE HAVE BEEN KEEPING A FILE ON YOU. CHOOSE WHAT YOU BECOME."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", NEON)
	v.add_child(title)
	_choice_timer = Label.new()
	_choice_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_choice_timer.add_theme_font_size_override("font_size", 11)
	v.add_child(_choice_timer)
	var h := HBoxContainer.new()
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(h)
	_choice_races = ItemList.new()
	_choice_races.custom_minimum_size = Vector2(170, 280)
	_choice_races.add_theme_font_size_override("font_size", 11)
	h.add_child(_choice_races)
	_choice_classes = ItemList.new()
	_choice_classes.custom_minimum_size = Vector2(230, 280)
	_choice_classes.add_theme_font_size_override("font_size", 11)
	h.add_child(_choice_classes)
	_choice_detail = RichTextLabel.new()
	_choice_detail.bbcode_enabled = true
	_choice_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_choice_detail.add_theme_font_size_override("normal_font_size", 11)
	h.add_child(_choice_detail)
	_choice_races.item_selected.connect(func(_i): _refresh_choice_detail())
	_choice_classes.item_selected.connect(func(_i): _refresh_choice_detail())
	var ok := Button.new()
	ok.text = "Confirm (permanent)"
	ok.pressed.connect(_confirm_choice)
	v.add_child(ok)

func _show_choice() -> void:
	var offers: Dictionary = me.offers
	_choice_races.clear()
	for r in offers.races:
		_choice_races.add_item(r.name)
	_choice_classes.clear()
	for c in offers.classes:
		_choice_classes.add_item(c.name)
	_choice_races.select(0)
	_choice_classes.select(0)
	_choice.visible = true
	_choice_shown = true
	_refresh_choice_detail()

func _stat_line(stats: Dictionary) -> String:
	var parts := []
	for s in stats:
		parts.append("%s %+d" % [str(s).to_upper(), int(stats[s])])
	return ", ".join(parts) if not parts.is_empty() else "no stat changes"

func _refresh_choice_detail() -> void:
	if not me.has("offers"):
		return
	var r: Dictionary = me.offers.races[_choice_races.get_selected_items()[0]]
	var c: Dictionary = me.offers.classes[_choice_classes.get_selected_items()[0]]
	_choice_detail.text = "[b]%s[/b]\n%s\n\n[b]%s[/b]\n[color=#ff4fd8]%s[/color]\n\nStats: %s\n[color=#5cf2a6]Perk: %s[/color]\n[color=#f25c5c]Drawback: %s[/color]\n[color=#9aa0b0]%s[/color]\n\nYou have %d banked stat points to spend in a safe room afterwards." % [
		r.name, r.text, c.name, c.quip, _stat_line(c.get("stats", {})), c.perk, c.drawback, c.get("why", ""), me.get("points", 0)]

func _confirm_choice() -> void:
	if not me.has("offers"):
		return
	Net.send("choose", {
		"race": me.offers.races[_choice_races.get_selected_items()[0]].id,
		"klass": me.offers.classes[_choice_classes.get_selected_items()[0]].id})

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
	var st: Dictionary = me.get("stats", {})
	var who := "%s %s" % [me.get("race", ""), me.get("klass", "")] if me.get("klass", "") != "" else "No class yet (chosen on level 3)"
	var points := int(me.get("points", 0))
	var point_note := ""
	if points > 0:
		point_note = "   %d points %s" % [points, "to spend" if me.get("can_spend", false) else ("banked (spend in a safe room)" if me.get("klass", "") != "" else "banked until you pick a class")]
	_stats.text = "HP %d/%d   MP %d   Level %d   XP %d/%d\nSTR %d  DEX %d  CON %d  INT %d  CHA %d%s\n%s   Past life: %s\nBrawling %d  Throwing %d  Tinkering %d\nAchievements %d%s%s" % [
		ceil(hp), max_hp, me.get("mana", 0), me.get("level", 1), me.get("xp", 0), me.get("xp_needed", 0),
		st.get("str", 0), st.get("dex", 0), st.get("con", 0), st.get("int", 0), st.get("cha", 0), point_note,
		who, me.get("past", ""),
		skills.get("brawling", 0), skills.get("throwing", 0), skills.get("tinkering", 0),
		me.get("achievements", 0),
		"   %d prize boxes waiting (open in a safe room)" % me.boxes_waiting if me.get("boxes_waiting", 0) > 0 else "",
		"   Companion: %s" % me.companion if me.get("companion", "") != "" else ""]
	if me.get("perk", "") != "":
		_stats.text += "\nPerk: %s\nDrawback: %s" % [me.perk, me.drawback]
	_spend_box.visible = points > 0 and me.get("can_spend", false)
	_spend_box.position.y = 112 + (44 if me.get("perk", "") != "" else 0)
	if me.get("state", "play") == "choosing":
		if not _choice_shown:
			_show_choice()
		_banner.text = ""
		_choice_timer.text = "The choice is made for you in %d seconds" % int(me.get("choose_seconds", 0))
	elif _choice_shown:
		_choice.visible = false
		_choice_shown = false
	var t := int(snap.timer)
	_top.text = "%s COLLAPSES IN %02d:%02d\nViewers: %d" % [level_name.to_upper(), t / 60, t % 60, me.get("viewers", 0)]
	var bar := []
	var abilities: Array = me.get("abilities", [])
	for i in abilities.size():
		bar.append("[%d] %s Lv%d" % [i + 1, abilities[i].name, abilities[i].level])
	_hotbar.text = "   ".join(bar)
	if invite_from != "":
		_hotbar.text += "\n%s invites you to a party. Press Y to accept." % invite_from

func _rebuild_inventory() -> void:
	for c in _inv_box.get_children():
		c.queue_free()
	var inv: Dictionary = me.get("inv", {})
	selected = selected.filter(func(item_id): return inv.has(item_id))
	var head := Label.new()
	head.add_theme_font_size_override("font_size", 11)
	head.text = "PACK (click up to 3 to combine)" if me.get("crafting", false) else "PACK (click one to throw)"
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
	if on and not selected.has(item_id):
		if not me.get("crafting", false):
			selected.clear()
		if selected.size() < 3:
			selected.append(item_id)
	elif not on:
		selected.erase(item_id)
	_rebuild_inventory()

# ------------------------------------------------------------------ network

func on_msg(kind: String, data: Dictionary) -> void:
	match kind:
		"welcome":
			my_id = data.id
		"floor":
			grid = data.grid
			timer_total = data.timer_total
			level_name = data.name
			shown.clear()
			fx.clear()
			_say("Level %d: %s." % [data.index + 1, data.name], "ffd75c")
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
	for n in snap.get("n", []):
		seen["n%d" % n[0]] = n[2]
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
	if me.get("state", "play") == "choosing":
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
			var tile_tex := _sprites.first("tiles", [TILE_ART.get(c, "floor"), "floor"])
			if tile_tex != null:
				draw_texture(tile_tex, Vector2(iso(Vector2(x, y + 1)).x, iso(Vector2(x, y)).y))
			else:
				var col: Color = FLOOR_COLORS.get(c, FLOOR_COLORS["."])
				if (x + y) % 2 == 0:
					col = col.lightened(0.04)
				draw_colored_polygon(PackedVector2Array([iso(Vector2(x, y)), iso(Vector2(x + 1, y)),
					iso(Vector2(x + 1, y + 1)), iso(Vector2(x, y + 1))]), col)
			if c == ">" and _sprites.get_tex("tiles", "stairs") == null:
				var mid := iso(Vector2(x + 0.5, y + 0.5))
				draw_colored_polygon(PackedVector2Array([mid + Vector2(-8, -4), mid + Vector2(8, -4), mid + Vector2(0, 6)]), Color("5cf2a6"))
	for d in snap.d:
		var dp := iso(d[2])
		var item_tex := _sprites.get_tex("items", d[1])
		if item_tex != null:
			draw_texture(item_tex, dp - Vector2(item_tex.get_width() / 2.0, item_tex.get_height() - 3.0))
			continue
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
	for n in snap.get("n", []):
		var pos: Vector2 = shown.get("n%d" % n[0], n[2])
		tall.append([pos.x + pos.y, 3, n, pos])
	tall.sort_custom(func(a, b): return a[0] < b[0])
	var my_party: Array = me.get("party", [])
	for t in tall:
		match t[1]:
			0: _draw_wall(t[2])
			1: _draw_player(t[2], t[3], my_party)
			2: _draw_mob(t[2], t[3])
			3: _draw_npc(t[2], t[3])
	for f in fx:
		_draw_fx(f)

## Draw a sprite standing on the ground at s (feet at the bottom centre).
func _stand(tex: Texture2D, s: Vector2, tint: Color) -> void:
	draw_texture(tex, (s - Vector2(tex.get_width() / 2.0, tex.get_height() - 4.0)).round(), tint)

func _draw_wall(tile: Vector2) -> void:
	var wall_tex := _sprites.get_tex("tiles", "wall")
	if wall_tex != null:
		draw_texture(wall_tex, Vector2(iso(tile + Vector2(0, 1)).x, iso(tile + Vector2(1, 1)).y - wall_tex.get_height()))
		return
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
	var ptex := _sprites.first("players", ["default"])
	if ptex != null:
		# One look for everyone for now; a ring on the ground shows who is who.
		_ellipse(s, 11, 5.5, body, false, 1.5)
		_stand(ptex, s, Color(0.4, 0.4, 0.4) if dead else Color.WHITE)
		if not dead:
			_bar(s + Vector2(0, -ptex.get_height() - 4.0), p[3] / p[4], Color("5cf27a"))
	elif dead:
		draw_rect(Rect2(s + Vector2(-10, -6), Vector2(20, 6)), body)
	else:
		draw_rect(Rect2(s + Vector2(-6, -22), Vector2(12, 20)), body)
		draw_circle(s + Vector2(0, -27), 6, body.lightened(0.3))
		var face: Vector2 = iso(p[7]).normalized() * 5.0
		draw_circle(s + Vector2(0, -27) + face, 2, Color.BLACK)
		_bar(s + Vector2(0, -40), p[3] / p[4], Color("5cf27a"))
	draw_string(_font, s + Vector2(-70, -44), p[1] if p[8] == "" else "%s, %s" % [p[1], p[8]], HORIZONTAL_ALIGNMENT_CENTER, 140, 10, Color.WHITE)

func _draw_npc(n: Array, pos: Vector2) -> void:
	var s := iso(pos)
	var body := Color(n[3])
	_ellipse(s, 10, 5, Color(0, 0, 0, 0.45))
	var ntex := _sprites.first("npcs", [str(n[1]).to_lower(), "default"])
	if ntex != null:
		_stand(ntex, s, Color.WHITE)
	else:
		draw_rect(Rect2(s + Vector2(-6, -22), Vector2(12, 20)), body)
		draw_circle(s + Vector2(0, -27), 6, body.lightened(0.3))
	var label: String = n[1] if n[4] != 0 else "%s (press P to recruit)" % n[1]
	draw_string(_font, s + Vector2(-80, -38), label, HORIZONTAL_ALIGNMENT_CENTER, 160, 10, Color("c8c8ff"))

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
	var mtex := _sprites.get_tex("mobs", m[1])
	if mtex != null:
		_stand(mtex, s, Color.WHITE.lerp(col, 0.5) if (m[4] or m[5]) else Color.WHITE)
	else:
		_ellipse(s + Vector2(0, -8 * size), 11 * size, 9 * size, col)
		draw_circle(s + Vector2(-4 * size, -10 * size), 1.5 * size, Color("ff3030"))
		draw_circle(s + Vector2(4 * size, -10 * size), 1.5 * size, Color("ff3030"))
	_bar(s + Vector2(0, -22 * size - 4), m[3] / float(m[6]), Color("f25c5c"))
	draw_string(_font, s + Vector2(-40, -22 * size - 7), "Lv %d" % m[7], HORIZONTAL_ALIGNMENT_CENTER, 80, 9, Color("ffb0b0"))

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
