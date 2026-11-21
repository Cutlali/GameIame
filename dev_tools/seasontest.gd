extends SceneTree

# 开发工具：验证 M2 的回合驱动自动换季。
# 直接调用 GS.deal_new_hand()（与真实结束回合时的调用点一致）。
# 用法：
#   Godot --path <project> --script res://dev_tools/seasontest.gd
# 输出：D:/Godot/m2_spring_r6.png、m2_summer_r1.png，并在控制台打印状态。

const OUT_DIR = "D:/Godot/"
const CAM_POS = Vector2(0, -480)
const CAM_ZOOM = 1.3

var game = null
var season_mgr = null
var gs = null
var frames = 0
var stage = 0
var next_at = 0
var calls_done = 0


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
		gs = get_root().get_node_or_null("GS")
		if season_mgr == null or gs == null:
			if frames > 200:
				print("autoload not found")
				quit()
			return

	if frames == 8:
		var cam = game.get_node_or_null("Camera")
		if cam != null:
			cam.position = CAM_POS
			cam.zoom = Vector2(CAM_ZOOM, CAM_ZOOM)

	if frames < 20:
		return

	match stage:
		0:
			print("start: %s round %d" % [season_mgr.current_season, season_mgr.rounds_in_season])
			stage = 1
			next_at = OS.get_ticks_msec() + 400
		1:
			if OS.get_ticks_msec() < next_at:
				return
			if calls_done < 5:
				gs.deal_new_hand()
				calls_done += 1
				print("deal_new_hand #%d -> %s round %d" % [
					calls_done, season_mgr.current_season, season_mgr.rounds_in_season])
				next_at = OS.get_ticks_msec() + 350
			else:
				_capture("m2_spring_r6")
				stage = 2
				next_at = OS.get_ticks_msec() + 400
		2:
			if OS.get_ticks_msec() < next_at:
				return
			gs.deal_new_hand()
			print("deal_new_hand #6 -> %s round %d" % [
				season_mgr.current_season, season_mgr.rounds_in_season])
			stage = 3
			next_at = OS.get_ticks_msec() + 2600
		3:
			if OS.get_ticks_msec() < next_at:
				return
			print("final: %s round %d" % [season_mgr.current_season, season_mgr.rounds_in_season])
			_capture("m2_summer_r1")
			stage = 4
		4:
			quit()


func _capture(name):
	VisualServer.force_draw()
	var img = get_root().get_texture().get_data()
	img.flip_y()
	img.save_png(OUT_DIR + name + ".png")
	print("saved " + name + ".png")