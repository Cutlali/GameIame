extends SceneTree

# 开发工具：v1.8 名额制自由开垦流程测试。
# 初始 4 格 -> 名额1 -> 放置模式自选北侧 2×2（8 格）
#          -> 名额2 -> 自选东侧 2×2（12 格）-> 旧接口 claim_parcel 兼容（16 格）。
# 每次开垦：手牌上限（bonus_draws）+1、能量上限 +1；名额耗尽自动退出放置模式。

const OUT_DIR = "D:/Godot/"

var game = null
var frames = 0
var stage = 0
var wait_until = 0
var failures = []
var gs = null
var tilemap = null
var ui = null


func _init():
	var flags = get_root().get_node_or_null("Flags")
	if flags != null:
		flags.skip_tutorial = true
	game = load("res://Game.tscn").instance()
	get_root().add_child(game)


func _check(name, got, want):
	if got != want:
		failures.append("%s: got %s, want %s" % [name, str(got), str(want)])
	print("%s: %s" % [name, str(got)])


func _shot(name):
	var img = get_root().get_texture().get_data()
	if img == null:
		return
	img.flip_y()
	img.save_png(OUT_DIR + name + ".png")
	print("saved " + name + ".png")


func _idle(_delta):
	frames += 1
	if frames < 20:
		return
	if OS.get_ticks_msec() < wait_until:
		return

	match stage:
		0:
			gs = get_root().get_node("GS")
			tilemap = gs.tilemap
			ui = get_root().get_node("FarmChoiceUI")
			_check("initial plantable", tilemap.count_plantable(), 4)
			_check("initial energy max", gs.energy_max, 3)
			_check("initial quota", gs.farm_quota, 0)
			gs.queue_farm_choice()
			_check("quota granted", gs.farm_quota, 1)
			stage = 1
			wait_until = OS.get_ticks_msec() + 150
		1:
			_check("button visible", ui._farm_button.visible, true)
			ui.start_placement()
			_check("placement on", gs.farm_choice_open, true)
			_check("ghost visible", tilemap.plot_ghost.visible, true)
			_shot("farm_placement")
			# 位置校验：北侧草地可垦；中央已耕不可垦；压住初始田不可垦。
			_check("north claimable", tilemap.can_claim_plot(Vector2(-2, -5)), true)
			_check("center not claimable", tilemap.can_claim_plot(Vector2(-2, -3)), false)
			_check("overlap not claimable", tilemap.can_claim_plot(Vector2(-3, -4)), false)
			# 非法点击不动数据。
			var before_draws = gs.bonus_draws
			_check("bad claim rejected", tilemap.claim_plot(Vector2(-2, -3)), false)
			_check("bad claim kept quota", gs.farm_quota, 1)
			_check("bad claim kept draws", gs.bonus_draws, before_draws)
			# 合法：开垦北侧。
			_check("north claim ok", tilemap.claim_plot(Vector2(-2, -5)), true)
			_check("after north plantable", tilemap.count_plantable(), 8)
			_check("after north keeps draws", gs.bonus_draws, 0)
			_check("after north energy max", gs.energy_max, 4)
			_check("quota spent", gs.farm_quota, 0)
			_check("placement auto-exit", gs.farm_choice_open, false)
			_shot("farm_after_north")
			gs.queue_farm_choice()
			stage = 2
			wait_until = OS.get_ticks_msec() + 120
		2:
			ui.start_placement()
			_check("second placement on", gs.farm_choice_open, true)
			_check("east claim ok", tilemap.claim_plot(Vector2(0, -3)), true)
			_check("after east plantable", tilemap.count_plantable(), 12)
			_check("after east keeps draws", gs.bonus_draws, 0)
			_check("after east energy max", gs.energy_max, 5)
			# 旧接口（存档迁移/测试用）：不占名额，也能垦。
			_check("legacy claim_parcel ok", tilemap.claim_parcel(3), true)
			_check("after legacy plantable", tilemap.count_plantable(), 16)
			_check("after legacy keeps draws", gs.bonus_draws, 0)
			_check("after legacy energy max", gs.energy_max, 6)
			_check("legacy kept quota", gs.farm_quota, 0)
			# 重复序号不再叠加。
			_check("legacy duplicate rejected", tilemap.claim_parcel(3), false)
			_report()
			quit()

	return false


func _report():
	if failures.empty():
		print("FARM CHECK OK")
	else:
		print("FARM CHECK FAILED:")
		for f in failures:
			print(" - " + f)
