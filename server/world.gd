class_name World
extends RefCounted
## The authoritative game simulation. Runs only on the server. It has no
## dependency on rendering or networking, so tests can drive it directly.
## Positions are in tile units on a flat grid; clients project them to isometric.

signal event(targets: Array, ev: Dictionary)  # targets empty = everyone
signal self_changed(pid: int)

const PLAYER_SPEED := 4.0
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
const MAX_COMBO := 3

var db: Dictionary
var rng := RandomNumberGenerator.new()
var world_seed: int
var now := 0.0
var timer_total := 1800.0
var timer_left := 1800.0
var grid: Array = []
var width := 0
var height := 0
var player_spawns: Array = []
var mob_spawns: Array = []
var item_spawns: Array = []
var players := {}
var mobs := {}
var drops := {}
var pending: Array = []
var parties := {}
var invites := {}
var canon := {}
var _next_id := 1

func _init(p_db: Dictionary, p_seed: int = 1) -> void:
	db = p_db
	world_seed = p_seed
	rng.seed = p_seed
	_load_level()

# ---------------------------------------------------------------- level

func _load_level() -> void:
	var level: Dictionary = db.level
	timer_total = float(level.timer_seconds)
	timer_left = timer_total
	grid.clear()
	player_spawns.clear()
	mob_spawns.clear()
	item_spawns.clear()
	var rows: Array = level.map
	height = rows.size()
	width = str(rows[0]).length()
	for y in height:
		var row: String = rows[y]
		var out := ""
		for x in width:
			var c := row[x]
			if c in ["P", "m", "G", "i"]:
				var floor_c := out[x - 1] if x > 0 and out[x - 1] != "#" else "."
				var pos := Vector2(x + 0.5, y + 0.5)
				match c:
					"P": player_spawns.append(pos)
					"m": mob_spawns.append({"pos": pos, "type": "drain_leech" if floor_c == "~" else "sump_rat", "mob": 0, "respawn_at": 0.0})
					"G": mob_spawns.append({"pos": pos, "type": "scrap_golem", "mob": 0, "respawn_at": 0.0})
					"i": item_spawns.append({"pos": pos, "drop": 0, "respawn_at": 0.0})
				c = floor_c
			out += c
		grid.append(out)

func tile_at(pos: Vector2) -> String:
	var x := int(floor(pos.x))
	var y := int(floor(pos.y))
	if x < 0 or y < 0 or x >= width or y >= height:
		return "#"
	return grid[y][x]

func tags_at(pos: Vector2) -> Array:
	match tile_at(pos):
		"~": return ["wet"]
		",": return ["narrow"]
		"S": return ["safe"]
		".": return ["open"]
	return []

func _free(pos: Vector2, r: float, no_safe: bool) -> bool:
	for off in [Vector2(-r, -r), Vector2(r, -r), Vector2(-r, r), Vector2(r, r)]:
		var c := tile_at(pos + off)
		if c == "#" or (no_safe and c == "S"):
			return false
	return true

func _move(pos: Vector2, delta: Vector2, r: float, no_safe := false) -> Vector2:
	var nx := Vector2(pos.x + delta.x, pos.y)
	if _free(nx, r, no_safe):
		pos = nx
	var ny := Vector2(pos.x, pos.y + delta.y)
	if _free(ny, r, no_safe):
		pos = ny
	return pos

func _id() -> int:
	_next_id += 1
	return _next_id

# ---------------------------------------------------------------- players

func add_player(pid: int, player_name: String) -> void:
	var clean := player_name.strip_edges().substr(0, 16)
	if clean == "":
		clean = "Crawler%d" % (pid % 1000)
	players[pid] = {
		"id": pid, "name": clean, "pos": _spawn_point(pid), "input": Vector2.ZERO,
		"facing": Vector2(1, 1).normalized(), "hp": 30.0, "max_hp": 30.0, "level": 1, "xp": 0,
		"inv": {"oil_flask": 3, "rag": 3, "flint": 2}, "abilities": [], "ability_ready": {},
		"party": 0, "skills": {"brawling": 0, "throwing": 0, "tinkering": 0},
		"combo": {}, "counters": {}, "ach": {}, "excite": 0.0,
		"cd_melee": 0.0, "cd_throw": 0.0, "dead_until": -1.0,
	}
	_say("welcome", {"name": clean}, [pid])
	_log("%s has entered the dungeon." % clean)
	self_changed.emit(pid)

func remove_player(pid: int) -> void:
	if not players.has(pid):
		return
	var left_name: String = players[pid].name
	_leave_party(pid)
	invites.erase(pid)
	players.erase(pid)
	_log("%s has left the dungeon." % left_name)

func _spawn_point(pid: int) -> Vector2:
	if player_spawns.is_empty():
		return Vector2(1.5, 1.5)
	return player_spawns[pid % player_spawns.size()]

func set_input(pid: int, dir: Vector2) -> void:
	if players.has(pid):
		players[pid].input = dir.limit_length(1.0)

func chat(pid: int, text: String) -> void:
	if not players.has(pid):
		return
	var clean := text.strip_edges().substr(0, 200)
	if clean != "":
		event.emit([], {"type": "chat", "from": players[pid].name, "text": clean})

func _alive(p: Dictionary) -> bool:
	return p.dead_until < 0.0

func _skill_level(p: Dictionary, skill: String) -> int:
	return min(15, int(sqrt(float(p.skills[skill]) / 5.0)))

func _ctx(p: Dictionary) -> Dictionary:
	return {
		"room_tags": tags_at(p.pos), "hp_frac": p.hp / p.max_hp,
		"allies_near": _allies_near(p).size(), "time_frac": timer_left / timer_total,
		"player_level": p.level,
	}

func _allies_near(p: Dictionary, dist := 6.0) -> Array:
	var out := []
	if p.party == 0:
		return out
	for other_id in parties.get(p.party, []):
		if other_id != p.id and players.has(other_id):
			var o: Dictionary = players[other_id]
			if _alive(o) and o.pos.distance_to(p.pos) <= dist:
				out.append(other_id)
	return out

# ---------------------------------------------------------------- combat

func melee(pid: int) -> void:
	var p: Dictionary = players.get(pid, {})
	if p.is_empty() or not _alive(p) or now < p.cd_melee or tile_at(p.pos) == "S":
		return
	p.cd_melee = now + MELEE_CD
	var best := {}
	var best_d := MELEE_RANGE
	for m in mobs.values():
		var d: float = m.pos.distance_to(p.pos)
		if d <= best_d:
			best = m
			best_d = d
	event.emit([], {"type": "swing", "id": pid})
	if best.is_empty():
		return
	p.facing = (best.pos - p.pos).normalized()
	p.skills.brawling += 1
	var dmg := MELEE_DAMAGE * (1.0 + 0.05 * _skill_level(p, "brawling"))
	_damage_mob(best, dmg, pid)

func throw_items(pid: int, items: Array, target: Vector2, ability_idx := -1) -> bool:
	var p: Dictionary = players.get(pid, {})
	# No fighting from inside a safe room: you are safe there, and so is everything else.
	if p.is_empty() or not _alive(p) or now < p.cd_throw or tile_at(p.pos) == "S":
		return false
	var ability := {}
	if ability_idx >= 0:
		if ability_idx >= p.abilities.size():
			return false
		ability = p.abilities[ability_idx]
		items = ability.items
	if items.is_empty() or items.size() > MAX_COMBO:
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
	var skill_mult := 1.0 + 0.05 * _skill_level(p, "throwing")
	for i in payload.effects.size():
		payload.effects[i] = Invention._scaled(payload.effects[i], skill_mult)
	var offset: Vector2 = target - p.pos
	offset = offset.limit_length(payload.range)
	var hit_pos: Vector2 = p.pos + offset
	if offset.length() > 0.01:
		p.facing = offset.normalized()
	p.cd_throw = now + THROW_CD
	p.skills.throwing += 1
	if items.size() > 1:
		p.skills.tinkering += 1
	pending.append({
		"at": now + THROW_FLIGHT + payload.delay, "pos": hit_pos, "owner": pid,
		"payload": payload, "sig": sig, "items": items.duplicate(), "ctx": ctx,
		"is_ability": not ability.is_empty(),
	})
	event.emit([], {"type": "throw", "from": p.pos, "to": hit_pos, "flight": THROW_FLIGHT,
		"delay": payload.delay, "color": db.items[items[0]].color})
	_count(p, "throw")
	self_changed.emit(pid)
	return true

func _detonate(d: Dictionary) -> void:
	var payload: Dictionary = d.payload
	var hit := []
	for m in mobs.values():
		if m.pos.distance_to(d.pos) <= payload.radius + float(db.mobs[m.type].size) * 0.3:
			hit.append(m)
	var effect_ids := []
	for e in payload.effects:
		effect_ids.append(e.id)
	event.emit([], {"type": "boom", "pos": d.pos, "radius": payload.radius, "effects": effect_ids})
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
		if _damage_mob(m, dmg, d.owner):
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

## Watch what the player keeps doing. When a combination has proved itself,
## hand the history to the invention engine.
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
	# Canon registry: a name belongs to the first inventor's version.
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
	_count(p, "discovery")
	self_changed.emit(p.id)

func _damage_mob(m: Dictionary, amount: float, owner: int) -> bool:
	if not mobs.has(m.id):
		return false
	m.hp -= amount
	m.target = owner
	if m.hp > 0.0:
		return false
	mobs.erase(m.id)
	for s in mob_spawns:
		if s.mob == m.id:
			s.mob = 0
			s.respawn_at = now + MOB_RESPAWN
	event.emit([], {"type": "mob_dead", "id": m.id, "pos": m.pos})
	if rng.randf() < 0.6:
		_drop(_roll(db.boxes.tin.table), m.pos)
	var killer: Dictionary = players.get(owner, {})
	if killer.is_empty():
		return true
	killer.excite += 3.0
	_count(killer, "kill")
	var share := [owner]
	for ally in _allies_near(killer, SHARE_RANGE):
		share.append(ally)
	for pid in share:
		_give_xp(players[pid], int(db.mobs[m.type].xp))
	return true

func _give_xp(p: Dictionary, amount: int) -> void:
	p.xp += amount
	while p.xp >= _xp_needed(p.level):
		p.xp -= _xp_needed(p.level)
		p.level += 1
		p.max_hp += 5.0
		p.hp = p.max_hp
		_say("levelup", {"name": p.name, "level": p.level}, [p.id])
	self_changed.emit(p.id)

func _xp_needed(level: int) -> int:
	return int(20.0 * pow(level, 1.5))

func _damage_player(p: Dictionary, amount: float) -> void:
	if not _alive(p) or tile_at(p.pos) == "S":
		return
	p.hp -= amount
	if p.hp > 0.0:
		return
	p.hp = 0.0
	p.dead_until = now + RESPAWN_TIME
	p.input = Vector2.ZERO
	p.excite += 10.0
	_say("death", {"name": p.name})
	_count(p, "death")
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

func _drop(item_id: String, pos: Vector2) -> int:
	var id := _id()
	drops[id] = {"id": id, "item": item_id, "pos": pos}
	return id

func _count(p: Dictionary, ev: String) -> void:
	p.counters[ev] = int(p.counters.get(ev, 0)) + 1
	for a in db.achievements:
		if a.event == ev and p.counters[ev] >= int(a.count) and not p.ach.has(a.id):
			p.ach[a.id] = true
			var box: Dictionary = db.boxes[a.box]
			var loot := []
			for i in int(box.rolls):
				var item_id := _roll(box.table)
				p.inv[item_id] = int(p.inv.get(item_id, 0)) + 1
				loot.append(db.items[item_id].name)
			event.emit([p.id], {"type": "achievement", "title": a.title, "text": a.text,
				"box": box.name, "loot": loot})
			_log("%s earned the achievement \"%s\"." % [p.name, a.title])
			self_changed.emit(p.id)

# ---------------------------------------------------------------- parties

func party_invite(pid: int) -> void:
	var p: Dictionary = players.get(pid, {})
	if p.is_empty():
		return
	var best := 0
	var best_d := PARTY_RANGE
	for o in players.values():
		if o.id != pid and (p.party == 0 or o.party != p.party):
			var d: float = o.pos.distance_to(p.pos)
			if d <= best_d:
				best = o.id
				best_d = d
	if best == 0:
		event.emit([pid], {"type": "log", "text": "Nobody is close enough to invite."})
		return
	invites[best] = pid
	event.emit([best], {"type": "invite", "from": p.name})
	event.emit([pid], {"type": "log", "text": "Invite sent to %s." % players[best].name})

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
		_count(host, "party_join")
	p.party = host.party
	parties[host.party].append(pid)
	host.excite += 5.0
	_say("party", {"a": host.name, "b": p.name})
	_count(p, "party_join")
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
	timer_left -= dt
	if timer_left <= 0.0:
		_collapse()
	_tick_players(dt)
	_tick_mobs(dt)
	var still := []
	for d in pending:
		if d.at <= now:
			_detonate(d)
		else:
			still.append(d)
	pending = still
	_tick_spawns()

func _collapse() -> void:
	timer_left = timer_total
	mobs.clear()
	for s in mob_spawns:
		s.mob = 0
		s.respawn_at = 0.0
	for p in players.values():
		p.pos = _spawn_point(p.id)
		p.hp = p.max_hp
		p.dead_until = -1.0
		self_changed.emit(p.id)
	_say("collapse", {})

func _tick_players(dt: float) -> void:
	for p in players.values():
		p.excite = max(0.0, p.excite - p.excite * 0.02 * dt)
		if not _alive(p):
			if now >= p.dead_until:
				p.dead_until = -1.0
				p.hp = p.max_hp
				p.pos = _spawn_point(p.id)
				_say("respawn", {"name": p.name}, [p.id])
				self_changed.emit(p.id)
			continue
		if p.input.length() > 0.05:
			p.facing = p.input.normalized()
			p.pos = _move(p.pos, p.input * PLAYER_SPEED * dt, PLAYER_RADIUS)
		if tile_at(p.pos) == "S" and p.hp < p.max_hp:
			p.hp = min(p.max_hp, p.hp + 3.0 * dt)
		for d in drops.values():
			if d.pos.distance_to(p.pos) <= PICKUP_RANGE:
				p.inv[d.item] = int(p.inv.get(d.item, 0)) + 1
				drops.erase(d.id)
				for s in item_spawns:
					if s.drop == d.id:
						s.drop = 0
						s.respawn_at = now + ITEM_RESPAWN
				event.emit([p.id], {"type": "log", "text": "Picked up %s." % db.items[d.item].name})
				self_changed.emit(p.id)

func _tick_mobs(dt: float) -> void:
	for m in mobs.values():
		var def: Dictionary = db.mobs[m.type]
		# Damage over time
		var live := []
		for dot in m.dots:
			if dot.until > now:
				live.append(dot)
			if mobs.has(m.id):
				_damage_mob(m, dot.dps * dt, dot.owner)
		m.dots = live
		if not mobs.has(m.id) or now < m.stun_until:
			continue
		# Pick the nearest living player who is not hiding in a safe room
		var target := {}
		var best_d := AGGRO_RANGE
		for p in players.values():
			if _alive(p) and tile_at(p.pos) != "S":
				var d: float = p.pos.distance_to(m.pos)
				if d <= best_d or (p.id == m.target and d <= AGGRO_RANGE * 2.0 and target.is_empty()):
					target = p
					best_d = min(best_d, d)
		var goal: Vector2 = m.home
		if not target.is_empty():
			goal = target.pos
		var to_goal: Vector2 = goal - m.pos
		var dist := to_goal.length()
		if not target.is_empty() and dist <= 0.9:
			if now >= m.cd_attack:
				m.cd_attack = now + 1.0
				_damage_player(target, float(def.damage))
				event.emit([], {"type": "bite", "id": m.id, "target": target.id})
			continue
		if dist < 0.1 or now < m.root_until:
			continue
		var speed: float = def.speed
		if now < m.slow_until:
			speed *= m.slow_factor
		else:
			m.slow_factor = 1.0
		m.pos = _move(m.pos, to_goal.normalized() * speed * dt, 0.25, true)

func _tick_spawns() -> void:
	for s in mob_spawns:
		if s.mob == 0 and now >= s.respawn_at:
			var id := _id()
			mobs[id] = {
				"id": id, "type": s.type, "pos": s.pos, "home": s.pos,
				"hp": float(db.mobs[s.type].hp), "target": 0, "cd_attack": 0.0, "dots": [],
				"slow_until": 0.0, "slow_factor": 1.0, "root_until": 0.0, "stun_until": 0.0,
			}
			s.mob = id
	for s in item_spawns:
		if s.drop == 0 and now >= s.respawn_at:
			s.drop = _drop(db.items.keys()[rng.randi() % db.items.size()], s.pos)

# ---------------------------------------------------------------- views

func viewers(p: Dictionary) -> int:
	return int(round(5.0 + p.excite * 10.0))

## Small, frequent state everyone needs.
func snapshot() -> Dictionary:
	var ps := []
	for p in players.values():
		ps.append([p.id, p.name, p.pos, p.hp, p.max_hp, p.party, not _alive(p), p.facing])
	var ms := []
	for m in mobs.values():
		ms.append([m.id, m.type, m.pos, m.hp, now < m.slow_until or now < m.root_until or now < m.stun_until, not m.dots.is_empty()])
	var ds := []
	for d in drops.values():
		ds.append([d.id, d.item, d.pos])
	return {"timer": timer_left, "p": ps, "m": ms, "d": ds}

## Private state for one player, sent only when it changes.
func self_state(pid: int) -> Dictionary:
	var p: Dictionary = players.get(pid, {})
	if p.is_empty():
		return {}
	var skills := {}
	for s in p.skills:
		skills[s] = _skill_level(p, s)
	return {
		"id": pid, "level": p.level, "xp": p.xp, "xp_needed": _xp_needed(p.level),
		"inv": p.inv, "abilities": p.abilities, "party": parties.get(p.party, []),
		"skills": skills, "viewers": viewers(p), "achievements": p.ach.size(),
	}
