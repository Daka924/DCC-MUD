class_name AbilityGen
extends RefCounted
## Builds one signature ability for a generated class by choosing a value on
## each axis (function, delivery, flavour, cost) from the class's tags weighed
## by the player's tag profile. Pure and deterministic: the same history always
## yields the same ability.

static func _pick(tags: Array, table: Dictionary, weights: Dictionary, seed_text: String, avoid := {}) -> String:
	var totals := {}
	for t in tags:
		if table.has(t):
			var v: String = table[t]
			totals[v] = float(totals.get(v, 0.0)) + float(weights.get(t, 0.0)) + 0.5
	var best := ""
	var best_score := -1.0
	var names: Array = totals.keys()
	names.sort()
	for v in names:
		var s: float = totals[v] + float(abs((seed_text + "|" + str(v)).hash()) % 100) / 200.0
		if avoid.has(v):
			s *= 0.15
		if s > best_score:
			best_score = s
			best = v
	return best

static func _choose(list: Array, seed_text: String) -> String:
	return str(list[abs(seed_text.hash()) % list.size()])

static func _num(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, round(v)) else str(snapped(v, 0.1))

## tags: the class's own tags (job plus describing word). weights: the
## player's profile. avoid: functions already used by this player's other offers.
static func build(tags: Array, weights: Dictionary, db: Dictionary, seed_text: String, avoid := {}, core_count := 99) -> Dictionary:
	var parts: Dictionary = db.ability_parts
	# The class's own tags lead; the rest of the player's profile is a quieter
	# second voice, so six offers do not all do the same thing.
	var lean: Dictionary = weights.duplicate()
	var wide := tags.duplicate()
	for t in weights:
		if not tags.has(t):
			lean[t] = float(weights[t]) * 0.25
			wide.append(t)
	var fn_id := _pick(wide, parts.tag_function, lean, seed_text, avoid)
	if fn_id == "":
		fn_id = "damage"
	var fn: Dictionary = parts.functions[fn_id]
	# Delivery: only the ones this function has words for.
	var allowed: Dictionary = fn.nouns
	var delivery_table := {}
	for t in parts.tag_delivery:
		if allowed.has(parts.tag_delivery[t]):
			delivery_table[t] = parts.tag_delivery[t]
	var delivery := _pick(tags, delivery_table, weights, seed_text)
	if delivery == "":
		delivery = _pick(weights.keys(), delivery_table, weights, seed_text)
	if delivery == "":
		delivery = str(allowed.keys()[0])
	var dl: Dictionary = parts.deliveries[delivery]
	# Flavour: the class tag the player leans on hardest.
	var flavour_tag := ""
	var best := -1.0
	for i in tags.size():
		var t: String = tags[i]
		if parts.flavours.has(t):
			var has_status: bool = parts.flavours[t].has("status")
			if fn.kind != "burst" and has_status:
				continue      # burning or freezing only makes sense on an attack
			var s := float(weights.get(t, 0.0)) + float(abs((seed_text + "~" + t).hash()) % 100) / 200.0
			if i >= core_count:
				s *= 0.6     # the job's tags outrank the describing word's
			if fn.kind == "burst" and has_status:
				s += 1.0
			if s > best:
				best = s
				flavour_tag = t
	var flavour: Dictionary = parts.flavours.get(flavour_tag, {"adj": ["Improvised"]})
	var cost_id := "mana"
	if not fn.get("passive", false):
		var c := _pick(tags, parts.tag_cost, weights, seed_text)
		# Paying with health or items is for players who really lived that way.
		if c != "" and _score_for(tags, parts.tag_cost, c, weights) >= 3.0:
			cost_id = c
	var cost: Dictionary = parts.costs[cost_id]

	var power: float = float(fn.get("power", 0.0)) * float(dl.power_mult) * float(cost.get("power_mult", 1.0))
	var radius: float = float(fn.get("radius", 0.0)) * float(dl.radius_mult)
	var effects := []
	var lines := []
	if fn.kind == "burst":
		power *= float(flavour.get("power_mult", 1.0))
		radius *= float(flavour.get("radius_mult", 1.0))
		effects.append({"id": "thump", "kind": "damage", "power": power, "duration": 0.0})
		if fn.has("status"):
			var st: Dictionary = fn.status
			effects.append({"id": "snare", "kind": st.kind, "power": float(st.get("power", 0.0)), "duration": float(st.duration)})
			lines.append(str(st.says).format({"duration": _num(st.duration)}))
		if flavour.has("status"):
			var st: Dictionary = flavour.status
			effects.append({"id": st.id, "kind": st.kind, "power": float(st.power), "duration": float(st.duration)})
			lines.append(str(st.says).format({"duration": _num(st.duration)}))
	var does: String = str(fn.does).format({"power": _num(round(power)), "duration": _num(float(fn.get("duration", 0.0)))})
	var text: String = dl.says + ": " + does
	if fn.kind == "burst":
		text += " in a %s-tile area" % _num(snapped(radius, 0.1))
	for l in lines:
		text += ", and " + l
	text += "."
	if fn.get("passive", false):
		text = does.substr(0, 1).to_upper() + does.substr(1) + ". Works by itself, once every %d seconds." % int(fn.cooldown)
	else:
		text += " %s. %d second cooldown." % [str(cost.says).format({"mana": int(fn.mana)}), int(fn.cooldown)]
	return {
		"name": "%s %s" % [_choose(flavour.adj, seed_text + "adj"), _choose(fn.nouns[delivery], seed_text + "noun")],
		"text": text, "function": fn_id, "delivery": delivery, "flavour": flavour_tag, "cost": cost_id,
		"kind": fn.kind, "passive": fn.get("passive", false),
		"power": round(power), "radius": snapped(radius, 0.1), "range": float(dl.range),
		"audience": dl.get("audience", false), "effects": effects,
		"mods": fn.get("mods", {}), "allies": fn.get("allies", false), "duration": float(fn.get("duration", 0.0)),
		"cooldown": float(fn.cooldown), "mana": float(fn.mana) if cost_id == "mana" else 0.0,
		"hp_frac": float(cost.get("hp_frac", 0.0)),
	}

static func _score_for(tags: Array, table: Dictionary, value: String, weights: Dictionary) -> float:
	var total := 0.0
	for t in tags:
		if table.get(t, "") == value:
			total += float(weights.get(t, 0.0))
	return total
