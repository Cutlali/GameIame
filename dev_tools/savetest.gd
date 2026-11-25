extends SceneTree

# 开发工具：存档往返冒烟测试（写入→伪重启→读回→瓶碎语义）。
# 用独立 user 目录跑，不碰真实存档：
#   D:/Godot/Godot_v3.5.3-stable_win64.exe --path <project> --user-dir savetest_run --script res://dev_tools/savetest.gd

var frames = 0
var started = false
var stage = 0
var wait_until = 0
var failures = []

var gs = null
var game = null
var bottle = null
var encyclopedia = null
var season = null
# --script 模式下裸 autoload 标识符会在引擎 boot 之前触发整条脚本图编译，
# 撞进 GS/Cursor 的环。所有 dev 脚本一律 get_node 取单例，这里照旧。
var sv = null
var runstats = null
var flags = null

# 第一次游玩时写入、读回后逐项比对的期望值
var expect = {}


func _init():
	OS.window_size = Vector2(1080, 800)


func _idle(_delta):
	frames += 1
	if not started:
		if frames < 3:
			return
		started = true
		gs = get_root().get_node("GS")
		bottle = get_root().get_node("BottleManager")
		encyclopedia = get_root().get_node("Encyclopedia")
		season = get_root().get_node("Season")
		sv = get_root().get_node("SaveGame")
		runstats = get_root().get_node("RunStats")
		flags = get_root().get_node("Flags")
		# --script 模式默认禁用存档，这里强行打开（配合独立 --user-dir）
		sv.enabled = true
		sv.start_new()
		get_root().get_node("Flags").skip_tutorial = true
		stage = 0
		wait_until = OS.get_ticks_msec() + 200
		return

	if frames < 30:
		return
	if OS.get_ticks_msec() < wait_until:
		return
	# 防活锁：某阶段反复抛错卡住时，20 秒强制收摊并报告卡在哪。
	if OS.get_ticks_msec() > 20000:
		print("SAVE TIMEOUT stage=", stage)
		quit()
		return

	match stage:
		0:
			# 开一局，写状态
			game = load("res://Game.tscn").instance()
			get_root().add_child(game)
			stage = 1
			wait_until = OS.get_ticks_msec() + 400
		1:
			_write_run_state()
			stage = 2
			wait_until = OS.get_ticks_msec() + 200
		2:
			# 模拟"关掉程序"：清场景 + 重置单例
			if game != null and is_instance_valid(game):
				game.queue_free()
			gs.reset_all_state()
			stage = 3
			wait_until = OS.get_ticks_msec() + 300
		3:
			# 模拟"重新打开程序"：读档 + 继续农场
			sv.load_save()
			if not sv.has_save:
				_fail("load_save: no save found after first session")
			sv.apply_meta()
			game = load("res://Game.tscn").instance()
			get_root().add_child(game)
			stage = 4
			wait_until = OS.get_ticks_msec() + 500
		4:
			_check_restored()
			_check_shatter_semantics()
			stage = 5
			wait_until = OS.get_ticks_msec() + 100
		5:
			_cleanup()
			_report()
			quit()


func _write_run_state():
	# 图鉴 2 条（触发第一个里程碑：抽牌+1）
	encyclopedia.discover("tomato")
	encyclopedia.discover("sunflower")
	# 开垦一块田（抽牌+1、永久能量+1）
	if not gs.tilemap.claim_parcel(0):
		_fail("claim_parcel(0) returned false")
	# 走到第 3 年秋天，攒下水、瓶伤、统计
	season.year = 3
	runstats.year = 3
	season.round_in_year = 9
	season.rounds_in_season = 3
	season.current_index = 1
	season.current_season = "summer"
	sv.note_year_reached(3)
	gs.refresh_energy_max()
	gs.orb_water = 5
	bottle.hp = 2
	gs.next_spawn = 5
	gs.no_enemy_turns = 1
	gs.some_enemy_turns = 2
	runstats.harvests = 7
	runstats.mutation_pity = 2
	_write_plants_and_hand()
	sv.save_now()

	expect = {
		"bonus_draws": 1,
		"permanent_energy_bonus": 1,
		"energy_max": 6,
		"milestone_index": 1,
		"hand_ids": ["whack", "water_drop"]
	}


# v1.8：场上植物与手牌也要能跨退出保留。
func _write_plants_and_hand():
	var t = gs.tilemap
	var p1 = load("res://plants/plant1/Plant1.tscn").instance()
	p1.species_id = "tomato"
	p1.mutation_rolled = true
	p1.mutated = false
	p1.position = Vector2(-256, -384)   # 格子 (-2,-3)
	t.add_child(p1)
	p1.set_water(2)
	p1.set_health(5)
	p1.get_node("Plant").frame = 2

	var p2 = load("res://plants/plant2/Plant2.tscn").instance()
	p2.species_id = "sunflower"
	p2.mutation_rolled = true
	p2.mutated = true
	p2.variant_index = 1
	p2.position = Vector2(-128, -384)   # 格子 (-1,-3)
	t.add_child(p2)
	p2.set_health(4)
	p2.get_node("Plant").frame = 3

	# 手牌固定成两张可识别的牌，方便读回断言。
	for i in range(gs.hand.get_child_count() - 1, -1, -1):
		var n = gs.hand.get_child(i)
		gs.hand.remove_child(n)
		n.queue_free()
	gs.add_card_to_hand(gs.card_by_id("whack"))
	gs.add_card_to_hand(gs.card_by_id("water_drop"))


func _check_restored():
	if encyclopedia.discovered_count() != 2:
		_fail("discovered count %d != 2" % encyclopedia.discovered_count())
	if not encyclopedia.is_discovered("tomato") or not encyclopedia.is_discovered("sunflower"):
		_fail("discovered ids lost")
	if encyclopedia.is_discovered("moonflower"):
		_fail("unexpected entry restored")
	if encyclopedia.milestone_index != expect["milestone_index"]:
		_fail("milestone_index %d != %d" % [encyclopedia.milestone_index, expect["milestone_index"]])
	if gs.bonus_draws != expect["bonus_draws"]:
		_fail("bonus_draws %d != %d (milestone re-claimed?)" % [gs.bonus_draws, expect["bonus_draws"]])
	if gs.permanent_energy_bonus != expect["permanent_energy_bonus"]:
		_fail("permanent_energy_bonus lost")
	if gs.energy_max != expect["energy_max"]:
		_fail("energy_max %d != %d (year gate from max_year_reached)" % [gs.energy_max, expect["energy_max"]])
	if gs.energy != gs.energy_max:
		_fail("energy not refilled on restore")
	if gs.orb_water != 5:
		_fail("orb_water %d != 5" % gs.orb_water)
	if bottle.hp != 2:
		_fail("bottle hp %d != 2" % bottle.hp)
	if season.year != 3 or season.current_season != "summer" \
			or season.round_in_year != 9 or season.rounds_in_season != 3:
		_fail("calendar not restored: y%d %s riy%d ris%d" % [
			season.year, season.current_season, season.round_in_year, season.rounds_in_season])
	if gs.tilemap.claimed_plots != [Vector2(-4, -3)]:
		_fail("plots not restored: %s" % [str(gs.tilemap.claimed_plots)])
	if gs.tilemap.count_plantable() != 8:
		_fail("plantable cells %d != 8" % gs.tilemap.count_plantable())
	if not flags.skip_tutorial:
		_fail("skip_tutorial not set for saved player")
	# 植物快照回灌：两株、位置/状态一致。
	var plants = gs.get_tree().get_nodes_in_group("Plant")
	if plants.size() != 2:
		_fail("plants restored %d != 2" % plants.size())
	else:
		var by_pos = {}
		for pl in plants:
			by_pos[pl.position] = pl
		var a = by_pos.get(Vector2(-256, -384))
		var b = by_pos.get(Vector2(-128, -384))
		if a == null or b == null:
			_fail("plants not at saved positions")
		else:
			if a.species_id != "tomato" or int(a.water) != 2 or int(a.health) != 5 					or int(a.get_node("Plant").frame) != 2 or a.mutated:
				_fail("tomato snapshot wrong: w%d hp%d f%d mut%s" % [
					a.water, a.health, a.get_node("Plant").frame, str(a.mutated)])
			if b.species_id != "sunflower" or not b.mutated or b.variant_index != 1 					or int(b.get_node("Plant").frame) != 3:
				_fail("sunflower snapshot wrong: mut%s v%d f%d" % [
					str(b.mutated), b.variant_index, b.get_node("Plant").frame])
	# 手牌快照回灌：恰是那两张。
	var ids = []
	for hc in gs.hand.get_children():
		if hc.get("associated_card") != null:
			ids.append(sv.call("_card_id_of", hc.associated_card))
	ids.sort()
	var want = expect["hand_ids"].duplicate()
	want.sort()
	if ids != want:
		_fail("hand not restored: %s != %s" % [str(ids), str(want)])
	# 三个计数器 reset 后为 0、局内只增不减：恢复到不低于存档值即算成功，
	# 精确相等会被恢复后自动跑的几轮虫群回合干扰（曾出现 ne 1→2）。
	if gs.next_spawn < 1 or gs.no_enemy_turns < 1 or gs.some_enemy_turns < 2:
		_fail("spawn counters not restored: ns=%d ne=%d se=%d" % [
			gs.next_spawn, gs.no_enemy_turns, gs.some_enemy_turns])
	if runstats.year != 3 or runstats.harvests != 7 or runstats.mutation_pity != 2:
		_fail("run stats not restored: y%d h%d p%d" % [
			runstats.year, runstats.harvests, runstats.mutation_pity])


func _check_shatter_semantics():
	# 瓶碎=软重开：年份回 1、虫与作物清空，但图鉴/田/解锁/能量上限保留
	var plant = load("res://plants/plant1/Plant1.tscn").instance()
	plant.species_id = "tomato"
	gs.tilemap.add_child(plant)

	bottle.refill()
	gs.restart_after_shatter()

	if season.year != 1 or season.round_in_year != 1 or season.rounds_in_season != 1:
		_fail("shatter did not reset calendar to year1 round1")
	if season.current_season != "spring":
		_fail("shatter did not return to spring")
	if gs.energy_max != expect["energy_max"]:
		_fail("energy cap dropped after shatter: %d" % gs.energy_max)
	if gs.energy != gs.energy_max:
		_fail("energy not refilled after shatter")
	if not encyclopedia.is_discovered("tomato"):
		_fail("shatter lost encyclopedia")
	if gs.bonus_draws != expect["bonus_draws"]:
		_fail("shatter lost draw bonus")
	if gs.tilemap.claimed_plots != [Vector2(-4, -3)]:
		_fail("shatter lost claimed plots")
	if gs.orb_water != 0:
		_fail("shatter should empty crystal orb, got %d" % gs.orb_water)
	if bottle.hp != 3:
		_fail("shatter restart should refill bottle")
	if not gs.get_tree().get_nodes_in_group("Plant").empty():
		_fail("shatter should clear plants")
	if gs.turn_state != gs.TurnState.PLAYING_CARDS:
		_fail("shatter restart did not resume play state")
	if sv.max_year_reached != 3:
		_fail("max_year_reached should survive shatter, got %d" % sv.max_year_reached)
	if not sv.has_save:
		_fail("shatter save not written")


func _cleanup():
	if game != null and is_instance_valid(game):
		game.queue_free()
	var f = File.new()
	if f.file_exists("user://four_seasons_save.json"):
		if f.open("user://four_seasons_save.json", File.WRITE) == OK:
			f.close()


func _fail(msg):
	failures.append(msg)


func _report():
	if failures.empty():
		print("SAVE CHECK OK")
	else:
		for f in failures:
			print("FAIL: " + f)
		print("SAVE CHECK FAILED")
