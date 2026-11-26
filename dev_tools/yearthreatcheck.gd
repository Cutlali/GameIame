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

	# 第 1 年：春/夏 1-2 只，秋/冬 2 只；只有蚜虫(3)与瓢虫(5)。
	season.year = 1
	for s in ["spring", "summer"]:
		season.current_season = s
		for i in range(20):
			var cfg = gs.build_spawn_config()
			if cfg.size() < 1 or cfg.size() > 2:
				failures.append("year1 %s wave size %d not in 1..2" % [s, cfg.size()])
				break
			for item in cfg:
				if item != gs.SpawnOpt.Bug3 and item != gs.SpawnOpt.Bug5:
					failures.append("year1 %s leaked advanced bug" % s)
	for s in ["autumn", "winter"]:
		season.current_season = s
		for i in range(10):
			if gs.build_spawn_config().size() != 2:
				failures.append("year1 %s wave should be exactly 2" % s)
				break

	# 第 2 年：每波至少 2 只，大虫子会混进来。
	season.year = 2
	var giants = 0
	for s in ["spring", "summer", "autumn", "winter"]:
		season.current_season = s
		for i in range(40):
			var cfg2 = gs.build_spawn_config()
			if cfg2.size() < 2:
				failures.append("year2 %s wave size %d < 2" % [s, cfg2.size()])
				break
			for item in cfg2:
				if item == gs.SpawnOpt.Giant:
					giants += 1
	if giants == 0:
		failures.append("year2 never offered a giant")

	# 刷怪轮次表：春 2 / 夏 4 / 秋 1 / 冬 1，第 2 年秋冬各 +1，第 3 年每轮。
	var p1 = gs._spawn_plan_for(1, 0)
	if p1.size() != 2:
		failures.append("year1 spring plan %d != 2" % p1.size())
	var p2 = gs._spawn_plan_for(1, 1)
	if p2.size() != 4:
		failures.append("year1 summer plan %d != 4" % p2.size())
	if gs._spawn_plan_for(1, 2).size() != 1:
		failures.append("year1 autumn plan should be 1")
	if gs._spawn_plan_for(1, 3).size() != 1:
		failures.append("year1 winter plan should be 1")
	if gs._spawn_plan_for(2, 2).size() != 2:
		failures.append("year2 autumn plan should be 2")
	if gs._spawn_plan_for(2, 3).size() != 2:
		failures.append("year2 winter plan should be 2")
	if gs._spawn_plan_for(3, 0).size() != 6:
		failures.append("year3 spring plan should be every round")

	season.year = old_year
	season.current_season = old_season
	print("spawn config: year1/2/3 curve checked (giants seen=%d)" % giants)


func _check_bug_kinds():
	# 第 1 年：蚜虫 3 血、瓢虫 5 血。
	season.year = 1
	gs._spawn_bug_at(Vector2(-2, -1), gs.SpawnOpt.Bug3)
	var aphid = get_nodes_in_group("Enemy")[0]
	if aphid.health != 3:
		failures.append("year1 aphid health %d != 3" % aphid.health)
	_despawn(aphid)
	gs._spawn_bug_at(Vector2(-2, -1), gs.SpawnOpt.Bug5)
	var ladybug = get_nodes_in_group("Enemy")[0]
	if ladybug.health != 5:
		failures.append("year1 ladybug health %d != 5" % ladybug.health)
	_despawn(ladybug)

	# 第 2 年：蚜虫 4 / 瓢虫 6 / 大虫子 10（一口 2、无护甲）。
	season.year = 2
	gs._spawn_bug_at(Vector2(-2, -1), gs.SpawnOpt.Bug3)
	aphid = get_nodes_in_group("Enemy")[0]
	if aphid.health != 4:
		failures.append("year2 aphid health %d != 4" % aphid.health)
	_despawn(aphid)
	gs._spawn_bug_at(Vector2(-2, -1), gs.SpawnOpt.Bug5)
	ladybug = get_nodes_in_group("Enemy")[0]
	if ladybug.health != 6:
		failures.append("year2 ladybug health %d != 6" % ladybug.health)
	_despawn(ladybug)

	gs._spawn_bug_at(Vector2(-2, -1), gs.SpawnOpt.Giant)
	var giant = get_nodes_in_group("Enemy")[0]
	if not giant.is_giant or giant.health != 10:
		failures.append("year2 giant should be 10 hp")
	if giant.armor != 0:
		failures.append("giant should have no armor")
	if giant.bite_damage != 2:
		failures.append("year2 giant bite %d != 2" % giant.bite_damage)
	_despawn(giant)

	# 第 3 年数值维持第 2 年，只提高刷新频率。
	season.year = 3
	gs._spawn_bug_at(Vector2(-2, -1), gs.SpawnOpt.Giant)
	giant = get_nodes_in_group("Enemy")[0]
	if giant.health != 10:
		failures.append("year3 giant health %d != 10" % giant.health)
	if giant.bite_damage != 2:
		failures.append("year3 giant bite %d != 2" % giant.bite_damage)
	_despawn(giant)
	season.year = 1
	print("bug kinds: aphid / ladybug / giant checked")


func _despawn(bug):
	bug.get_parent().remove_child(bug)
	bug.queue_free()


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
	if season.threat_text_for_year(3).find("每一轮") < 0:
		failures.append("year 3 threat should mention every round")
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
