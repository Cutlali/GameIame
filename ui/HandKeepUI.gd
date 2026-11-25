extends CanvasLayer

# v1.8 手牌保留制的"归还魔瓶"面板。
# 唯一的触发点：点击结束回合时手牌超过上限（5 张，成长后 6 张）。
# 勾选要留下的牌，未保留的交给魔瓶回收、退出本局牌库循环（牌库变薄）。
# 第四轮试玩后不再提供常驻的"整理手牌"按钮——整理只发生在回合边界。

var _root: Control
var _grid: GridContainer
var _title: Label
var _hint: Label
var _confirm_button: Button

var _slot_buttons = []
var _tags = []
var _cards = []
var _keep = {}
var _resume_end_turn = false



func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	layer = 112
	_build_panel()


func _build_panel():
	_root = Control.new()
	_root.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_root.visible = false
	add_child(_root)

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.66)
	dim.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_root.add_child(dim)

	var panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.margin_left = -470.0
	panel.margin_top = -260.0
	panel.margin_right = 470.0
	panel.margin_bottom = 260.0
	panel.add_stylebox_override("panel", _flat_box(
		Color(0.09, 0.10, 0.12, 0.97), Color(0.62, 0.72, 0.55, 0.85), 2, 16))
	_root.add_child(panel)

	var margin = MarginContainer.new()
	margin.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	margin.add_constant_override("margin_left", 26)
	margin.add_constant_override("margin_right", 26)
	margin.add_constant_override("margin_top", 18)
	margin.add_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_constant_override("separation", 10)
	margin.add_child(vbox)

	_title = _make_label("整理手牌", 26, Color(0.95, 0.97, 0.90))
	_title.align = Label.ALIGN_CENTER
	vbox.add_child(_title)

	_hint = _make_label("", 15, Color(0.78, 0.82, 0.76))
	_hint.align = Label.ALIGN_CENTER
	vbox.add_child(_hint)

	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.add_constant_override("hseparation", 12)
	_grid.add_constant_override("vseparation", 12)
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_grid)

	var buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGN_CENTER
	vbox.add_child(buttons)

	_confirm_button = _make_flat_button("交给魔瓶", Vector2(260, 44))
	_confirm_button.connect("pressed", self, "_on_confirm_pressed")
	buttons.add_child(_confirm_button)



# 结束回合被截停时打开；确认后继续结算。
func open_panel():
	if _root.visible:
		return
	if GS.hand == null or not is_instance_valid(GS.hand):
		return
	_resume_end_turn = true
	GS.hand_keep_open = true
	_rebuild()
	_root.visible = true


func _rebuild():
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	_slot_buttons.clear()
	_tags.clear()
	_cards.clear()
	_keep = {}

	for node in GS.hand.get_children():
		if node.get("associated_card") == null:
			continue
		var idx = _cards.size()
		_cards.append(node)
		_keep[idx] = true

	# 超上限时默认弃掉最右边的牌（发牌顺序 = 新入手的多在后面）。
	var cap = GS.hand_cap()
	if _cards.size() > cap:
		for i in range(_cards.size() - 1, _cards.size() - 1 - (_cards.size() - cap), -1):
			_keep[i] = false

	for i in range(_cards.size()):
		var card = _cards[i].associated_card
		var slot = _create_slot(card, i, _keep[i])
		_grid.add_child(slot)
		_slot_buttons.append(slot)

	_title.text = "手牌超出上限 · 交给魔瓶" 
	_update_confirm()


func _create_slot(card, idx, keep_it):
	var b = Button.new()
	b.toggle_mode = true
	b.rect_min_size = Vector2(150, 200)
	b.add_stylebox_override("normal", _flat_box(Color(0.15, 0.16, 0.18), Color(0.35, 0.38, 0.35), 1, 10))
	b.add_stylebox_override("hover", _flat_box(Color(0.21, 0.23, 0.25), Color(0.58, 0.66, 0.55), 1, 10))
	b.add_stylebox_override("pressed", _flat_box(Color(0.15, 0.28, 0.17), Color(0.55, 0.92, 0.55), 3, 10))
	b.add_stylebox_override("focus", StyleBoxEmpty.new())
	b.connect("toggled", self, "_on_slot_toggled", [idx])

	var margin = MarginContainer.new()
	margin.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_constant_override("margin_left", 8)
	margin.add_constant_override("margin_right", 8)
	margin.add_constant_override("margin_top", 8)
	margin.add_constant_override("margin_bottom", 8)
	b.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_constant_override("separation", 4)
	margin.add_child(vbox)

	var icon = TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.rect_min_size = Vector2(0, 52)
	icon.expand = true
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = card.icon
	vbox.add_child(icon)

	var title = _make_label(card.title, 17, Color(0.97, 0.97, 0.92))
	title.align = Label.ALIGN_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

	var cost = _make_label("能量 %d" % card.cost, 13, Color(0.75, 0.82, 0.74))
	cost.align = Label.ALIGN_CENTER
	cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(cost)

	var tag = _make_label("保留", 13, Color(0.55, 0.90, 0.60))
	tag.align = Label.ALIGN_CENTER
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.name = "TagLabel"
	vbox.add_child(tag)
	# 直接存引用：find_node 默认要 owner 匹配，运行时拼的节点取不到。
	_tags.append(tag)

	if keep_it:
		# 先屏蔽信号再设初值，避免 rebuild 时误触发 _on_slot_toggled。
		b.set_block_signals(true)
		b.pressed = true
		b.set_block_signals(false)
	else:
		tag.text = "回收"
		tag.add_color_override("font_color", Color(0.95, 0.55, 0.45))

	return b


func _on_slot_toggled(pressed, idx):
	_keep[idx] = pressed
	var tag = _tags[idx]
	tag.text = "保留" if pressed else "回收"
	tag.add_color_override("font_color",
		Color(0.55, 0.90, 0.60) if pressed else Color(0.95, 0.55, 0.45))
	_update_confirm()


func _kept_count():
	var n = 0
	for k in _keep.keys():
		if _keep[k]:
			n += 1
	return n


func _update_confirm():
	var cap = GS.hand_cap()
	var n = _kept_count()
	var drop = _cards.size() - n
	_confirm_button.disabled = n > cap
	_confirm_button.text = "归还魔瓶（收走 %d 张）" % drop
	_hint.text = "一回合最多留 %d 张。勾的要留下，没勾的扔给魔瓶、退出牌库。" % cap


func _on_confirm_pressed():
	if _kept_count() > GS.hand_cap():
		return
	for i in range(_cards.size()):
		var hc = _cards[i]
		if not _keep[i] and is_instance_valid(hc):
			hc.destroy()
	# _close() 会清掉 _resume_end_turn，先取副本再关。
	var resume = _resume_end_turn
	_close()
	if resume:
		GS._finish_end_turn()


func _close():
	GS.hand_keep_open = false
	_resume_end_turn = false
	_root.visible = false


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
	var b = _make_plain_button(text, min_size)
	b.connect("mouse_entered", SFX.button_hover, "play_sfx")
	b.connect("pressed", SFX.button_click, "play_sfx")
	return b


func _make_plain_button(text, min_size):
	var b = Button.new()
	b.text = text
	b.rect_min_size = min_size
	var font = DynamicFont.new()
	font.font_data = load("res://fonts/SimHei.ttf")
	font.size = 19
	b.add_font_override("font", font)
	b.add_color_override("font_color", Color(0.96, 0.97, 0.93))
	b.focus_mode = Control.FOCUS_NONE
	b.add_stylebox_override("normal", _flat_box(Color(0.17, 0.19, 0.21), Color(0.45, 0.50, 0.44), 1, 8))
	b.add_stylebox_override("hover", _flat_box(Color(0.23, 0.26, 0.28), Color(0.65, 0.78, 0.60), 1, 8))
	b.add_stylebox_override("pressed", _flat_box(Color(0.16, 0.26, 0.18), Color(0.60, 0.90, 0.58), 2, 8))
	b.add_stylebox_override("disabled", _flat_box(Color(0.12, 0.13, 0.14), Color(0.28, 0.30, 0.28), 1, 8))
	b.add_stylebox_override("focus", StyleBoxEmpty.new())
	return b
