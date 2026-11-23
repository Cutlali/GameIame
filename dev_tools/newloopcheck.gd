extends SceneTree

# 开发工具：新循环冒烟测试。
# 用法：
#   Godot --path <project> --script res://dev_tools/newloopcheck.gd
# 检查卡牌注册表、收获二选一、自动转化、魔瓶抽取、图鉴与年终总结。
# 注意：--script 的解析早于 autoload 注册，所以这里全部用节点变量访问。

const OUT_DIR = "D:/Godot/"

var game = null
var started = false
var frames = 0
var stage = 0
var wait_until = 0
var failures = []

var gs = null
var game_data = null
var run_stats = null
var encyclopedia = null
var bottle = null
var harvest = null
var bestiary = null
var year_summary = null
var season = null


func _idle(_delta):
	frames += 1
	if not started:
		if frames < 3:
			return
		started = true
		gs = get_root().get_node("GS")
		game_data = get_root().get_node("GameData")
		run_stats = get_root().get_node("RunStats")
		encyclopedia = get_root().get_node("Encyclopedia")
		bottle = get_root().get_node("BottleManager")
		harvest = get_root().get_node("HarvestManager")
		bestiary = get_root().get_node("EncyclopediaUI")
		year_summary = get_root().get_node("YearSummary")
		season = get_root().get_node("Season")
		get_root().get_node("Flags").skip_tutorial = true
		game = load("res://Game.tscn").instance()
		get_root().add_child(game)
		return

	if frames < 40:
		return
	if OS.get_ticks_msec() < wait_until:
		return

	match stage:
		0:
			_check_autoloads()
			_check_cards()
			_check_hud()
			_check_mutation_pity()
			stage = 1
			wait_until = OS.get_ticks_msec() + 250
		1:
			_check_harvest_flow()
			stage = 2
			wait_until = OS.get_ticks_msec() + 250
		2:
			_check_bottle()
			stage = 3
			wait_until = OS.get_ticks_msec() + 250
		3:
			_shot("newloop_bottle")
			bottle.close()
			bottle.charges.clear()
			bestiary.open()
			stage = 4
			wait_until = OS.get_ticks_msec() + 250
		4:
			_shot("newloop_bestiary")
			if bestiary._title.text != "植物图鉴":
				failures.append("bestiary title should not show progress count")
			# 未收录的变异条目不能透露它由哪个基础物种变来。
			bestiary._on_entry_pressed("tomato_v0")
			if bestiary._detail.text.find("番茄") >= 0:
				failures.append("undiscovered variant detail leaks base species")
			stage = 6
			wait_until = OS.get_ticks_msec() + 150
		6:
			_shot("newloop_variant_unknown")
			bestiary.close()
			_check_year_end()
			stage = 5
			wait_until = OS.get_ticks_msec() + 250
		5:
			_shot("newloop_year_end")
			_report()
			quit()


func _check_autoloads():
	var names = ["GameData", "RunStats", "Encyclopedia", "Toast",
		"BottleManager", "HarvestManager", "EncyclopediaUI", "YearSummary"]
	for n in names:
		if get_root().get_node_or_null(n) == null:
			failures.append("autoload missing: " + n)
	print("autoloads: %d checked" % names.size())


func _check_cards():
	var ids = {}
	for e in game_data.BASIC_POOL:
		ids[e["id"]] = true
	for pool in game_data.BOTTLE_POOLS.values():
		for e in pool:
			ids[e["id"]] = true
	for id in ids.keys():
		if gs.card_by_id(id) == null:
			failures.append("card missing: " + id)
	print("card registry: %d ids checked" % ids.size())
	print("season: %s, year %d, round %d, growth/water %d" % [
		season.current_season, season.year, season.round_in_year, season.growth_per_water()])


func _check_hud():
	var hud = game.get_node_or_null("CanvasLayer/Panel")
	if hud == null or hud._bestiary_button == null:
		failures.append("HUD bestiary button missing")
		return
	if hud._bestiary_button.icon == null or \
		not hud._bestiary_button.icon.resource_path.ends_with("bestiary_icon.svg"):
		failures.append("HUD bestiary icon missing")
	if hud._guide_button.rect_size.x < 60:
		failures.append("HUD guide icon should be enlarged")
	if hud._guide_button.rect_position.x > 30 or hud._guide_button.rect_position.y > 75:
		failures.append("HUD guide icon should sit top-left")
	var energy = game.get_node("CanvasLayer/EnergyOrbHolder/EnergyOrb")
	var ec = energy.global_position + Vector2(0, 9)
	var c = hud._orb_center()
	if abs(c.y - ec.y) > 4 or c.x - ec.x < 110 or c.x - ec.x > 150:
		failures.append("crystal orb should sit beside energy orb, energy=%s orb=%s" % [str(ec), str(c)])
	print("hud bestiary icon: " + hud._bestiary_button.icon.resource_path)


func _check_mutation_pity():
	var base = game_data.mutation_chance("spring", 0)
	var once = game_data.mutation_chance("spring", 1)
	var capped = game_data.mutation_chance("summer", 7)
	if abs(base - 0.06) > 0.0001:
		failures.append("mutation base chance wrong: %f" % base)
	if abs(once - 0.21) > 0.0001:
		failures.append("mutation pity step wrong: %f" % once)
	if abs(capped - 1.0) > 0.0001:
		failures.append("mutation chance not capped: %f" % capped)

	# 攒到 7 次未变异时，任何季节都应必定变异，并在变异后清零。
	run_stats.mutation_pity = 7
	var plant = load("res://plants/plant1/Plant1.tscn").instance()
	plant.species_id = "tomato"
	game.get_node("TileMap").add_child(plant)
	var eid = plant.resolve_entry_id()
	if eid.find("_v") < 0:
		failures.append("guaranteed mutation did not occur at pity 7")
	if run_stats.mutation_pity != 0:
		failures.append("mutation pity did not reset after mutation")
	plant.queue_free()
	print("mutation pity: base=%.2f once=%.2f capped=%.2f" % [base, once, capped])


func _check_harvest_flow():
	var plant = load("res://plants/plant1/Plant1.tscn").instance()
	plant.species_id = "tomato"
	game.get_node("TileMap").add_child(plant)
	plant.position = Vector2(0, 0)
	# 这一阶段只验证收获流程，固定为不突变，避免随机结果影响断言。
	plant.mutation_rolled = true
	plant.mutated = false

	var eid = plant.resolve_entry_id()
	print("plant entry: " + eid)

	harvest.handle_harvest(plant)
	if not harvest._root.visible:
		failures.append("harvest popup did not open")
	if not encyclopedia.is_discovered("tomato") and harvest._pending_entry != null:
		harvest._on_sample_pressed()
	if not encyclopedia.is_discovered("tomato"):
		failures.append("sample choice did not discover tomato")

	# 第二次收获应该自动交给魔瓶
	var charges_before = bottle.charges.size()
	var plant2 = load("res://plants/plant1/Plant1.tscn").instance()
	plant2.species_id = "tomato"
	game.get_node("TileMap").add_child(plant2)
	plant2.mutation_rolled = true
	plant2.mutated = false
	harvest.handle_harvest(plant2)
	if harvest._root.visible:
		failures.append("collected entry should auto-bottle")
	if bottle.charges.size() != charges_before + 1:
		failures.append("auto-bottle did not add charge")

	plant.queue_free()
	plant2.queue_free()
	print("harvest flow: encyclopedia=%d, charges=%d" % [
		encyclopedia.discovered_count(), bottle.charges.size()])


func _check_bottle():
	# 上一阶段的收获蓄能应已自动弹出魔瓶。
	if not bottle._root.visible:
		failures.append("harvest charge did not auto-open bottle")
	else:
		_shot("newloop_auto_draw")

	# 清掉自动弹出的这一轮，单独测试手动开启与选牌。
	bottle.force_close()
	bottle.charges.clear()
	bottle.add_charge("medium")
	bottle.open_bottle()
	if not bottle._root.visible:
		failures.append("bottle did not open")

	var offers = bottle._offer_ids.size()
	var need = season.bottle_pick_count()
	if offers != season.bottle_offer_count():
		failures.append("bottle offer count %d != %d" % [offers, season.bottle_offer_count()])

	# 重复打开不能刷新候选。
	var first_offer = bottle._offer_ids.duplicate()
	bottle.open_bottle()
	if bottle._offer_ids != first_offer:
		failures.append("bottle rerolled offers while already open")

	var hand_before = 0
	if gs.hand != null:
		hand_before = gs.hand.get_child_count()

	bottle._on_slot_toggled(true, 0)
	bottle._on_confirm_pressed()

	if bottle._root.visible:
		failures.append("bottle did not close after confirm")
	if bottle.charges.size() != 0:
		failures.append("bottle charge not consumed")

	var hand_after = 0
	if gs.hand != null:
		hand_after = gs.hand.get_child_count()
	if hand_after != hand_before + 1:
		failures.append("bottle card did not go directly to hand")
	print("bottle: offers=%d need=%d, hand %d -> %d, charges=%d" % [
		offers, need, hand_before, hand_after, bottle.charges.size()])

	# 多次收获合并：同一界面里连续结算，不关闭窗口。
	bottle.add_charge("medium")
	bottle.add_charge("rare")
	bottle.open_bottle()
	if bottle._batch_total != 2:
		failures.append("batch total should be 2")
	var batch_hand_before = gs.hand.get_child_count()
	bottle._on_slot_toggled(true, 0)
	bottle._on_confirm_pressed()
	if not bottle._root.visible:
		failures.append("batch session closed after first pick")
	if bottle._batch_done != 2 or bottle.charges.size() != 0:
		failures.append("batch did not advance to second pick")
	bottle._on_slot_toggled(true, 0)
	bottle._on_confirm_pressed()
	if bottle._root.visible or bottle.charges.size() != 0:
		failures.append("batch did not finish")
	if gs.hand.get_child_count() != batch_hand_before + 2:
		failures.append("batch cards did not go to hand")
	print("batch: 2 picks merged, hand %d -> %d" % [
		batch_hand_before, gs.hand.get_child_count()])

	# 留一组两次蓄能的批量界面给截图，确认进度标题正常。
	bottle.add_charge("medium")
	bottle.add_charge("rare")
	bottle.open_bottle()


func _check_year_end():
	season.round_in_year = 24
	var year_before = season.year
	season.advance_round()
	if season.year != year_before + 1:
		failures.append("year did not advance")
	if not year_summary._root.visible:
		failures.append("year summary did not show")
	print("year end: %d -> %d, summary=%s" % [
		year_before, season.year, str(year_summary._root.visible)])


func _shot(name):
	var img = get_root().get_texture().get_data()
	if img == null:
		return
	img.flip_y()
	img.save_png(OUT_DIR + name + ".png")
	print("saved " + name + ".png")


func _report():
	if failures.empty():
		print("NEWLOOP CHECK OK")
	else:
		print("NEWLOOP CHECK FAILED:")
		for f in failures:
			print(" - " + f)