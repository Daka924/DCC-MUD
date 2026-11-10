extends Node
## Networking glue (autoload "Net"). The server owns the World and is the only
## place rules run. Clients send requests; the server sends back snapshots,
## private state and events. A "host and play" game runs both in one process,
## with the local player as peer 1.

const DEFAULT_PORT := 24555
const MAX_PLAYERS := 32
const SNAPSHOT_EVERY := 4      # physics frames (15 per second)
const SELF_EVERY := 60

var world: World = null
var client: Node = null        # object with on_msg(kind, data) and on_snapshot(data)
var _frame := 0
var _dirty := {}

func host(port: int = DEFAULT_PORT, world_seed: int = 0) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	# Clients only ever talk to the server, so they do not need to hear about each other.
	(multiplayer as SceneMultiplayer).server_relay = false
	multiplayer.peer_disconnected.connect(_on_peer_left)
	if world_seed == 0:
		world_seed = int(Time.get_unix_time_from_system())
	world = World.new(DB.load_all(), world_seed)
	world.event.connect(_on_world_event)
	world.self_changed.connect(func(pid): _dirty[pid] = true)
	return OK

func join(address: String, port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	return OK

## Client -> server request.
func send(method: String, arg: Variant = null) -> void:
	if world != null:
		_handle(1, method, arg)
	elif multiplayer.multiplayer_peer != null \
			and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		c_msg.rpc_id(1, method, arg)

@rpc("any_peer", "call_remote", "reliable")
func c_msg(method: String, arg: Variant) -> void:
	if world != null:
		_handle(multiplayer.get_remote_sender_id(), method, arg)

@rpc("authority", "call_remote", "reliable")
func s_msg(kind: String, data: Dictionary) -> void:
	if client != null:
		client.on_msg(kind, data)

@rpc("authority", "call_remote", "unreliable_ordered")
func s_snap(data: Dictionary) -> void:
	if client != null:
		client.on_snapshot(data)

## True while the peer is fully connected. Avoids sending to someone mid-disconnect.
func _peer_ok(pid: int) -> bool:
	if not multiplayer.get_peers().has(pid):
		return false
	var enet := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	return enet == null or enet.get_peer(pid).get_state() == ENetPacketPeer.STATE_CONNECTED

func _to(pid: int, kind: String, data: Dictionary) -> void:
	if pid == 1:
		if client != null:
			client.on_msg(kind, data)
	elif _peer_ok(pid):
		s_msg.rpc_id(pid, kind, data)

## Every request is checked here. Clients are never trusted.
func _handle(sender: int, method: String, arg: Variant) -> void:
	if method == "hello":
		if not world.players.has(sender) and typeof(arg) == TYPE_STRING:
			world.add_player(sender, arg)
			_to(sender, "welcome", {"id": sender, "grid": world.grid, "level": world.db.level.name,
				"timer_total": world.timer_total})
			_dirty[sender] = true
		return
	if not world.players.has(sender):
		return
	match method:
		"input":
			if typeof(arg) == TYPE_VECTOR2:
				world.set_input(sender, arg)
		"melee":
			world.melee(sender)
		"throw":
			if typeof(arg) == TYPE_DICTIONARY and typeof(arg.get("target")) == TYPE_VECTOR2 \
					and typeof(arg.get("items")) == TYPE_ARRAY and typeof(arg.get("ability")) == TYPE_INT:
				world.throw_items(sender, arg.items, arg.target, arg.ability)
		"invite":
			world.party_invite(sender)
		"accept":
			world.party_accept(sender)
		"leave":
			world.party_leave(sender)
		"chat":
			if typeof(arg) == TYPE_STRING:
				world.chat(sender, arg)

func _on_peer_left(pid: int) -> void:
	if world != null:
		world.remove_player(pid)

func _on_world_event(targets: Array, ev: Dictionary) -> void:
	var to: Array = targets if not targets.is_empty() else world.players.keys()
	for pid in to:
		if world.players.has(pid):
			_to(pid, "event", ev)

func _physics_process(delta: float) -> void:
	if world == null:
		return
	world.tick(delta)
	_frame += 1
	if _frame % SELF_EVERY == 0:
		for pid in world.players:
			_dirty[pid] = true
	for pid in _dirty:
		if world.players.has(pid):
			_to(pid, "self", world.self_state(pid))
	_dirty.clear()
	if _frame % SNAPSHOT_EVERY == 0:
		var snap := world.snapshot()
		for pid in world.players:
			if pid == 1:
				if client != null:
					client.on_snapshot(snap)
			elif _peer_ok(pid):
				s_snap.rpc_id(pid, snap)
