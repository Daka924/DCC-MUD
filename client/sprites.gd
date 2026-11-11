class_name Sprites
extends RefCounted
## Finds art for a thing by kind and id (art/<kind>/<id>.png) and remembers the
## answer. Anything without a file returns null, and the caller draws its
## placeholder shape instead, so art can arrive one piece at a time.

var _cache := {}

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
