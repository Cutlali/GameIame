extends CanvasLayer

# 魔瓶：收获植物后自动触发一次高级抽卡。
# 池子由植物决定（番茄→基础池，向日葵→中级池，南瓜→高级池，月见草→稀有池）。
# 季节决定候选数与可选数：
#   春/夏：4 选 1
#   秋：  4 选 2
#   冬：  5 选 1，可刷新一次
# 没有手动入口：只要还有蓄能，就会自动弹出下一次抽取。

const POOL_NAMES = {
	"basic": "基础",
	"medium": "中级",
	"high": "高级",
	"rare": "稀有"
}

var charges = []

var _root: Control
var _panel: Panel
var _title: Label
var _grid: HBoxContainer
var _refresh_button: Button
var _confirm_button: Button

var _slot_buttons = []
var _selected = {}
var _offer_ids = []
var _required = 1
var _current_pool = ""
var _refresh_left = 0

# 一次收获可能积攒多次抽取，这里把它们合并成同一个界面连续结算。
var _batch_total = 0
var _batch_done = 0
var _batch_gained = 0

# 魔瓶维持着这个世界的四季，最多 3 滴血。
# 植物被虫害杀死时扣 1 滴，归零后进入瓶碎结算。
const MAX_HP = 3
var hp = MAX_HP

signal hp_changed(current, max_hp)

var _shatter_pending = false
var _shatter_open = false
var _damage_flash: ColorRect
var _flash_tween: Tween
var _shatter_root: Control
var _shatter_body: Label


func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	layer = 116
	_build_ui()


func _build_ui():
	# 受伤红屏放在所有界面之下，避免盖住弹窗文字。
	_damage_flash = ColorRect.new()
	_damage_flash.color = Color(0.72, 0.08, 0.08, 0.0)
	_damage_flash.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_damage_flash)

	_root = Control.new()
	_root.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_root.visible = false
	add_child(_root)

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.68)
	dim.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_root.add_child(dim)

	_panel = Panel.new()
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.margin_left = -500.0
	_panel.margin_top = -280.0
	_panel.margin_right = 500.0
	_panel.margin_bottom = 280.0
	_panel.add_stylebox_override("panel", _flat_box(Color(0.09, 0.10, 0.12, 0.97), Color(0.62, 0.72, 0.55, 0.85), 2, 16))
	_root.add_child(_panel)

	var margin = MarginContainer.new()
	margin.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	margin.add_constant_override("margin_left", 26)
	margin.add_constant_override("margin_right", 26)
	margin.add_constant_override("margin_top", 20)
	margin.add_constant_override("margin_bottom", 20)
	_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_constant_override("separation", 10)
	margin.add_child(vbox)

	_title = _make_label("魔瓶", 34, Color(0.95, 0.97, 0.90))
	_title.align = Label.ALIGN_CENTER
	vbox.add_child(_title)

	_grid = HBoxContainer.new()
	_grid.alignment = BoxContainer.ALIGN_CENTER
	_grid.add_constant_override("separation", 14)
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_grid)

	var buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGN_CENTER
	buttons.add_constant_override("separation", 18)
	vbox.add_child(buttons)

	_refresh_button = _make_flat_button("刷新候选", Vector2(170, 46))
	_refresh_button.connect("pressed", self, "_on_refresh_pressed")
	buttons.add_child(_refresh_button)

	_confirm_button = _make_flat_button("收下", Vector2(210, 46))
	_confirm_button.connect("pressed", self, "_on_confirm_pressed")
	buttons.add_child(_confirm_button)

	_build_shatter_ui()


func _build_shatter_ui():
	_shatter_root = Control.new()
	_shatter_root.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_shatter_root.visible = false
	add_child(_shatter_root)

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	dim.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_shatter_root.add_child(dim)

	var panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.margin_left = -330.0
	panel.margin_top = -210.0
	panel.margin_right = 330.0
	panel.margin_bottom = 210.0
	panel.add_stylebox_override("panel", _flat_box(Color(0.08, 0.08, 0.10, 0.98), Color(0.70, 0.32, 0.30, 0.9), 2, 16))
	_shatter_root.add_child(panel)

	var margin = MarginContainer.new()
	margin.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	margin.add_constant_override("margin_left", 34)
	margin.add_constant_override("margin_right", 34)
	margin.add_constant_override("margin_top", 28)
	margin.add_constant_override("margin_bottom", 26)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_constant_override("separation", 16)
	margin.add_child(vbox)

	var title = _make_label("魔瓶碎了", 40, Color(1.0, 0.78, 0.62))
	title.align = Label.ALIGN_CENTER
	vbox.add_child(title)

	_shatter_body = _make_label("", 18, Color(0.90, 0.90, 0.86))
	_shatter_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_shatter_body)

	var restart = _make_flat_button("带着图鉴重新开始", Vector2(300, 56))
	restart.connect("pressed", self, "_on_shatter_restart_pressed")
	vbox.add_child(restart)


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
	b.add_color_override("font_color_disabled", Color(0.45, 0.47, 0.45))
	b.add_stylebox_override("normal", _flat_box(Color(0.17, 0.19, 0.21), Color(0.45, 0.50, 0.44), 1, 8))
	b.add_stylebox_override("hover", _flat_box(Color(0.23, 0.26, 0.28), Color(0.65, 0.78, 0.60), 1, 8))
	b.add_stylebox_override("pressed", _flat_box(Color(0.16, 0.26, 0.18), Color(0.60, 0.90, 0.58), 2, 8))
	b.add_stylebox_override("disabled", _flat_box(Color(0.12, 0.13, 0.14), Color(0.28, 0.30, 0.28), 1, 8))
	b.add_stylebox_override("focus", StyleBoxEmpty.new())
	return b


func _process(_delta):
	# 瓶碎结算优先于一切抽取；等这一轮植物/虫子结算完再弹。
	if _shatter_open:
		return
	if _shatter_pending:
		_try_open_shatter()
		return

	# 没有手动入口：收获产生的蓄能会在合适的时机自动弹出。
	if _root == null or _root.visible:
		return
	if charges.empty():
		return
	if GS.tilemap == null or not is_instance_valid(GS.tilemap):
		return
	if get_tree().paused or GS.tutorial:
		return
	# 等植物和虫子结算完再统一弹一次，避免同一轮连续打断。
	if GS.current_turns != null:
		return
	if GS.harvest_open or GS.bestiary_open or GS.year_summary_open \
			or GS.farm_choice_open or GS.shop_open:
		return
	open_bottle()


func is_busy():
	return _shatter_pending or _shatter_open \
		or (_root != null and _root.visible) or not charges.empty()


func damage(amount = 1):
	if hp <= 0 or _shatter_pending or _shatter_open:
		return 0
	hp = max(0, hp - amount)
	emit_signal("hp_changed", hp, MAX_HP)
	_flash_damage()
	if hp <= 0:
		_shatter_pending = true
		Toast.show_message("魔瓶碎裂了！四季开始停滞……")
	else:
		Toast.show_message("魔瓶受损！剩余 %d 滴血。" % hp)
	return amount


func refill():
	hp = MAX_HP
	_shatter_pending = false
	emit_signal("hp_changed", hp, MAX_HP)


func _flash_damage():
	if _damage_flash == null:
		return
	if _flash_tween == null or not is_instance_valid(_flash_tween):
		_flash_tween = Tween.new()
		add_child(_flash_tween)
	else:
		_flash_tween.stop_all()
		_flash_tween.remove_all()
	_damage_flash.color = Color(0.72, 0.08, 0.08, 0.30)
	_flash_tween.interpolate_property(_damage_flash, "color",
		Color(0.72, 0.08, 0.08, 0.30), Color(0.72, 0.08, 0.08, 0.0),
		0.65, Tween.TRANS_QUAD, Tween.EASE_OUT)
	_flash_tween.start()


func _try_open_shatter():
	if GS.tilemap == null or not is_instance_valid(GS.tilemap):
		return
	if GS.tutorial or get_tree().paused:
		return
	if GS.current_turns != null:
		return
	if GS.harvest_open or GS.bestiary_open or GS.year_summary_open \
			or GS.farm_choice_open or GS.shop_open:
		return
	_show_shatter()


func _show_shatter():
	charges.clear()
	if has_node("/root/Toast"):
		Toast.clear()
	_shatter_pending = false
	_shatter_open = true
	GS.shatter_open = true
	GS.bottle_open = false
	GS.waiting_for_card_selection = false

	var year = Season.year
	var entries = Encyclopedia.discovered_count()
	var plots = 0
	if GS.tilemap != null and is_instance_valid(GS.tilemap):
		plots = GS.tilemap.claimed_parcels.size()

	var lines = PoolStringArray()
	lines.append("维持四季的魔瓶耗尽了最后一点力量。")
	lines.append("")
	lines.append("你走到了第 %d 年。" % year)
	lines.append("图鉴收录：%d 条（保留）" % entries)
	lines.append("额外开垦农田：%d 块（保留）" % plots)
	lines.append("")
	lines.append("农场会回到第一年的春天重新开始，图鉴与农田不会丢失。")
	_shatter_body.text = lines.join("\n")
	_shatter_root.visible = true


func _on_shatter_restart_pressed():
	if not _shatter_open:
		return
	_shatter_open = false
	_shatter_root.visible = false
	GS.shatter_open = false
	refill()
	GS.restart_after_shatter()


func add_charge(pool_id, silent = false):
	charges.append(pool_id)
	RunStats.bottle_uses += 1
	if not silent:
		Toast.show_message("魔瓶蓄能 +1（%s池），共 %d 次" % [pool_name(pool_id), charges.size()])


func pool_name(pool_id):
	return POOL_NAMES.get(pool_id, "未知")


func has_charges():
	return charges.size() > 0


func reset_all():
	charges.clear()
	_current_pool = ""
	_offer_ids = []
	_selected = {}
	_batch_total = 0
	_batch_done = 0
	_batch_gained = 0
	hp = MAX_HP
	_shatter_pending = false
	_shatter_open = false
	if _root != null:
		_root.visible = false
	if _shatter_root != null:
		_shatter_root.visible = false
	GS.waiting_for_card_selection = false
	GS.bottle_open = false
	GS.shatter_open = false


func open_bottle():
	if _root == null or _root.visible:
		return
	if _shatter_pending or _shatter_open:
		return
	if GS.harvest_open or GS.bestiary_open or GS.year_summary_open \
			or GS.farm_choice_open or GS.shop_open or GS.shatter_open:
		return
	if GS.tilemap == null or not is_instance_valid(GS.tilemap):
		return
	if charges.empty():
		return

	_batch_total = charges.size()
	_batch_done = 0
	_batch_gained = 0

	GS.waiting_for_card_selection = true
	GS.bottle_open = true
	_root.visible = true
	_start_next_pick()


func _start_next_pick():
	if charges.empty():
		return

	_current_pool = charges.pop_front()
	_batch_done += 1
	_required = Season.bottle_pick_count()
	_refresh_left = 1 if Season.bottle_can_refresh() else 0

	_roll_offer()
	_rebuild_grid()

	_refresh_button.visible = Season.bottle_can_refresh()
	_refresh_button.disabled = _refresh_left <= 0
	if _batch_total > 1:
		_title.text = "魔瓶 · %s池（%d/%d）" % [
			pool_name(_current_pool), _batch_done, _batch_total]
	else:
		_title.text = "魔瓶 · %s池" % pool_name(_current_pool)
	_update_confirm()


func _roll_offer():
	_offer_ids = GameData.roll_offer(_current_pool, Season.bottle_offer_count())
	_selected = {}


func _rebuild_grid():
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	_slot_buttons.clear()

	for i in range(_offer_ids.size()):
		var card = GS.card_by_id(_offer_ids[i])
		if card == null:
			continue
		var slot = _create_slot(card, i)
		_grid.add_child(slot)
		_slot_buttons.append(slot)


func _create_slot(card, idx):
	var b = Button.new()
	b.toggle_mode = true
	b.rect_min_size = Vector2(176, 320)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_stylebox_override("normal", _flat_box(Color(0.15, 0.16, 0.18), Color(0.35, 0.38, 0.35), 1, 10))
	b.add_stylebox_override("hover", _flat_box(Color(0.21, 0.23, 0.25), Color(0.58, 0.66, 0.55), 1, 10))
	b.add_stylebox_override("pressed", _flat_box(Color(0.15, 0.28, 0.17), Color(0.55, 0.92, 0.55), 3, 10))
	b.add_stylebox_override("focus", StyleBoxEmpty.new())
	b.connect("toggled", self, "_on_slot_toggled", [idx])

	var margin = MarginContainer.new()
	margin.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_constant_override("margin_left", 10)
	margin.add_constant_override("margin_right", 10)
	margin.add_constant_override("margin_top", 10)
	margin.add_constant_override("margin_bottom", 10)
	b.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_constant_override("separation", 5)
	margin.add_child(vbox)

	var icon = TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.rect_min_size = Vector2(0, 62)
	icon.expand = true
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = card.icon
	vbox.add_child(icon)

	var title = _make_label(card.title, 21, Color(0.97, 0.97, 0.92))
	title.align = Label.ALIGN_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

	var cost = _make_label("能量 %d" % card.cost, 16, Color(0.75, 0.82, 0.74))
	cost.align = Label.ALIGN_CENTER
	cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(cost)

	var desc = _make_label(card.desc.replace("$DQ", String(card.quantity)), 14, Color(0.80, 0.82, 0.80))
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc)

	return b


func _selected_count():
	var n = 0
	for k in _selected.keys():
		if _selected[k]:
			n += 1
	return n


func _on_slot_toggled(pressed, idx):
	_selected[idx] = pressed
	if pressed and _selected_count() > _required:
		for i in _selected.keys():
			if i == idx or not _selected[i]:
				continue
			_selected[i] = false
			if i < _slot_buttons.size():
				var b = _slot_buttons[i]
				b.set_block_signals(true)
				b.pressed = false
				b.set_block_signals(false)
			break
	_update_confirm()


func _update_confirm():
	if _confirm_button == null:
		return
	var count = _selected_count()
	_confirm_button.disabled = count != _required
	_confirm_button.text = "收下（%d/%d）" % [count, _required]


func _on_refresh_pressed():
	if _refresh_left <= 0 or not Season.bottle_can_refresh():
		return
	_refresh_left -= 1
	_refresh_button.disabled = _refresh_left <= 0
	_roll_offer()
	_rebuild_grid()
	_update_confirm()


func _on_confirm_pressed():
	if _selected_count() != _required:
		return

	for idx in _selected.keys():
		if not _selected[idx]:
			continue
		if idx < 0 or idx >= _offer_ids.size():
			continue
		var card = GS.card_by_id(_offer_ids[idx])
		if card == null:
			continue

		# 魔瓶的牌全部直接进手牌，不占用弃牌堆。
		if GS.hand != null and is_instance_valid(GS.hand):
			GS.add_card_to_hand(card)
		else:
			GS.discard_pile.push_back(card)
		_batch_gained += 1

	if not charges.empty():
		# 同一批收获还有下一次抽取，直接刷新界面，不关闭窗口。
		_start_next_pick()
		return

	Toast.show_message("魔瓶：本次收获共 %d 张卡牌加入手牌" % _batch_gained)
	close()


func close(refund = false):
	if refund and _current_pool != "":
		charges.push_front(_current_pool)
	_current_pool = ""
	_offer_ids = []
	_selected = {}
	GS.waiting_for_card_selection = false
	GS.bottle_open = false
	if _root != null:
		_root.visible = false


func force_close():
	close(true)