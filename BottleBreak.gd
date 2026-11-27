extends CanvasLayer

# 瓶碎过场：魔瓶摔碎 → 碎片发光 → 重新合好。
# 只在第一次瓶碎时播放：读完后翻到手记新页，合上后自动从第一年春天重开。
# 之后的碎瓶仍走原来的瓶碎结算面板。
# 结构与序章 / 终章一致：点击翻页，右上角可跳过。

const PANELS = [
	{
		"path": "res://prologue/break_1.jpg",
		"text": "魔瓶在我面前摔开了。玻璃碎片散进麦丛，四季的风停在了半空。"
	},
	{
		"path": "res://prologue/break_2.jpg",
		"text": "过了一会儿，那些碎片忽然亮了起来，像是想起了自己该去哪里。"
	},
	{
		"path": "res://prologue/break_3.jpg",
		"text": "它们一块块飞回去，重新拼成完整的瓶子。瓶底那圈旧纹路，亮了一下。"
	}
]

const INK = Color(0.24, 0.17, 0.11)
const PAPER = Color(0.99, 0.97, 0.92, 0.98)
const CAPTION_BG = Color(0.97, 0.93, 0.82, 0.97)

# 由 BottleManager 在入树前赋值；读完或跳过时调用。
var on_finished = null

var _current = 0
var _leaving = false
var _tween = null

var _photo = null
var _caption_label = null
var _dots_label = null
var _hint_label = null
var _title_font = null
var _body_font = null
var _small_font = null
var _button_font = null


func _ready():
	layer = 150
	pause_mode = Node.PAUSE_MODE_PROCESS
	_make_fonts()
	_build_background()
	_show_panel(0, false)
	_update_footer()


func _make_fonts():
	_title_font = DynamicFont.new()
	_title_font.font_data = load("res://fonts/SimHei.ttf")
	_title_font.size = 22

	_body_font = DynamicFont.new()
	_body_font.font_data = load("res://fonts/SimHei.ttf")
	_body_font.size = 18

	_small_font = DynamicFont.new()
	_small_font.font_data = load("res://fonts/SimHei.ttf")
	_small_font.size = 13

	_button_font = DynamicFont.new()
	_button_font.font_data = load("res://fonts/SimHei.ttf")
	_button_font.size = 16


func _build_background():
	var root = Control.new()
	root.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.connect("gui_input", self, "_gui_input")
	add_child(root)

	var bg = TextureRect.new()
	bg.texture = load("res://prologue/paper.jpg")
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.expand = true
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	var margin = MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_constant_override("margin_left", 100)
	margin.add_constant_override("margin_right", 100)
	margin.add_constant_override("margin_top", 66)
	margin.add_constant_override("margin_bottom", 24)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = VBoxContainer.ALIGN_CENTER
	vbox.add_constant_override("separation", 12)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "碎 裂"
	title.align = Label.ALIGN_CENTER
	title.add_font_override("font", _title_font)
	title.add_color_override("font_color", INK)
	vbox.add_child(title)

	var frame = Panel.new()
	frame.rect_min_size = Vector2(0, 512)
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_FILL
	frame.add_stylebox_override("panel", _frame_box())
	vbox.add_child(frame)

	var photo_margin = MarginContainer.new()
	photo_margin.anchor_right = 1.0
	photo_margin.anchor_bottom = 1.0
	photo_margin.add_constant_override("margin_left", 8)
	photo_margin.add_constant_override("margin_right", 8)
	photo_margin.add_constant_override("margin_top", 8)
	photo_margin.add_constant_override("margin_bottom", 8)
	photo_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(photo_margin)

	_photo = TextureRect.new()
	_photo.expand = true
	_photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	photo_margin.add_child(_photo)

	var caption = PanelContainer.new()
	caption.rect_min_size = Vector2(0, 70)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.add_stylebox_override("panel", _caption_box())
	vbox.add_child(caption)

	var caption_margin = MarginContainer.new()
	caption_margin.anchor_right = 1.0
	caption_margin.anchor_bottom = 1.0
	caption_margin.add_constant_override("margin_left", 18)
	caption_margin.add_constant_override("margin_right", 18)
	caption_margin.add_constant_override("margin_top", 8)
	caption_margin.add_constant_override("margin_bottom", 8)
	caption_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.add_child(caption_margin)

	_caption_label = Label.new()
	_caption_label.add_font_override("font", _body_font)
	_caption_label.add_color_override("font_color", INK)
	_caption_label.autowrap = true
	_caption_label.valign = Label.VALIGN_CENTER
	_caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption_margin.add_child(_caption_label)

	var footer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGN_CENTER
	footer.add_constant_override("separation", 16)
	vbox.add_child(footer)

	_dots_label = Label.new()
	_dots_label.add_font_override("font", _small_font)
	_dots_label.add_color_override("font_color", Color(0.42, 0.28, 0.18, 0.85))
	_dots_label.valign = Label.VALIGN_CENTER
	footer.add_child(_dots_label)

	_hint_label = Label.new()
	_hint_label.text = "点击画面继续"
	_hint_label.add_font_override("font", _small_font)
	_hint_label.add_color_override("font_color", Color(0.47, 0.31, 0.19, 0.75))
	_hint_label.valign = Label.VALIGN_CENTER
	footer.add_child(_hint_label)

	var skip = Button.new()
	skip.text = "跳过"
	skip.anchor_left = 1.0
	skip.anchor_right = 1.0
	skip.margin_left = -98
	skip.margin_right = -26
	skip.margin_top = 24
	skip.margin_bottom = 56
	skip.add_font_override("font", _small_font)
	skip.focus_mode = Control.FOCUS_NONE
	skip.connect("pressed", self, "_skip")
	skip.connect("mouse_entered", SFX.button_hover, "play_sfx")
	skip.connect("pressed", SFX.button_click, "play_sfx")
	root.add_child(skip)

	# 除了“跳过”，装饰层全部放行鼠标，点画面任意位置都能翻页。
	_ignore_mouse_recursive(root)


func _ignore_mouse_recursive(node):
	for c in node.get_children():
		if c is Button:
			continue
		if c is Control:
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse_recursive(c)


func _frame_box():
	var sb = StyleBoxFlat.new()
	sb.bg_color = PAPER
	sb.border_color = Color(0.22, 0.15, 0.10, 0.92)
	sb.border_width_left = 3
	sb.border_width_right = 3
	sb.border_width_top = 3
	sb.border_width_bottom = 3
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 3
	sb.corner_radius_bottom_left = 3
	sb.corner_radius_bottom_right = 3
	sb.shadow_color = Color(0.25, 0.17, 0.10, 0.22)
	sb.shadow_size = 6
	return sb


func _caption_box():
	var sb = StyleBoxFlat.new()
	sb.bg_color = CAPTION_BG
	sb.border_color = Color(0.42, 0.30, 0.20, 0.60)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 2
	sb.corner_radius_bottom_right = 2
	return sb


func _unhandled_input(event):
	if _leaving:
		return
	if event.is_action_pressed("ui_cancel"):
		_skip()
	elif event.is_action_pressed("ui_accept"):
		_on_click()


func _gui_input(event):
	if _leaving:
		return
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		_on_click()
		get_tree().set_input_as_handled()


func _on_click():
	if _current >= PANELS.size() - 1:
		_finish()
		return
	_current += 1
	SFX.card_deal.play_sfx()
	_show_panel(_current, true)
	_update_footer()


func _skip():
	_finish()


func _show_panel(index, animate):
	_photo.texture = load(PANELS[index]["path"])
	_caption_label.text = PANELS[index]["text"]

	if _tween != null and is_instance_valid(_tween):
		_tween.stop_all()
		_tween.queue_free()
		_tween = null

	if not animate:
		_photo.modulate = Color(1, 1, 1, 1)
		return
	_photo.modulate = Color(1, 1, 1, 0)
	var tween = Tween.new()
	add_child(tween)
	_tween = tween
	tween.interpolate_property(_photo, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1),
		0.16, Tween.TRANS_SINE, Tween.EASE_OUT)
	tween.start()


func _update_footer():
	var dots = ""
	for i in range(PANELS.size()):
		dots += "●" if i <= _current else "○"
		if i < PANELS.size() - 1:
			dots += " "
	_dots_label.text = dots
	_hint_label.visible = _current < PANELS.size() - 1
	_hint_label.text = "点击画面继续"


func _finish():
	if _leaving:
		return
	_leaving = true
	var cb = on_finished
	on_finished = null
	queue_free()
	if cb != null:
		cb.call_func()