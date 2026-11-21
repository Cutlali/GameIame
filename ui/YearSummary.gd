extends CanvasLayer

# 年终总结 / 中途退出总结。

var _root: Control
var _title: Label
var _body: Label
var _progress: Label
var _button: Button
var _final = false


func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	layer = 121
	_build_ui()


func _build_ui():
	_root = Control.new()
	_root.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_root.visible = false
	add_child(_root)

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.74)
	dim.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_root.add_child(dim)

	var panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.margin_left = -390.0
	panel.margin_top = -285.0
	panel.margin_right = 390.0
	panel.margin_bottom = 285.0
	panel.add_stylebox_override("panel", _flat_box(Color(0.09, 0.10, 0.12, 0.98), Color(0.78, 0.70, 0.45, 0.9), 2, 16))
	_root.add_child(panel)

	var margin = MarginContainer.new()
	margin.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	margin.add_constant_override("margin_left", 34)
	margin.add_constant_override("margin_right", 34)
	margin.add_constant_override("margin_top", 26)
	margin.add_constant_override("margin_bottom", 26)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_constant_override("separation", 12)
	margin.add_child(vbox)

	_title = _make_label("", 32, Color(0.98, 0.93, 0.70))
	_title.align = Label.ALIGN_CENTER
	vbox.add_child(_title)

	var divider = ColorRect.new()
	divider.color = Color(0.72, 0.66, 0.44, 0.55)
	divider.rect_min_size = Vector2(0, 2)
	vbox.add_child(divider)

	_body = _make_label("", 19, Color(0.88, 0.89, 0.85))
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_body)

	_progress = _make_label("", 17, Color(0.76, 0.84, 0.74))
	_progress.align = Label.ALIGN_CENTER
	vbox.add_child(_progress)

	_button = _make_flat_button("继续", Vector2(240, 50))
	_button.anchor_left = 0.5
	_button.anchor_right = 0.5
	_button.margin_left = -120
	_button.margin_right = 120
	_button.connect("pressed", self, "_on_button_pressed")
	vbox.add_child(_button)


func _flat_box(bg, border, width, radius):
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = width
	sb.border_width_right = width
	sb.border_width_top = width
	sb.border_width_bottom = width
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	return sb


func _make_label(text, size, color):
	var label = Label.new()
	label.text = text
	label.autowrap = true
	var font = DynamicFont.new()
	font.font_data = load("res://fonts/SimHei.ttf")
	font.size = size
	label.add_font_override("font", font)
	label.add_color_override("font_color", color)
	return label


func _make_flat_button(text, min_size):
	var b = Button.new()
	b.text = text
	b.rect_min_size = min_size
	var font = DynamicFont.new()
	font.font_data = load("res://fonts/SimHei.ttf")
	font.size = 20
	b.add_font_override("font", font)
	b.add_color_override("font_color", Color(0.96, 0.97, 0.93))
	b.add_color_override("font_color_hover", Color(1, 1, 1))
	b.add_color_override("font_color_pressed", Color(0.85, 1.0, 0.85))
	b.add_stylebox_override("normal", _flat_box(Color(0.17, 0.19, 0.21), Color(0.52, 0.56, 0.45), 1, 8))
	b.add_stylebox_override("hover", _flat_box(Color(0.23, 0.26, 0.28), Color(0.72, 0.80, 0.58), 1, 8))
	b.add_stylebox_override("pressed", _flat_box(Color(0.16, 0.26, 0.18), Color(0.60, 0.90, 0.58), 2, 8))
	b.add_stylebox_override("focus", StyleBoxEmpty.new())
	return b


func show_summary(year_number, final, lines = null, discovered = -1, total = -1):
	if _root == null:
		return

	BottleManager.force_close()
	HarvestManager.force_close()
	EncyclopediaUI.close()

	if lines == null:
		lines = RunStats.summary_lines()
	if discovered < 0:
		discovered = Encyclopedia.discovered_count()
	if total < 0:
		total = Encyclopedia.total_entries()

	_final = final
	_title.text = "第 %d 年 · %s" % [year_number, "中途总结" if final else "年终总结"]
	_body.text = PoolStringArray(lines).join("\n")

	var progress = "图鉴进度：%d / %d 条" % [discovered, total]
	progress += "\n" + Encyclopedia.next_milestone_text()
	_progress.text = progress

	if final:
		_button.text = "返回主菜单"
	else:
		_button.text = "继续下一年"

	GS.year_summary_open = true
	_root.visible = true
	# 年终是一个阶段性的高光节点，给一段成就感的音效；中途退出总结不加。
	if not final:
		SFX.year_end.play_usual()
	# 总结期间冻结农场，避免虫子或植物在图后面继续变化。
	get_tree().paused = true


func _on_button_pressed():
	_root.visible = false
	GS.year_summary_open = false
	get_tree().paused = false
	if _final:
		SceneTransitions.change_scene_to(GS.MainMenu)


func reset_all():
	_final = false
	GS.year_summary_open = false
	if _root != null:
		_root.visible = false
	get_tree().paused = false