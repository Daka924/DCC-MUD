class_name Sprites
extends RefCounted
## Finds art for a thing by kind and id (art/<kind>/<id>.png) and remembers the
## answer. Anything without a file returns null, and the caller draws its
## placeholder shape instead, so art can arrive one piece at a time.

var _cache := {}
var _folders := {}   # kind/id -> whether an animation folder exists

func get_tex(kind: String, id: String) -> Texture2D:
	var key := "%s/%s" % [kind, id]
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D = null
	var path := "res://art/%s.png" % key
	if ResourceLoader.exists(path):
		tex = load(path)
	elif FileAccess.file_exists(path):
		# Freshly made by make_sprites and not yet imported by the editor.
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null:
			tex = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

## First id that has art, or null.
func first(kind: String, ids: Array) -> Texture2D:
	for id in ids:
		var tex := get_tex(kind, str(id))
		if tex != null:
			return tex
	return null

# ---------------------------------------------------------------- animation
# An animated thing is a folder: art/<kind>/<id>/<anim>_<dir>.png, each a
# horizontal strip of square frames. Directions are named for where the figure
# faces on screen: s (toward the camera), sw, w, nw, n, ne, e, se.
# Missing directions are filled from the nearest one, mirrored where that
# works, so a set can start with one direction and grow.

const FPS := 8.0
## For each direction: what to try, in order. true = draw it mirrored.
const FALLBACK := {
	"s": [["s", false], ["sw", false], ["se", true], ["se", false], ["sw", true]],
	"sw": [["sw", false], ["se", true], ["s", false], ["w", false], ["e", true]],
	"w": [["w", false], ["e", true], ["sw", false], ["se", true], ["nw", false]],
	"nw": [["nw", false], ["ne", true], ["n", false], ["w", false], ["e", true]],
	"n": [["n", false], ["nw", false], ["ne", true], ["ne", false], ["nw", true]],
	"ne": [["ne", false], ["nw", true], ["n", false], ["e", false], ["w", true]],
	"e": [["e", false], ["w", true], ["se", false], ["sw", true], ["ne", false]],
	"se": [["se", false], ["sw", true], ["s", false], ["e", false], ["w", true]],
}
const ANIM_FALLBACK := {"attack": ["attack", "idle", "walk"], "walk": ["walk", "idle"], "idle": ["idle", "walk"],
	"dead": ["dead"]}
const ANY_DIR := ["s", "sw", "se", "w", "e", "nw", "ne", "n"]

## Name of the screen direction for a screen-space vector.
static func dir_name(screen: Vector2) -> String:
	if screen.length() < 0.001:
		return "s"
	var names := ["e", "se", "s", "sw", "w", "nw", "n", "ne"]
	return names[int(round(screen.angle() / (PI / 4.0))) & 7]

## The frame to draw, or {} when this thing has no animation art.
## Returns {tex, region, flip}.
func frame(kind: String, id: String, anim: String, dir: String, t: float) -> Dictionary:
	var folder := "%s/%s" % [kind, id]
	if not _folders.has(folder):
		_folders[folder] = DirAccess.dir_exists_absolute("res://art/" + folder)
	if not _folders[folder]:
		return {}
	for a in ANIM_FALLBACK.get(anim, [anim, "idle"]):
		var tries: Array = FALLBACK.get(dir, FALLBACK["s"]).duplicate()
		for d in ANY_DIR:
			tries.append([d, false])
		for pair in tries:
			var tex := get_tex(kind, "%s/%s_%s" % [id, a, pair[0]])
			if tex == null:
				continue
			var h := tex.get_height()
			var count: int = max(1, tex.get_width() / h)
			var i := int(t * FPS) % count
			if a == "dead":
				i = count - 1
			return {"tex": tex, "region": Rect2(i * h, 0, h, h), "flip": pair[1]}
	return {}
