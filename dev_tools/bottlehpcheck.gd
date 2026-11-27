extends SceneTree

# 开发工具：魔瓶血量/瓶碎重开冒烟测试。
# 用法：
#   Godot --path <project> --script res://dev_tools/bottlehpcheck.gd
# 检查：HUD 血量、植物死亡扣血、瓶碎过场、重开后图鉴与农田保留。

const OUT_DIR = "D:/Godot/"

var game = null
var started = false
var frames = 0
var stage = 0
var wait_until = 0
var failures = []

var gs = null
var bottle = null
var encyclopedia = null
var season = null
var run_stats = null


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
		run_stats = get_root().get_node("RunStats")
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
			encyclopedia.discover("tomato")
			gs.tilemap.claim_parcel(0)
			stage = 1
			wait_until = OS.get_ticks_msec() + 250
		1:
			_shot("bottle_hp_hud")
			if bottle.hp != 3:
				failures.append("bottle should start at 3 hp, got %d" % bottle.hp)
			var hud = game.get_node_or_null("CanvasLayer/Panel")
			if hud == null or hud._hp != 3:
				failures.append("HUD did not show 3 hp")
			_kill_one_plant()
			stage = 2
			wait_until = OS.get_ticks_msec() + 250
		2:
			if bottle.hp != 2:
				failures.append("plant death should cost 1 hp, got %d" % bottle.hp)
			var hud = game.get_node_or_null("CanvasLayer/Panel")
			if hud == null or hud._hp != 2:
				failures.append("HUD did not update to 2 hp")
			_shot("bottle_hp_damaged")
			_sacrifice_one_plant()
			season.change_season(3, false, false)
			stage = 5
			wait_until = OS.get_ticks_msec() + 500
		5:
			# 玩家主动牺牲植物不扣瓶血。
			if bottle.hp != 2:
				failures.append("sacrificed plant should not damage bottle")
			# 光晕要跟着季节走到冬色（蓝色分量明显高于红色）。
			var hud = game.get_node_or_null("CanvasLayer/Panel")
			if hud == null or hud._glow.b <= hud._glow.r + 0.1:
				failures.append("bottle glow did not follow winter color")
			_shot("bottle_hp_winter")
			season.year = 4
			season.round_in_year = 13
			run_stats.year = 4
			bottle.damage(2)
			stage = 3
			wait_until = OS.get_ticks_msec() + 350
		3:
			if not bottle._shatter_open:
				failures.append("shatter flow did not open at 0 hp")
			if bottle._break_cutscene == null:
				failures.append("shatter cutscene did not play")
			_shot("bottle_shatter")
			# 跳过过场；首碎会强制翻到手记新页，合上后才重开。
			if bottle._break_cutscene != null:
				bottle._break_cutscene._skip()
			var shatter_guide = game.get_node_or_null("GuideBook")
			if shatter_guide != null and shatter_guide.visible:
				shatter_guide.close()
			stage = 4
			wait_until = OS.get_ticks_msec() + 300
		4:
			_shot("bottle_hp_restart")
			if bottle.hp != 3:
				failures.append("restart did not refill bottle hp")
			if season.year != 1 or run_stats.year != 1:
				failures.append("restart did not reset year")
			if season.round_in_year != 1 or season.current_season != "spring":
				failures.append("restart did not return to spring round 1")
			if not encyclopedia.is_discovered("tomato"):
				failures.append("restart should keep encyclopedia")
			if gs.tilemap.claimed_plots.size() != 1:
				failures.append("restart should keep claimed farmland")
			if gs.energy_max != 4 or gs.bonus_draws != 0:
				failures.append("restart should keep farm upgrades (energy only, v1.8 cap rule)")
			# 瓶碎重开后的第一手：固定 3 张且含水牌保证。
			if gs.hand == null or gs.hand.get_child_count() < gs.card_draw_count:
				failures.append("restart did not deal a fresh hand")
			if gs._hand_water_count() < 1:
				failures.append("restart hand lacks guaranteed water card")
			if not gs.get_tree().get_nodes_in_group("Plant").empty():
				failures.append("restart should clear plants")
			if gs.shatter_open:
				failures.append("shatter flag not cleared after restart")
			# 第二次碎瓶：不再播过场，直接回到原来的结算面板。
			bottle.damage(3)
			stage = 6
			wait_until = OS.get_ticks_msec() + 350
		6:
			if bottle._break_cutscene != null:
				failures.append("later break should skip the cutscene")
			if not bottle._shatter_root.visible:
				failures.append("later break should show the summary panel")
			_shot("bottle_shatter_summary")
			bottle._on_shatter_restart_pressed()
			stage = 7
			wait_until = OS.get_ticks_msec() + 300
		7:
			_shot("bottle_hp_restart_again")
			if bottle.hp != 3 or bottle._shatter_open:
				failures.append("summary restart did not refill/close the flow")
			if gs.shatter_open:
				failures.append("summary restart left shatter flag set")
			_report()
			quit()


func _kill_one_plant():
	var plant = load("res://plants/plant1/Plant1.tscn").instance()
	plant.species_id = "tomato"
	game.get_node("TileMap").add_child(plant)
	plant.position = Vector2(0, 0)
	# 模拟虫害：把血量压到 1，再吃一次伤害。
	plant.health = 1
	plant.dec_health()


func _sacrifice_one_plant():
	var plant = load("res://plants/plant1/Plant1.tscn").instance()
	plant.species_id = "tomato"
	game.get_node("TileMap").add_child(plant)
	plant.position = Vector2(0, 0)
	# 牺牲卡走 set_health(0)，不应算作虫害死亡。
	plant.set_health(0)


func _shot(name):
	var img = get_root().get_texture().get_data()
	img.flip_y()
	img.save_png(OUT_DIR + name + ".png")
	print("saved " + name + ".png")


func _report():
	if failures.empty():
		print("BOTTLE HP CHECK OK")
	else:
		for f in failures:
			print("FAIL: " + f)
		print("BOTTLE HP CHECK FAILED")
