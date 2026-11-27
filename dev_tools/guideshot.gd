extends SceneTree

# 开发工具：截取手记的雾气状态与散开过程。
# 用法：Godot --path <project> --script res://dev_tools/guideshot.gd

var start_ms = 0
var guide = null
var stage = 0
var stage_ms = 0


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
		var flags = get_root().get_node("Flags")
		flags.reset_guide_unlocks()
		flags.guide_season_changed = true
		flags.guide_variant_seen = true
		flags.guide_pest_seen = true
		flags.guide_bottle_damaged = true
		flags.guide_milestone_seen = true
		guide = load("res://ui/GuideBook.tscn").instance()
		get_root().add_child(guide)
		stage = 1
		return
	if stage == 1 and t >= 220:
		guide.open()
		guide.select_chapter(10)
		stage = 2
		stage_ms = t
		return
	if stage == 2 and t >= stage_ms + 300:
		_save("guide_fog")
		var flags = get_root().get_node("Flags")
		flags.guide_bottle_shattered = true
		guide._refresh_toc()
		guide.select_chapter(10)
		stage = 3
		stage_ms = t
		return
	if stage == 3 and t >= stage_ms + 180:
		_save("guide_fog_dissolving")
		stage = 4
		stage_ms = t
		return
	if stage == 4 and t >= stage_ms + 700:
		_save("guide_fog_cleared")
		quit()
