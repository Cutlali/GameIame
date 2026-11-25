extends SceneTree

# 开发工具：年度压力与新工具冒烟测试。
# 用法：
#   Godot --path <project> --script res://dev_tools/yearthreatcheck.gd
# 检查逐年虫压力、瓶虱/精英虫机制、三张新卡、卡池年份门槛与年终威胁提示。

var frames = 0
var started = false
var game = null
var failures = []

var gs = null
var game_data = null
var bottle = null
var season = null


func _idle(_delta):
	frames += 1
	if not started:
		if frames < 3:
			return
		started = true
		gs = get_root().get_node("GS")
		game_data = get_root().get_node("GameData")
		bottle = get_root().get_node("BottleManager")
		season = get_root().get_node("Season")
		get_root().get_node("Flags").skip_tutorial = true
		game = load("res://Game.tscn").instance()
		get_root().add_child(game)
		return

	if frames < 45:
		return

	_check_cards()
	_check_year_gate()
	_check_spawn_config()
	_check_bug_kinds()
	_check_tools()
	_check_threat_text()
	_report()
	quit()


func _check_cards():
	for id in ["swarm", "thorns_armor"]:
		if gs.card_by_id(id) == null:
			failures.append("new card missing: " + id)

	var swarm = gs.card_by_id("swarm")
	if swarm.cost != 3 or swarm.quantity != 2:
		failures.append("swarm should be 3 cost / 2 damage")
	if game_data.BASIC_POOL[0].get("min_year", 1) != 1:
		failures.append("default min_year should be 1")

	# v1.8：修补卡全删（卡、池子、回复渠道都不该再出现）。
	if gs.card_by_id("patch") != null:
		failures.append("patch card should be removed in v1.8")
	for e in game_data.BASIC_POOL:
		if e["id"] == "patch":
			failures.append("patch still in basic pool")
	for pool_id in game_data.BOTTLE_POOLS.keys():
		for e in game_data.BOTTLE_POOLS[pool_id]:
			if e["id"] == "patch":
				failures.append("patch still in " + pool_id + " pool")

	# 种子季门阶梯：15 物种最晚 2 年冬（gate 7）必须全部进池。
	for e in game_data.SEED_CARDS:
		if game_data.entry_gate(e) > 7:
			failures.append("seed " + e["id"] + " gate %d > year2 winter" % game_data.entry_gate(e))
	print("cards: swarm / thorns_armor registered, patch removed")


func _check_year_gate():
	var old_year = season.year

	season.year = 1
	for i in range(300):
		var id = game_data.roll_basic_card_id()
		if id == "thorns_armor" or id == "swarm":
			failures.append("year 1 basic pool leaked: " + id)
			break
	var offer = game_data.roll_offer("medium", 7)
	for id in offer:
		if id == "thorns_armor" or id == "swarm":
			failures.append("year 1 medium offer leaked: " + id)

	season.year = 2
	var saw_swarm = false
	for i in range(200):
		if game_data.roll_basic_card_id() == "swarm":
			saw_swarm = true
			break
	if not saw_swarm:
		failures.append("swarm should appear from year 2")

	season.year = 4
	var saw_all = {"swarm": false, "thorns_armor": false}
	for i in range(600):
		var id = game_data.roll_basic_card_id()
		if saw_all.has(id):
			saw_all[id] = true
		if saw_all["swarm"] and saw_all["thorns_armor"]:
			break
	for k in saw_all.keys():
		if not saw_all[k]:
			failures.append("year 4 basic pool missing: " + k)

	season.year = old_year
	print("year gate: pools respect min_year")


func _check_spawn_config():
	var old_year = season.year
	var old_season = season.current_season
	var old_spawn = gs.next_spawn

	# 春天、第 1 年：配置里只有基础虫子。
	season.current_season = "spring"
	season.year = 1
	gs.next_spawn = 0
	var base = gs.build_spawn_config()
	if base.size() != 1:
		failures.append("year 1 wave size should stay 1, got %d" % base.size())

	# 第 2 年：每波额外多一只虫。
	season.year = 2
	var y2 = gs.build_spawn_config()
	if y2.size() != base.size() + 1:
		failures.append("year 2 should add a partner bug")

	# 第 3 / 4 年：有概率混入瓶虱、精英虫。
	season.year = 3
	var biters = 0
	for i in range(60):
		if gs.build_spawn_config().find(gs.SpawnOpt.BottleBiter) >= 0:
			biters += 1
	if biters == 0:
		failures.append("year 3 never offered a bottle biter")

	season.year = 4
	var elites = 0
	for i in range(60):
		if gs.build_spawn_config().find(gs.SpawnOpt.Elite) >= 0:
			elites += 1
	if elites == 0:
		failures.append("year 4 never offered an elite")

	gs.next_spawn = old_spawn
	season.year = old_year
	season.current_season = old_season
	print("spawn config: year pressure checked (biters=%d elites=%d)" % [biters, elites])


func _check_bug_kinds():
	# 精英虫：6 血、1 点护甲、咬 2 点。
	var elite = load("res://bugs/Bug.tscn").instance()
	elite.is_elite = true
	elite.health = 6
	game.get_node("TileMap").add_child(elite)
	elite.position = Vector2(0, 0)
	if elite.armor != 1 or elite.bite_damage != 2:
		failures.append("elite should have armor 1 and bite 2")
	elite.take_damage(2)
	elite.dec_health()
	if elite.health != 5:
		failures.append("elite armor should reduce 2 damage to 1, got hp %d" % elite.health)
	elite.queue_free()

	# 瓶虱：第 3 回合直接啃掉 1 点瓶血。
	var biter = load("res://bugs/Bug.tscn").instance()
	biter.is_bottle_biter = true
	biter.health = 3
	biter.spawned = true
	game.get_node("TileMap").add_child(biter)
	biter.position = Vector2(256, 0)

	bottle.hp = 3
	biter.take_turn()
	biter.take_turn()
	if bottle.hp != 3:
		failures.append("bottle biter bit too early")
	biter.take_turn()
	if bottle.hp != 2:
		failures.append("bottle biter should damage the bottle on turn 3, hp %d" % bottle.hp)
	biter.queue_free()
	bottle.hp = 3

	# 飞虫：锁定最渴的植物，落点必须紧贴它旁边一格。
	# _make_plant() 已经把它挂到 TileMap 上了，这里只补位置和水分。
	var p_wet = _make_plant()
	p_wet.position = Vector2(-1024, 0)
	p_wet.set_water(3)
	var p_dry = _make_plant()
	p_dry.position = Vector2(512, 512)
	p_dry.set_water(0)
	var fly = load("res://bugs/Bug.tscn").instance()
	fly.is_flyer = true
	fly.health = 2
	fly.spawned = true
	game.get_node("TileMap").add_child(fly)
	fly.position = Vector2(-128, -128)
	if fly.find_thirstiest() != p_dry:
		failures.append("flyer should pick the driest plant")
	var landing = fly._landing_cell(p_dry)
	if abs(abs(landing.x - p_dry.position.x) + abs(landing.y - p_dry.position.y) - 128) > 1:
		failures.append("flyer landing should hug the plant, got " + str(landing))
	fly.take_turn()
	if fly.current_plant_target != p_dry:
		failures.append("flyer take_turn should commit to the driest plant")
	fly.queue_free()
	p_wet.queue_free()
	p_dry.queue_free()
	print("bug kinds: elite / bottle biter / flyer checked")


func _make_plant(sid = "tomato"):
	var p = load("res://plants/plant1/Plant1.tscn").instance()
	p.species_id = sid
	p.mutation_rolled = true
	p.mutated = false
	game.get_node("TileMap").add_child(p)
	return p


func _check_tools():
	# 反伤甲：2 点护盾 + 2 点固定反伤，和变种反伤叠加。
	var plant = _make_plant()
	plant.position = Vector2(0, 0)
	plant.set_defense(0)
	plant.set_health(7)
	gs.cursor.position = plant.position
	gs.cursor.thorns_armor(gs.card_by_id("thorns_armor"))
	if plant.defense != 2:
		failures.append("thorns armor should add 2 defense")
	if plant.reflect_damage != 2:
		failures.append("thorns armor should add 2 reflect")

	var bug = load("res://bugs/Bug.tscn").instance()
	game.get_node("TileMap").add_child(bug)
	bug.health = 5
	bug.position = Vector2(0, 128)
	plant.slash_health(1, bug)
	if bug.attack_queue.size() != 1 or int(bug.attack_queue[0]) != 2:
		failures.append("plant reflect should queue 2 damage")

	# 蜂群：对所有敌人造成 2 点伤害。
	var bug2 = load("res://bugs/Bug.tscn").instance()
	game.get_node("TileMap").add_child(bug2)
	bug2.health = 5
	bug2.position = Vector2(128, 128)
	gs.cursor.attack_all(gs.card_by_id("swarm"))
	# bug 身上已有一次反伤记录，所以这里看最后一次伤害即可。
	if bug.attack_queue.size() != 2 or int(bug.attack_queue[1]) != 2:
		failures.append("swarm should hit every enemy for 2")
	if bug2.attack_queue.size() != 1 or int(bug2.attack_queue[0]) != 2:
		failures.append("swarm should hit every enemy for 2")

	# v1.8：修补渠道整体下线——瓶血只减不增。
	if bottle.has_method("heal"):
		failures.append("BottleManager.heal should be removed")
	bottle.hp = 3

	plant.queue_free()
	bug.queue_free()
	bug2.queue_free()
	print("tools: thorns armor / swarm checked (patch removed)")


func _check_threat_text():
	if season.threat_text_for_year(2) == "":
		failures.append("missing threat text for year 2")
	if season.threat_text_for_year(3).find("瓶") < 0:
		failures.append("year 3 threat should mention the bottle")
	if season.threat_text_for_year(3).find("修补") >= 0:
		failures.append("year 3 threat should no longer promise patching")
	if season.threat_text_for_year(4) == "":
		failures.append("missing threat text for year 4")
	if season.threat_text_for_year(9) == "":
		failures.append("missing threat text for late years")

	var summary = get_root().get_node("YearSummary")
	summary.show_summary(1, false, ["测试"], 1, 12, "明年的新威胁：测试")
	if not summary._threat.visible or summary._threat.text != "明年的新威胁：测试":
		failures.append("year summary did not display the threat line")
	summary.reset_all()
	print("threat: year summary line checked")


func _report():
	if failures.empty():
		print("YEAR THREAT CHECK OK")
	else:
		for f in failures:
			print("YEAR THREAT CHECK FAIL: " + f)
		print("YEAR THREAT CHECK FAILED (%d)" % failures.size())
