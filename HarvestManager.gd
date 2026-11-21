extends CanvasLayer

# 收获处理：
# - 图鉴里还没有这个条目 → 让玩家二选一：收录样本 / 交给魔瓶
# - 已经收录过 → 自动触发魔瓶抽卡，不再打断节奏
# 变种是独立条目，同样遵循这条规则，因此不会出现“先选了魔瓶就永远错过”的情况。

var _root: Control
var _title: Label
var _body: Label
var _sample_button: Button
var _bottle_button: Button
var _photo_plate: Panel
var _photo: TextureRect
var _photo_caption: Label

var _pending_entry = null
var _pending_pool = ""


func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	layer = 118
	_build_ui()


func _build_ui():
	_root = Control.new()
	_root.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_root.visible = false
	add_child(_root)

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_root.add_child(dim)

	var panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.margin_left = -440.0
	panel.margin_top = -250.0
	panel.margin_right = 440.0
	panel.margin_bottom = 250.0
	panel.add_stylebox_override("panel", _flat_box(Color(0.09, 0.10, 0.12, 0.97), Color(0.72, 0.68, 0.46, 0.9), 2, 16))
	_root.add_child(panel)

	var margin = MarginContainer.new()
	margin.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	margin.add_constant_override("margin_left", 28)
	margin.add_constant_override("margin_right", 28)
	margin.add_constant_override("margin_top", 22)
	margin.add_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_constant_override("separation", 12)
	margin.add_child(vbox)

	_title = _make_label("", 30, Color(0.98, 0.94, 0.74))
	_title.align = Label.ALIGN_CENTER
	vbox.add_child(_title)

	var content = HBoxContainer.new()
	content.add_constant_override("separation", 24)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(content)

	# 第一次收获时展示成熟期图片，让“我种出来的是什么”有一个直观反馈。
	var photo_col = VBoxContainer.new()
	photo_col.add_constant_override("separation", 8)
	photo_col.rect_min_size = Vector2(236, 0)
	content.add_child(photo_col)

	_photo_plate = Panel.new()
	_photo_plate.rect_min_size = Vector2(236, 236)
	_photo_plate.add_stylebox_override("panel", _flat_box(Color(0.055, 0.065, 0.075, 0.95), Color(0.72, 0.68, 0.46, 0.9), 2, 12))
	photo_col.add_child(_photo_plate)

	var photo_margin = MarginContainer.new()
	photo_margin.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	photo_margin.add_constant_override("margin_left", 10)
	photo_margin.add_constant_override("margin_right", 10)
	photo_margin.add_constant_override("margin_top", 10)
	photo_margin.add_constant_override("margin_bottom", 10)
	_photo_plate.add_child(photo_margin)

	_photo = TextureRect.new()
	_photo.expand = true
	_photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	photo_margin.add_child(_photo)

	_photo_caption = _make_label("", 16, Color(0.82, 0.84, 0.78))
	_photo_caption.align = Label.ALIGN_CENTER
	photo_col.add_child(_photo_caption)

	var text_col = VBoxContainer.new()
	text_col.add_constant_override("separation", 12)
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(text_col)

	_body = _make_label("", 17, Color(0.86, 0.87, 0.84))
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_col.add_child(_body)

	var buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGN_CENTER
	buttons.add_constant_override("separation", 22)
	text_col.add_child(buttons)

	_sample_button = _make_flat_button("收录到图鉴", Vector2(220, 52))
	_sample_button.connect("pressed", self, "_on_sample_pressed")
	buttons.add_child(_sample_button)

	_bottle_button = _make_flat_button("交给魔瓶", Vector2(300, 52))
	_bottle_button.connect("pressed", self, "_on_bottle_pressed")
	buttons.add_child(_bottle_button)


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
	b.add_stylebox_override("normal", _flat_box(Color(0.17, 0.19, 0.21), Color(0.45, 0.50, 0.44), 1, 8))
	b.add_stylebox_override("hover", _flat_box(Color(0.23, 0.26, 0.28), Color(0.65, 0.78, 0.60), 1, 8))
	b.add_stylebox_override("pressed", _flat_box(Color(0.16, 0.26, 0.18), Color(0.60, 0.90, 0.58), 2, 8))
	b.add_stylebox_override("focus", StyleBoxEmpty.new())
	return b


func _show_photo(entry):
	if _photo == null:
		return

	_photo.texture = GameData.photo_for(entry["species_id"])
	_photo.modulate = Color.white

	var gold = Color(0.72, 0.68, 0.46, 0.9)
	var border = gold
	if entry["is_variant"]:
		var c = GameData.variant_color(entry["species_id"], entry["variant_index"])
		border = Color(c.r, c.g, c.b, 0.95)
		# 只做很轻的染色，保留图片本身的辨识度，同时让变种有一点颜色倾向。
		_photo.modulate = Color(1, 1, 1).linear_interpolate(Color(c.r, c.g, c.b), 0.18)

	_photo_plate.add_stylebox_override("panel",
		_flat_box(Color(0.055, 0.065, 0.075, 0.95), border, 2, 12))
	_photo_caption.text = "%s季 · %s" % [entry["season_name"], entry["family"]]
	_photo_caption.add_color_override("font_color", border)


func handle_harvest(plant):
	if plant == null or _root == null or _root.visible:
		return

	var entry_id = plant.resolve_entry_id()
	var entry = GameData.entry(entry_id)

	RunStats.harvests += 1

	if entry == null:
		BottleManager.add_charge("basic", true)
		Toast.show_message("收获了一株植物，魔瓶开始自动抽取（基础池）。")
		return

	if entry["is_variant"]:
		RunStats.variants_found += 1

	var species = GameData.species(entry["species_id"])
	var pool = "basic"
	if species != null:
		pool = species["pool"]

	# 已收录：直接自动抽卡，不再需要玩家手动开魔瓶
	if Encyclopedia.is_discovered(entry_id):
		BottleManager.add_charge(pool, true)
		Toast.show_message("已收录「%s」，魔瓶自动抽取（%s池）。" % [
			entry["name"], BottleManager.pool_name(pool)])
		return

	_pending_entry = entry
	_pending_pool = pool

	_show_photo(entry)

	_title.text = "收获：" + entry["name"]
	if entry["is_variant"]:
		_title.text = "✦ 发现变异：" + entry["name"]

	var lines = PoolStringArray()
	lines.append("%s（%s）" % [entry["name"], entry["scientific"]])
	lines.append("%s · 原产%s" % [entry["family"], entry["origin"]])
	if entry["is_variant"] and entry["variant_desc"] != "":
		lines.append(entry["variant_desc"])
	lines.append("")
	lines.append(entry["lore"])
	lines.append("")
	lines.append("这个条目还没有收录进图鉴。你可以保留样本，也可以把它交给魔瓶换取高级抽卡。")
	_body.text = lines.join("\n")

	_bottle_button.text = "交给魔瓶（+1 次%s抽卡）" % BottleManager.pool_name(pool)

	GS.waiting_for_card_selection = true
	GS.harvest_open = true
	_root.visible = true


func _on_sample_pressed():
	if _pending_entry == null:
		return
	var entry_id = _pending_entry["id"]
	if Encyclopedia.discover(entry_id):
		Toast.show_message("图鉴新增：%s" % _pending_entry["name"])
	close()


func _on_bottle_pressed():
	if _pending_entry == null:
		return
	BottleManager.add_charge(_pending_pool, true)
	Toast.show_message("「%s」已交给魔瓶，开始自动抽取。" % _pending_entry["name"])
	close()


func close():
	_pending_entry = null
	_pending_pool = ""
	GS.waiting_for_card_selection = false
	GS.harvest_open = false
	if _root != null:
		_root.visible = false


func reset_all():
	close()


func force_close():
	close()