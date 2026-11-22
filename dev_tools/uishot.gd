extends SceneTree

# 依次截取序章、指南、游戏内教程的画面，检查新样式。

var intro = null
var guide = null
var game = null
var start_ms = 0
var stage = 0


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

	if stage == 0 and t >= 60:
		intro = load("res://Intro.tscn").instance()
		get_root().add_child(intro)
		stage = 1
		return
	if stage == 1 and t >= 900:
		intro.call("_advance")
		stage = 2
		return
	if stage == 2 and t >= 1550:
		intro.call("_advance")
		stage = 3
		return
	if stage == 3 and t >= 2200:
		intro.call("_advance")
		stage = 4
		return
	if stage == 4 and t >= 2900:
		_save("D:/Godot/intro_new.png")
		intro.queue_free()
		guide = load("res://ui/GuideBook.tscn").instance()
		get_root().add_child(guide)
		guide.open()
		guide.select_chapter(6)
		stage = 5
		return
	if stage == 5 and t >= 3300:
		_save("D:/Godot/guide_new.png")
		guide.select_chapter(0)
		stage = 6
		return
	if stage == 6 and t >= 3700:
		_save("D:/Godot/guide_note.png")
		guide.queue_free()
		get_root().get_node("Flags").skip_tutorial = false
		game = load("res://Game.tscn").instance()
		get_root().add_child(game)
		stage = 7
		return
	if stage == 7 and t >= 5200:
		var tut = game.get_node_or_null("CanvasLayer/Tutorial")
		if tut != null:
			print("TUTORIAL text_len=%d rect=%s line=%d" % [tut.text.length(), str(tut.rect_size), tut.current_line])
		_save("D:/Godot/tutorial_new.png")
		quit()
