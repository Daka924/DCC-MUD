class_name DB
extends RefCounted
## Loads every data file once. All game content lives in res://data as JSON
## so it can be edited without touching code.

const FILES := {
	"items": "res://data/items.json",
	"tag_rules": "res://data/tag_rules.json",
	"context": "res://data/context_rules.json",
	"mobs": "res://data/mobs.json",
	"achievements": "res://data/achievements.json",
	"boxes": "res://data/boxes.json",
	"narrator": "res://data/narrator.json",
	"floors": "res://data/floors.json",
	"past_lives": "res://data/past_lives.json",
	"companions": "res://data/companions.json",
	"races": "res://data/races.json",
	"classes": "res://data/classes.json",
	"class_parts": "res://data/class_parts.json",
}

static func load_json(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("DB: cannot open %s" % path)
		return null
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed == null:
		push_error("DB: invalid JSON in %s" % path)
	return parsed

static func load_all() -> Dictionary:
	var db := {}
	for key in FILES:
		db[key] = load_json(FILES[key])
	return db
