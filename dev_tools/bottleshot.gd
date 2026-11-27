extends SceneTree

# 截取首次瓶碎过场的三页，确认图片、字幕、页码与跳过按钮的位置。

var cut = null
var guide = null
var stage = 0
var start_ms = 0


func _init():
	OS.window_size = Vector2(1080, 800)
	start_ms = OS.get_ticks_msec()


func _save(path):
	var img = get_root().get_texture().get_data()
	img.flip_y()
	img.save_png(path)
	print("saved " + path)


func _idle(_delta):
	var t = OS.get_ticks_msec() - start_ms
	if stage == 0 and t >= 80:
		cut = load("res://BottleBreak.gd").new()
		get_root().add_child(cut)
		stage = 1
		return
	if stage == 1 and t >= 700:
		_save("D:/Godot/bottlebreak_1.png")
		cut.call("_on_click")
		stage = 2
		return
	if stage == 2 and t >= 1400:
		_save("D:/Godot/bottlebreak_2.png")
		cut.call("_on_click")
		stage = 3
		return
	if stage == 3 and t >= 2100:
		_save("D:/Godot/bottlebreak_3.png")
		var flags = get_root().get_node("Flags")
		flags.reset_guide_unlocks()
		flags.unlock_guide("guide_bottle_shattered", 9, "碎裂之后")
		guide = load("res://ui/GuideBook.tscn").instance()
		get_root().add_child(guide)
		stage = 4
		return
	if stage == 4 and t >= 2600:
		guide.open()
		guide.select_chapter(9)
		stage = 5
		return
	if stage == 5 and t >= 3000:
		_save("D:/Godot/bottlebreak_guide.png")
		print("BOTTLE SHOT DONE")
		cut.queue_free()
		guide.queue_free()
		quit()