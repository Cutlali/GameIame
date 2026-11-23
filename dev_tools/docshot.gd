extends SceneTree

# 为参赛创作手记拍摄配图：主菜单、序章、游戏内、手记。
# 运行：Godot --path . --script res://dev_tools/docshot.gd

var menu = null
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

	if stage == 0 and t >= 100:
		get_root().get_node("Flags").skip_tutorial = false
		menu = load("res://MainMenu.tscn").instance()
		get_root().add_child(menu)
		stage = 1
		return
	if stage == 1 and t >= 1100:
		_save("D:/Godot/doc_menu.png")
		menu.queue_free()
		intro = load("res://Intro.tscn").instance()
		get_root().add_child(intro)
		stage = 2
		return
	if stage == 2 and t >= 1700:
		for i in range(5):
			intro.call("_advance")
		stage = 3
		return
	if stage == 3 and t >= 2600:
		_save("D:/Godot/doc_intro.png")
		intro.queue_free()
		get_root().get_node("Flags").guide_pest_seen = true
		guide = load("res://ui/GuideBook.tscn").instance()
		get_root().add_child(guide)
		guide.open()
		guide.select_chapter(6)
		stage = 4
		return
	if stage == 4 and t >= 3400:
		_save("D:/Godot/doc_guide.png")
		guide.queue_free()
		get_root().get_node("Flags").skip_tutorial = true
		game = load("res://Game.tscn").instance()
		get_root().add_child(game)
		stage = 5
		return
	if stage == 5 and t >= 5200:
		_save("D:/Godot/doc_game.png")
		stage = 6
		return
	if stage == 6 and t >= 6000:
		quit()