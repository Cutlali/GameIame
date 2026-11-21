extends Panel

# 右上角常驻面板：图鉴入口 + 魔瓶血量。
# 魔瓶维持着四季，所以瓶子光晕会跟随当前季节变色。

var _bestiary_button: Button

var _hp = 3
var _hp_max = 3
var _glow = Color(0.45, 0.85, 0.45)
var _damage_flash = 0.0

var _title_font: DynamicFont
var _small_font: DynamicFont


func _ready():
	add_stylebox_override("panel", _flat_box(Color(0.10, 0.11, 0.13, 0.82), Color(0.60, 0.64, 0.52, 0.75), 1, 10))

	_bestiary_button = _make_button(Vector2(8, 8), Vector2(235, 40))
	_bestiary_button.text = "图鉴"
	_bestiary_button.connect("pressed", self, "_on_bestiary_pressed")
	add_child(_bestiary_button)

	_title_font = DynamicFont.new()
	_title_font.font_data = load("res://fonts/SimHei.ttf")
	_title_font.size = 16

	_small_font = DynamicFont.new()
	_small_font.font_data = load("res://fonts/SimHei.ttf")
	_small_font.size = 12

	var hint = Label.new()
	hint.text = "P 键暂停"
	hint.rect_position = Vector2(54, 100)
	hint.rect_size = Vector2(180, 20)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_font_override("font", _small_font)
	hint.add_color_override("font_color", Color(0.72, 0.74, 0.70))
	add_child(hint)


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


func _make_button(pos, size):
	var b = Button.new()
	b.rect_position = pos
	b.rect_size = size
	var font = DynamicFont.new()
	font.font_data = load("res://fonts/SimHei.ttf")
	font.size = 17
	b.add_font_override("font", font)
	b.add_color_override("font_color", Color(0.96, 0.97, 0.93))
	b.add_color_override("font_color_hover", Color(1, 1, 1))
	b.add_color_override("font_color_pressed", Color(0.85, 1.0, 0.85))
	b.add_stylebox_override("normal", _flat_box(Color(0.17, 0.19, 0.21), Color(0.42, 0.46, 0.40), 1, 7))
	b.add_stylebox_override("hover", _flat_box(Color(0.23, 0.26, 0.28), Color(0.62, 0.74, 0.58), 1, 7))
	b.add_stylebox_override("pressed", _flat_box(Color(0.16, 0.26, 0.18), Color(0.60, 0.90, 0.58), 2, 7))
	b.add_stylebox_override("focus", StyleBoxEmpty.new())
	return b


func contains_mouse(control: Control):
	var r = Rect2(Vector2.ZERO, control.rect_size)
	return r.has_point(control.get_local_mouse_position())


func _season_color(season):
	match season:
		"spring":
			return Color(0.45, 0.85, 0.45)
		"summer":
			return Color(1.0, 0.80, 0.28)
		"autumn":
			return Color(0.95, 0.55, 0.22)
		"winter":
			return Color(0.55, 0.80, 1.0)
	return Color(0.55, 0.80, 0.60)


func _process(delta):
	visible = not GS.tutorial

	if has_node("/root/BottleManager"):
		var new_hp = BottleManager.hp
		if new_hp < _hp:
			_damage_flash = 1.0
		_hp = new_hp
		_hp_max = BottleManager.MAX_HP
	else:
		_hp = 3
		_hp_max = 3

	_glow = _glow.linear_interpolate(_season_color(Season.current_season),
		clamp(delta * 3.0, 0.0, 1.0))
	if _damage_flash > 0.0:
		_damage_flash = max(0.0, _damage_flash - delta * 2.2)

	update()
	GS.upper_panel_mouse = visible and contains_mouse(self)


func _draw():
	# 季节光晕：魔瓶维持四季，光晕颜色跟着季节走。
	var pulse = 0.9 + 0.1 * sin(OS.get_ticks_msec() / 520.0)
	var center = Vector2(27, 80)
	draw_circle(center, 30.0, Color(_glow.r, _glow.g, _glow.b, 0.10 * pulse))
	draw_circle(center, 21.0, Color(_glow.r, _glow.g, _glow.b, 0.14 * pulse))

	# 瓶身、瓶颈、瓶塞。
	draw_rect(Rect2(20, 49, 14, 5), Color(0.52, 0.36, 0.22))
	draw_rect(Rect2(21, 53, 12, 10), Color(0.16, 0.19, 0.20))
	draw_rect(Rect2(12, 62, 30, 40), Color(0.13, 0.16, 0.18))
	draw_rect(Rect2(12, 62, 30, 40), Color(0.58, 0.64, 0.58), false, 2.0)

	# 液体高度就是剩余血量。
	var ratio = float(_hp) / float(max(1, _hp_max))
	var liquid_h = 36.0 * ratio
	if liquid_h > 0.0:
		var liquid = Color(_glow.r, _glow.g, _glow.b, 0.88)
		if _damage_flash > 0.0:
			liquid = liquid.linear_interpolate(Color(1.0, 0.25, 0.25, 0.95), _damage_flash)
		draw_rect(Rect2(15, 99 - liquid_h, 24, liquid_h), liquid)

	# 三滴血：亮起表示剩余，暗下去表示已损失。
	for i in range(_hp_max):
		var p = Vector2(60 + i * 18, 84)
		if i < _hp:
			var c = Color(_glow.r, _glow.g, _glow.b, 0.95)
			if _damage_flash > 0.0:
				c = c.linear_interpolate(Color(1.0, 0.3, 0.3, 1.0), _damage_flash)
			draw_circle(p, 6.5, c)
		else:
			draw_circle(p, 6.5, Color(0.20, 0.21, 0.22, 0.9))
			draw_arc(p, 6.5, 0, PI * 2, 20, Color(0.42, 0.44, 0.42), 1.0)

	draw_string(_title_font, Vector2(54, 70), "魔瓶",
		Color(0.94, 0.95, 0.90))
	draw_string(_small_font, Vector2(112, 88), "%d / %d" % [_hp, _hp_max],
		Color(0.78, 0.80, 0.76))


func _on_bestiary_pressed():
	EncyclopediaUI.open()
