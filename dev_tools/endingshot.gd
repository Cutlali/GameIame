extends SceneTree

# 截取终章分镜，确认画面、字幕与收尾印章。

var ending = null
var stage = 0
var start_ms = 0
var page = 0


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
		ending = load("res://Ending.tscn").instance()
		get_root().add_child(ending)
		stage = 1
		return
	if stage == 1 and t >= 700:
		_save("D:/Godot/ending_1.png")
		ending.call("_advance")
		stage = 2
		return
	if stage == 2 and t >= 1400:
		_save("D:/Godot/ending_2.png")
		ending.call("_advance")
		stage = 3
		return
	if stage == 3 and t >= 2100:
		_save("D:/Godot/ending_3.png")
		ending.call("_advance")
		stage = 4
		return
	if stage == 4 and t >= 3300:
		_save("D:/Godot/ending_4.png")
		print("ENDING SHOT DONE")
		ending.queue_free()
		quit()
