extends SceneTree

# 开发工具：验证正式四季素材（走 SeasonManager 真实换图流程）。
# 用法：
#   Godot --path <project> --script res://dev_tools/seasoncheck.gd
# 输出：D:/Godot/final_<season>_trees.png / final_<season>_board.png

const OUT_DIR = "D:/Godot/"
const SEASONS = ["spring", "summer", "autumn", "winter"]
const TREE_CAM_POS = Vector2(-1000, -1050)
const TREE_CAM_ZOOM = 0.8
const BOARD_CAM_POS = Vector2(0, -480)
const BOARD_CAM_ZOOM = 1.3

var game = null
var season_mgr = null
var frames = 0
var stage = 0
var wait_until = 0
var applied = false


func _init():
	game = load("res://Game.tscn").instance()
	get_root().add_child(game)
	var ui = game.get_node_or_null("CanvasLayer")
	if ui != null:
		ui.visible = false
	var cards = game.get_node_or_null("Camera/Cards")
	if cards != null:
		cards.visible = false


func _idle(_delta):
	frames += 1
	if season_mgr == null:
		season_mgr = get_root().get_node_or_null("Season")
		if season_mgr == null:
			if frames > 200:
				print("Season autoload not found")
				quit()
			return
		var hud = season_mgr.get("_hud_layer")
		if hud != null:
			hud.visible = false

	if frames < 30:
		return
	if OS.get_ticks_msec() < wait_until:
		return
	if stage >= SEASONS.size():
		quit()
		return

	var idx = stage
	if not applied:
		if idx > 0:
			season_mgr.change_season(idx, false, true)
		applied = true
		wait_until = OS.get_ticks_msec() + 450
		return

	_capture_view("final_%s_trees" % SEASONS[idx], TREE_CAM_POS, TREE_CAM_ZOOM)
	_capture_view("final_%s_board" % SEASONS[idx], BOARD_CAM_POS, BOARD_CAM_ZOOM)
	applied = false
	stage += 1
	wait_until = OS.get_ticks_msec() + 200


func _capture_view(name, pos, zoom):
	var cam = game.get_node_or_null("Camera")
	if cam != null:
		cam.position = pos
		cam.zoom = Vector2(zoom, zoom)
	VisualServer.force_draw()
	VisualServer.force_draw()
	var img = get_root().get_texture().get_data()
	img.flip_y()
	img.save_png(OUT_DIR + name + ".png")
	print("saved " + name + ".png")