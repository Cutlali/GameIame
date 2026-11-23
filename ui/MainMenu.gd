extends Control

func _ready():
	$Content/Panel/Margin/VBox/StartButton.grab_focus()
	_style_guide_icon()


func _style_guide_icon():
	var b = $Content/GuideIcon
	b.add_stylebox_override("normal", _icon_box(Color(0.86, 0.74, 0.53), Color(0.40, 0.25, 0.14), 1))
	b.add_stylebox_override("hover", _icon_box(Color(0.93, 0.83, 0.63), Color(0.55, 0.36, 0.20), 2))
	b.add_stylebox_override("pressed", _icon_box(Color(0.80, 0.66, 0.46), Color(0.35, 0.21, 0.12), 2))
	b.add_stylebox_override("focus", StyleBoxEmpty.new())


func _icon_box(bg, border, width):
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = width
	sb.border_width_right = width
	sb.border_width_top = width
	sb.border_width_bottom = width
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.content_margin_left = 7
	sb.content_margin_right = 7
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	return sb


func _on_StartButton_pressed():
	GS.reset_all_state()
	SceneTransitions.change_scene_to(GS.Intro)


func _on_GuideIcon_pressed():
	$GuideBook.open()
