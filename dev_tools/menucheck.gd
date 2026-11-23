extends SceneTree

# 开发工具：开始界面结构、主题与交互冒烟检查。

var frames = 0
var scene = null
var problems = []
var guide = null


func _init():
	OS.window_size = Vector2(1080, 800)
	scene = load("res://MainMenu.tscn").instance()
	get_root().add_child(scene)


func _check(ok, msg):
	if not ok:
		problems.append(msg)


func _idle(_delta):
	frames += 1
	if frames == 4:
		var bg = scene.get_node("Background")
		var panel = scene.get_node("Content/Panel")
		var button = scene.get_node("Content/Panel/Margin/VBox/StartButton")
		var label = button.get_node("Center/Row/Label")
		var vol = scene.get_node("Content/Panel/Margin/VBox/VolumeBars")
		var guide_icon = scene.get_node("Content/GuideIcon")
		guide = scene.get_node("GuideBook")

		_check(bg.texture != null and bg.texture.resource_path.ends_with("menu_bg.png"), "background texture")
		_check(panel.rect_size.x >= 440 and panel.rect_size.y >= 300, "panel size %s" % panel.rect_size)
		_check(panel.get_global_rect().end.x <= 1080, "panel stays on screen")
		_check(button.rect_size.y >= 80, "start button height")
		_check(button.has_focus(), "start button has focus")
		_check(button.is_connected("pressed", scene, "_on_StartButton_pressed"), "start signal")
		_check(label.mouse_filter == 2, "button label ignores mouse")
		_check(button.get_color("font_color", "Button") == Color(0.3, 0.19, 0.12, 1), "button font color")
		var sb = button.get_stylebox("normal", "Button")
		_check(sb is StyleBoxTexture and sb.texture.resource_path.ends_with("menu_button_normal.png"), "button style")

		_check(vol.rect_size.y >= 90, "volume height %s" % vol.rect_size.y)
		var vlabel = vol.get_node("VolumeLabel")
		var grid = vol.get_node("GridContainer")
		_check(vlabel.rect_position.y + vlabel.rect_size.y <= grid.rect_position.y + 1, "volume label/grid overlap")

		_check(scene.get_node_or_null("Content/Panel/Margin/VBox/SkipTutorial") == null, "skip tutorial removed")
		_check(scene.get_node_or_null("Content/Panel/Margin/VBox/HardMode") == null, "hard mode removed")
		_check(guide_icon.icon != null and guide_icon.icon.resource_path.ends_with("guide_icon.png"), "guide icon")
		_check(guide_icon.rect_position.y + guide_icon.rect_size.y <= 740, "guide icon on screen")
		_check(guide != null and not guide.visible, "guide starts hidden")

	if frames == 8:
		var slider = scene.get_node("Content/Panel/Margin/VBox/VolumeBars/GridContainer/MasterSlider")
		var idx = AudioServer.get_bus_index("Master")
		var old = db2linear(AudioServer.get_bus_volume_db(idx))
		slider.value = 0.3
		_check(abs(db2linear(AudioServer.get_bus_volume_db(idx)) - 0.3) < 0.02, "master volume applies")
		slider.value = old

		guide.open()
		_check(guide.visible, "guide opens from menu")
		guide.close()
		_check(not guide.visible, "guide closes from menu")

		if problems.empty():
			print("MENU CHECK OK")
		else:
			for p in problems:
				print("MENU CHECK FAIL: " + p)
		quit()