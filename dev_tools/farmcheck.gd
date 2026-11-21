extends SceneTree

# 开发工具：农田开垦流程测试。
# 初始 4 格 -> 开垦西侧 8 格 -> 开垦东侧 12 格；
# 每次开垦提升每轮抽牌数。

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
			_shot("farm_initial")
			gs.queue_farm_choice()
			stage = 1
			wait_until = OS.get_ticks_msec() + 150
		1:
			if not ui._root.visible:
				failures.append("farm choice did not open")
			if not paused:
				failures.append("farm choice did not pause the game")
			if ui._root.visible:
				_shot("farm_choice")
			ui._on_parcel_pressed(0)
			ui._on_confirm_pressed()
			_check("after west plantable", tilemap.count_plantable(), 8)
			_check("after west bonus draws", gs.bonus_draws, 1)
			_check("after west energy max", gs.energy_max, 4)
			if paused:
				failures.append("farm choice did not resume the game")
			stage = 3
			wait_until = OS.get_ticks_msec() + 150
		3:
			# 等 UI 真正关闭后再截图，确认地图确实扩成 8 格。
			_shot("farm_after_west")
			gs.queue_farm_choice()
			stage = 2
			wait_until = OS.get_ticks_msec() + 150
		2:
			if not ui._root.visible:
				failures.append("second farm choice did not open")
			ui._on_parcel_pressed(1)
			ui._on_confirm_pressed()
			_check("after east plantable", tilemap.count_plantable(), 12)
			_check("after east bonus draws", gs.bonus_draws, 2)
			_check("after east energy max", gs.energy_max, 5)
			_report()
			quit()


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


func _report():
	if failures.empty():
		print("FARM CHECK OK")
	else:
		print("FARM CHECK FAILED:")
		for f in failures:
			print(" - " + f)