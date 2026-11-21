extends SceneTree

# 开发工具：变种特性与新卡牌冒烟测试。
# 用法：
#   Godot --path <project> --script res://dev_tools/variantcheck.gd

var frames = 0
var started = false
var game = null
var failures = []

var gs = null
var game_data = null
var run_stats = null
var bottle = null
var harvest = null


func _idle(_delta):
	frames += 1
	if not started:
		if frames < 3:
			return
		started = true
		gs = get_root().get_node("GS")
		game_data = get_root().get_node("GameData")
		run_stats = get_root().get_node("RunStats")
		bottle = get_root().get_node("BottleManager")
		harvest = get_root().get_node("HarvestManager")
		get_root().get_node("Flags").skip_tutorial = true
		game = load("res://Game.tscn").instance()
		get_root().add_child(game)
		return

	if frames < 45:
		return

	_check_data()
	_check_cards()
	_check_plant_perks()
	_check_harvest_perks()
	_check_bottle_perks()
	_check_net()
	_report()
	quit()


func _check_data():
	for sid in game_data.SPECIES_ORDER:
		for i in range(2):
			var perk = game_data.variant_perk(sid, i)
			if perk == null:
				failures.append("missing perk: %s_v%d" % [sid, i])
				continue
			if String(perk.get("text", "")) == "":
				failures.append("missing perk text: %s_v%d" % [sid, i])
			var e = game_data.entry(sid + "_v" + str(i))
			if e["perk_text"] != perk.get("text", ""):
				failures.append("entry perk_text mismatch: %s_v%d" % [sid, i])
	print("variant data: 8 perks checked")


func _check_cards():
	for id in ["hasten", "graft", "cork", "net"]:
		if gs.card_by_id(id) == null:
			failures.append("new card missing: " + id)

	for e in game_data.BASIC_POOL:
		if e["id"] == "hasten" or e["id"] == "graft" or e["id"] == "net":
			print("basic pool has: " + e["id"])

	if gs.card_by_id("water_drip").quantity != 2:
		failures.append("water_drip should water 2 now")
	print("cards: new ids registered")


func _make_plant(scene_path, sid, variant = -1):
	var p = load(scene_path).instance()
	p.species_id = sid
	p.mutation_rolled = true
	p.mutated = variant >= 0
	p.variant_index = max(0, variant)
	game.get_node("TileMap").add_child(p)
	return p


func _check_plant_perks():
	# 樱桃番茄：种下时直接领先 1 帧，并带有轻微颜色。
	var cherry = _make_plant("res://plants/plant1/Plant1.tscn", "tomato", 0)
	cherry.position = Vector2(-256, 0)
	var cherry_sprite = cherry.get_node("Plant")
	if cherry_sprite.frame != 1:
		failures.append("cherry tomato should start at frame 1, got %d" % cherry_sprite.frame)
	if cherry_sprite.modulate == Color.white:
		failures.append("variant should have a color tint")

	var before = cherry_sprite.frame
	cherry.advance_growth(2)
	if cherry_sprite.frame != before + 2:
		failures.append("advance_growth did not advance 2 frames")

	# 靛蓝番茄：被咬时反伤。
	var indigo = _make_plant("res://plants/plant1/Plant1.tscn", "tomato", 1)
	indigo.position = Vector2(256, 0)
	var bug = load("res://bugs/Bug.tscn").instance()
	game.get_node("TileMap").add_child(bug)
	bug.health = 5
	bug.position = Vector2(256, 128)
	indigo.slash_health(1, bug)
	if bug.attack_queue.size() != 1:
		failures.append("indigo tomato reflect did not queue damage")

	# 非洲太阳月见草：非春季也按 2 帧生长。
	var season = get_root().get_node("Season")
	var old_season = season.current_season
	season.current_season = "winter"
	var moon = _make_plant("res://plants/winplant/WinPlant.tscn", "moonflower", 0)
	moon.position = Vector2(-512, 0)
	if moon.growth_steps() != 2:
		failures.append("African Sun should ignore winter growth penalty")
	season.current_season = old_season
	moon.queue_free()

	print("plant perks: frames, reflect, season growth checked")


func _check_harvest_perks():
	# 泰迪熊向日葵：收获时为相邻植物加护盾。
	var teddy = _make_plant("res://plants/plant2/Plant2.tscn", "sunflower", 0)
	teddy.position = Vector2(0, 0)
	var neighbor = _make_plant("res://plants/plant1/Plant1.tscn", "tomato", -1)
	neighbor.position = Vector2(128, 0)
	neighbor.set_defense(0)
	var note = harvest._apply_harvest_perks(
		teddy, game_data.entry("sunflower_v0"), "medium")
	if neighbor.defense != 1:
		failures.append("teddy bear harvest shield did not apply")
	if note.find("护盾") < 0:
		failures.append("teddy bear perk note missing")

	# 奶油南瓜：额外充能。
	var charges_before = bottle.charges.size()
	harvest._apply_harvest_perks(
		teddy, game_data.entry("pumpkin_v0"), "high")
	if bottle.charges.size() != charges_before + 1:
		failures.append("butternut extra bottle charge did not apply")

	# 柠檬日落月见草：恢复 1 点瓶血。
	bottle.hp = 2
	harvest._apply_harvest_perks(
		teddy, game_data.entry("moonflower_v1"), "rare")
	if bottle.hp != 3:
		failures.append("lemon sunset did not heal the bottle")

	print("harvest perks: shield, charge, bottle heal checked")


func _check_bottle_perks():
	bottle.hp = 3
	bottle.cork_charges = 0
	bottle.add_cork(1)
	var hp_before = bottle.hp
	bottle.damage(1)
	if bottle.hp != hp_before:
		failures.append("cork did not absorb bottle damage")
	if bottle.cork_charges != 0:
		failures.append("cork charge was not consumed")

	bottle.hp = 1
	bottle.heal(1)
	if bottle.hp != 2:
		failures.append("bottle heal failed")
	print("bottle: cork and heal checked")


func _check_net():
	var bug = load("res://bugs/Bug.tscn").instance()
	game.get_node("TileMap").add_child(bug)
	bug.health = 3
	bug.spawned = true
	bug.stun_next_attack()
	bug.take_turn()
	if bug.stun_turns != 0:
		failures.append("net stun was not consumed")
	if bug.current_plant_target != null:
		failures.append("stunned bug should not keep a target")

	var bug2 = load("res://bugs/Bug.tscn").instance()
	game.get_node("TileMap").add_child(bug2)
	bug2.health = 3
	bug2.position = Vector2(384, 0)
	gs.cursor.position = bug2.position
	var net = gs.card_by_id("net")
	gs.cursor.net(net)
	if bug2.attack_queue.size() != 1:
		failures.append("net did not queue damage")
	if bug2.stun_turns != 1:
		failures.append("net did not apply stun")

	# 嫁接：已经判定为普通株时，给一次新的变异机会。
	run_stats.mutation_pity = 7
	var plant = _make_plant("res://plants/plant1/Plant1.tscn", "tomato", -1)
	plant.add_mutation_bonus(0.3)
	if not plant.mutated:
		failures.append("graft did not re-roll mutation at pity 7")
	run_stats.mutation_pity = 0
	print("net and graft checked")


func _report():
	if failures.empty():
		print("VARIANT CHECK OK")
	else:
		for f in failures:
			print("VARIANT CHECK FAIL: " + f)
		print("VARIANT CHECK FAILED (%d)" % failures.size())