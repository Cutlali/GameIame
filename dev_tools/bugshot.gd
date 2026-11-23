extends SceneTree

# 截取不同年份/类型的虫子外观，确认剪影与颜色能区分。

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


func _make_label(text, pos):
	var l = Label.new()
	l.text = text
	l.rect_position = pos
	l.rect_size = Vector2(150, 30)
	l.align = Label.ALIGN_CENTER
	var f = DynamicFont.new()
	f.font_data = load("res://fonts/SimHei.ttf")
	f.size = 18
	l.add_font_override("font", f)
	l.add_color_override("font_color", Color(0.95, 0.94, 0.86))
	return l


func _idle(_delta):
	var t = OS.get_ticks_msec() - start_ms
	if stage == 0 and t >= 100:
		stage = 1
		get_root().get_node("Season").year = 3

		var bg = ColorRect.new()
		bg.color = Color(0.10, 0.13, 0.10)
		bg.rect_size = Vector2(1080, 800)
		get_root().add_child(bg)

		var row = Node2D.new()
		get_root().add_child(row)

		var specs = [
			{"hp": 1, "label": "小虫"},
			{"hp": 4, "label": "甲虫"},
			{"hp": 6, "label": "大头虫"},
			{"hp": 10, "label": "厚血虫"},
			{"hp": 6, "elite": true, "label": "精英"},
			{"hp": 4, "biter": true, "label": "瓶虱"}
		]
		var bug_scene = load("res://bugs/Bug.tscn")
		for i in range(specs.size()):
			var b = bug_scene.instance()
			b.health = specs[i]["hp"]
			b.is_elite = specs[i].get("elite", false)
			b.is_bottle_biter = specs[i].get("biter", false)
			b.position = Vector2(110 + i * 150, 300)
			b.scale = Vector2(1.4, 1.4)
			row.add_child(b)
			b.spawn_now()
			var l = _make_label(specs[i]["label"], Vector2(100 + i * 150 - 35, 520))
			get_root().add_child(l)
		return
	if stage == 1 and t >= 900:
		stage = 2
		_save("D:/Godot/bug_variety.png")
		print("BUG SHOT DONE")
		quit()
