extends SceneTree

# 开发工具：渲染同一张地图的四季截图，用于检查贴图替换是否完整。
# 用法：
#   Godot_v3.5.3-stable_win64.exe --path <project> --script res://dev_tools/seasonshot.gd
# 输出：D:/Godot/m1_spring.png、m1_summer.png、m1_autumn.png、m1_winter.png

const OUT_DIR = "D:/Godot/"
const SEASONS = ["spring", "summer", "autumn", "winter"]
const CAM_POS = Vector2(0, -480)
const CAM_ZOOM = 1.3

var frames = 0
var step = 0
var next_shot_at = 0
var game = null
var season_mgr = null


func _init():
	game = load("res://Game.tscn").instance()
	get_root().add_child(game)

	var ui = game.get_node_or_null("CanvasLayer")
	if ui != null:
		ui.visible = false
	var cards = game.get_node_or_null("Camera/Cards")
	if cards != null:
		cards.visible = false


func _idle(delta):
	frames += 1

	if season_mgr == null:
		season_mgr = get_root().get_node_or_null("Season")
		if season_mgr == null:
			if frames > 120:
				print("Season autoload not found")
				quit()
			return

	if frames == 8:
		var cam = game.get_node_or_null("Camera")
		if cam != null:
			cam.position = CAM_POS
			cam.zoom = Vector2(CAM_ZOOM, CAM_ZOOM)

	if frames < 16:
		return

	if step >= SEASONS.size():
		quit()
		return

	# 使用完整的带动画切换流程，同时验证淡入淡出与协程
	if next_shot_at == 0:
		if step > 0:
			season_mgr.change_season(step)
		next_shot_at = OS.get_ticks_msec() + 2300
		return

	if OS.get_ticks_msec() >= next_shot_at:
		_capture(SEASONS[step])
		next_shot_at = 0
		step += 1


func _capture(name):
	VisualServer.force_draw()
	var img = get_root().get_texture().get_data()
	img.flip_y()
	img.save_png(OUT_DIR + "m1_" + name + ".png")
	print("saved m1_" + name + ".png")
