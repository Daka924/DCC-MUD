class_name ClassOffers
extends RefCounted
## Builds each player's personal list of races and classes for the level 3
## choice from their dossier (what they did on the first two levels) and their
## past life. Pure and deterministic: no AI model involved.

const MULT_SUFFIX := "_mult"

static func past_life(past_id: String, db: Dictionary) -> Dictionary:
	for p in db.past_lives.past_lives:
		if p.id == past_id:
			return p
	return db.past_lives.past_lives[0]

static func _qualifies(entry: Dictionary, dossier: Dictionary, past: Dictionary) -> bool:
	var needs: Dictionary = entry.get("needs", {})
	for key in needs:
		if float(dossier.get(key, 0)) < float(needs[key]):
			return false
	var needs_max: Dictionary = entry.get("needs_max", {})
	for key in needs_max:
		if float(dossier.get(key, 0)) > float(needs_max[key]):
			return false
	var tags: Array = entry.get("needs_past", [])
	if tags.is_empty():
		return true
	for t in tags:
		if past.tags.has(t):
			return true
	return false

## Combine several mod dictionaries. Keys ending in _mult multiply; others add.
static func merge_mods(list: Array) -> Dictionary:
	var out := {}
	for mods in list:
		for key in mods:
			if str(key).ends_with(MULT_SUFFIX) or key == "party_aura":
				out[key] = float(out.get(key, 1.0)) * float(mods[key])
			else:
				out[key] = float(out.get(key, 0.0)) + float(mods[key])
	return out

static func races(dossier: Dictionary, past: Dictionary, db: Dictionary) -> Array:
	var out := []
	for r in db.races.races:
		if _qualifies(r, dossier, past):
			out.append(r)
	return out

## The player's tag profile: tag -> weight, built from who they were, where
## they started and what the dossier says they did. 'why' maps each tag to a
## plain-language reason, shown to the player with the class.
static func profile(dossier: Dictionary, past: Dictionary, db: Dictionary, start := 0) -> Dictionary:
	var parts: Dictionary = db.class_parts
	var weights := {}
	var why := {}
	for t in past.tags:
		weights[t] = float(weights.get(t, 0.0)) + float(parts.past_weight)
		why[t] = "you used to be a %s" % str(past.name).to_lower()
	var start_tags: Array = db.floors.floors[0].get("start_tags", [])
	if start >= 0 and start < start_tags.size():
		for t in start_tags[start]:
			weights[t] = float(weights.get(t, 0.0)) + float(parts.start_weight)
			if not why.has(t):
				why[t] = "you woke up in %s" % db.floors.floors[0].starts[start]
	for sig in parts.signals:
		var total := 0.0
		for key in sig["keys"]:
			total += float(dossier.get(key, 0))
		var add := 0.0
		if sig.has("below"):
			if total < float(sig.below):
				add = float(sig.weight)
		else:
			add = min(float(sig.cap), floor(total / float(sig.per)))
		if add > 0.0:
			weights[sig.tag] = float(weights.get(sig.tag, 0.0)) + add
			why[sig.tag] = sig.why      # what you did outranks who you were
	return {"weights": weights, "why": why}

## A small repeatable number in 0..1 so ties break the same way every time
## for the same player history, and differently for different ones.
static func _jitter(seed_text: String, id: String) -> float:
	return float(abs((seed_text + "|" + id).hash()) % 1000) / 1000.0

static func _score(tags: Array, weights: Dictionary) -> float:
	var total := 0.0
	for t in tags:
		total += float(weights.get(t, 0.0))
	return total

## Plain-language lines for a set of mods, split into good and bad.
static func describe(mods: Dictionary) -> Dictionary:
	var good := []
	var bad := []
	var pct := {"melee_mult": "melee damage", "throw_mult": "thrown damage", "hp_mult": "health",
		"speed_mult": "movement speed", "xp_mult": "experience", "viewers_mult": "viewers",
		"companion_mult": "companion damage"}
	for key in mods:
		var v := float(mods[key])
		if pct.has(key):
			var change := int(round((v - 1.0) * 100.0))
			if change > 0:
				good.append("+%d%% %s" % [change, pct[key]])
			elif change < 0:
				bad.append("%d%% %s" % [change, pct[key]])
			continue
		match key:
			"aggro_mult":
				var change := int(round((v - 1.0) * 100.0))
				if change < 0:
					good.append("monsters notice you from %d%% less far" % -change)
				elif change > 0:
					bad.append("monsters notice you from %d%% further" % change)
			"party_aura":
				if v > 1.0:
					good.append("you and nearby allies deal +%d%% damage" % int(round((v - 1.0) * 100.0)))
			"stun_chance":
				good.append("%d%% chance to stun on melee hits" % int(round(v * 100.0)))
			"heal_on_melee":
				good.append("%d%% chance to heal on melee hits" % int(round(v * 100.0)))
			"regen":
				good.append("regenerates %s health per second" % str(snapped(v, 0.1)))
			"thorns":
				good.append("attackers take %s damage" % str(snapped(v, 0.1)))
			"box_extra_roll":
				good.append("+%d item%s in every loot box" % [int(v), "" if int(v) == 1 else "s"])
			"throw_range":
				good.append("+%s throwing range" % str(snapped(v, 0.1)))
			"crafting":
				good.append("can combine items into inventions")
	return {"good": good, "bad": bad}

static func _sentence(lines: Array, empty: String) -> String:
	if lines.is_empty():
		return empty
	var text := "; ".join(lines)
	return text.substr(0, 1).to_upper() + text.substr(1)

## Classes built for this one player: the best-matching cores (the job) each
## paired with a twist (a describing word), named after their past life.
static func generated(dossier: Dictionary, past: Dictionary, db: Dictionary, start := 0) -> Array:
	var parts: Dictionary = db.class_parts
	var prof := profile(dossier, past, db, start)
	var weights: Dictionary = prof.weights.duplicate()
	var tag_names: Array = weights.keys()
	tag_names.sort()
	var seed_text := str(past.id)
	for t in tag_names:
		seed_text += ",%s=%d" % [t, int(weights[t])]
	var out := []
	var used_cores := {}
	var used_twists := {}
	for n in int(db.classes.offer.generated_max):
		var core := {}
		var best := 0.0
		for c in parts.cores:
			if used_cores.has(c.id):
				continue
			var s := _score(c.tags, weights)
			if s <= 0.0:
				continue
			s += _jitter(seed_text, c.id) * 0.9
			if s > best:
				best = s
				core = c
		if core.is_empty():
			break
		used_cores[core.id] = true
		var patterns: Array = parts.patterns
		var pattern: String = patterns[abs((seed_text + core.id).hash()) % patterns.size()]
		# Prefer a twist that says something the core does not already say.
		# A name without a describing word gets no twist.
		var twist := {"id": "plain", "adj": "", "tags": [], "mods": {}}
		if pattern.contains("{adj}"):
			var twist_weights: Dictionary = prof.weights.duplicate()
			for t in core.tags:
				if twist_weights.has(t):
					twist_weights[t] = float(twist_weights[t]) * 0.3
			best = -1.0
			for tw in parts.twists:
				if used_twists.has(tw.id):
					continue
				var s := _score(tw.tags, twist_weights) + _jitter(seed_text, tw.id) * 0.9
				if s > best:
					best = s
					twist = tw
			used_twists[twist.id] = true
		# Later picks lean on other parts of the profile, for variety.
		for t in core.tags:
			if weights.has(t):
				weights[t] = float(weights[t]) * 0.4
		var mods := merge_mods([past.mods, core.mods, twist.mods])
		var text := describe(mods)
		var reasons := []
		for t in core.tags + twist.tags:
			if prof.why.has(t) and not reasons.has(prof.why[t]):
				reasons.append(prof.why[t])
		out.append({
			"id": "gen_%s_%s_%s" % [twist.id, past.id, core.id],
			"name": pattern.format({"adj": twist.adj, "past": past.adj, "noun": core.noun}),
			"family": "generated", "stats": {}, "mods": mods,
			"perk": _sentence(text.good, "Nothing in particular"),
			"drawback": _sentence(text.bad, "None"),
			"quip": core.quip,
			"why": "Offered because " + ", and ".join(reasons.slice(0, 3)) + ".",
		})
	return out

static func classes(dossier: Dictionary, past: Dictionary, db: Dictionary, start := 0) -> Array:
	var classics := []
	var earned := []
	var jokes := []
	for c in db.classes.classes:
		if not _qualifies(c, dossier, past):
			continue
		match c.family:
			"classic": classics.append(c)
			"joke": jokes.append(c)
			_: earned.append(c)
	var out := classics
	out.append_array(earned.slice(0, int(db.classes.offer.hand_written_max)))
	out.append_array(generated(dossier, past, db, start))
	if not jokes.is_empty():
		out.append(jokes[0])
	return out

static func offers(dossier: Dictionary, past_id: String, db: Dictionary, start := 0) -> Dictionary:
	var past := past_life(past_id, db)
	return {"races": races(dossier, past, db), "classes": classes(dossier, past, db, start)}
