extends Node

# 四季系统
#
# 设计约定：
# - 春季直接使用 res://farm/ 与 res://decor/ 的原始素材
# - 夏 / 秋 / 冬 使用 res://seasons/<season>/ 下的同尺寸替换图
# - 切换只换贴图，不改动图块 id、位置、生长与数值
# - 一年 24 轮，每季 6 轮，春夏秋冬循环；年份可以一直继续
#
# 季节 buff：
#   春：1 次浇水推进 2 个生长帧
#   夏：虫害更多，变异概率提升
#   秋：魔瓶 4 选 2
#   冬：魔瓶 5 选 1，可刷新一次候选
#
# 左上角常驻 HUD 显示年份、季节与全年轮次。

const SEASONS = ["spring", "summer", "autumn", "winter"]
const SEASON_NAMES_CN = ["春", "夏", "秋", "冬"]
const ROUNDS_PER_SEASON = 6
const SEASONS_PER_YEAR = 4
const ROUNDS_PER_YEAR = ROUNDS_PER_SEASON * SEASONS_PER_YEAR

# TileSet 中 1-10 号图块对应的文件名，顺序与 id 一致
const FARM_FILES = [
	"dirt_pixel.png",
	"grass_pixel.png",
	"plant_spot.png",
	"dirt_pixel_2.png",
	"dirt_pixel_3.png",
	"dirt_pixel_4.png",
	"farmland_1.png",
	"farmland_2.png",
	"farmland_3.png",
	"farmland_4.png"
]

# 耕地边缘过渡层（TheTileMap 运行时创建），按节点名映射到贴图文件
const FARM_EDGE_FILES = {
	"FarmEdgeN": "farm_edge_n.png",
	"FarmEdgeE": "farm_edge_e.png",
	"FarmEdgeS": "farm_edge_s.png",
	"FarmEdgeW": "farm_edge_w.png"
}

const FADE_IN_TIME = 0.18
const FADE_OUT_TIME = 0.30
const HOLD_ON_BLACK = 0.45

var current_index = 0
var current_season = "spring"

var year = 1
var round_in_year = 1
var rounds_in_season = 0

var _tilemap = null
# 每个元素为 { "node": Sprite, "file": String }，file 是原始装饰文件名
var _decor = []
var _edge_maps = []
var _cache = {}
var _switching = false

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _season_label: Label
var _label_tween: Tween

var _hud_layer: CanvasLayer
var _hud_panel: ColorRect
var _hud_label: Label


func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	_build_overlay()
	_build_hud()


func _build_overlay():
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 128
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_fade_layer.add_child(_fade_rect)

	_season_label = Label.new()
	_season_label.align = Label.ALIGN_CENTER
	_season_label.valign = Label.VALIGN_CENTER
	_season_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_season_label.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_season_label.modulate.a = 0.0

	var font = DynamicFont.new()
	font.font_data = load("res://fonts/SimHei.ttf")
	font.size = 42
	_season_label.add_font_override("font", font)
	_season_label.add_color_override("font_color", Color(1, 1, 1, 1))
	_season_label.add_color_override("font_color_shadow", Color(0, 0, 0, 0.85))
	_season_label.add_constant_override("shadow_offset_x", 3)
	_season_label.add_constant_override("shadow_offset_y", 3)
	_fade_layer.add_child(_season_label)


func _build_hud():
	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 120
	_hud_layer.visible = false
	add_child(_hud_layer)

	_hud_panel = ColorRect.new()
	_hud_panel.color = Color(0, 0, 0, 0.45)
	_hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_panel.rect_position = Vector2(12, 10)
	_hud_panel.rect_size = Vector2(236, 36)
	_hud_layer.add_child(_hud_panel)

	_hud_label = Label.new()
	_hud_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_label.rect_position = Vector2(24, 15)
	var font = DynamicFont.new()
	font.font_data = load("res://fonts/SimHei.ttf")
	font.size = 19
	_hud_label.add_font_override("font", font)
	_hud_label.add_color_override("font_color", Color(1, 1, 1, 1))
	_hud_layer.add_child(_hud_label)


func _update_hud():
	if _hud_label == null:
		return
	_hud_label.text = "%s · 本季第 %d / %d 轮" % [
		SEASON_NAMES_CN[current_index], rounds_in_season, ROUNDS_PER_SEASON]


# ---- 季节 buff 接口 ----

func is_in_game():
	return _tilemap != null and is_instance_valid(_tilemap)


func season_name():
	return SEASON_NAMES_CN[current_index]


func is_spring():
	return current_season == "spring"


func is_summer():
	return current_season == "summer"


func is_autumn():
	return current_season == "autumn"


func is_winter():
	return current_season == "winter"


func growth_per_water():
	return 2 if is_spring() else 1


func bottle_offer_count():
	return 5 if is_winter() else 4


func bottle_pick_count():
	return 2 if is_autumn() else 1


func bottle_can_refresh():
	return is_winter()


# 由 TheTileMap 在 _ready 时调用。每次进入 Game 场景都重置回春季。
func bind_tilemap(map):
	if _tilemap != null and is_instance_valid(_tilemap):
		if _tilemap.is_connected("tree_exited", self, "_on_tilemap_exited"):
			_tilemap.disconnect("tree_exited", self, "_on_tilemap_exited")

	_tilemap = map
	_decor.clear()
	_edge_maps.clear()

	for child in map.get_children():
		if child is TileMap and FARM_EDGE_FILES.has(child.name):
			_edge_maps.append(child)

	var decor_root = map.get_node_or_null("Decor")
	if decor_root != null:
		for node in decor_root.get_children():
			if node is Sprite and node.texture != null:
				var path = node.texture.resource_path
				if path != "" and path.begins_with("res://decor/"):
					_decor.append({"node": node, "file": path.get_file()})

	current_index = 0
	current_season = SEASONS[0]
	year = 1
	round_in_year = 1
	RunStats.year = 1
	# 开局第一手牌就是第 1 轮，第一次 end_turn 时由 advance_round 推进到第 2 轮
	rounds_in_season = 1
	apply_textures()

	_hud_layer.visible = true
	_update_hud()

	if not map.is_connected("tree_exited", self, "_on_tilemap_exited"):
		map.connect("tree_exited", self, "_on_tilemap_exited")

	# 预热缓存放在绘制完成之后，避免卡住首帧
	call_deferred("_warm_cache")


func _on_tilemap_exited():
	_tilemap = null
	if _hud_layer != null:
		_hud_layer.visible = false


func _warm_cache():
	for season in ["summer", "autumn", "winter"]:
		for file in FARM_FILES:
			_texture(season, "farm", file)
		for file in FARM_EDGE_FILES.values():
			_texture(season, "farm", file)
		for entry in _decor:
			_texture(season, "decor", entry.file)


func _texture(season, kind, file):
	if season == "spring":
		var original = "res://%s/%s" % [kind, file]
		if ResourceLoader.exists(original):
			return load(original)
		return null

	var key = "%s/%s/%s" % [season, kind, file]
	if _cache.has(key):
		return _cache[key]

	var path = "res://seasons/%s/%s/%s" % [season, kind, file]
	var tex = null
	if ResourceLoader.exists(path):
		tex = load(path)
	_cache[key] = tex
	return tex


func apply_textures():
	if _tilemap == null or not is_instance_valid(_tilemap):
		return
	if _tilemap.tile_set == null:
		return

	var ids = _tilemap.tile_set.get_tiles_ids()
	for i in range(FARM_FILES.size()):
		var id = i + 1
		if not (id in ids):
			continue
		var tex = _texture(current_season, "farm", FARM_FILES[i])
		if tex != null:
			_tilemap.tile_set.tile_set_texture(id, tex)

	for em in _edge_maps:
		if not is_instance_valid(em) or em.tile_set == null:
			continue
		var edge_tex = _texture(current_season, "farm", FARM_EDGE_FILES[em.name])
		if edge_tex != null:
			em.tile_set.tile_set_texture(1, edge_tex)

	for entry in _decor:
		var node = entry.node
		if not is_instance_valid(node):
			continue
		var tex = _texture(current_season, "decor", entry.file)
		if tex != null:
			node.texture = tex


# 切换季节。index: 0=春 1=夏 2=秋 3=冬
# reset_rounds: 手动切换时重置为第 1 轮；自动换季由 advance_round 自行管理计数
func change_season(index, animate = true, reset_rounds = true):
	if index < 0 or index >= SEASONS.size():
		return
	if index == current_index or _switching:
		return
	if _tilemap == null or not is_instance_valid(_tilemap):
		return

	_switching = true

	if not animate:
		current_index = index
		current_season = SEASONS[index]
		if reset_rounds:
			rounds_in_season = 1
		apply_textures()
		_update_hud()
		_switching = false
		return

	# 淡入黑场 -> 换纹理 -> 显示季节名 -> 淡出
	yield(_fade_to(1.0, FADE_IN_TIME), "completed")

	current_index = index
	current_season = SEASONS[index]
	if reset_rounds:
		rounds_in_season = 1
	apply_textures()
	_update_hud()

	_show_season_name()
	yield(get_tree().create_timer(HOLD_ON_BLACK), "timeout")

	yield(_fade_to(0.0, FADE_OUT_TIME), "completed")
	yield(get_tree().create_timer(0.7), "timeout")
	_hide_season_name()

	_switching = false


# 每次发出一手新牌时调用一次（即进入新的一轮）。
# 返回是否发生了季节切换或年度结算。
func advance_round():
	if _tilemap == null or not is_instance_valid(_tilemap):
		return false

	# 一年结束：先截取总结数据，再重置年份与统计
	if round_in_year >= ROUNDS_PER_YEAR:
		var finished_year = year
		var lines = RunStats.summary_lines()
		var discovered = Encyclopedia.discovered_count()
		var total = Encyclopedia.total_entries()

		year += 1
		RunStats.year = year
		RunStats.reset_year()

		round_in_year = 1
		rounds_in_season = 1
		# 年度切换直接回到春天，避免黑场动画盖住年终总结。
		change_season(0, false, false)
		_update_hud()

		YearSummary.show_summary(finished_year, false, lines, discovered, total)
		return true

	round_in_year += 1
	rounds_in_season += 1

	if rounds_in_season > ROUNDS_PER_SEASON:
		rounds_in_season = 1
		var next_index = (current_index + 1) % SEASONS.size()
		change_season(next_index, true, false)
		_update_hud()
		return true

	_update_hud()
	return false


func _fade_to(alpha, duration):
	var tween = Tween.new()
	tween.pause_mode = Node.PAUSE_MODE_PROCESS
	add_child(tween)
	tween.interpolate_property(_fade_rect, "color",
		_fade_rect.color, Color(0, 0, 0, alpha), duration,
		Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_all_completed")
	tween.queue_free()


func _show_season_name():
	_season_label.text = "%s季" % SEASON_NAMES_CN[current_index]
	_tween_label_alpha(1.0, 0.20)


func _hide_season_name():
	_tween_label_alpha(0.0, 0.35)


func _tween_label_alpha(alpha, duration):
	if _label_tween != null and is_instance_valid(_label_tween):
		_label_tween.stop_all()
		_label_tween.queue_free()
	_label_tween = Tween.new()
	_label_tween.pause_mode = Node.PAUSE_MODE_PROCESS
	add_child(_label_tween)
	_label_tween.interpolate_property(_season_label, "modulate",
		_season_label.modulate, Color(1, 1, 1, alpha), duration,
		Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	_label_tween.start()
