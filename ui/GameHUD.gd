extends Panel

# 右上角常驻面板：图鉴入口 + 魔瓶血量。
# 魔瓶维持着四季，所以瓶子光晕会跟随当前季节变色。

var _bestiary_button: Button
var _guide_button: Button
var _guide_badge: Label
var _orb_button: Button

# 最近一次解锁的手记页；有值说明玩家还没去看。
var _new_guide_index = -1

const ORB_CENTER = Vector2(210, 78)
const ORB_RADIUS = 21.0

var _hp = 3
var _hp_max = 3
var _glow = Color(0.45, 0.85, 0.45)
var _damage_flash = 0.0

# 正拖着一张水牌悬在水晶球上时，给球体加一圈高亮。
var _orb_drag_hover = false

var _title_font: DynamicFont
var _small_font: DynamicFont


func _ready():
	GS.hud = self
	add_stylebox_override("panel", _flat_box(Color(0.10, 0.11, 0.13, 0.82), Color(0.60, 0.64, 0.52, 0.75), 1, 10))

	_bestiary_button = _make_button(Vector2(8, 8), Vector2(150, 40))
	_bestiary_button.text = "图鉴"
	_bestiary_button.connect("pressed", self, "_on_bestiary_pressed")
	add_child(_bestiary_button)

	_guide_button = _make_icon_button(Vector2(166, 8), Vector2(40, 40),
		"res://ui/guide_icon.png", "瓶中手记")
	_guide_button.connect("pressed", self, "_on_guide_pressed")
	add_child(_guide_button)

	_guide_badge = Label.new()
	_guide_badge.text = "新"
	_guide_badge.rect_position = Vector2(196, -3)
	_guide_badge.rect_size = Vector2(22, 22)
	_guide_badge.align = Label.ALIGN_CENTER
	_guide_badge.valign = Label.VALIGN_CENTER
	_guide_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_font = DynamicFont.new()
	badge_font.font_data = load("res://fonts/SimHei.ttf")
	badge_font.size = 12
	badge_font.outline_size = 3
	badge_font.outline_color = Color(0.20, 0.10, 0.05, 0.95)
	_guide_badge.add_font_override("font", badge_font)
	_guide_badge.add_color_override("font_color", Color(1.0, 0.82, 0.34))
	_guide_badge.visible = false
	add_child(_guide_badge)

	if not Flags.is_connected("guide_page_unlocked", self, "_on_guide_page_unlocked"):
		Flags.connect("guide_page_unlocked", self, "_on_guide_page_unlocked")

	_title_font = DynamicFont.new()
	_title_font.font_data = load("res://fonts/SimHei.ttf")
	_title_font.size = 16

	_small_font = DynamicFont.new()
	_small_font.font_data = load("res://fonts/SimHei.ttf")
	_small_font.size = 12

	var hint = Label.new()
	hint.text = "P 键暂停"
	hint.rect_position = Vector2(54, 100)
	hint.rect_size = Vector2(110, 20)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_font_override("font", _small_font)
	hint.add_color_override("font_color", Color(0.72, 0.74, 0.70))
	add_child(hint)

	_orb_button = Button.new()
	_orb_button.rect_position = ORB_CENTER - Vector2(ORB_RADIUS + 4, ORB_RADIUS + 4)
	_orb_button.rect_size = Vector2(ORB_RADIUS + 4, ORB_RADIUS + 4) * 2
	_orb_button.flat = true
	_orb_button.focus_mode = Control.FOCUS_NONE
	_orb_button.hint_tooltip = "水晶球：点击取 1 点水；把水牌拖到这里存水"
	_orb_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus"]:
		_orb_button.add_stylebox_override(state, StyleBoxEmpty.new())
	_orb_button.connect("pressed", self, "_on_orb_pressed")
	add_child(_orb_button)


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
	b.add_color_override("font_color", Color(0.30, 0.19, 0.12))
	b.add_color_override("font_color_hover", Color(0.20, 0.11, 0.06))
	b.add_color_override("font_color_pressed", Color(0.26, 0.16, 0.10))
	b.add_stylebox_override("normal", _flat_box(Color(0.87, 0.76, 0.56), Color(0.45, 0.30, 0.18), 1, 7))
	b.add_stylebox_override("hover", _flat_box(Color(0.93, 0.83, 0.63), Color(0.55, 0.36, 0.20), 2, 7))
	b.add_stylebox_override("pressed", _flat_box(Color(0.80, 0.66, 0.46), Color(0.35, 0.21, 0.12), 2, 7))
	b.add_stylebox_override("focus", StyleBoxEmpty.new())
	return b


func _make_icon_button(pos, size, icon_path, tooltip):
	var b = _make_button(pos, size)
	b.icon = load(icon_path)
	b.expand_icon = true
	b.hint_tooltip = tooltip
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b


func contains_mouse(control: Control):
	var r = Rect2(Vector2.ZERO, control.rect_size)
	return r.has_point(control.get_local_mouse_position())


func _exit_tree():
	if GS.hud == self:
		GS.hud = null


# 鼠标是否落在水晶球范围内。拖水牌时判定比球体略宽松一点。
func is_mouse_over_orb():
	if not visible:
		return false
	return get_local_mouse_position().distance_to(ORB_CENTER) <= ORB_RADIUS + 6.0


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

	_orb_drag_hover = false
	var picked = GS.current_picked_up_card
	if picked != null and is_instance_valid(picked) and picked.associated_card != null:
		var ac = picked.associated_card
		if ac.action == GS.Action.WATER and not ac.from_orb and is_mouse_over_orb():
			_orb_drag_hover = true

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

	_draw_crystal_orb()


# 水晶球：存下的水没有上限，球体本身只表示“有没有水”，数量写在中间。
func _draw_crystal_orb():
	var c = ORB_CENTER
	var r = ORB_RADIUS
	draw_circle(c, r + 3.0, Color(0.08, 0.10, 0.12, 0.55))
	draw_circle(c, r, Color(0.13, 0.17, 0.21, 0.92))

	var has_water = GS.orb_water > 0
	if has_water:
		var pulse = 0.85 + 0.15 * sin(OS.get_ticks_msec() / 700.0)
		draw_circle(c, r - 1.5, Color(0.34, 0.63, 0.92, 0.36 * pulse))
		draw_circle(c + Vector2(0, 1.5), r - 4.0, Color(0.40, 0.70, 0.96, 0.88))
		draw_circle(c + Vector2(-6, -7), 4.5, Color(0.88, 0.96, 1.0, 0.55))
	else:
		draw_circle(c, r - 1.5, Color(0.18, 0.23, 0.27, 0.9))

	draw_arc(c, r + 0.5, 0, PI * 2, 32, Color(0.62, 0.78, 0.88, 0.85), 2.0)
	if _orb_drag_hover:
		var hp = 0.7 + 0.3 * sin(OS.get_ticks_msec() / 180.0)
		draw_arc(c, r + 7.0, 0, PI * 2, 40, Color(0.78, 0.95, 1.0, 0.55 + 0.35 * hp), 2.5)

	var text = "%d" % GS.orb_water
	var font = _title_font
	var tw = font.get_string_size(text).x
	draw_string(font, c + Vector2(-tw * 0.5, 6), text,
		Color(0.96, 0.98, 1.0) if has_water else Color(0.55, 0.60, 0.62))
	draw_string(_small_font, Vector2(c.x - 14, c.y + r + 16), "水晶球",
		Color(0.62, 0.72, 0.80))


func _on_bestiary_pressed():
	EncyclopediaUI.open()


func _on_orb_pressed():
	if GS.turn_state != GS.TurnState.PLAYING_CARDS:
		Toast.show_message("等回到你的回合再取水。")
		return
	if GS.hand == null or not is_instance_valid(GS.hand):
		return
	if GS.orb_water <= 0:
		Toast.show_message("水晶球里还没有水。")
		return
	if GS.orb_water - GS.orb_water_in_hand() <= 0:
		Toast.show_message("取出的水已经在手牌里了。")
		return
	GS.add_card_to_hand(GS.card_orb_water)
	Toast.show_message("从水晶球取出 1 点水。")


func _on_guide_pressed():
	var game = owner
	if game == null:
		return
	var guide = game.get_node_or_null("GuideBook")
	if guide == null:
		return
	guide.open(true)
	# 有新解锁的页时，直接翻到那一页，并收掉角标。
	if _new_guide_index >= 0:
		guide.select_chapter(_new_guide_index)
		_new_guide_index = -1
		if _guide_badge != null:
			_guide_badge.visible = false


func _on_guide_page_unlocked(index, title):
	_new_guide_index = index
	if _guide_badge != null:
		_guide_badge.visible = true
	Toast.show_message("手记更新：%s" % title)
