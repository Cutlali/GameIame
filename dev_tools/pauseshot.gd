extends SceneTree

# 截取暂停菜单里翻开的图鉴指南，检查层级与可读性。

var start_ms = 0
var game = null


func _init():
	OS.window_size = Vector2(1080, 800)
	start_ms = OS.get_ticks_msec()


func _idle(_delta):
	var t = OS.get_ticks_msec() - start_ms
	if game == null and t >= 60:
		get_root().get_node("Flags").skip_tutorial = true
		game = load("res://Game.tscn").instance()
		get_root().add_child(game)
		return
	if game != null and t >= 1200 and not game.get_node("PauseMenu").visible:
		game.get_node("PauseMenu").pause()
		game.get_node("PauseMenu")._on_GuideButton_pressed()
		return
	if game != null and t >= 1800:
		var img = get_root().get_texture().get_data()
		img.flip_y()
		img.save_png("D:/Godot/pause_guide.png")
		print("saved pause_guide.png")
		quit()
