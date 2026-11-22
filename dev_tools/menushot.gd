extends SceneTree

# 开发工具：截取开始界面，便于检查布局。
# 用法：
#   Godot --path <project> --script res://dev_tools/menushot.gd -- <输出文件名>

var frames = 0
var scene = null
var out_name = "menu_shot.png"


func _init():
	OS.window_size = Vector2(1080, 800)
	var args = OS.get_cmdline_args()
	for a in args:
		if not a.begins_with("-") and a != "--" and a.find("Godot") < 0 and a.find("menushot") < 0:
			out_name = a
	scene = load("res://MainMenu.tscn").instance()
	get_root().add_child(scene)


func _idle(_delta):
	frames += 1
	if frames < 30:
		return
	VisualServer.force_draw()
	VisualServer.force_draw()
	var img = get_root().get_texture().get_data()
	img.flip_y()
	img.save_png("D:/Godot/" + out_name)
	print("saved " + out_name)
	quit()