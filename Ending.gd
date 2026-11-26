extends Control

# 终章：图鉴集齐、最后的种子成熟后播放的结局分镜。
# 与序章相同的阅读方式：点击画面翻页，最后一页回到主菜单。

const PANELS = [
	{
		"path": "res://prologue/ending_1.jpg",
		"text": "奇迹的种子成熟时，魔瓶忽然亮了。瓶中浮起这颗种子，像是等了我很久。"
	},
	{
		"path": "res://prologue/ending_2.jpg",
		"text": "我在田里挖开一小块土，将它埋了进去，等待着它的成熟"
	},
	{
		"path": "res://prologue/ending_3.jpg",
		"text": "瓶里的虫出现在了现实，造成了铺天盖地的虫灾，那植物散发出了耀眼的光芒！"
	},
	{
		"path": "res://prologue/ending_4.jpg",
		"text": "所有的虫子都被驱散了，魔瓶的使命似乎在我的手中迎来终结，我会将魔瓶中得到的植物播撒出去，守护好我的家园"
	}
]

const INK = Color(0.24, 0.17, 0.11)
const PAPER = Color(0.99, 0.97, 0.92, 0.98)
const CAPTION_BG = Color(0.97, 0.93, 0.82, 0.97)

var _frame = null
var _photo = null
var _caption_label = null
var _dots_label = null
var _hint_label = null
var _next_button = null
var _skip_button = null
var _finish_label = null
var _title_font = null
var _body_font = null
var _small_font = null
var _button_font = null
var _finish_font = null

var _index = 0
var _tween = null
var _leaving = false


func _ready():
	Music.set_mode("ending")
	_make_fonts()
	_build_background()
	_build_page()
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

	_finish_font = DynamicFont.new()
	_finish_font.font_data = load("res://fonts/SimHei.ttf")
	_finish_font.size = 44


func _build_background():
	var bg = TextureRect.new()
	bg.texture = load("res://prologue/paper.jpg")
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.expand = true
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)


func _build_page():
	var margin = MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_constant_override("margin_left", 100)
	margin.add_constant_override("margin_right", 100)
	margin.add_constant_override("margin_top", 66)
	margin.add_constant_override("margin_bottom", 24)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = VBoxContainer.ALIGN_CENTER
	vbox.add_constant_override("separation", 12)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "终 章   ·   最后一颗种子"
	title.align = Label.ALIGN_CENTER
	title.add_font_override("font", _title_font)
	title.add_color_override("font_color", INK)
	vbox.add_child(title)

	_frame = Panel.new()
	_frame.rect_min_size = Vector2(0, 512)
	_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_frame.size_flags_vertical = Control.SIZE_FILL
	_frame.add_stylebox_override("panel", _frame_box())
	vbox.add_child(_frame)

	var photo_margin = MarginContainer.new()
	photo_margin.anchor_right = 1.0
	photo_margin.anchor_bottom = 1.0
	photo_margin.add_constant_override("margin_left", 8)
	photo_margin.add_constant_override("margin_right", 8)
	photo_margin.add_constant_override("margin_top", 8)
	photo_margin.add_constant_override("margin_bottom", 8)
	photo_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(photo_margin)

	_photo = TextureRect.new()
	_photo.expand = true
	_photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	photo_margin.add_child(_photo)

	# 最后一页压在画面上的收尾印章。
	_finish_label = Label.new()
	_finish_label.text = "奇迹之种\n— 完 —"
	_finish_label.align = Label.ALIGN_CENTER
	_finish_label.valign = Label.VALIGN_CENTER
	_finish_label.anchor_right = 1.0
	_finish_label.anchor_bottom = 1.0
	_finish_label.add_font_override("font", _finish_font)
	_finish_label.add_color_override("font_color", Color(1.0, 0.97, 0.86, 1.0))
	_finish_label.add_color_override("font_color_shadow", Color(0.16, 0.10, 0.05, 0.85))
	_finish_label.add_constant_override("shadow_offset_x", 3)
	_finish_label.add_constant_override("shadow_offset_y", 3)
	_finish_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_finish_label.visible = false
	_frame.add_child(_finish_label)

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

	_next_button = Button.new()
	_next_button.text = "回到主菜单"
	_next_button.rect_min_size = Vector2(150, 36)
	_next_button.add_font_override("font", _button_font)
	_next_button.focus_mode = Control.FOCUS_NONE
	_next_button.visible = false
	_next_button.connect("pressed", self, "_to_menu")
	footer.add_child(_next_button)

	_skip_button = Button.new()
	_skip_button.text = "跳过"
	_skip_button.anchor_left = 1.0
	_skip_button.anchor_right = 1.0
	_skip_button.margin_left = -98
	_skip_button.margin_right = -26
	_skip_button.margin_top = 24
	_skip_button.margin_bottom = 56
	_skip_button.add_font_override("font", _small_font)
	_skip_button.focus_mode = Control.FOCUS_NONE
	_skip_button.connect("pressed", self, "_to_menu")
	add_child(_skip_button)

	_add_button_sfx(_next_button)
	_add_button_sfx(_skip_button)

	_ignore_mouse_recursive(margin)


func _add_button_sfx(btn):
	btn.connect("mouse_entered", SFX.button_hover, "play_sfx")
	btn.connect("pressed", SFX.button_click, "play_sfx")


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
		_to_menu()
		return
	if event.is_action_pressed("ui_accept"):
		_on_click()


func _gui_input(event):
	if _leaving:
		return
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		_on_click()
		accept_event()


func _on_click():
	if _index >= PANELS.size() - 1:
		_to_menu()
		return
	_advance()


func _advance():
	_index += 1
	SFX.card_deal.play_sfx()
	_show_panel(_index, true)
	_update_footer()


func _show_panel(index, animate):
	_photo.texture = load(PANELS[index]["path"])
	_caption_label.text = PANELS[index]["text"]

	if _tween != null and is_instance_valid(_tween):
		_tween.stop_all()
		_tween.queue_free()
		_tween = null

	if not animate:
		_photo.modulate = Color(1, 1, 1, 1)
	else:
		_photo.modulate = Color(1, 1, 1, 0)
		var tween = Tween.new()
		add_child(tween)
		_tween = tween
		tween.interpolate_property(_photo, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1),
			0.16, Tween.TRANS_SINE, Tween.EASE_OUT)
		tween.start()

	_show_finish(index >= PANELS.size() - 1)


# 最后一页把“完”慢慢压上来。
func _show_finish(show_it):
	if _finish_label == null:
		return
	if not show_it:
		_finish_label.visible = false
		_finish_label.modulate = Color(1, 1, 1, 0)
		return
	_finish_label.visible = true
	_finish_label.modulate = Color(1, 1, 1, 0)
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(_finish_label, "modulate:a", 0.0, 1.0, 0.9,
		Tween.TRANS_SINE, Tween.EASE_OUT)
	tween.start()


func _update_footer():
	var total = PANELS.size()
	var dots = ""
	for i in range(total):
		if i <= _index:
			dots += "●"
		else:
			dots += "○"
		if i < total - 1:
			dots += " "
	_dots_label.text = dots

	var done = _index >= total - 1
	_hint_label.visible = not done
	_hint_label.text = "点击画面继续"
	_next_button.visible = done


func _to_menu():
	if _leaving:
		return
	_leaving = true
	SceneTransitions.change_scene_to(GS.MainMenu)
