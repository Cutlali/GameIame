extends Control

# 主菜单。存档存在时多出一行"继续农场"；
# "开始游戏"此时视为推倒重来，先弹确认再清档。

var _confirm: Control = null


func _ready():
	Music.set_mode("menu")
	$Content/Panel/Margin/VBox/StartButton.grab_focus()
	if OS.has_feature("HTML5"):
		$Content/Panel/Margin/VBox/QuitButton.hide()
	_refresh_save_ui()


func _refresh_save_ui():
	var can_continue = SaveGame.enabled and SaveGame.has_save
	$Content/Panel/Margin/VBox/ContinueButton.visible = can_continue
	$Content/Panel/Margin/VBox/SaveInfo.visible = can_continue
	if can_continue:
		$Content/Panel/Margin/VBox/SaveInfo.text = SaveGame.summary_text()


func _on_StartButton_pressed():
	if SaveGame.enabled and SaveGame.has_save:
		_show_confirm()
		return
	_begin_new()


func _begin_new():
	SaveGame.start_new()
	GS.reset_all_state()
	SceneTransitions.change_scene_to(GS.Intro)


func _on_ContinueButton_pressed():
	SaveGame.apply_meta()
	SceneTransitions.change_scene_to(GS.Game)


func _on_QuitButton_pressed():
	# 退出进程前的最后一道兜底快照（关窗/杀进程够不到，这里能救多少算多少）。
	SaveGame.save_now()
	get_tree().quit()


# ---- 清档确认 ----

func _show_confirm():
	if _confirm != null and is_instance_valid(_confirm):
		_confirm.visible = true
		return
	_confirm = Control.new()
	_confirm.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	add_child(_confirm)

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.66)
	dim.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm.add_child(dim)

	var panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.margin_left = -300.0
	panel.margin_top = -150.0
	panel.margin_right = 300.0
	panel.margin_bottom = 150.0
	_confirm.add_child(panel)

	var margin = MarginContainer.new()
	margin.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	margin.add_constant_override("margin_left", 30)
	margin.add_constant_override("margin_right", 30)
	margin.add_constant_override("margin_top", 24)
	margin.add_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_constant_override("separation", 14)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "要开始全新的四季吗？"
	title.align = Label.ALIGN_CENTER
	_style_label(title, 26, Color(0.97, 0.94, 0.86))
	vbox.add_child(title)

	var body = Label.new()
	body.text = "当前存档里的图鉴、农田与解锁都会被清空。\n想保留进度请点击\"继续农场\"。"
	body.align = Label.ALIGN_CENTER
	body.autowrap = true
	_style_label(body, 17, Color(0.86, 0.86, 0.82))
	vbox.add_child(body)

	var buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGN_CENTER
	buttons.add_constant_override("separation", 24)
	vbox.add_child(buttons)

	var no = _make_button("取消", Vector2(180, 52))
	no.connect("pressed", self, "_hide_confirm")
	buttons.add_child(no)

	var yes = _make_button("清空并开始", Vector2(220, 52))
	yes.connect("pressed", self, "_on_confirm_yes")
	buttons.add_child(yes)


func _hide_confirm():
	if _confirm != null and is_instance_valid(_confirm):
		_confirm.visible = false


func _on_confirm_yes():
	_hide_confirm()
	_begin_new()


func _style_label(label: Label, size: int, color: Color):
	var font = DynamicFont.new()
	font.font_data = load("res://fonts/SimHei.ttf")
	font.size = size
	label.add_font_override("font", font)
	label.add_color_override("font_color", color)


func _make_button(text: String, min_size: Vector2) -> Button:
	var b = Button.new()
	b.text = text
	b.rect_min_size = min_size
	var font = DynamicFont.new()
	font.font_data = load("res://fonts/SimHei.ttf")
	font.size = 20
	b.add_font_override("font", font)
	b.add_color_override("font_color", Color(0.96, 0.97, 0.93))
	b.add_color_override("font_color_hover", Color(1, 1, 1))
	b.add_stylebox_override("focus", StyleBoxEmpty.new())
	b.connect("pressed", SFX.button_click, "play_sfx")
	return b
