extends SceneTree

# 开发工具：截取开始界面，检查右侧面板的按钮、音量条与退出按钮排版。
# 用法：Godot --path <project> --script res://dev_tools/menushot.gd

var start_ms = 0
var done = false


func _init():
	OS.window_size = Vector2(1080, 800)
	start_ms = OS.get_ticks_msec()
	get_root().add_child(load("res://MainMenu.tscn").instance())


func _idle(_delta):
	if done or OS.get_ticks_msec() - start_ms < 500:
		return
	done = true
	var img = get_root().get_texture().get_data()
	img.flip_y()
	img.save_png("D:/Godot/mainmenu.png")
	print("saved mainmenu.png")
	quit()