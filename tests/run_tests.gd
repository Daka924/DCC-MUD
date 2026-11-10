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
	test_offers(db)
	test_world_basics(db)
	test_companion_and_party(db)
	test_boxes_and_safety(db)
	test_descent_and_choice(db)
	test_crafting_class(db)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func test_data(db: Dictionary) -> void:
	print("data")
	for key in db:
		check(db[key] != null, "data file loads: " + key)
	for f in db.floors.floors:
		for row in f.map:
			check(str(row).length() == str(f.map[0]).length(), "level rows are the same width: " + f.name)
	for box in db.boxes:
		if box != "_doc":
			for item_id in db.boxes[box].table:
				check(db.items.has(item_id), "box item exists: " + item_id)
	for a in db.achievements:
		check(db.boxes.has(a.box), "achievement box exists: " + a.id)
	var ids := {}
	for c in db.classes.classes:
		check(not ids.has(c.id), "class ids are unique: " + c.id)
		ids[c.id] = true
		check(c.perk != "" and c.drawback != "", "class has a perk and a drawback: " + c.id)

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

func _names(list: Array) -> Array:
	return list.map(func(c): return c.id)

func test_offers(db: Dictionary) -> void:
	print("class offers")
	var quiet := ClassOffers.offers({}, "accountant", db)
	var quiet_ids := _names(quiet.classes)
	check(quiet_ids.has("bruiser") and quiet_ids.has("sneak"), "classics are always offered")
	check(quiet_ids.has("bystander"), "killing almost nothing offers the bystander class")
	check(not quiet_ids.has("chiropractor"), "unearned classes are not offered")
	check(not _names(quiet.races).has("ratblood"), "locked races are hidden")
	var brawler := ClassOffers.offers({"kills": 12, "kills_melee": 9, "deaths": 2, "pickups": 11}, "cashier", db)
	var ids := _names(brawler.classes)
	check(ids.has("chiropractor"), "bare-handed kills offer the chiropractor")
	check(ids.has("coupon_paladin"), "past life plus behaviour offers the paladin")
	check(ids.has("disgraced_mascot"), "dying a lot offers a joke class")
	check(not ids.has("bystander"), "a killer is not offered the bystander")
	check(_names(brawler.races).has("ratblood"), "ten kills unlock a race")
	var gen: Array = brawler.classes.filter(func(c): return c.family == "generated")
	check(gen.size() >= 2, "generated classes are offered")
	if not gen.is_empty():
		print("    generated: ", gen.map(func(c): return c.name))
		check(str(gen[0].name).ends_with("Cashier"), "generated class is named after the past life")
	var other := ClassOffers.offers({"kills": 12, "kills_melee": 9}, "baker", db)
	check(_names(other.classes) != ids, "a different past life gives a different list")
	check(str(ClassOffers.offers({"kills": 12}, "baker", db)) == str(ClassOffers.offers({"kills": 12}, "baker", db)), "offers are deterministic")
	var merged := ClassOffers.merge_mods([{"hp_mult": 1.2, "regen": 0.5}, {"hp_mult": 0.5, "regen": 0.5}])
	check(is_equal_approx(merged.hp_mult, 0.6) and is_equal_approx(merged.regen, 1.0), "mods multiply or add correctly")

func _join(w: World, pid: int, player_name: String, past := "plumber", start := 0) -> Dictionary:
	w.add_player(pid, {"name": player_name, "past": past, "start": start})
	_step(w, 0.1)
	return w.players[pid]

func test_world_basics(db: Dictionary) -> void:
	print("world: creation and combat")
	var w := World.new(db, 42)
	check(w.start_names().size() == 3, "three starting locations")
	var a := _join(w, 2, "Ann", "plumber", 0)
	var b := _join(w, 3, "Bo", "karaoke", 2)
	var f: Dictionary = w.floors[0]
	check(a.pos.distance_to(b.pos) > 8.0, "different starting locations are far apart")
	check(w.tile_at(f, a.pos) == "S" and w.tile_at(f, b.pos) == "S", "players start in safe rooms")
	check(w._skill_level(a, "brawling") == 2, "past life grants starting skills")
	check(f.mobs.size() > 0 and f.drops.size() > 0, "mobs and items spawn")
	check(a.pet == null, "there is an empty pet slot")
	var rat: Dictionary = f.mobs.values()[0]
	a.pos = rat.pos + Vector2(0.8, 0)
	rat.hp = 1.0
	w.melee(2)
	check(not f.mobs.has(rat.id), "melee kills the mob")
	check(a.dossier.get("kills_melee", 0) == 1, "the dossier records how it died")
	check(a.xp > 0 and b.xp == 0, "strangers do not share XP")
	a.pos = Vector2(8.5, 3.5)
	check(not w.throw_items(2, ["oil_flask", "rag"], a.pos + Vector2(2, 0)), "combining items needs a crafting class")
	check(w.throw_items(2, ["oil_flask"], a.pos + Vector2(2, 0)), "anyone can throw a single item")
	check(not w.throw_items(2, ["bogus"], a.pos), "unknown items are refused")
	check(not w.spend_point(2, "str"), "stat points cannot be spent before a class is chosen")
	a.pos = Vector2(1.5, 1.5)
	w.set_input(2, Vector2(-1, 0))
	_step(w, 2.0)
	check(w.tile_at(f, a.pos) != "#", "walls stop movement")

func test_companion_and_party(db: Dictionary) -> void:
	print("world: companions and parties")
	var w := World.new(db, 7)
	var a := _join(w, 2, "Ann", "nurse", 0)
	var b := _join(w, 3, "Bo", "baker", 0)
	var f: Dictionary = w.floors[0]
	b.pos = Vector2(8.5, 9.5)
	check(w.companions.size() == 3, "one companion waits at each start")
	w.party_invite(2)
	check(a.companion != 0, "a solo player can recruit the nearby NPC")
	var npc: Dictionary = w.companions[a.companion]
	a.pos = Vector2(8.5, 3.5)
	_step(w, 1.0)
	check(npc.pos.distance_to(a.pos) < 3.0, "the companion follows")
	var rat := {}
	for m in f.mobs.values():
		if m.pos.distance_to(a.pos) < 4.0:
			rat = m
	check(not rat.is_empty(), "there is a mob near the first room")
	if not rat.is_empty():
		var before: float = rat.hp
		_step(w, 3.0)
		check(not f.mobs.has(rat.id) or rat.hp < before, "the companion fights")
	b.pos = a.pos + Vector2(1, 0)
	w.party_invite(2)
	check(w.invites.get(3, 0) == 2, "a real player nearby gets the invite instead")
	w.party_accept(3)
	check(a.party != 0 and a.party == b.party, "both are in one party")
	check(a.companion == 0 and npc.owner == 0, "the companion leaves once real players team up")
	var xp_before: int = b.xp + b.level * 1000
	var target: Dictionary = {}
	for m in f.mobs.values():
		target = m
	a.pos = target.pos + Vector2(0.8, 0)
	b.pos = target.pos + Vector2(2.0, 0)
	target.hp = 1.0
	w.melee(2)
	check(b.xp + b.level * 1000 > xp_before, "party members nearby share XP")
	w.remove_player(2)
	check(b.party == 0, "party dissolves when a member leaves")

func test_boxes_and_safety(db: Dictionary) -> void:
	print("world: safe rooms, boxes and death")
	var w := World.new(db, 3)
	var seen := []
	w.event.connect(func(_targets, ev): seen.append(ev))
	var p := _join(w, 2, "Ann")
	var f: Dictionary = w.floors[0]
	var home: Vector2 = p.pos
	w._damage_player(p, 999.0)
	check(p.hp == p.max_hp, "no damage inside the safe room")
	check(not w.throw_items(2, ["oil_flask"], p.pos + Vector2(3, 0)), "no throwing from inside the safe room")
	p.pos = Vector2(8.5, 3.5)
	var rat: Dictionary = f.mobs.values()[0]
	p.pos = rat.pos + Vector2(0.8, 0)
	rat.hp = 1.0
	w.melee(2)
	_step(w, 0.2)
	check(p.boxes.size() >= 1, "the achievement box waits")
	check(not seen.any(func(ev): return ev.type == "achievement"), "boxes do not open outside a safe room")
	var inv_before := str(p.inv)
	p.pos = home
	_step(w, 4.0)
	check(p.boxes.is_empty() and seen.any(func(ev): return ev.type == "achievement"), "boxes open in the safe room")
	check(str(p.inv) != inv_before, "the box contained loot")
	p.pos = Vector2(8.5, 3.5)
	w._damage_player(p, 999.0)
	check(p.dead_until > 0.0, "players can die outside safe rooms")
	_step(w, 6.0)
	check(p.dead_until < 0.0 and p.pos == home, "dead players respawn at their start")

func test_descent_and_choice(db: Dictionary) -> void:
	print("world: stairs and the level 3 choice")
	var w := World.new(db, 5)
	var changed := []
	w.floor_changed.connect(func(pid): changed.append(pid))
	var p := _join(w, 2, "Ann", "cashier")
	w.party_invite(2)
	var npc_id: int = p.companion
	for key in ["kills_melee", "kills_melee", "kills_melee", "kills_melee", "kills_melee", "kills_melee"]:
		w._note(p, key)
	w._note(p, "kills", 6.0)
	w._give_xp(p, 60)
	check(p.level >= 2 and p.points == 3 * (p.level - 1), "levelling banks three stat points per level")
	var stairs := Vector2.ZERO
	var f: Dictionary = w.floors[0]
	for y in f.height:
		for x in f.width:
			if f.grid[y][x] == ">":
				stairs = Vector2(x + 0.5, y + 0.5)
	p.pos = stairs
	_step(w, 0.1)
	check(p.floor == 1 and changed == [2], "stairs lead down one level")
	check(w.companions[npc_id].floor == 1, "the companion comes along")
	check(p.state == "play", "no choice yet on the second level")
	var f2: Dictionary = w.floors[1]
	_step(w, 0.2)
	var m2: Dictionary = f2.mobs.values()[0]
	check(m2.max_hp > float(db.mobs[m2.type].hp), "deeper levels have tougher mobs")
	check(w.snapshot(0).p.is_empty() and w.snapshot(1).p.size() == 1, "snapshots are per level")
	for y in f2.height:
		for x in f2.width:
			if f2.grid[y][x] == ">":
				stairs = Vector2(x + 0.5, y + 0.5)
	p.pos = stairs
	_step(w, 0.1)
	check(p.floor == 2 and p.state == "choosing", "arriving on the third level starts the choice")
	var st := w.self_state(2)
	check(st.has("offers") and st.offers.classes.size() >= 5, "the player is sent their offers")
	var ids := _names(st.offers.classes)
	check(ids.has("chiropractor"), "offers reflect the dossier")
	check(not w.choose(2, "human", "karaoke_warlord"), "a class that was not offered is refused")
	w.set_input(2, Vector2(1, 0))
	var before: Vector2 = p.pos
	_step(w, 0.5)
	check(p.pos == before, "players cannot move while choosing")
	var hp_before: float = p.max_hp
	check(w.choose(2, "slabfolk", "chiropractor"), "a valid choice is accepted")
	check(p.klass == "Unlicensed Chiropractor" and p.race == "Slabfolk" and p.state == "play", "race and class are applied")
	check(p.stats.con == 7 and p.stats.dex == 2 and p.stats.str == 5, "race and class change stats")
	check(is_equal_approx(p.mods.stun_chance, 0.3), "class perks become modifiers")
	check(p.max_hp != hp_before, "health is recalculated")
	check(not w.choose(2, "human", "bruiser"), "the choice is permanent")
	var points: int = p.points
	check(w.spend_point(2, "str") and p.points == points - 1 and p.stats.str == 6, "banked points can now be spent in a safe room")
	check(not w.spend_point(2, "luck"), "unknown stats are refused")
	# Timeout picks for you.
	var q := _join(w, 3, "Bo")
	q.floor = 2
	w._begin_choice(q)
	_step(w, float(db.classes.offer.seconds) + 1.0)
	check(q.klass != "" and q.state == "play", "running out of time picks a class for you")

func test_crafting_class(db: Dictionary) -> void:
	print("world: crafting class and inventions")
	var w := World.new(db, 42)
	var seen := []
	w.event.connect(func(_targets, ev): seen.append(ev))
	var p := _join(w, 2, "Tester", "tinkerer")
	w._note(p, "throws", 8.0)
	p.floor = 2
	w._begin_choice(p)
	check(w.choose(2, "human", "dumpster_alchemist"), "throwing a lot offers the crafting class")
	p.floor = 0
	var f: Dictionary = w.floors[0]
	var leech := {}
	for m in f.mobs.values():
		if m.type == "drain_leech":
			leech = m
			break
	check(not leech.is_empty(), "there is a leech in the flooded rooms")
	p.pos = leech.pos + Vector2(2.0, 0.0)
	check(w.tags_at(f, p.pos) == ["wet"], "player stands in a flooded room")
	p.inv = {"oil_flask": 9, "rag": 9, "flint": 9}
	for i in 3:
		leech.hp = 500.0
		p.hp = p.max_hp
		check(w.throw_items(2, ["oil_flask", "rag", "flint"], leech.pos), "combined throw %d accepted" % (i + 1))
		if i == 0:
			check(int(p.inv.oil_flask) == 8 and int(p.inv.rag) == 8, "ingredients are consumed")
		_step(w, 2.5)
	check(p.abilities.size() == 1, "three purposeful uses create one invention")
	if p.abilities.size() == 1:
		var ab: Dictionary = p.abilities[0]
		print("    invented: %s  traits: %s" % [ab.name, ab.traits.map(func(t): return t.id)])
		check(ab.traits.map(func(t): return t.id).has("channel"), "the invention remembers it was born in water")
		check(ab.born.family == "ooze", "the invention remembers its first target")
	check(seen.any(func(ev): return ev.type == "discovery"), "discovery event sent")
