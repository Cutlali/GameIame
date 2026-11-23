extends SceneTree

# 开发工具：开始界面结构、主题与交互冒烟检查。

var frames = 0
var scene = null
var problems = []


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
		var quit_btn = scene.get_node("Content/Panel/Margin/VBox/QuitButton")
		var quit_label = quit_btn.get_node("Center/Row/Label")
		var stop_icon = quit_btn.get_node("Center/Row/Icon")

		_check(bg.texture != null and bg.texture.resource_path.ends_with("menu_bg.png"), "background texture")
		_check(panel.rect_size.x >= 440 and panel.rect_size.y >= 420, "panel size %s" % panel.rect_size)
		_check(panel.get_global_rect().end.x <= 1080, "panel stays on screen")
		_check(panel.get_global_rect().end.y <= 740, "panel stays above version label")
		var version_label = scene.get_node("Content/Version")
		_check(version_label.text == "v1.6.0", "version label %s" % version_label.text)
		_check(button.rect_size.y >= 70, "start button height %s" % button.rect_size.y)
		_check(button.has_focus(), "start button has focus")
		_check(button.is_connected("pressed", scene, "_on_StartButton_pressed"), "start signal")
		_check(label.mouse_filter == 2, "button label ignores mouse")
		_check(label.get_font("font").size == 32, "menu label font %s" % label.get_font("font").size)
		_check(button.get_color("font_color", "Button") == Color(0.3, 0.19, 0.12, 1), "button font color")
		var sb = button.get_stylebox("normal", "Button")
		_check(sb is StyleBoxTexture and sb.texture.resource_path.ends_with("menu_button_normal.png"), "button style")

		_check(vol.rect_size.y >= 90, "volume height %s" % vol.rect_size.y)
		var vlabel = vol.get_node("VolumeLabel")
		var grid = vol.get_node("GridContainer")
		var master_label = grid.get_node("MasterLabel")
		_check(vlabel.rect_position.y + vlabel.rect_size.y <= grid.rect_position.y + 1, "volume label/grid overlap")
		_check(vlabel.get_font("font").size == 24,
			"volume heading font %s" % vlabel.get_font("font").size)
		_check(master_label.get_font("font").size == 22,
			"volume row font %s" % master_label.get_font("font").size)
		_check(vlabel.rect_size.y >= 30, "volume heading height %s" % vlabel.rect_size.y)

		_check(scene.get_node_or_null("Content/Panel/Margin/VBox/SkipTutorial") == null, "skip tutorial removed")
		_check(scene.get_node_or_null("Content/Panel/Margin/VBox/HardMode") == null, "hard mode removed")
		_check(scene.get_node_or_null("Content/GuideIcon") == null, "guide icon removed from menu")
		_check(scene.get_node_or_null("GuideBook") == null, "guide book removed from menu")
		_check(grid.get_global_rect().end.y <= quit_btn.get_global_rect().position.y - 2,
			"volume rows overlap quit button: grid_end=%.0f quit_top=%.0f"
			% [grid.get_global_rect().end.y, quit_btn.get_global_rect().position.y])
		_check(quit_btn.rect_size.y >= 50, "quit button height %s" % quit_btn.rect_size.y)
		_check(quit_label.text == "退出游戏", "quit button label")
		_check(quit_label.get_font("font").size == label.get_font("font").size,
			"start/quit labels same font size")
		_check(stop_icon is ColorRect and abs(stop_icon.rect_size.x - stop_icon.rect_size.y) < 1,
			"quit icon is a square %s" % stop_icon.rect_size)
		_check(quit_btn.visible, "quit button visible on desktop")
		_check(quit_btn.is_connected("pressed", scene, "_on_QuitButton_pressed"), "quit signal")
		_check(abs(button.rect_size.y - quit_btn.rect_size.y) < 1,
			"start/quit buttons same height: %.0f vs %.0f"
			% [button.rect_size.y, quit_btn.rect_size.y])
		_check(vol.get_global_rect().end.y < button.get_global_rect().position.y,
			"volume sits above the buttons")

	if frames == 8:
		var slider = scene.get_node("Content/Panel/Margin/VBox/VolumeBars/GridContainer/MasterSlider")
		var track = slider.get_stylebox("slider")
		_check(track is StyleBoxFlat and track.content_margin_top >= 5,
			"slider track thickness")
		var idx = AudioServer.get_bus_index("Master")
		var old = db2linear(AudioServer.get_bus_volume_db(idx))
		slider.value = 0.3
		_check(abs(db2linear(AudioServer.get_bus_volume_db(idx)) - 0.3) < 0.02, "master volume applies")
		slider.value = old

		if problems.empty():
			print("MENU CHECK OK")
		else:
			for p in problems:
				print("MENU CHECK FAIL: " + p)
		quit()
