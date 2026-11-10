extends SceneTree
## Headless rules tests. Run with:
##   godot --headless --path . -s tests/run_tests.gd

var failures := 0
var checks := 0

func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("  FAIL: ", label)

func _init() -> void:
	var db := DB.load_all()
	test_data(db)
	test_resolve(db)
	test_invent(db)
	test_world_discovery(db)
	test_party_and_xp(db)
	test_safety(db)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func test_data(db: Dictionary) -> void:
	print("data")
	for key in db:
		check(db[key] != null, "data file loads: " + key)
	var rows: Array = db.level.map
	for row in rows:
		check(str(row).length() == str(rows[0]).length(), "level rows are the same width")
	for box in ["tin", "copper"]:
		for item_id in db.boxes[box].table:
			check(db.items.has(item_id), "box item exists: " + item_id)
	for a in db.achievements:
		check(db.boxes.has(a.box), "achievement box exists: " + a.id)

func test_resolve(db: Dictionary) -> void:
	print("tag rules")
	var fire := Invention.resolve(["oil_flask", "rag", "flint"], db)
	var ids: Array = fire.effects.map(func(e): return e.id)
	check(ids.has("burn"), "oil + rag + flint burns")
	check(fire.mods.has("splash") and fire.mods.has("fuse"), "it splashes and has a fuse")
	check(fire.delay > 0.0, "fuse adds a delay")
	var plain := Invention.resolve(["oil_flask", "rag"], db)
	check(not plain.effects.map(func(e): return e.id).has("burn"), "no spark, no fire")
	var unplanned := Invention.resolve(["glue_pot", "nails", "frost_moss"], db)
	check(unplanned.effects.size() >= 4, "an unplanned three-item mix still does something")
	check(Invention.signature(["rag", "oil_flask"]) == Invention.signature(["oil_flask", "rag"]), "signature ignores order")

func test_invent(db: Dictionary) -> void:
	print("invention")
	var ctx := {"items": ["oil_flask", "rag", "flint"], "room_tags": ["wet"], "target_family": "ooze",
		"hp_frac": 0.2, "allies_near": 0, "time_frac": 0.9, "player_id": 7, "player_level": 1, "world_seed": 42}
	var a := Invention.invent(ctx, db)
	var b := Invention.invent(ctx, db)
	check(a.name == b.name and str(a) == str(b), "same history gives the same ability")
	var trait_ids: Array = a.traits.map(func(t): return t.id)
	check(trait_ids.has("channel"), "invented in water gets the water trait")
	check(trait_ids.has("bane"), "first target family gives a grudge")
	check(trait_ids.has("desperate"), "invented while badly hurt gets the panic trait")
	var ctx2 := ctx.duplicate()
	ctx2.room_tags = ["narrow"]
	ctx2.target_family = "vermin"
	ctx2.hp_frac = 1.0
	var c := Invention.invent(ctx2, db)
	check(c.name != a.name, "a different history gives a different name (%s vs %s)" % [a.name, c.name])
	check(not c.traits.map(func(t): return t.id).has("channel"), "a different history gives different traits")
	var wet := Invention.payload_for(a, {"room_tags": ["wet"], "hp_frac": 1.0}, db)
	var dry := Invention.payload_for(a, {"room_tags": ["open"], "hp_frac": 1.0}, db)
	check(wet.radius > dry.radius, "water trait only applies in water")
	var hurt := Invention.payload_for(a, {"room_tags": ["open"], "hp_frac": 0.1}, db)
	check(hurt.effects[0].power > dry.effects[0].power, "panic trait only applies when hurt")
	var big := ctx.duplicate()
	big.items = ["glue_pot", "nails", "glowcap"]
	var capped := Invention.invent(big, db)
	check(capped.budget_scale < 1.0, "over-budget combinations are scaled down")
	var levelled := false
	for i in 5:
		levelled = Invention.record_use(a, db) or levelled
	check(levelled and a.level == 2, "abilities level up with use")

func _step(w: World, seconds: float) -> void:
	for i in int(seconds * 20.0):
		w.tick(0.05)

func test_world_discovery(db: Dictionary) -> void:
	print("world: discovery")
	var w := World.new(db, 42)
	var seen := []
	w.event.connect(func(_targets, ev): seen.append(ev))
	w.add_player(2, "Tester")
	_step(w, 0.1)
	check(w.mobs.size() > 0 and w.drops.size() > 0, "mobs and items spawn")
	var p: Dictionary = w.players[2]
	var leech := {}
	for m in w.mobs.values():
		if m.type == "drain_leech":
			leech = m
			break
	check(not leech.is_empty(), "there is a leech in the flooded rooms")
	p.pos = leech.pos + Vector2(2.0, 0.0)
	check(w.tags_at(p.pos) == ["wet"], "player stands in a flooded room")
	p.inv = {"oil_flask": 9, "rag": 9, "flint": 9}
	for i in 3:
		leech.hp = 500.0
		p.hp = p.max_hp
		check(w.throw_items(2, ["oil_flask", "rag", "flint"], leech.pos), "throw %d accepted" % (i + 1))
		if i == 0:
			check(int(p.inv.oil_flask) == 8 and int(p.inv.rag) == 8, "ingredients are consumed")
		_step(w, 2.5)
	check(p.abilities.size() == 1, "three purposeful uses create one ability")
	if p.abilities.size() == 1:
		var ab: Dictionary = p.abilities[0]
		print("    invented: %s  traits: %s" % [ab.name, ab.traits.map(func(t): return t.id)])
		check(ab.traits.map(func(t): return t.id).has("channel"), "ability remembers it was born in water")
		check(ab.born.family == "ooze", "ability remembers its first target")
	check(seen.any(func(ev): return ev.type == "discovery"), "discovery event sent")
	check(seen.any(func(ev): return ev.type == "achievement"), "achievement and box granted")
	check(not w.throw_items(2, ["oil_flask", "bogus"], leech.pos), "unknown items are refused")
	check(not w.throw_items(2, ["glowcap"], leech.pos), "items the player lacks are refused")

func test_party_and_xp(db: Dictionary) -> void:
	print("world: parties")
	var w := World.new(db, 7)
	w.add_player(2, "Ann")
	w.add_player(3, "Bo")
	_step(w, 0.1)
	w.players[3].pos = w.players[2].pos + Vector2(1, 0)
	w.party_invite(2)
	check(w.invites.get(3, 0) == 2, "invite reaches the nearby player")
	w.party_accept(3)
	check(w.players[2].party != 0 and w.players[2].party == w.players[3].party, "both are in one party")
	var rat: Dictionary = w.mobs.values()[0]
	w.players[2].pos = rat.pos + Vector2(0.8, 0)
	w.players[3].pos = rat.pos + Vector2(2.0, 0)
	rat.hp = 1.0
	w.melee(2)
	check(not w.mobs.has(rat.id), "melee kills the mob")
	check(w.players[3].xp > 0 or w.players[3].level > 1, "party member nearby shares the XP")
	w.remove_player(2)
	check(w.players[3].party == 0, "party dissolves when a member leaves")

func test_safety(db: Dictionary) -> void:
	print("world: safe room and death")
	var w := World.new(db, 3)
	w.add_player(2, "Ann")
	_step(w, 0.1)
	var p: Dictionary = w.players[2]
	check(w.tile_at(p.pos) == "S", "players start in the safe room")
	w._damage_player(p, 999.0)
	check(p.hp == p.max_hp, "no damage inside the safe room")
	check(not w.throw_items(2, ["oil_flask"], p.pos + Vector2(3, 0)), "no throwing from inside the safe room")
	p.pos = Vector2(8.5, 3.5)
	w._damage_player(p, 999.0)
	check(p.dead_until > 0.0, "players can die outside it")
	_step(w, 6.0)
	check(p.dead_until < 0.0 and w.tile_at(p.pos) == "S", "dead players respawn in the safe room")
	p.pos = Vector2(1.5, 1.5)
	w.set_input(2, Vector2(-1, 0))
	_step(w, 2.0)
	check(w.tile_at(p.pos) != "#", "walls stop movement")
