class_name World
extends RefCounted
## The authoritative game simulation. Runs only on the server. It has no
## dependency on rendering or networking, so tests can drive it directly.
## Positions are in tile units on a flat grid; clients project them to isometric.

signal event(targets: Array, ev: Dictionary)  # targets empty = everyone
signal self_changed(pid: int)
signal floor_changed(pid: int)

const BASE_SPEED := 4.0
const PLAYER_RADIUS := 0.3
const MELEE_RANGE := 1.3
const MELEE_CD := 0.45
const MELEE_DAMAGE := 4.0
const THROW_CD := 0.5
const THROW_FLIGHT := 0.35
const PICKUP_RANGE := 0.7
const AGGRO_RANGE := 5.0
const RESPAWN_TIME := 5.0
const ITEM_RESPAWN := 25.0
const MOB_RESPAWN := 20.0
const PARTY_RANGE := 4.0
const SHARE_RANGE := 10.0
const BASE_STAT := 4
const POINTS_PER_LEVEL := 3
const CHOICE_FLOOR := 2          # index of the level where race and class are chosen
const BOX_INTERVAL := 1.5
const STATS := ["str", "dex", "con", "int", "cha"]

var db: Dictionary
var rng := RandomNumberGenerator.new()
var world_seed: int
var now := 0.0
var floors: Array = []
var players := {}
var companions := {}
var parties := {}
var invites := {}
var canon := {}
var _next_id := 1

func _init(p_db: Dictionary, p_seed: int = 1) -> void:
	db = p_db
	world_seed = p_seed
	rng.seed = p_seed
	for i in db.floors.floors.size():
		floors.append(_load_floor(i))

# ---------------------------------------------------------------- levels

func _load_floor(index: int) -> Dictionary:
	var def: Dictionary = db.floors.floors[index]
	var f := {
		"index": index, "name": def.name, "timer_total": float(def.timer_seconds),
		"timer_left": float(def.timer_seconds), "grid": [], "width": 0, "height": 0,
		"starts": [], "arrivals": [], "mob_spawns": [], "item_spawns": [],
		"mobs": {}, "drops": {}, "pending": [],
	}
	var rows: Array = def.map
	f.height = rows.size()
	f.width = str(rows[0]).length()
	var names: Array = def.get("starts", [])
	for y in f.height:
		var row: String = rows[y]
		var out := ""
		for x in f.width:
			var c := row[x]
			if c in ["P", "m", "G", "i", "N", "1", "2", "3"]:
				var floor_c := out[x - 1] if x > 0 and out[x - 1] != "#" else "."
				var pos := Vector2(x + 0.5, y + 0.5)
				match c:
					"P": f.arrivals.append(pos)
					"m": f.mob_spawns.append({"pos": pos, "type": "drain_leech" if floor_c == "~" else "sump_rat", "mob": 0, "respawn_at": 0.0})
					"G": f.mob_spawns.append({"pos": pos, "type": "scrap_golem", "mob": 0, "respawn_at": 0.0})
					"i": f.item_spawns.append({"pos": pos, "drop": 0, "respawn_at": 0.0})
					"N":
						var defs: Array = db.companions.companions
						var cdef: Dictionary = defs[companions.size() % defs.size()]
						var id := _id()
						companions[id] = {"id": id, "def": cdef, "floor": index, "pos": pos,
							"home": pos, "home_floor": index, "owner": 0, "cd": 0.0}
					_:
						var n := int(c) - 1
						f.starts.append({"pos": pos, "name": names[n] if n < names.size() else "Start %s" % c})
				c = floor_c
			out += c
		f.grid.append(out)
	if f.arrivals.is_empty():
		for s in f.starts:
			f.arrivals.append(s.pos)
	return f

func start_names() -> Array:
	return floors[0].starts.map(func(s): return s.name)

func tile_at(f: Dictionary, pos: Vector2) -> String:
	var x := int(floor(pos.x))
	var y := int(floor(pos.y))
	if x < 0 or y < 0 or x >= f.width or y >= f.height:
		return "#"
	return f.grid[y][x]

func tags_at(f: Dictionary, pos: Vector2) -> Array:
	match tile_at(f, pos):
		"~": return ["wet"]
		",": return ["narrow"]
		"S": return ["safe"]
		".", ">": return ["open"]
	return []

func _free(f: Dictionary, pos: Vector2, r: float, no_safe: bool) -> bool:
	for off in [Vector2(-r, -r), Vector2(r, -r), Vector2(-r, r), Vector2(r, r)]:
		var c := tile_at(f, pos + off)
		if c == "#" or (no_safe and c == "S"):
			return false
	return true

func _move(f: Dictionary, pos: Vector2, delta: Vector2, r: float, no_safe := false) -> Vector2:
	var nx := Vector2(pos.x + delta.x, pos.y)
	if _free(f, nx, r, no_safe):
		pos = nx
	var ny := Vector2(pos.x, pos.y + delta.y)
	if _free(f, ny, r, no_safe):
		pos = ny
	return pos

func _id() -> int:
	_next_id += 1
	return _next_id

func _floor_of(p: Dictionary) -> Dictionary:
	return floors[p.floor]

func _in_safe(p: Dictionary) -> bool:
	return tile_at(_floor_of(p), p.pos) == "S"

func _on_floor(index: int) -> Array:
	var out := []
	for p in players.values():
		if p.floor == index:
			out.append(p.id)
	return out

## Send something only the players on one level should see or hear.
func _floor_ev(index: int, ev: Dictionary) -> void:
	var ids := _on_floor(index)
	if not ids.is_empty():
		event.emit(ids, ev)

# ---------------------------------------------------------------- players

## info: {name, past, start}. past is a past-life id, start an index into the
## first level's starting locations.
func add_player(pid: int, info: Dictionary) -> void:
	var clean := str(info.get("name", "")).strip_edges().substr(0, 16)
	if clean == "":
		clean = "Crawler%d" % (pid % 1000)
	var past := ClassOffers.past_life(str(info.get("past", "")), db)
	var starts: Array = floors[0].starts
	var start: int = clamp(int(info.get("start", 0)), 0, starts.size() - 1)
	var skills := {"brawling": 0, "throwing": 0, "tinkering": 0}
	for s in past.skills:
		skills[s] = int(pow(float(past.skills[s]), 2.0) * 5.0)
	var stats := {}
	for s in STATS:
		stats[s] = BASE_STAT
	players[pid] = {
		"id": pid, "name": clean, "past": past.id, "start": start, "floor": 0,
		"pos": starts[start].pos, "input": Vector2.ZERO, "facing": Vector2(1, 1).normalized(),
		"stats": stats, "points": 0, "race": "", "klass": "", "mods": {}, "perk": "", "drawback": "",
		"state": "play", "offers": {}, "choose_until": 0.0,
		"hp": 1.0, "max_hp": 1.0, "level": 1, "xp": 0,
		"inv": {"oil_flask": 2, "rag": 2, "flint": 1, "bone": 1}, "abilities": [], "ability_ready": {},
		"party": 0, "companion": 0, "pet": null, "skills": skills,
		"combo": {}, "dossier": {}, "ach": {}, "boxes": [], "next_box_at": 0.0, "excite": 0.0,
		"cd_melee": 0.0, "cd_throw": 0.0, "dead_until": -1.0,
	}
	var p: Dictionary = players[pid]
	_recalc(p)
	p.hp = p.max_hp
	_say("welcome", {"name": clean}, [pid])
	_log("%s (%s) has entered the dungeon at %s." % [clean, past.name, starts[start].name])
	self_changed.emit(pid)

func remove_player(pid: int) -> void:
	if not players.has(pid):
		return
	var left_name: String = players[pid].name
	_release_companion(players[pid], false)
	_leave_party(pid)
	invites.erase(pid)
	players.erase(pid)
	_log("%s has left the dungeon." % left_name)

func _mod(p: Dictionary, key: String, default: float) -> float:
	return float(p.mods.get(key, default))

func _recalc(p: Dictionary) -> void:
	var old_max: float = p.max_hp
	p.max_hp = round((20.0 + p.stats.con * 5.0 + (p.level - 1) * 4.0) * _mod(p, "hp_mult", 1.0))
	if p.max_hp > old_max:
		p.hp += p.max_hp - old_max
	p.hp = min(p.hp, p.max_hp)

func _arrival(p: Dictionary) -> Vector2:
	var f := _floor_of(p)
	if p.floor == 0:
		return f.starts[p.start].pos
	return f.arrivals[p.id % f.arrivals.size()]

func set_input(pid: int, dir: Vector2) -> void:
	if players.has(pid):
		players[pid].input = dir.limit_length(1.0)

func chat(pid: int, text: String) -> void:
	if not players.has(pid):
		return
	var clean := text.strip_edges().substr(0, 200)
	if clean != "":
		_note(players[pid], "chats")
		event.emit([], {"type": "chat", "from": players[pid].name, "text": clean})

func _alive(p: Dictionary) -> bool:
	return p.dead_until < 0.0

func _can_act(p: Dictionary) -> bool:
	return _alive(p) and p.state == "play"

func _skill_level(p: Dictionary, skill: String) -> int:
	return min(15, int(sqrt(float(p.skills[skill]) / 5.0)))

func _ctx(p: Dictionary) -> Dictionary:
	var f := _floor_of(p)
	return {
		"room_tags": tags_at(f, p.pos), "hp_frac": p.hp / p.max_hp,
		"allies_near": _allies_near(p).size(), "time_frac": f.timer_left / f.timer_total,
		"player_level": p.level,
	}

func _allies_near(p: Dictionary, dist := 6.0) -> Array:
	var out := []
	if p.party == 0:
		return out
	for other_id in parties.get(p.party, []):
		if other_id != p.id and players.has(other_id):
			var o: Dictionary = players[other_id]
			if _alive(o) and o.floor == p.floor and o.pos.distance_to(p.pos) <= dist:
				out.append(other_id)
	return out

## Damage bonus from party auras (a class perk), your own included.
func _aura(p: Dictionary) -> float:
	var best := _mod(p, "party_aura", 1.0)
	for ally in _allies_near(p):
		best = max(best, _mod(players[ally], "party_aura", 1.0))
	return best

## The dossier: a running count of what the player does. It drives
## achievements and, at the level 3 choice, which classes they are offered.
func _note(p: Dictionary, key: String, amount := 1.0) -> void:
	p.dossier[key] = float(p.dossier.get(key, 0.0)) + amount

# ---------------------------------------------------------------- combat

func melee(pid: int) -> void:
	var p: Dictionary = players.get(pid, {})
	if p.is_empty() or not _can_act(p) or now < p.cd_melee or _in_safe(p):
		return
	p.cd_melee = now + MELEE_CD
	var f := _floor_of(p)
	var best := {}
	var best_d := MELEE_RANGE
	for m in f.mobs.values():
		var d: float = m.pos.distance_to(p.pos)
		if d <= best_d:
			best = m
			best_d = d
	_floor_ev(p.floor, {"type": "swing", "id": pid})
	if best.is_empty():
		return
	p.facing = (best.pos - p.pos).normalized()
	p.skills.brawling += 1
	var dmg: float = MELEE_DAMAGE * (1.0 + 0.08 * (p.stats.str - BASE_STAT)) \
		* (1.0 + 0.05 * _skill_level(p, "brawling")) * _mod(p, "melee_mult", 1.0) * _aura(p)
	if rng.randf() < _mod(p, "stun_chance", 0.0):
		best.stun_until = max(best.stun_until, now + 1.0)
	if rng.randf() < _mod(p, "heal_on_melee", 0.0):
		var patient: Dictionary = p
		for ally in _allies_near(p):
			var o: Dictionary = players[ally]
			if o.hp / o.max_hp < patient.hp / patient.max_hp:
				patient = o
		patient.hp = min(patient.max_hp, patient.hp + 4.0)
	_damage_mob(f, best, dmg, pid, "melee")

func throw_items(pid: int, items: Array, target: Vector2, ability_idx := -1) -> bool:
	var p: Dictionary = players.get(pid, {})
	# No fighting from inside a safe room: you are safe there, and so is everything else.
	if p.is_empty() or not _can_act(p) or now < p.cd_throw or _in_safe(p):
		return false
	var crafter := _mod(p, "crafting", 0.0) > 0.0
	var ability := {}
	if ability_idx >= 0:
		if ability_idx >= p.abilities.size():
			return false
		ability = p.abilities[ability_idx]
		items = ability.items
	# Combining items is a class perk. Everyone else throws one thing at a time.
	if items.is_empty() or items.size() > (3 if crafter else 1):
		return false
	var need := {}
	for item_id in items:
		if typeof(item_id) != TYPE_STRING or not db.items.has(item_id):
			return false
		need[item_id] = need.get(item_id, 0) + 1
	for item_id in need:
		if int(p.inv.get(item_id, 0)) < need[item_id]:
			return false
	var sig := Invention.signature(items)
	if ability.is_empty():
		for a in p.abilities:
			if a.sig == sig:
				ability = a
	if not ability.is_empty() and now < float(p.ability_ready.get(sig, 0.0)):
		return false
	for item_id in need:
		p.inv[item_id] = int(p.inv[item_id]) - need[item_id]
		if p.inv[item_id] <= 0:
			p.inv.erase(item_id)

	var ctx := _ctx(p)
	var payload: Dictionary
	if ability.is_empty():
		payload = Invention.resolve(items, db)
	else:
		payload = Invention.payload_for(ability, ctx, db)
		p.ability_ready[sig] = now + payload.cooldown
	var mult: float = (1.0 + 0.06 * (p.stats.dex - BASE_STAT)) * (1.0 + 0.05 * _skill_level(p, "throwing")) \
		* _mod(p, "throw_mult", 1.0) * _aura(p)
	for i in payload.effects.size():
		payload.effects[i] = Invention._scaled(payload.effects[i], mult)
	var offset: Vector2 = (target - p.pos).limit_length(payload.range + _mod(p, "throw_range", 0.0))
	var hit_pos: Vector2 = p.pos + offset
	if offset.length() > 0.01:
		p.facing = offset.normalized()
	p.cd_throw = now + THROW_CD
	p.skills.throwing += 1
	if items.size() > 1:
		p.skills.tinkering += 1
	_floor_of(p).pending.append({
		"at": now + THROW_FLIGHT + payload.delay, "pos": hit_pos, "owner": pid,
		"payload": payload, "sig": sig, "items": items.duplicate(), "ctx": ctx,
		"is_ability": not ability.is_empty(),
	})
	_floor_ev(p.floor, {"type": "throw", "from": p.pos, "to": hit_pos, "flight": THROW_FLIGHT,
		"delay": payload.delay, "color": db.items[items[0]].color})
	_count(p, "throws")
	for item_id in items:
		for tag in db.items[item_id].tags:
			_note(p, "threw_" + str(tag))
	self_changed.emit(pid)
	return true

func _detonate(f: Dictionary, d: Dictionary) -> void:
	var payload: Dictionary = d.payload
	var hit := []
	for m in f.mobs.values():
		if m.pos.distance_to(d.pos) <= payload.radius + float(db.mobs[m.type].size) * 0.3:
			hit.append(m)
	var effect_ids := []
	for e in payload.effects:
		effect_ids.append(e.id)
	_floor_ev(f.index, {"type": "boom", "pos": d.pos, "radius": payload.radius, "effects": effect_ids})
	var kills := 0
	var first_family := ""
	for m in hit:
		var family: String = db.mobs[m.type].family
		if first_family == "":
			first_family = family
		var mult := 1.0
		if payload.bane.get("family", "") == family:
			mult = float(payload.bane.mult)
		for e in payload.effects:
			match e.kind:
				"dot":
					m.dots.append({"dps": e.power * mult, "until": now + e.duration, "owner": d.owner})
				"slow":
					m.slow_until = max(m.slow_until, now + e.duration)
					m.slow_factor = min(m.slow_factor, e.power)
				"root":
					m.root_until = max(m.root_until, now + e.duration)
				"stun":
					m.stun_until = max(m.stun_until, now + e.duration)
		var dmg := 0.0
		for e in payload.effects:
			if e.kind == "damage":
				dmg += e.power * mult
		if _damage_mob(f, m, dmg, d.owner, "thrown"):
			kills += 1
	var p: Dictionary = players.get(d.owner, {})
	if p.is_empty():
		return
	if kills >= 2:
		p.excite += 5.0 * kills
	if d.is_ability:
		for a in p.abilities:
			if a.sig == d.sig and Invention.record_use(a, db):
				_say("ability_up", {"name": p.name, "ability": a.name, "level": a.level}, [p.id])
				self_changed.emit(p.id)
		return
	_track_combo(p, d, hit.size(), kills, first_family)

## Crafting classes only: watch which combinations the player keeps using and
## hand the history to the invention engine once one has proved itself.
func _track_combo(p: Dictionary, d: Dictionary, hits: int, kills: int, family: String) -> void:
	if d.items.size() < 2 or hits == 0:
		return
	var rules: Dictionary = db.context
	var rec: Dictionary = p.combo.get(d.sig, {})
	if rec.is_empty():
		rec = {"uses": 0, "room_tags": d.ctx.room_tags, "family": family, "min_hp": 1.0}
		p.combo[d.sig] = rec
	rec.uses += 1
	rec.min_hp = min(rec.min_hp, d.ctx.hp_frac)
	var dramatic: bool = kills >= int(rules.discovery.multi_kill) \
		or (kills >= 1 and d.ctx.hp_frac < float(rules.desperate.hp_below))
	if rec.uses < int(rules.discovery.uses_needed) and not dramatic:
		return
	var ability := Invention.invent({
		"items": d.items, "room_tags": rec.room_tags, "target_family": rec.family,
		"hp_frac": rec.min_hp, "allies_near": d.ctx.allies_near, "time_frac": d.ctx.time_frac,
		"player_id": p.id, "player_level": p.level, "world_seed": world_seed,
	}, db)
	var base_name: String = ability.name
	var n := 2
	while canon.has(ability.name):
		ability.name = "%s Mk %d" % [base_name, n]
		n += 1
	canon[ability.name] = {"sig": d.sig, "by": p.name}
	p.abilities.append(ability)
	p.combo.erase(d.sig)
	p.excite += 25.0
	_say("discovery", {"name": p.name, "ability": ability.name, "quip": ability.quip})
	event.emit([p.id], {"type": "discovery", "ability": ability})
	_count(p, "discoveries")
	self_changed.emit(p.id)

func _damage_mob(f: Dictionary, m: Dictionary, amount: float, owner: int, how := "") -> bool:
	if not f.mobs.has(m.id):
		return false
	m.hp -= amount
	if owner != 0:
		m.target = owner
	if m.hp > 0.0:
		return false
	f.mobs.erase(m.id)
	for s in f.mob_spawns:
		if s.mob == m.id:
			s.mob = 0
			s.respawn_at = now + MOB_RESPAWN
	_floor_ev(f.index, {"type": "mob_dead", "id": m.id, "pos": m.pos})
	if rng.randf() < 0.6:
		_drop(f, _roll(db.boxes.tin.table), m.pos)
	var killer: Dictionary = players.get(owner, {})
	if killer.is_empty():
		return true
	killer.excite += 3.0
	if how != "":
		_note(killer, "kills_" + how)
	_note(killer, "killed_" + str(db.mobs[m.type].family))
	for tag in tags_at(f, killer.pos):
		_note(killer, "kills_in_" + str(tag))
	if m.level > killer.level:
		_count(killer, "kills_above")
	_count(killer, "kills")
	var share := [owner]
	for ally in _allies_near(killer, SHARE_RANGE):
		share.append(ally)
	for pid in share:
		_give_xp(players[pid], int(m.xp))
	return true

func _give_xp(p: Dictionary, amount: int) -> void:
	p.xp += int(round(amount * _mod(p, "xp_mult", 1.0)))
	while p.xp >= _xp_needed(p.level):
		p.xp -= _xp_needed(p.level)
		p.level += 1
		p.points += POINTS_PER_LEVEL
		_recalc(p)
		p.hp = p.max_hp
		_say("levelup", {"name": p.name, "level": p.level}, [p.id])
	self_changed.emit(p.id)

func _xp_needed(level: int) -> int:
	return int(20.0 * pow(level, 1.5))

func _damage_player(p: Dictionary, amount: float, by: Dictionary = {}) -> void:
	if not _can_act(p) or _in_safe(p):
		return
	p.hp -= amount
	_note(p, "hits_taken")
	var thorns := _mod(p, "thorns", 0.0)
	if thorns > 0.0 and not by.is_empty():
		_damage_mob(_floor_of(p), by, thorns, p.id, "thorns")
	if p.hp > 0.0:
		if p.hp / p.max_hp < 0.15:
			p["close_call"] = true
		return
	p.hp = 0.0
	p.dead_until = now + RESPAWN_TIME
	p.input = Vector2.ZERO
	p.excite += 10.0
	_say("death", {"name": p.name})
	if by.has("type"):
		_note(p, "died_to_" + str(db.mobs[by.type].family))
	_count(p, "deaths")
	self_changed.emit(p.id)

# ---------------------------------------------------------------- loot

func _roll(table: Dictionary) -> String:
	var total := 0.0
	for k in table:
		total += float(table[k])
	var r := rng.randf() * total
	for k in table:
		r -= float(table[k])
		if r <= 0.0:
			return k
	return table.keys()[0]

func _drop(f: Dictionary, item_id: String, pos: Vector2) -> int:
	var id := _id()
	f.drops[id] = {"id": id, "item": item_id, "pos": pos}
	return id

## Count something in the dossier and check achievements. Prizes are not
## handed over here: they queue up until the player reaches a safe room.
func _count(p: Dictionary, ev: String) -> void:
	_note(p, ev)
	for a in db.achievements:
		if a.event == ev and p.dossier[ev] >= float(a.count) and not p.ach.has(a.id):
			p.ach[a.id] = true
			p.boxes.append(a)
			_note(p, "achievements")
			_say("box_wait", {}, [p.id])
			_log("%s earned the achievement \"%s\"." % [p.name, a.title])
			self_changed.emit(p.id)

func _open_box(p: Dictionary) -> void:
	var a: Dictionary = p.boxes.pop_front()
	var box: Dictionary = db.boxes[a.box]
	var loot := []
	for i in int(box.rolls) + int(_mod(p, "box_extra_roll", 0.0)):
		var item_id := _roll(box.table)
		p.inv[item_id] = int(p.inv.get(item_id, 0)) + 1
		loot.append(db.items[item_id].name)
	event.emit([p.id], {"type": "achievement", "title": a.title, "text": a.text,
		"box": box.name, "loot": loot})
	self_changed.emit(p.id)

# ---------------------------------------------------------------- stairs and the choice

func _descend(p: Dictionary) -> void:
	if p.floor + 1 >= floors.size():
		return
	p.floor += 1
	p.pos = _arrival(p)
	p.input = Vector2.ZERO
	p.excite += 15.0
	if p.companion != 0:
		var c: Dictionary = companions[p.companion]
		c.floor = p.floor
		c.pos = p.pos
	_say("descend", {"name": p.name, "floor": _floor_of(p).name})
	_count(p, "descents")
	floor_changed.emit(p.id)
	if p.floor >= CHOICE_FLOOR and p.klass == "":
		_begin_choice(p)
	self_changed.emit(p.id)

func _begin_choice(p: Dictionary) -> void:
	p.state = "choosing"
	p.offers = ClassOffers.offers(p.dossier, p.past, db, p.start)
	p.choose_until = now + float(db.classes.offer.seconds)
	_say("choose_start", {"name": p.name}, [p.id])

## The player's pick. Both ids must be among what they were offered.
func choose(pid: int, race_id: String, class_id: String) -> bool:
	var p: Dictionary = players.get(pid, {})
	if p.is_empty() or p.state != "choosing":
		return false
	var race := {}
	for r in p.offers.races:
		if r.id == race_id:
			race = r
	var klass := {}
	for c in p.offers.classes:
		if c.id == class_id:
			klass = c
	if race.is_empty() or klass.is_empty():
		return false
	p.race = race.name if race.id != "human" else "Human"
	p.klass = klass.name
	p.perk = klass.perk
	p.drawback = klass.drawback
	for source in [race, klass]:
		for s in source.get("stats", {}):
			p.stats[s] = max(1, int(p.stats[s]) + int(source.stats[s]))
	p.mods = ClassOffers.merge_mods([race.get("mods", {}), klass.get("mods", {})])
	p.state = "play"
	p.offers = {}
	_recalc(p)
	p.hp = p.max_hp
	p.excite += 20.0
	_say("chosen", {"name": p.name, "race": p.race, "klass": p.klass, "quip": klass.quip})
	_count(p, "class_chosen")
	self_changed.emit(pid)
	return true

## Banked stat points can be spent once a class is chosen, in a safe room.
func spend_point(pid: int, stat: String) -> bool:
	var p: Dictionary = players.get(pid, {})
	if p.is_empty() or p.klass == "" or p.points <= 0 or not STATS.has(stat) or not _in_safe(p):
		return false
	p.points -= 1
	p.stats[stat] = int(p.stats[stat]) + 1
	_recalc(p)
	self_changed.emit(pid)
	return true

# ---------------------------------------------------------------- parties and companions

## Invite the nearest player, or failing that recruit a waiting NPC companion.
func party_invite(pid: int) -> void:
	var p: Dictionary = players.get(pid, {})
	if p.is_empty():
		return
	var best := 0
	var best_d := PARTY_RANGE
	for o in players.values():
		if o.id != pid and o.floor == p.floor and (p.party == 0 or o.party != p.party):
			var d: float = o.pos.distance_to(p.pos)
			if d <= best_d:
				best = o.id
				best_d = d
	if best != 0:
		invites[best] = pid
		event.emit([best], {"type": "invite", "from": p.name})
		event.emit([pid], {"type": "log", "text": "Invite sent to %s." % players[best].name})
		return
	if p.party == 0 and p.companion == 0:
		for c in companions.values():
			if c.owner == 0 and c.floor == p.floor and c.pos.distance_to(p.pos) <= PARTY_RANGE:
				c.owner = pid
				p.companion = c.id
				_say("recruit", {"npc": c.def.name, "line": c.def.join}, [pid])
				_count(p, "recruits")
				self_changed.emit(pid)
				return
	event.emit([pid], {"type": "log", "text": "Nobody is close enough to invite."})

func _release_companion(p: Dictionary, speak := true) -> void:
	if p.companion == 0:
		return
	var c: Dictionary = companions[p.companion]
	if speak:
		_say("npc_leave", {"npc": c.def.name, "line": c.def.leave}, [p.id])
	c.owner = 0
	c.floor = c.home_floor
	c.pos = c.home
	p.companion = 0

func party_accept(pid: int) -> void:
	var from: int = invites.get(pid, 0)
	invites.erase(pid)
	if not players.has(pid) or not players.has(from):
		return
	var host: Dictionary = players[from]
	var p: Dictionary = players[pid]
	_leave_party(pid)
	if host.party == 0:
		host.party = _id()
		parties[host.party] = [from]
		_count(host, "parties")
	p.party = host.party
	parties[host.party].append(pid)
	host.excite += 5.0
	_say("party", {"a": host.name, "b": p.name})
	_count(p, "parties")
	# NPC helpers step aside once real players have found each other.
	_release_companion(host)
	_release_companion(p)
	for member in parties[host.party]:
		self_changed.emit(member)

func party_leave(pid: int) -> void:
	_leave_party(pid)
	self_changed.emit(pid)

func _leave_party(pid: int) -> void:
	var p: Dictionary = players.get(pid, {})
	if p.is_empty() or p.party == 0:
		return
	var party_id: int = p.party
	var members: Array = parties.get(party_id, [])
	members.erase(pid)
	p.party = 0
	if members.size() <= 1:
		for m in members:
			players[m].party = 0
			self_changed.emit(m)
		parties.erase(party_id)
	else:
		for m in members:
			self_changed.emit(m)

# ---------------------------------------------------------------- narrator

func _say(key: String, vars: Dictionary, targets: Array = []) -> void:
	var lines: Array = db.narrator.get(key, [])
	if lines.is_empty():
		return
	var text: String = str(lines[rng.randi() % lines.size()]).format(vars)
	event.emit(targets, {"type": "narrator", "text": text})

func _log(text: String) -> void:
	event.emit([], {"type": "log", "text": text})

# ---------------------------------------------------------------- tick

func tick(dt: float) -> void:
	now += dt
	_tick_players(dt)
	_tick_companions(dt)
	for f in floors:
		f.timer_left -= dt
		if f.timer_left <= 0.0:
			_collapse(f)
		_tick_mobs(f, dt)
		var still := []
		for d in f.pending:
			if d.at <= now:
				_detonate(f, d)
			else:
				still.append(d)
		f.pending = still
		_tick_spawns(f)

func _collapse(f: Dictionary) -> void:
	f.timer_left = f.timer_total
	f.mobs.clear()
	for s in f.mob_spawns:
		s.mob = 0
		s.respawn_at = 0.0
	var here := _on_floor(f.index)
	for pid in here:
		var p: Dictionary = players[pid]
		p.pos = _arrival(p)
		p.hp = p.max_hp
		p.dead_until = -1.0
		self_changed.emit(pid)
	if not here.is_empty():
		_say("collapse", {}, here)

func _tick_players(dt: float) -> void:
	for p in players.values():
		var f := _floor_of(p)
		p.excite = max(0.0, p.excite - p.excite * 0.02 * dt)
		if p.state == "choosing":
			if now >= p.choose_until:
				choose(p.id, p.offers.races[0].id, p.offers.classes[0].id)
			continue
		if not _alive(p):
			if now >= p.dead_until:
				p.dead_until = -1.0
				p.hp = p.max_hp
				p.pos = _arrival(p)
				_say("respawn", {"name": p.name}, [p.id])
				self_changed.emit(p.id)
			continue
		if p.input.length() > 0.05:
			p.facing = p.input.normalized()
			var speed: float = BASE_SPEED * _mod(p, "speed_mult", 1.0) * (1.0 + 0.02 * (p.stats.dex - BASE_STAT))
			p.pos = _move(f, p.pos, p.input * speed * dt, PLAYER_RADIUS)
		var safe := tile_at(f, p.pos) == "S"
		if safe:
			_note(p, "safe_seconds", dt)
			p.hp = min(p.max_hp, p.hp + 3.0 * dt)
			if p.get("close_call", false):
				p["close_call"] = false
				_note(p, "close_calls")
			if not p.boxes.is_empty() and now >= p.next_box_at:
				p.next_box_at = now + BOX_INTERVAL
				_open_box(p)
		else:
			p.hp = min(p.max_hp, p.hp + _mod(p, "regen", 0.0) * dt)
		for d in f.drops.values():
			if d.pos.distance_to(p.pos) <= PICKUP_RANGE:
				p.inv[d.item] = int(p.inv.get(d.item, 0)) + 1
				f.drops.erase(d.id)
				for s in f.item_spawns:
					if s.drop == d.id:
						s.drop = 0
						s.respawn_at = now + ITEM_RESPAWN
				_note(p, "pickups")
				event.emit([p.id], {"type": "log", "text": "Picked up %s." % db.items[d.item].name})
				self_changed.emit(p.id)
		if tile_at(f, p.pos) == ">":
			_descend(p)

func _tick_companions(dt: float) -> void:
	for c in companions.values():
		if c.owner == 0 or not players.has(c.owner):
			c.owner = 0
			continue
		var p: Dictionary = players[c.owner]
		var f := _floor_of(p)
		if c.pos.distance_to(p.pos) > 8.0:
			c.pos = p.pos
		# Fight whatever is closest to the owner; otherwise tag along behind.
		var target := {}
		var best_d := 4.0
		if not _in_safe(p) and _can_act(p):
			for m in f.mobs.values():
				var d: float = m.pos.distance_to(p.pos)
				if d <= best_d:
					target = m
					best_d = d
		var goal: Vector2 = p.pos - p.facing * 0.9
		if not target.is_empty():
			goal = target.pos
		var to_goal: Vector2 = goal - c.pos
		if not target.is_empty() and to_goal.length() <= 1.0:
			if now >= c.cd:
				c.cd = now + 0.9
				_floor_ev(f.index, {"type": "npc_swing", "id": c.id})
				_damage_mob(f, target, float(c.def.damage) * _mod(p, "companion_mult", 1.0), p.id, "companion")
		elif to_goal.length() > 0.3:
			c.pos = _move(f, c.pos, to_goal.normalized() * BASE_SPEED * 1.05 * dt, 0.25)

func _tick_mobs(f: Dictionary, dt: float) -> void:
	for m in f.mobs.values():
		var live := []
		for dot in m.dots:
			if dot.until > now:
				live.append(dot)
			if f.mobs.has(m.id):
				_damage_mob(f, m, dot.dps * dt, dot.owner, "thrown")
		m.dots = live
		if not f.mobs.has(m.id) or now < m.stun_until:
			continue
		# Chase the nearest living player who is not in a safe room. Each
		# player's class can change how far away they get noticed.
		var target := {}
		var best_d := 999.0
		for p in players.values():
			if p.floor != f.index or not _can_act(p) or tile_at(f, p.pos) == "S":
				continue
			var d: float = p.pos.distance_to(m.pos)
			var reach := AGGRO_RANGE * _mod(p, "aggro_mult", 1.0)
			if p.id == m.target:
				reach = max(reach, AGGRO_RANGE * 2.0)
			if d <= reach and d < best_d:
				target = p
				best_d = d
		var goal: Vector2 = m.home
		if not target.is_empty():
			goal = target.pos
		var to_goal: Vector2 = goal - m.pos
		var dist := to_goal.length()
		if not target.is_empty() and dist <= 0.9:
			if now >= m.cd_attack:
				m.cd_attack = now + 1.0
				_floor_ev(f.index, {"type": "bite", "id": m.id, "target": target.id})
				_damage_player(target, m.damage, m)
			continue
		if dist < 0.1 or now < m.root_until:
			continue
		var speed: float = db.mobs[m.type].speed
		if now < m.slow_until:
			speed *= m.slow_factor
		else:
			m.slow_factor = 1.0
		m.pos = _move(f, m.pos, to_goal.normalized() * speed * dt, 0.25, true)

func _tick_spawns(f: Dictionary) -> void:
	# Deeper levels have tougher versions of everything.
	var scale: float = 1.0 + 0.6 * f.index
	for s in f.mob_spawns:
		if s.mob == 0 and now >= s.respawn_at:
			var def: Dictionary = db.mobs[s.type]
			var id := _id()
			f.mobs[id] = {
				"id": id, "type": s.type, "pos": s.pos, "home": s.pos,
				"hp": float(def.hp) * scale, "max_hp": float(def.hp) * scale,
				"damage": float(def.damage) * scale, "xp": int(def.xp * scale),
				"level": int(def.level) + 2 * f.index,
				"target": 0, "cd_attack": 0.0, "dots": [],
				"slow_until": 0.0, "slow_factor": 1.0, "root_until": 0.0, "stun_until": 0.0,
			}
			s.mob = id
	for s in f.item_spawns:
		if s.drop == 0 and now >= s.respawn_at:
			s.drop = _drop(f, db.items.keys()[rng.randi() % db.items.size()], s.pos)

# ---------------------------------------------------------------- views

func viewers(p: Dictionary) -> int:
	return int(round((5.0 + p.excite * 10.0) * (1.0 + 0.1 * (p.stats.cha - BASE_STAT)) * _mod(p, "viewers_mult", 1.0)))

func floor_info(pid: int) -> Dictionary:
	var f := _floor_of(players[pid])
	return {"index": f.index, "name": f.name, "grid": f.grid, "timer_total": f.timer_total}

## Small, frequent state for everyone on one level.
func snapshot(index: int) -> Dictionary:
	var f: Dictionary = floors[index]
	var ps := []
	for p in players.values():
		if p.floor == index:
			ps.append([p.id, p.name, p.pos, p.hp, p.max_hp, p.party, not _alive(p), p.facing, p.klass])
	var ms := []
	for m in f.mobs.values():
		ms.append([m.id, m.type, m.pos, m.hp, now < m.slow_until or now < m.root_until or now < m.stun_until,
			not m.dots.is_empty(), m.max_hp, m.level])
	var ds := []
	for d in f.drops.values():
		ds.append([d.id, d.item, d.pos])
	var ns := []
	for c in companions.values():
		if c.floor == index:
			ns.append([c.id, c.def.name, c.pos, c.def.color, c.owner])
	return {"timer": f.timer_left, "p": ps, "m": ms, "d": ds, "n": ns}

## Private state for one player, sent only when it changes.
func self_state(pid: int) -> Dictionary:
	var p: Dictionary = players.get(pid, {})
	if p.is_empty():
		return {}
	var skills := {}
	for s in p.skills:
		skills[s] = _skill_level(p, s)
	var state := {
		"id": pid, "level": p.level, "xp": p.xp, "xp_needed": _xp_needed(p.level),
		"stats": p.stats, "points": p.points, "mana": p.stats.int * 3,
		"race": p.race, "klass": p.klass, "perk": p.perk, "drawback": p.drawback,
		"past": ClassOffers.past_life(p.past, db).name,
		"crafting": _mod(p, "crafting", 0.0) > 0.0, "can_spend": p.klass != "" and _in_safe(p),
		"inv": p.inv, "abilities": p.abilities, "party": parties.get(p.party, []),
		"companion": companions[p.companion].def.name if p.companion != 0 else "",
		"pet": p.pet, "skills": skills, "viewers": viewers(p),
		"achievements": p.ach.size(), "boxes_waiting": p.boxes.size(), "state": p.state,
	}
	if p.state == "choosing":
		state["offers"] = p.offers
		state["choose_seconds"] = max(0.0, p.choose_until - now)
	return state
