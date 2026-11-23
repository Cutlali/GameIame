extends SceneTree

# 依次截取序章、指南、强制阅读和游戏内教程的画面，检查新样式。

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
		get_root().get_node("Flags").skip_tutorial = false
		intro = load("res://Intro.tscn").instance()
		get_root().add_child(intro)
		stage = 1
		return
	if stage == 1 and t >= 900:
		_save("D:/Godot/intro_p1.png")
		intro.call("_advance")
		stage = 2
		return
	if stage == 2 and t >= 1550:
		_save("D:/Godot/intro_p2.png")
		intro.call("_advance")
		stage = 3
		return
	if stage == 3 and t >= 2200:
		intro.call("_advance")
		stage = 4
		return
	if stage == 4 and t >= 2850:
		intro.call("_advance")
		stage = 5
		return
	if stage == 5 and t >= 3500:
		intro.call("_advance")
		stage = 6
		return
	if stage == 6 and t >= 4150:
		_save("D:/Godot/intro_new.png")
		intro.queue_free()
		get_root().get_node("Flags").guide_pest_seen = true
		guide = load("res://ui/GuideBook.tscn").instance()
		get_root().add_child(guide)
		guide.open()
		guide.select_chapter(6)
		stage = 7
		return
	if stage == 7 and t >= 4550:
		_save("D:/Godot/guide_new.png")
		guide.select_chapter(0)
		stage = 8
		return
	if stage == 8 and t >= 4950:
		_save("D:/Godot/guide_note.png")
		guide.queue_free()
		game = load("res://Game.tscn").instance()
		get_root().add_child(game)
		stage = 9
		return
	if stage == 9 and t >= 5700:
		_save("D:/Godot/guide_forced.png")
		stage = 10
		return
	if stage == 10 and t >= 6400:
		var g = game.get_node_or_null("GuideBook")
		if g != null and g.visible:
			# 被强制阅读挡住时，模拟把四页都翻完再合上。
			for i in [0, 1, 2, 3]:
				g.select_chapter(i)
			g.close()
			print("forced guide closed, restricted=%s" % str(g._restricted))
		stage = 11
		return
	if stage == 11 and t >= 7200:
		var tut = game.get_node_or_null("CanvasLayer/Tutorial")
		if tut != null:
			tut._type_accum = 9999.0
			tut._process(0.0)
			print("TUTORIAL stage=%d text_len=%d rect=%s" % [
				tut.stage, tut.text.length(), str(tut.rect_size)])
		_save("D:/Godot/tutorial_new.png")
		quit()
