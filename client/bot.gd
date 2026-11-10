extends Node
## A scripted player used for automated multiplayer tests. It walks out of the
## safe room, parties up with anyone it meets, throws oil and rags at the
## nearest monster and prints what it saw before quitting.

var player_name := "Bot"
var seconds := 12.0
var passive := false
var my_id := 0
var snap := {}
var me := {}
var elapsed := 0.0
var _next_action := 0.0
var discoveries := []
var achievements := []
var max_players_seen := 0
var chat_seen := 0
var max_party := 0

func on_msg(kind: String, data: Dictionary) -> void:
	match kind:
		"welcome":
			my_id = data.id
			Net.send("chat", "hello from %s" % player_name)
		"self":
			me = data
			max_party = max(max_party, data.party.size())
		"event":
			match data.type:
				"invite":
					Net.send("accept")
				"discovery":
					discoveries.append(data.ability.name)
				"achievement":
					achievements.append(data.title)
				"chat":
					chat_seen += 1

func on_snapshot(data: Dictionary) -> void:
	snap = data
	max_players_seen = max(max_players_seen, data.p.size())

func _my_pos() -> Vector2:
	for p in snap.get("p", []):
		if p[0] == my_id:
			return p[2]
	return Vector2.ZERO

func _process(delta: float) -> void:
	if my_id == 0 or snap.is_empty():
		return
	elapsed += delta
	if elapsed >= seconds:
		print("BOT %s: players_seen=%d party=%d level=%d abilities=%s achievements=%s chat_seen=%d pos=%s" % [
			player_name, max_players_seen, max_party, me.get("level", 0),
			discoveries, achievements, chat_seen, _my_pos().snapped(Vector2(0.1, 0.1))])
		multiplayer.multiplayer_peer.close()
		set_process(false)
		get_tree().create_timer(0.3).timeout.connect(func(): get_tree().quit(0))
		return
	if elapsed < _next_action:
		return
	_next_action = elapsed + 0.1
	var pos := _my_pos()
	if elapsed < 1.0:
		return
	if me.get("party", []).is_empty() and elapsed < 3.0:
		Net.send("invite")
	# Leave the safe room through the east door, then hunt.
	var nearest := Vector2.ZERO
	var best := 999.0
	for m in snap.m:
		var d: float = m[2].distance_to(pos)
		if d < best:
			best = d
			nearest = m[2]
	if pos.x < 7.0:
		var dy: float = clamp((3.5 - pos.y) * 3.0, -1.0, 1.0)
		Net.send("input", Vector2(1.0 if abs(pos.y - 3.5) < 0.15 else 0.0, dy))
	elif best < 6.0:
		Net.send("input", Vector2.ZERO if best < 3.0 else (nearest - pos).normalized())
		if passive:
			return
		# Monsters charge, so aim where they will be when the fuse runs out: at our feet.
		Net.send("throw", {"items": ["oil_flask", "rag"], "target": pos.lerp(nearest, 0.2), "ability": -1})
	else:
		Net.send("input", (Vector2(9.5, 5.5) - pos).normalized())
