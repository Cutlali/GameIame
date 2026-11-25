extends SceneTree

# 开发工具：截取开始界面，检查右侧面板的按钮、音量条与退出按钮排版。
# 出两张：无存档基线 mainmenu.png，以及注入假存档后的 mainmenu_save.png。
# 用法：Godot --path <project> --script res://dev_tools/menushot.gd

var start_ms = 0
var stage = 0
var menu = null


func _init():
	OS.window_size = Vector2(1080, 800)
	start_ms = OS.get_ticks_msec()
	menu = load("res://MainMenu.tscn").instance()
	get_root().add_child(menu)


func _idle(_delta):
	if OS.get_ticks_msec() - start_ms < 500:
		return
	match stage:
		0:
			stage = 1
			start_ms = OS.get_ticks_msec() + 200
			_shot("D:/Godot/mainmenu.png")
		1:
			# 注入"有存档"的显示状态（--script 下 SaveGame 默认 disabled）。
			# 用 get_node 取，裸标识符会在 boot 前触发循环编译。
			var sv = get_root().get_node("SaveGame")
			sv.enabled = true
			sv.has_save = true
			sv.discovered_ids = ["tomato", "sunflower", "wheat"]
			sv.parcels = [0, 1]
			sv.run = {"year": 2}
			menu._refresh_save_ui()
			stage = 2
			start_ms = OS.get_ticks_msec() + 200
		2:
			stage = 3
			start_ms = OS.get_ticks_msec() + 200
			_shot("D:/Godot/mainmenu_save.png")
		3:
			print("saved mainmenu.png + mainmenu_save.png")
			quit()


func _shot(path):
	var img = get_root().get_texture().get_data()
	img.flip_y()
	img.save_png(path)