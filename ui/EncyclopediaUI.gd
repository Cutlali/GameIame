extends CanvasLayer

# 植物图鉴：4 种植物 × 3 个条目（基础 + 2 个变种），共 12 条。
# 收录基础物种会推进里程碑：能量上限、每回合抽卡数、农田扩建。

var _root: Control
var _title: Label
var _milestone: Label
var _grid: GridContainer
var _detail_image: TextureRect
var _detail_plate: Panel
var _detail: Label
var _selected_id = ""


func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	layer = 117
	_build_ui()
	Encyclopedia.connect("entry_discovered", self, "_on_entry_discovered")


func _build_ui():
	_root = Control.new()
	_root.theme = load("res://ui/MenuTheme.tres")
	_root.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_root.visible = false
	add_child(_root)

	var dim = ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.02, 0.78)
	dim.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_root.add_child(dim)

	var panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.margin_left = -550.0
	panel.margin_top = -340.0
	panel.margin_right = 550.0
	panel.margin_bottom = 340.0
	_root.add_child(panel)

	var margin = MarginContainer.new()
	margin.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	margin.add_constant_override("margin_left", 26)
	margin.add_constant_override("margin_right", 26)
	margin.add_constant_override("margin_top", 20)
	margin.add_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_constant_override("separation", 8)
	margin.add_child(vbox)

	var header = HBoxContainer.new()
	header.add_constant_override("separation", 18)
	vbox.add_child(header)

	_title = _make_label("植物图鉴", 32, Color(0.30, 0.19, 0.12))
	_title.autowrap = false
	header.add_child(_title)

	_milestone = _make_label("", 17, Color(0.47, 0.31, 0.19))
	_milestone.autowrap = false
	_milestone.align = Label.ALIGN_RIGHT
	_milestone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_milestone)

	vbox.add_child(HSeparator.new())

	var content = HBoxContainer.new()
	content.add_constant_override("separation", 16)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(content)

	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_constant_override("hseparation", 12)
	_grid.add_constant_override("vseparation", 12)
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_grid)

	var detail_panel = Panel.new()
	detail_panel.rect_min_size = Vector2(330, 0)
	detail_panel.add_stylebox_override("panel",
		_flat_box(Color(0.88, 0.78, 0.61, 0.55), Color(0.48, 0.33, 0.22, 0.45), 1, 10))
	content.add_child(detail_panel)

	var detail_margin = MarginContainer.new()
	detail_margin.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	detail_margin.add_constant_override("margin_left", 14)
	detail_margin.add_constant_override("margin_right", 14)
	detail_margin.add_constant_override("margin_top", 14)
	detail_margin.add_constant_override("margin_bottom", 14)
	detail_panel.add_child(detail_margin)

	var detail_box = VBoxContainer.new()
	detail_box.add_constant_override("separation", 8)
	detail_margin.add_child(detail_box)

	_detail_plate = Panel.new()
	_detail_plate.rect_min_size = Vector2(0, 190)
	_detail_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_plate.add_stylebox_override("panel", StyleBoxEmpty.new())
	detail_box.add_child(_detail_plate)

	_detail_image = TextureRect.new()
	_detail_image.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_detail_image.expand = true
	_detail_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_plate.add_child(_detail_image)

	_detail = _make_label("选择一个条目查看详情。", 15, Color(0.38, 0.25, 0.15))
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_box.add_child(_detail)

	var bottom = HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGN_END
	vbox.add_child(bottom)

	var close = _make_flat_button("关闭", Vector2(140, 44))
	close.connect("pressed", self, "_on_close_pressed")
	bottom.add_child(close)


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
	label.add_constant_override("line_spacing", 4)
	return label


func _make_flat_button(text, min_size):
	var b = Button.new()
	b.text = text
	b.rect_min_size = min_size
	var font = DynamicFont.new()
	font.font_data = load("res://fonts/SimHei.ttf")
	font.size = 20
	b.add_font_override("font", font)
	return b


func open():
	if _root == null or _root.visible:
		return
	if GS.bottle_open or GS.harvest_open or GS.year_summary_open \
			or GS.farm_choice_open or GS.shatter_open:
		return
	GS.bestiary_open = true
	_root.visible = true
	_rebuild()


func close():
	GS.bestiary_open = false
	if _root != null:
		_root.visible = false


func _on_close_pressed():
	close()


func _on_entry_discovered(_entry_id):
	if _root != null and _root.visible:
		_rebuild()
		if _selected_id != "":
			_show_detail(_selected_id)


func _rebuild():
	_title.text = "植物图鉴"
	_milestone.text = Encyclopedia.next_milestone_text()

	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()

	for entry_id in GameData.all_entry_ids():
		_grid.add_child(_create_entry_button(entry_id))

	if _selected_id == "":
		# 打开时自动展示第一条已收录的植物，避免详情栏空着。
		var show_id = ""
		for entry_id in GameData.all_entry_ids():
			if Encyclopedia.is_discovered(entry_id):
				show_id = entry_id
				break
		if show_id == "":
			show_id = GameData.all_entry_ids()[0]
		_show_detail(show_id)
	else:
		_show_detail(_selected_id)


func _create_entry_button(entry_id):
	var entry = GameData.entry(entry_id)
	var found = Encyclopedia.is_discovered(entry_id)

	var b = Button.new()
	b.rect_min_size = Vector2(160, 138)
	b.add_stylebox_override("focus", StyleBoxEmpty.new())
	if found:
		b.add_stylebox_override("normal", _flat_box(Color(0.87, 0.76, 0.56), Color(0.50, 0.34, 0.21), 1, 8))
		b.add_stylebox_override("hover", _flat_box(Color(0.93, 0.83, 0.63), Color(0.58, 0.39, 0.23), 2, 8))
		b.add_stylebox_override("pressed", _flat_box(Color(0.80, 0.66, 0.46), Color(0.40, 0.26, 0.16), 2, 8))
	else:
		b.add_stylebox_override("normal", _flat_box(Color(0.81, 0.71, 0.55, 0.68), Color(0.58, 0.45, 0.32, 0.55), 1, 8))
		b.add_stylebox_override("hover", _flat_box(Color(0.86, 0.76, 0.59, 0.82), Color(0.62, 0.48, 0.34, 0.75), 1, 8))
		b.add_stylebox_override("pressed", _flat_box(Color(0.76, 0.65, 0.49, 0.82), Color(0.50, 0.37, 0.25, 0.8), 2, 8))
	b.connect("pressed", self, "_on_entry_pressed", [entry_id])

	var margin = MarginContainer.new()
	margin.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_constant_override("margin_left", 8)
	margin.add_constant_override("margin_right", 8)
	margin.add_constant_override("margin_top", 10)
	margin.add_constant_override("margin_bottom", 10)
	b.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_constant_override("separation", 4)
	margin.add_child(vbox)

	var name_text = "？？？"
	var sub_text = "未收录"
	var name_color = Color(0.52, 0.43, 0.33)
	if found:
		name_text = entry["name"]
		name_color = Color(0.28, 0.18, 0.11)
		sub_text = "变异品种" if entry["is_variant"] else entry["season_name"] + "季作物"
	# 未收录条目不显示“由什么变来”，避免剧透。

	var photo = TextureRect.new()
	photo.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	photo.expand = true
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	photo.texture = GameData.photo_for(entry["species_id"])
	if found and entry["is_variant"]:
		photo.modulate = GameData.variant_color(entry["species_id"], entry["variant_index"])
	elif not found:
		# 未收录只显示纯黑剪影，不泄露原色
		photo.modulate = Color(0, 0, 0, 1)

	# 未收录时垫一层浅色底，让黑色剪影能看清
	var plate = Panel.new()
	plate.rect_min_size = Vector2(0, 68)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if found:
		plate.add_stylebox_override("panel", StyleBoxEmpty.new())
	else:
		plate.add_stylebox_override("panel", _flat_box(Color(0.93, 0.85, 0.70), Color(0.93, 0.85, 0.70), 0, 6))
	plate.add_child(photo)
	vbox.add_child(plate)

	var name_label = _make_label(name_text, 19, name_color)
	name_label.align = Label.ALIGN_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	var sub_label = _make_label(sub_text, 14,
		Color(0.47, 0.35, 0.24) if found else Color(0.55, 0.46, 0.36))
	sub_label.align = Label.ALIGN_CENTER
	sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sub_label)

	return b


func _on_entry_pressed(entry_id):
	_selected_id = entry_id
	_show_detail(entry_id)


func _show_detail(entry_id):
	var entry = GameData.entry(entry_id)
	if entry == null:
		return

	var found = Encyclopedia.is_discovered(entry_id)
	_detail_image.texture = GameData.photo_for(entry["species_id"])
	if found and entry["is_variant"]:
		_detail_image.modulate = GameData.variant_color(
			entry["species_id"], entry["variant_index"])
	elif found:
		_detail_image.modulate = Color(1, 1, 1)
	else:
		# 未收录只显示纯黑剪影
		_detail_image.modulate = Color(0, 0, 0, 1)

	# 未收录时垫浅色底，保证黑色剪影可辨认
	if found:
		_detail_plate.add_stylebox_override("panel", StyleBoxEmpty.new())
	else:
		_detail_plate.add_stylebox_override("panel", _flat_box(
			Color(0.93, 0.85, 0.70), Color(0.93, 0.85, 0.70), 0, 8))

	if not found:
		var lines = PoolStringArray()
		lines.append("？？？")
		lines.append("")
		lines.append("这个条目还没有收录。")
		if entry["is_variant"]:
			lines.append("成熟植物在收获时可能发生品种变异，具体会变成什么，要等发现后才知晓。")
		lines.append("")
		lines.append("在农场里把植物养到成熟，收获时选择“收录到图鉴”。")
		_detail.text = lines.join("\n")
		return

	var lines = PoolStringArray()
	lines.append(entry["name"])
	lines.append(entry["scientific"])
	lines.append("")
	lines.append("科属：" + entry["family"])
	lines.append("原产：" + entry["origin"])
	lines.append("季节：" + entry["season_name"] + "季")
	lines.append("生长：需要 %d 次生长" % entry["frames"])
	lines.append("生命：%d 点" % entry["health"])
	if entry["is_variant"]:
		lines.append("")
		lines.append("【变异品种】")
		lines.append(entry["variant_desc"])
		if entry["perk_text"] != "":
			lines.append("【变种特性】" + entry["perk_text"])
	lines.append("")
	lines.append("【植物知识】")
	lines.append(entry["lore"])
	_detail.text = lines.join("\n")