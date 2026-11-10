extends Node
## Entry point. Decides whether this process is a dedicated server, a normal
## game client, or a test bot.
##
##   Dedicated server:  godot --headless --path . -- --server [--port=24555]
##   Client:            run the project normally and use the menu
##   Test bot:          godot --headless --path . -- --bot --name=Ann [--join=127.0.0.1]

const GameClient := preload("res://client/game_client.gd")
const Bot := preload("res://client/bot.gd")

var _name_edit: LineEdit
var _addr_edit: LineEdit
var _status: Label
var _past_pick: OptionButton
var _start_pick: OptionButton
var _db: Dictionary
var _menu: Node

func _arg(args: Array, key: String, default: String) -> String:
	for a in args:
		if str(a).begins_with(key + "="):
			return str(a).substr(key.length() + 1)
	return default

func _ready() -> void:
	var args := Array(OS.get_cmdline_user_args())
	var port := int(_arg(args, "--port", str(Net.DEFAULT_PORT)))
	if args.has("--server"):
		var err := Net.host(port, int(_arg(args, "--seed", "0")))
		if err != OK:
			push_error("Could not start server on port %d (error %d)" % [port, err])
			get_tree().quit(1)
			return
		print("Server listening on port %d" % port)
		return
	if args.has("--bot"):
		var bot := Bot.new()
		bot.player_name = _arg(args, "--name", "Bot")
		bot.seconds = float(_arg(args, "--seconds", "12"))
		bot.passive = args.has("--passive")
		bot.idle = args.has("--idle")
		add_child(bot)
		_connect_and_start(bot, _arg(args, "--join", "127.0.0.1"), port, {"name": bot.player_name,
			"past": _arg(args, "--past", "plumber"), "start": int(_arg(args, "--start", "0"))})
		return
	_build_menu()

func _build_menu() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_menu = layer
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(320, 0)
	box.position = Vector2(-160, -190)
	layer.add_child(box)
	var title := Label.new()
	title.text = "CRAWL SHOW\n(working title)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Your name"
	box.add_child(_name_edit)
	_db = DB.load_all()
	var past_label := Label.new()
	past_label.text = "Who were you before this?"
	box.add_child(past_label)
	_past_pick = OptionButton.new()
	for p in _db.past_lives.past_lives:
		_past_pick.add_item(p.name)
	box.add_child(_past_pick)
	var start_label := Label.new()
	start_label.text = "Where do you wake up?"
	box.add_child(start_label)
	_start_pick = OptionButton.new()
	for s in _db.floors.floors[0].starts:
		_start_pick.add_item(s)
	box.add_child(_start_pick)
	_addr_edit = LineEdit.new()
	_addr_edit.placeholder_text = "Server address (default 127.0.0.1)"
	box.add_child(_addr_edit)
	var join_btn := Button.new()
	join_btn.text = "Join server"
	join_btn.pressed.connect(_on_join)
	box.add_child(join_btn)
	var host_btn := Button.new()
	host_btn.text = "Host and play"
	host_btn.pressed.connect(_on_host)
	box.add_child(host_btn)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status)

func _on_host() -> void:
	var err := Net.host()
	if err != OK:
		_status.text = "Could not host (port %d busy?)" % Net.DEFAULT_PORT
		return
	var game := GameClient.new()
	_menu.queue_free()
	add_child(game)
	Net.client = game
	Net.send("hello", _character())

func _character() -> Dictionary:
	return {"name": _name_edit.text, "past": _db.past_lives.past_lives[_past_pick.selected].id,
		"start": _start_pick.selected}

func _on_join() -> void:
	var address := _addr_edit.text.strip_edges()
	if address == "":
		address = "127.0.0.1"
	_status.text = "Connecting to %s..." % address
	var game := GameClient.new()
	game.visible = false
	add_child(game)
	_connect_and_start(game, address, Net.DEFAULT_PORT, _character())

func _connect_and_start(game: Node, address: String, port: int, character: Dictionary) -> void:
	var err := Net.join(address, port)
	if err != OK:
		_fail(game, "Could not connect.")
		return
	Net.client = game
	multiplayer.connected_to_server.connect(func():
		if _menu != null:
			_menu.queue_free()
			_menu = null
		if game is CanvasItem:
			game.visible = true
		Net.send("hello", character), CONNECT_ONE_SHOT)
	multiplayer.connection_failed.connect(func(): _fail(game, "Connection failed."), CONNECT_ONE_SHOT)
	multiplayer.server_disconnected.connect(func(): _fail(game, "Server closed the connection."), CONNECT_ONE_SHOT)

func _fail(game: Node, message: String) -> void:
	print(message)
	Net.client = null
	multiplayer.multiplayer_peer = null
	if is_instance_valid(game):
		game.queue_free()
	if _status != null and is_instance_valid(_status):
		_status.text = message
	elif _menu == null and not Array(OS.get_cmdline_user_args()).has("--bot"):
		_build_menu()
		_status.text = message
	else:
		get_tree().quit(1)
