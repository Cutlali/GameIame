extends Control

# 游戏内常驻界面：
# 左上角手记，右上角图鉴 + 魔瓶，左下角水晶球（与魔力球并排）。
# 魔瓶维持着四季，所以瓶内液体与光晕会跟随当前季节变色。
# 瓶身下方那条是“瓶能”：收获植物攒满 15 点后，点魔瓶释放——
# 固定给全场植物各浇 1 滴水，田里有虫时一并砸出伤害。

var _bestiary_button: Button
var _bestiary_label: Label
var _guide_button: Button
var _guide_badge: Label
var _orb_button: Button
var _orb_holder: Control
var _power_button: Button

# 最近一次解锁的手记页；有值说明玩家还没去看。
var _new_guide_index = -1

const ORB_RADIUS = 56.0

var _hp = 3
var _hp_max = 3
var _glow = Color(0.45, 0.85, 0.45)
var _damage_flash = 0.0

# 瓶能读数，跟着 BottleManager 走；攒满时整条槽发亮、可以点瓶子释放。
var _power = 0
var _power_max = 15

# 正拖着一张水牌悬在水晶球上时，给球体加一圈高亮。
var _orb_drag_hover = false

var _title_font: DynamicFont
var _small_font: DynamicFont
var _orb_font: DynamicFont
var _bottle_body_box: StyleBoxFlat
var _bottle_outline_box: StyleBoxFlat


func _ready():
	GS.hud = self

	var frame = $Frame
	frame.add_stylebox_override("panel", _flat_box(
		Color(0.10, 0.11, 0.13, 0.82), Color(0.60, 0.64, 0.52, 0.75), 1, 10))

	# 左上角：手记入口，做得比原来更大更显眼；放在季节横幅下方。
	_guide_button = _make_icon_button(Vector2(16, 60), Vector2(64, 64),
		"res://ui/guide_icon.png", "瓶中手记")
	_guide_button.connect("pressed", self, "_on_guide_pressed")
	add_child(_guide_button)

	_guide_badge = Label.new()
	_guide_badge.text = "新"
	_guide_badge.rect_position = Vector2(63, 52)
	_guide_badge.rect_size = Vector2(24, 24)
	_guide_badge.align = Label.ALIGN_CENTER
	_guide_badge.valign = Label.VALIGN_CENTER
	_guide_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_font = DynamicFont.new()
	badge_font.font_data = load("res://fonts/SimHei.ttf")
	badge_font.size = 13
	badge_font.outline_size = 3
	badge_font.outline_color = Color(0.20, 0.10, 0.05, 0.95)
	_guide_badge.add_font_override("font", badge_font)
	_guide_badge.add_color_override("font_color", Color(1.0, 0.82, 0.34))
	_guide_badge.visible = false
	add_child(_guide_badge)

	# 右上角：图鉴图标。
	_bestiary_button = _make_icon_button(Vector2(10, 12), Vector2(52, 52),
		"res://ui/bestiary_icon.svg", "图鉴")
	_bestiary_button.connect("pressed", self, "_on_bestiary_pressed")
	frame.add_child(_bestiary_button)

	_bestiary_label = Label.new()
	_bestiary_label.text = "图鉴"
	_bestiary_label.rect_position = Vector2(10, 66)
	_bestiary_label.rect_size = Vector2(52, 18)
	_bestiary_label.align = Label.ALIGN_CENTER
	_bestiary_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var small = DynamicFont.new()
	small.font_data = load("res://fonts/SimHei.ttf")
	small.size = 12
	_bestiary_label.add_font_override("font", small)
	_bestiary_label.add_color_override("font_color", Color(0.88, 0.84, 0.72))
	frame.add_child(_bestiary_label)

	if not Flags.is_connected("guide_page_unlocked", self, "_on_guide_page_unlocked"):
		Flags.connect("guide_page_unlocked", self, "_on_guide_page_unlocked")

	# 瓶能攒满后，整个瓶身就是释放按钮；没满时不拦截鼠标。
	_power_button = Button.new()
	_power_button.rect_position = Vector2(126, 24)
	_power_button.rect_size = Vector2(64, 114)
	_power_button.flat = true
	_power_button.focus_mode = Control.FOCUS_NONE
	_power_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_power_button.hint_tooltip = "瓶能已满：点魔瓶给全场植物各浇一滴水，有虫时一并砸出伤害"
	for pstate in ["normal", "hover", "pressed", "focus"]:
		_power_button.add_stylebox_override(pstate, StyleBoxEmpty.new())
	_power_button.connect("pressed", self, "_on_power_pressed")
	_power_button.visible = false
	frame.add_child(_power_button)

	_title_font = DynamicFont.new()
	_title_font.font_data = load("res://fonts/SimHei.ttf")
	_title_font.size = 16

	_small_font = DynamicFont.new()
	_small_font.font_data = load("res://fonts/SimHei.ttf")
	_small_font.size = 12

	_orb_font = DynamicFont.new()
	_orb_font.font_data = load("res://fonts/SimHei.ttf")
	_orb_font.size = 30
	_orb_font.outline_size = 4
	_orb_font.outline_color = Color(0.06, 0.10, 0.14, 0.9)

	_bottle_body_box = _flat_box(Color(0.13, 0.17, 0.18, 0.96), Color(0, 0, 0, 0), 0, 10)
	_bottle_body_box.corner_radius_top_left = 4
	_bottle_body_box.corner_radius_top_right = 4
	_bottle_outline_box = _flat_box(Color(0, 0, 0, 0), Color(0.60, 0.68, 0.62, 0.9), 2, 10)
	_bottle_outline_box.draw_center = false
	_bottle_outline_box.corner_radius_top_left = 4
	_bottle_outline_box.corner_radius_top_right = 4

	# 左下角：水晶球与魔力球并排，尺寸对齐。
	_orb_holder = Control.new()
	_orb_holder.anchor_top = 1.0
	_orb_holder.anchor_bottom = 1.0
	_orb_holder.margin_left = 134.0
	_orb_holder.margin_right = 294.0
	_orb_holder.margin_top = -150.0
	_orb_holder.margin_bottom = -10.0
	_orb_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_orb_holder)

	_orb_button = Button.new()
	_orb_button.anchor_right = 1.0
	_orb_button.anchor_bottom = 1.0
	_orb_button.flat = true
	_orb_button.focus_mode = Control.FOCUS_NONE
	_orb_button.hint_tooltip = "水晶球：点击取 1 点水；把水牌拖到这里存水"
	_orb_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus"]:
		_orb_button.add_stylebox_override(state, StyleBoxEmpty.new())
	_orb_button.connect("pressed", self, "_on_orb_pressed")
	_orb_holder.add_child(_orb_button)


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
	b.connect("mouse_entered", SFX.button_hover, "play_sfx")
	b.connect("pressed", SFX.button_click, "play_sfx")
	return b


func _make_icon_button(pos, size, icon_path, tooltip):
	var b = _make_button(pos, size)
	b.icon = load(icon_path)
	b.expand_icon = true
	b.hint_tooltip = tooltip
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b


func contains_mouse(control: Control):
	if control == null or not is_instance_valid(control):
		return false
	var r = Rect2(Vector2.ZERO, control.rect_size)
	return r.has_point(control.get_local_mouse_position())


func _exit_tree():
	if GS.hud == self:
		GS.hud = null


func _orb_center():
	if _orb_holder == null or not is_instance_valid(_orb_holder):
		return Vector2(206, 720)
	return _orb_holder.rect_global_position + Vector2(72, 76)


# 鼠标是否落在水晶球范围内。拖水牌时判定比球体略宽松一点。
func is_mouse_over_orb():
	if not visible:
		return false
	return get_global_mouse_position().distance_to(_orb_center()) <= ORB_RADIUS + 7.0


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
	# 教程期间收起常驻 HUD；但储水课必须露出左下角水晶球，
	# 否则手里有水牌却没有可拖放的目标，流程会卡死。
	var in_tutorial = GS.tutorial
	var show_orb = in_tutorial and GS.tutorial_show_orb
	visible = not in_tutorial or show_orb
	$Frame.visible = not in_tutorial
	_guide_button.visible = not in_tutorial
	if _guide_badge != null:
		_guide_badge.visible = not in_tutorial and _new_guide_index >= 0

	if has_node("/root/BottleManager"):
		var new_hp = BottleManager.hp
		if new_hp < _hp:
			_damage_flash = 1.0
		_hp = new_hp
		_hp_max = BottleManager.MAX_HP
		_power = BottleManager.power
		_power_max = BottleManager.MAX_POWER
	else:
		_hp = 3
		_hp_max = 3
		_power = 0
		_power_max = 15

	if _power_button != null and is_instance_valid(_power_button):
		_power_button.visible = _power >= _power_max and _hp > 0

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
	GS.upper_panel_mouse = visible and (
		($Frame.visible and contains_mouse($Frame)) \
		or (_guide_button.visible and contains_mouse(_guide_button)) \
		or is_mouse_over_orb())


func _draw():
	# 教程里只露水晶球；魔瓶、图鉴和手记入口等引导结束再画。
	if not GS.tutorial:
		_draw_bottle($Frame.rect_position)
	_draw_crystal_orb()


# 魔瓶：瓶塞、瓶颈、肩部、玻璃瓶身、液体高度和血量。
func _draw_bottle(f):
	var cx = f.x + 157.0
	var y = f.y

	# 季节光晕与投影。
	var pulse = 0.9 + 0.1 * sin(OS.get_ticks_msec() / 520.0)
	draw_circle(Vector2(cx, y + 94), 36.0,
		Color(_glow.r, _glow.g, _glow.b, 0.10 * pulse))
	# 瓶能攒满时再套一圈紫光，配合下方提示告诉玩家可以点了。
	if _power >= _power_max and _hp > 0:
		var charge_pulse = 0.6 + 0.4 * sin(OS.get_ticks_msec() / 240.0)
		draw_circle(Vector2(cx, y + 94), 46.0, Color(0.72, 0.52, 0.96, 0.20 * charge_pulse))
	draw_circle(Vector2(cx, y + 134), 25.0, Color(0.0, 0.0, 0.0, 0.18))

	# 瓶塞与瓶颈。
	draw_rect(Rect2(cx - 7, y + 26, 14, 8), Color(0.50, 0.34, 0.20))
	draw_rect(Rect2(cx - 7, y + 26, 14, 2), Color(0.68, 0.50, 0.30))
	draw_rect(Rect2(cx - 4, y + 34, 8, 12), Color(0.16, 0.19, 0.20))
	draw_rect(Rect2(cx - 6, y + 42, 12, 3), Color(0.36, 0.40, 0.38))
	draw_rect(Rect2(cx - 5, y + 34, 2, 9), Color(0.30, 0.34, 0.34))

	# 肩部与瓶身。
	var shoulder = PoolVector2Array([
		Vector2(cx - 4, y + 43), Vector2(cx - 27, y + 58),
		Vector2(cx - 27, y + 67), Vector2(cx + 27, y + 67),
		Vector2(cx + 27, y + 58), Vector2(cx + 4, y + 43)])
	draw_colored_polygon(shoulder, Color(0.13, 0.17, 0.18, 0.96))
	draw_style_box(_bottle_body_box, Rect2(cx - 27, y + 58, 54, 76))

	# 液体高度就是剩余血量。
	var ratio = float(_hp) / float(max(1, _hp_max))
	var liquid_h = 72.0 * ratio
	if liquid_h > 0.0:
		var liquid = Color(_glow.r, _glow.g, _glow.b, 0.88)
		if _damage_flash > 0.0:
			liquid = liquid.linear_interpolate(Color(1.0, 0.25, 0.25, 0.95), _damage_flash)
		var ly = y + 130 - liquid_h
		draw_rect(Rect2(cx - 23, ly, 46, liquid_h), liquid)
		draw_line(Vector2(cx - 22, ly), Vector2(cx + 22, ly),
			Color(liquid.r, liquid.g, liquid.b, 0.95).lightened(0.25), 1.5)
		if liquid_h > 14.0:
			draw_circle(Vector2(cx - 8, ly + 9), 2.5,
				Color(1.0, 1.0, 1.0, 0.20))
			draw_circle(Vector2(cx + 6, ly + 18), 1.8,
				Color(1.0, 1.0, 1.0, 0.16))

	# 玻璃轮廓与反光。
	draw_polyline(shoulder, Color(0.60, 0.68, 0.62, 0.9), 2.0)
	draw_style_box(_bottle_outline_box, Rect2(cx - 27, y + 58, 54, 76))
	draw_rect(Rect2(cx - 21, y + 66, 4, 54), Color(1.0, 1.0, 1.0, 0.14))
	draw_circle(Vector2(cx - 14, y + 66), 3.5, Color(1.0, 1.0, 1.0, 0.22))

	# 标题与血量。
	draw_string(_title_font, Vector2(f.x + 84, y + 30), "魔瓶",
		Color(0.94, 0.95, 0.90))
	for i in range(_hp_max):
		var p = Vector2(f.x + 208 + i * 15, y + 42)
		if i < _hp:
			var c = Color(_glow.r, _glow.g, _glow.b, 0.95)
			if _damage_flash > 0.0:
				c = c.linear_interpolate(Color(1.0, 0.3, 0.3, 1.0), _damage_flash)
			draw_circle(p, 4.5, c)
		else:
			draw_circle(p, 4.5, Color(0.20, 0.21, 0.22, 0.9))
			draw_arc(p, 4.5, 0, PI * 2, 16, Color(0.42, 0.44, 0.42), 1.0)
	draw_string(_small_font, Vector2(f.x + 206, y + 62), "%d / %d" % [_hp, _hp_max],
		Color(0.78, 0.80, 0.76))

	_draw_bottle_power(f)


# 瓶能槽：15 格小方块一行排开，左右读齐；满格时整条发亮，
# 提示文字居中落在槽下方、仍在面板内。
func _draw_bottle_power(f):
	var bar_y = f.y + 140
	var x0 = f.x + 52
	var cell = 9.0
	var gap = 2.0
	var bar_w = float(_power_max) * cell + float(_power_max - 1) * gap
	var full = _power >= _power_max and _hp > 0
	var pulse = 0.75 + 0.25 * sin(OS.get_ticks_msec() / 220.0)

	# draw_string 的 y 是基线：取格子上沿 +9 才能和 10px 高的格子齐平。
	draw_string(_small_font, Vector2(f.x + 10, bar_y + 9), "瓶能",
		Color(0.88, 0.82, 0.96) if full else Color(0.70, 0.68, 0.74))

	for i in range(_power_max):
		var r = Rect2(x0 + i * (cell + gap), bar_y, cell, 10)
		if i < _power:
			var c = Color(0.72, 0.56, 0.95)
			if full:
				c = Color(0.84, 0.66, 1.0, 0.60 + 0.40 * pulse)
			draw_rect(r, c)
			draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 3),
				Color(0.94, 0.88, 1.0, 0.45))
		else:
			draw_rect(r, Color(0.17, 0.16, 0.22, 0.9))
			draw_rect(r, Color(0.40, 0.38, 0.48, 0.75), false, 1.0)

	draw_string(_small_font,
		Vector2(x0 + bar_w + 6, bar_y + 9),
		"%d/%d" % [_power, _power_max],
		Color(0.92, 0.88, 1.0) if full else Color(0.72, 0.70, 0.78))

	if full:
		var hint = "瓶能已满 · 点击魔瓶：全场浇水，有虫加伤"
		var hw = _small_font.get_string_size(hint).x
		draw_string(_small_font,
			Vector2(x0 + bar_w / 2.0 - hw / 2.0, bar_y + 26),
			hint, Color(0.93, 0.86, 1.0, 0.60 + 0.40 * pulse))


# 水晶球：存下的水没有上限，球体本身只表示“有没有水”，数量写在中间。
func _draw_crystal_orb():
	var c = _orb_center()
	var r = ORB_RADIUS
	draw_circle(c, r + 4.0, Color(0.08, 0.10, 0.12, 0.55))
	draw_circle(c, r, Color(0.13, 0.17, 0.21, 0.92))

	var has_water = GS.orb_water > 0
	if has_water:
		var pulse = 0.85 + 0.15 * sin(OS.get_ticks_msec() / 700.0)
		draw_circle(c, r - 3.0, Color(0.34, 0.63, 0.92, 0.36 * pulse))
		draw_circle(c + Vector2(0, 2.0), r - 8.0, Color(0.40, 0.70, 0.96, 0.88))
		draw_circle(c + Vector2(-14, -16), 9.0, Color(0.88, 0.96, 1.0, 0.40))
		draw_circle(c + Vector2(18, 22), 3.0, Color(0.88, 0.96, 1.0, 0.30))
	else:
		draw_circle(c, r - 3.0, Color(0.18, 0.23, 0.27, 0.9))

	draw_arc(c, r + 0.5, 0, PI * 2, 48, Color(0.62, 0.78, 0.88, 0.85), 2.5)
	if _orb_drag_hover:
		var hp = 0.7 + 0.3 * sin(OS.get_ticks_msec() / 180.0)
		draw_arc(c, r + 9.0, 0, PI * 2, 48, Color(0.78, 0.95, 1.0, 0.55 + 0.35 * hp), 3.0)

	var text = "%d" % GS.orb_water
	var tw = _orb_font.get_string_size(text).x
	draw_string(_orb_font, c + Vector2(-tw * 0.5, 10), text,
		Color(0.96, 0.98, 1.0) if has_water else Color(0.55, 0.60, 0.62))


func _on_bestiary_pressed():
	EncyclopediaUI.open()


# 点击瓶身释放瓶能。和取水一样，只在自己的回合里可以操作。
func _on_power_pressed():
	if GS.turn_state != GS.TurnState.PLAYING_CARDS:
		Toast.show_message("等回到你的回合再释放瓶能。")
		return
	BottleManager.release_power()


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
