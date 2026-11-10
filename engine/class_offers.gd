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

## Classes made by pairing the past life with what the player kept doing.
static func generated(dossier: Dictionary, past: Dictionary, db: Dictionary) -> Array:
	var scored := []
	for b in db.classes.behaviours:
		var amount := float(dossier.get(b.key, 0))
		if amount >= float(b.min):
			scored.append([amount / float(b.min), b])
	scored.sort_custom(func(x, y): return x[0] > y[0])
	var out := []
	for pair in scored.slice(0, int(db.classes.offer.generated_max)):
		var b: Dictionary = pair[1]
		out.append({
			"id": "gen_%s_%s" % [b.id, past.id], "name": "%s %s" % [b.adj, past.noun],
			"family": "generated", "stats": {},
			"mods": merge_mods([past.mods, b.mods]),
			"perk": past.perk, "drawback": b.text,
			"quip": "A %s who would not stop. We had to call it something." % str(past.name).to_lower(),
		})
	return out

static func classes(dossier: Dictionary, past: Dictionary, db: Dictionary) -> Array:
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
	out.append_array(generated(dossier, past, db))
	if not jokes.is_empty():
		out.append(jokes[0])
	return out

static func offers(dossier: Dictionary, past_id: String, db: Dictionary) -> Dictionary:
	var past := past_life(past_id, db)
	return {"races": races(dossier, past, db), "classes": classes(dossier, past, db)}
