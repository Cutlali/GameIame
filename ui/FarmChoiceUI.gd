extends CanvasLayer

# 图鉴里程碑后的开垦选择。打开时暂停游戏，必须选一块地才能继续。
# 每开垦一块：农田 +2x2，每轮抽牌 +1，能量上限 +1。

const PANEL_W = 720
const PANEL_H = 480

var _root: Control
var _status: Label
var _confirm: Button
var _buttons = []
var _selected = -1


func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	layer = 122
	_buttons.resize(4)
	_build_ui()


func _process(_delta):
	if _root == null or _root.visible:
		return
	if GS.pending_farm_choices <= 0:
		return
	if GS.tilemap == null or not is_instance_valid(GS.tilemap):
		return
	if get_tree().paused:
		return
	if GS.bottle_open or GS.harvest_open or GS.bestiary_open \
			or GS.year_summary_open or GS.shop_open or GS.shatter_open:
		return
	open()


func _build_ui():
	_root = Control.new()
	_root.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_root.visible = false
	add_child(_root)

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_root.add_child(dim)

	var panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.margin_left = -PANEL_W * 0.5
	panel.margin_top = -PANEL_H * 0.5
	panel.margin_right = PANEL_W * 0.5
	panel.margin_bottom = PANEL_H * 0.5
	panel.add_stylebox_override("panel", _flat_box(
		Color(0.09, 0.10, 0.12, 0.98), Color(0.55, 0.70, 0.62, 0.9), 2, 16))
	_root.add_child(panel)

	var margin = MarginContainer.new()
	margin.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	margin.add_constant_override("margin_left", 28)
	margin.add_constant_override("margin_right", 28)
	margin.add_constant_override("margin_top", 22)
	margin.add_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_constant_override("separation", 10)
	margin.add_child(vbox)

	var title = _make_label("开垦新农田", 30, Color(0.94, 0.97, 0.90))
	vbox.add_child(title)

	var hint = _make_label(
		"选一块空地开垦。每开垦一块：农田 2×2，每轮抽牌 +1，能量上限 +1。",
		17, Color(0.80, 0.86, 0.78))
	vbox.add_child(hint)

	var map_box = VBoxContainer.new()
	map_box.add_constant_override("separation", 8)
	map_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(map_box)

	var row_n = HBoxContainer.new()
	row_n.alignment = BoxContainer.ALIGN_CENTER
	map_box.add_child(row_n)
	row_n.add_child(_make_parcel_button(2))

	var row_mid = HBoxContainer.new()
	row_mid.alignment = BoxContainer.ALIGN_CENTER
	row_mid.add_constant_override("separation", 14)
	map_box.add_child(row_mid)
	row_mid.add_child(_make_parcel_button(0))
	row_mid.add_child(_make_center_card())
	row_mid.add_child(_make_parcel_button(1))

	var row_s = HBoxContainer.new()
	row_s.alignment = BoxContainer.ALIGN_CENTER
	map_box.add_child(row_s)
	row_s.add_child(_make_parcel_button(3))

	_status = _make_label("", 16, Color(0.72, 0.80, 0.72))
	vbox.add_child(_status)

	var bottom = HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGN_END
	vbox.add_child(bottom)

	_confirm = _make_flat_button("开垦这里", Vector2(170, 46))
	_confirm.disabled = true
	_confirm.connect("pressed", self, "_on_confirm_pressed")
	bottom.add_child(_confirm)


func _make_parcel_button(index):
	var b = Button.new()
	b.rect_min_size = Vector2(190, 78)
	b.align = Button.ALIGN_CENTER
	var font = DynamicFont.new()
	font.font_data = load("res://fonts/SimHei.ttf")
	font.size = 18
	b.add_font_override("font", font)
	b.add_color_override("font_color", Color(0.94, 0.96, 0.90))
	b.add_color_override("font_color_hover", Color(1, 1, 1))
	b.add_color_override("font_color_pressed", Color(0.85, 1.0, 0.85))
	b.add_color_override("font_color_disabled", Color(0.55, 0.58, 0.55))
	b.add_stylebox_override("focus", StyleBoxEmpty.new())
	b.connect("pressed", self, "_on_parcel_pressed", [index])
	_buttons[index] = b
	return b


func _make_center_card():
	var panel = Panel.new()
	panel.rect_min_size = Vector2(190, 78)
	panel.add_stylebox_override("panel", _flat_box(
		Color(0.16, 0.24, 0.18), Color(0.52, 0.80, 0.52), 2, 8))
	var label = _make_label("现有\n农田", 18, Color(0.88, 0.96, 0.86))
	label.align = Label.ALIGN_CENTER
	label.valign = Label.VALIGN_CENTER
	label.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	return panel


func open():
	if _root == null or _root.visible:
		return
	GS.pending_farm_choices -= 1
	if GS.pending_farm_choices < 0:
		GS.pending_farm_choices = 0
	GS.farm_choice_open = true
	_selected = -1
	_refresh()
	_root.visible = true
	get_tree().paused = true


func close():
	GS.farm_choice_open = false
	_root.visible = false
	_selected = -1
	get_tree().paused = false


func reset_all():
	GS.pending_farm_choices = 0
	GS.farm_choice_open = false
	_selected = -1
	if _root != null:
		_root.visible = false
	if get_tree().paused:
		get_tree().paused = false


func _on_parcel_pressed(index):
	var claimed = index in GS.tilemap.claimed_parcels
	if claimed:
		return
	_selected = index
	_refresh()


func _on_confirm_pressed():
	if _selected < 0:
		return
	if not GS.tilemap.claim_parcel(_selected):
		return
	close()


func _refresh():
	if _status == null or GS.tilemap == null:
		return

	for i in range(_buttons.size()):
		var b = _buttons[i]
		var claimed = i in GS.tilemap.claimed_parcels
		var parcel_name = GS.tilemap.PARCELS[i]["name"]
		b.text = parcel_name + (" · 已开垦" if claimed else " · 2×2")
		b.disabled = claimed
		_apply_button_style(b, claimed, i == _selected)

	var draw_total = GS.card_draw_count + GS.bonus_draws
	var energy_after = min(GS.energy_max + 1, GS.ENERGY_CAP)
	if energy_after > GS.energy_max:
		_status.text = "开垦后：每轮抽牌 +1（当前 %d 张），能量上限 %d → %d" % [
			draw_total, GS.energy_max, energy_after]
	else:
		_status.text = "开垦后：每轮抽牌 +1（当前 %d 张），能量已达上限 %d" % [
			draw_total, GS.energy_max]
	_confirm.disabled = _selected < 0


func _apply_button_style(b, claimed, selected):
	if claimed:
		b.add_stylebox_override("normal", _flat_box(
			Color(0.13, 0.14, 0.14), Color(0.28, 0.30, 0.29), 1, 8))
		b.add_stylebox_override("hover", _flat_box(
			Color(0.13, 0.14, 0.14), Color(0.28, 0.30, 0.29), 1, 8))
		b.add_stylebox_override("pressed", _flat_box(
			Color(0.13, 0.14, 0.14), Color(0.28, 0.30, 0.29), 1, 8))
		b.add_stylebox_override("disabled", _flat_box(
			Color(0.13, 0.14, 0.14), Color(0.28, 0.30, 0.29), 1, 8))
	elif selected:
		b.add_stylebox_override("normal", _flat_box(
			Color(0.22, 0.34, 0.23), Color(0.70, 1.0, 0.70), 3, 8))
		b.add_stylebox_override("hover", _flat_box(
			Color(0.25, 0.38, 0.26), Color(0.75, 1.0, 0.75), 3, 8))
		b.add_stylebox_override("pressed", _flat_box(
			Color(0.20, 0.31, 0.21), Color(0.70, 1.0, 0.70), 3, 8))
	else:
		b.add_stylebox_override("normal", _flat_box(
			Color(0.16, 0.19, 0.17), Color(0.45, 0.52, 0.45), 1, 8))
		b.add_stylebox_override("hover", _flat_box(
			Color(0.21, 0.25, 0.22), Color(0.62, 0.78, 0.60), 1, 8))
		b.add_stylebox_override("pressed", _flat_box(
			Color(0.17, 0.26, 0.18), Color(0.60, 0.90, 0.58), 2, 8))


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
	b.add_color_override("font_color_disabled", Color(0.50, 0.53, 0.50))
	b.add_stylebox_override("normal", _flat_box(
		Color(0.17, 0.19, 0.21), Color(0.45, 0.50, 0.44), 1, 8))
	b.add_stylebox_override("hover", _flat_box(
		Color(0.23, 0.26, 0.28), Color(0.65, 0.78, 0.60), 1, 8))
	b.add_stylebox_override("pressed", _flat_box(
		Color(0.16, 0.26, 0.18), Color(0.60, 0.90, 0.58), 2, 8))
	b.add_stylebox_override("disabled", _flat_box(
		Color(0.13, 0.14, 0.15), Color(0.30, 0.32, 0.30), 1, 8))
	b.add_stylebox_override("focus", StyleBoxEmpty.new())
	return b