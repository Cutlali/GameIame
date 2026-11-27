extends SceneTree

# 开发工具：截取 v1.5.2 的 HUD（含水晶球、速成卡）、羊皮纸图鉴、游戏内指南。
# 用法：Godot --path <project> --script res://dev_tools/v152shot.gd

var start_ms = 0
var game = null
var stage = 0


func _init():
	OS.window_size = Vector2(1080, 800)
	start_ms = OS.get_ticks_msec()


func _save(name):
	var img = get_root().get_texture().get_data()
	img.flip_y()
	img.save_png("D:/Godot/" + name + ".png")
	print("saved " + name + ".png")


func _idle(_delta):
	var t = OS.get_ticks_msec() - start_ms
	if stage == 0 and t >= 60:
		get_root().get_node("Flags").skip_tutorial = true
		game = load("res://Game.tscn").instance()
		get_root().add_child(game)
		stage = 1
		return
	if stage == 1 and t >= 400:
		var gs = get_root().get_node("GS")
		var hand_count = 0
		if gs.hand != null and is_instance_valid(gs.hand):
			hand_count = gs.hand.get_child_count()
		if hand_count > 0:
			gs.orb_water = 3
			gs.add_card_to_hand(gs.card_mature)
			stage = 2
		return
	if stage == 2 and t >= 1200:
		_save("hud_v152")
		get_root().get_node("EncyclopediaUI").open()
		stage = 3
		return
	if stage == 3 and t >= 1600:
		_save("bestiary_v152")
		get_root().get_node("EncyclopediaUI").close()
		var flags = get_root().get_node("Flags")
		flags.guide_season_changed = true
		flags.guide_variant_seen = true
		flags.guide_pest_seen = true
		flags.guide_bottle_damaged = true
		flags.guide_milestone_seen = true
		game.get_node("CanvasLayer/Panel").call("_on_guide_pressed")
		game.get_node("GuideBook").select_chapter(2)
		stage = 4
		return
	if stage == 4 and t >= 2100:
		_save("game_guide_v152")
		game.get_node("GuideBook").select_chapter(10)
		stage = 5
		return
	if stage == 5 and t >= 2400:
		_save("game_guide_last_v152")
		game.get_node("GuideBook").close()
		quit()