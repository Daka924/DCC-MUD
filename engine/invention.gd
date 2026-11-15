class_name Invention
extends RefCounted
## The invention engine. Pure, deterministic functions: the same inputs always
## give the same ability, so it can be tested and balanced. No AI model involved.
##
##   resolve()      what any pile of items does when thrown, from tag rules alone
##   invent()       turn a player's history with a combination into a named ability
##   payload_for()  what an invented ability does right now, given the situation

const ROOM_PRIORITY := ["wet", "narrow", "safe", "open"]

static func signature(items: Array) -> String:
	var sorted := items.duplicate()
	sorted.sort()
	return "+".join(PackedStringArray(sorted))

static func combined_tags(items: Array, db: Dictionary) -> Array:
	var tags := []
	for item_id in items:
		for t in db.items.get(item_id, {}).get("tags", []):
			if not tags.has(t):
				tags.append(t)
	return tags

static func _matches(rule: Dictionary, tags: Array) -> bool:
	for t in rule.get("all", []):
		if not tags.has(t):
			return false
	var any: Array = rule.get("any", [])
	if any.is_empty():
		return true
	for t in any:
		if tags.has(t):
			return true
	return false

static func _scaled(effect: Dictionary, mult: float) -> Dictionary:
	var e := effect.duplicate()
	if e.kind == "damage" or e.kind == "dot":
		e.power = e.power * mult
	else:
		e.duration = e.duration * mult
	return e

## What a set of items does when thrown, with no history attached.
static func resolve(items: Array, db: Dictionary) -> Dictionary:
	var rules: Dictionary = db.tag_rules
	var tags := combined_tags(items, db)
	var effects := []
	var radius: float = rules.base_radius
	var cost := 0.0
	for rule in rules.effects:
		if _matches(rule, tags):
			effects.append({
				"id": rule.id, "kind": rule.kind, "power": float(rule.power),
				"duration": float(rule.get("duration", 0.0)), "cost": float(rule.cost),
			})
			cost += float(rule.cost)
			radius = max(radius, float(rule.get("radius", 0.0)))
	var delay := 0.0
	var throw_range: float = rules.base_range
	var power_mult := 1.0
	var mods := []
	for mod in rules.mods:
		if _matches(mod, tags):
			mods.append(mod.id)
			radius = max(radius, float(mod.get("radius", 0.0)))
			delay += float(mod.get("delay", 0.0))
			throw_range += float(mod.get("range", 0.0))
			power_mult *= float(mod.get("power_mult", 1.0))
	if power_mult != 1.0:
		for i in effects.size():
			effects[i] = _scaled(effects[i], power_mult)
	return {
		"sig": signature(items), "items": items.duplicate(), "tags": tags,
		"effects": effects, "mods": mods, "radius": radius, "delay": delay,
		"range": throw_range, "cost": cost, "cooldown": 0.0, "bane": {},
	}

static func _pick(words: Array, key: String) -> String:
	if words.is_empty():
		return ""
	return str(words[abs(key.hash()) % words.size()])

static func _dominant(effects: Array) -> Dictionary:
	var best := {}
	for e in effects:
		if best.is_empty() or e.cost > best.cost:
			best = e
	return best

## Build a named ability from how the player found it.
## ctx: items, room_tags, target_family, hp_frac, allies_near, time_frac,
##      player_id, player_level, world_seed
static func invent(ctx: Dictionary, db: Dictionary) -> Dictionary:
	var rules: Dictionary = db.context
	var base := resolve(ctx.items, db)
	var traits := []

	# Where it was first used gives a home bonus.
	var room_words := []
	for tag in ROOM_PRIORITY:
		if ctx.get("room_tags", []).has(tag) and rules.room.has(tag):
			var r: Dictionary = rules.room[tag]
			var t := r.duplicate()
			t["id"] = r.trait
			t["when_room"] = tag
			t.erase("word")
			t.erase("trait")
			traits.append(t)
			room_words = r.word
			break

	# What it was first used on gives a bonus against that family.
	var family: String = ctx.get("target_family", "")
	if family != "":
		traits.append({
			"id": "bane", "family": family, "power_mult": float(rules.family.power_mult),
			"text": "Grudge: +%d%% power against %s" % [roundi((rules.family.power_mult - 1.0) * 100), family],
		})

	# The state the player was in.
	if ctx.get("hp_frac", 1.0) < rules.desperate.hp_below:
		traits.append({"id": "desperate", "hp_below": rules.desperate.hp_below,
			"power_mult": rules.desperate.power_mult, "text": rules.desperate.text})
	if ctx.get("allies_near", 0) > 0:
		traits.append({"id": "showboat", "per_ally": rules.showboat.per_ally,
			"max_allies": rules.showboat.max_allies, "text": rules.showboat.text})
	if ctx.get("time_frac", 1.0) < rules.buzzer.time_below:
		traits.append({"id": "buzzer", "time_below": rules.buzzer.time_below,
			"cooldown_mult": rules.buzzer.cooldown_mult, "text": rules.buzzer.text})

	# Each ingredient mod is listed as a trait too, so the card explains itself.
	for mod in db.tag_rules.mods:
		if base.mods.has(mod.id):
			traits.append({"id": mod.id, "text": mod.text})

	# Power budget: scale everything down if the combination is too strong
	# for this player's level.
	var budget: float = rules.budget.base + rules.budget.per_player_level * ctx.get("player_level", 1)
	var scale := 1.0
	if base.cost > budget:
		scale = budget / base.cost
	var effects := []
	for e in base.effects:
		effects.append(_scaled(e, scale))

	# Name: a word from the place (or the prey), plus a word from the main effect.
	var key := "%s|%s|%s" % [base.sig, ctx.get("player_id", 0), ctx.get("world_seed", 0)]
	var dominant := _dominant(base.effects)
	var core_words := []
	for rule in db.tag_rules.effects:
		if rule.id == dominant.get("id", ""):
			core_words = rule.word
	var prefix := _pick(room_words, key)
	if prefix == "" and family != "":
		prefix = _pick(rules.family.words.get(family, []), key)
	if prefix == "":
		prefix = _pick(["Pocket", "Bargain", "Back-Alley"], key)
	var ability_name := "%s %s" % [prefix, _pick(core_words, key + "c")]
	var quips: Array = db.narrator.quips.get(dominant.get("kind", "damage"), [""])

	return {
		"sig": base.sig, "items": base.items, "name": ability_name,
		"effects": effects, "radius": base.radius, "delay": base.delay, "range": base.range,
		"cooldown": float(rules.ability.cooldown), "traits": traits,
		"level": 1, "uses": 0, "budget_scale": scale,
		"quip": _pick(quips, key + "q"),
		"born": {"room_tags": ctx.get("room_tags", []), "family": family, "hp_frac": ctx.get("hp_frac", 1.0)},
	}

## What the ability does on this use. use_ctx: room_tags, hp_frac, allies_near, time_frac
static func payload_for(ability: Dictionary, use_ctx: Dictionary, db: Dictionary) -> Dictionary:
	var rules: Dictionary = db.context
	var power := 1.0 + float(rules.ability.power_per_level) * (int(ability.level) - 1)
	var radius: float = ability.radius
	var throw_range: float = ability.range
	var cooldown: float = ability.cooldown
	var bane := {}
	var active := []
	for t in ability.traits:
		var on := false
		match t.id:
			"bane":
				bane = {"family": t.family, "mult": float(t.power_mult)}
				continue
			"desperate":
				on = use_ctx.get("hp_frac", 1.0) < t.hp_below
			"showboat":
				var allies: int = min(int(use_ctx.get("allies_near", 0)), int(t.max_allies))
				if allies > 0:
					power *= 1.0 + float(t.per_ally) * allies
					active.append(t.id)
				continue
			"buzzer":
				on = use_ctx.get("time_frac", 1.0) < t.time_below
			_:
				if t.has("when_room"):
					on = use_ctx.get("room_tags", []).has(t.when_room)
		if on:
			active.append(t.id)
			power *= float(t.get("power_mult", 1.0))
			radius *= float(t.get("radius_mult", 1.0))
			throw_range += float(t.get("range_add", 0.0))
			cooldown *= float(t.get("cooldown_mult", 1.0))
	var effects := []
	for e in ability.effects:
		effects.append(_scaled(e, power))
	return {
		"sig": ability.sig, "items": ability.items, "effects": effects, "radius": radius,
		"delay": ability.delay, "range": throw_range, "cooldown": cooldown, "bane": bane,
		"active_traits": active,
	}

## Call after each use. Returns true when the ability gained a level.
static func record_use(ability: Dictionary, db: Dictionary) -> bool:
	var rules: Dictionary = db.context.ability
	ability.uses = int(ability.uses) + 1
	var target: int = min(int(rules.max_level), 1 + int(ability.uses) / int(rules.uses_per_level))
	if target > int(ability.level):
		ability.level = target
		return true
	return false
