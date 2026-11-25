extends TileMap

# 初始农田只有中央 2x2 四格。图鉴里程碑发放"开垦名额"，
# 玩家在任意一片泥地上自选 2×2 位置开垦（v1.8 改，旧的东南西北四块固定地仅作存档迁移用）。
# 每开垦一块：农田 +2x2，同时手牌上限 +1、能量上限 +1，保证新田真的能种得过来。

const GROUND_TILES = [1, 4, 5, 6]

const INITIAL_CELLS = [
	Vector2(-2, -3), Vector2(-1, -3),
	Vector2(-2, -2), Vector2(-1, -2)
]

# 顺序按“西、东、北、南”排列，UI 会按方位摆成十字。
const PARCELS = [
	{"name": "西侧空地", "cells": [
		Vector2(-4, -3), Vector2(-3, -3),
		Vector2(-4, -2), Vector2(-3, -2)]},
	{"name": "东侧空地", "cells": [
		Vector2(0, -3), Vector2(1, -3),
		Vector2(0, -2), Vector2(1, -2)]},
	{"name": "北侧空地", "cells": [
		Vector2(-2, -5), Vector2(-1, -5),
		Vector2(-2, -4), Vector2(-1, -4)]},
	{"name": "南侧空地", "cells": [
		Vector2(-2, -1), Vector2(-1, -1),
		Vector2(-2, 0), Vector2(-1, 0)]}
]

# 耕地边缘过渡层：在每块耕地的外沿叠加一圈当季地面颜色的抖动渐变，
# 避免耕地四季都像一个硬边矩形贴在地上。
const EDGE_DIRS = [
	{"name": "FarmEdgeN", "offset": Vector2(0, -1), "file": "farm_edge_n.png"},
	{"name": "FarmEdgeE", "offset": Vector2(1, 0), "file": "farm_edge_e.png"},
	{"name": "FarmEdgeS", "offset": Vector2(0, 1), "file": "farm_edge_s.png"},
	{"name": "FarmEdgeW", "offset": Vector2(-1, 0), "file": "farm_edge_w.png"}
]

var _edge_maps = []
var claimed_plots = []

# 开垦模式的光标虚影：2×2 绿框可垦，红框不行。
class PlotGhost extends Node2D:
	var host

	func _process(_d):
		host._ghost_origin = host.world_to_map(get_global_mouse_position())
		update()

	func _draw():
		var ok = host.can_claim_plot(host._ghost_origin)
		var fill = Color(0.45, 0.85, 0.50, 0.32) if ok else Color(0.85, 0.35, 0.30, 0.26)
		var edge = Color(0.60, 1.00, 0.65, 0.95) if ok else Color(1.00, 0.55, 0.50, 0.90)
		var r = Rect2(host._ghost_origin * host.cell_size, host.cell_size * 2.0)
		draw_rect(r, fill)
		draw_rect(r, edge, false, 4.0)

var plot_ghost = null
var _ghost_origin = Vector2(-9999, -9999)


# Called when the node enters the scene tree for the first time.
func _ready():
	GS.tilemap = self
	claimed_plots = []
	# 防御：上一场可能带着未退出的开垦模式离场。
	FarmChoiceUI.end_placement()
	setup_farmland_tiles()
	prepare_initial_farm()
	setup_farm_edges()
	rebuild_farm_edges()
	Season.bind_tilemap(self)
	# v1.8：农场场景挂"游戏循环"当 BGM。
	Music.set_mode("game")
	# "继续农场"进来时，等整个场景 ready 完再把存档里的耕地与历法盖回去。
	if SaveGame.pending_run_restore:
		SaveGame.call_deferred("apply_run")

# The four seamless farmland tiles are guaranteed to exist at runtime even if
# the scene file was saved with the old tileset, so the farm plot always uses
# the tilled-soil art instead of the rounded placeholder patches.
func setup_farmland_tiles():
	var ids = tile_set.get_tiles_ids()
	for i in range(4):
		var id = 7 + i
		if id in ids:
			continue
		tile_set.create_tile(id)
		tile_set.tile_set_texture(id, load("res://farm/farmland_%d.png" % (i + 1)))
		tile_set.tile_set_region(id, Rect2(0, 0, 128, 128))
		tile_set.tile_set_tile_mode(id, TileSet.TILE_MODE_SINGLE)
		tile_set.tile_set_texture_offset(id, Vector2.ZERO)

# 场景里原有的农田（包括旧的 11 格和 Up1/Up2）全部还原成普通泥地，
# 只保留中央四格。这样开局就是四块田，其他土地等玩家自己选。
func prepare_initial_farm():
	for cell in get_used_cells():
		var id = get_cellv(cell)
		if id == 3 or (id >= 7 and id <= 10):
			set_cellv(cell, ground_variant(cell))
	for cell in INITIAL_CELLS:
		set_cellv(cell, farmland_variant(cell))

func ground_variant(cell):
	var n = int(abs(cell.x * 5 + cell.y * 11))
	return GROUND_TILES[n % GROUND_TILES.size()]

func count_plantable():
	var n = 0
	for cell in get_used_cells():
		var id = get_cellv(cell)
		if id >= 7 and id <= 10:
			n += 1
	return n


# ---- v1.8 自由开垦 ----

func plot_cells(origin):
	return [origin, origin + Vector2(1, 0), origin + Vector2(0, 1), origin + Vector2(1, 1)]


# 2×2 全部是未开垦的泥地、且没有植物/虫子站上面，才算可选。
func can_claim_plot(origin):
	if GS.farm_quota <= 0:
		return false
	for cell in plot_cells(origin):
		var id = get_cellv(cell)
		if not (id in GROUND_TILES):
			return false
		if GS.get_plant_at_map_lcoord(cell * 128) != null:
			return false
		if GS.get_enemy_at_map_lcoord(cell * 128) != null:
			return false
	return true


# 以 origin 为左上角开垦一块 2×2。返回 false 表示没有名额或位置不合法。
func claim_plot(origin):
	if not can_claim_plot(origin):
		return false
	for cell in plot_cells(origin):
		set_cellv(cell, farmland_variant(cell))
	claimed_plots.append(origin)
	GS.farm_quota -= 1
	_apply_plot_bonuses()
	rebuild_farm_edges()
	SaveGame.save_now()
	Toast.show_message("新垦一块 2×2 农田（剩余名额 %d）" % GS.farm_quota)
	if GS.farm_quota <= 0:
		FarmChoiceUI.end_placement()
	return true


func _apply_plot_bonuses():
	# v1.8 第四轮：手牌上限封顶 6，开垦不再加抽牌，只加能量上限——
	# 新田的"种得过来"靠能量，不靠更鼓的手牌。
	var before = GS.energy_max
	GS.add_permanent_energy(1)
	if GS.turn_state == GS.TurnState.PLAYING_CARDS and GS.energy_max > before:
		GS.energy = min(GS.energy + 1, GS.energy_max)


# 兼容旧存档/旧检查：把固定地块序号转成左上角并直接垦掉（不占名额）。
func legacy_parcel_origin(index):
	if index < 0 or index >= PARCELS.size():
		return null
	return PARCELS[index]["cells"][0]


func claim_parcel(index):
	var origin = legacy_parcel_origin(index)
	if origin == null or origin in claimed_plots:
		return false
	for cell in PARCELS[index]["cells"]:
		set_cellv(cell, farmland_variant(cell))
	claimed_plots.append(origin)
	_apply_plot_bonuses()
	rebuild_farm_edges()
	SaveGame.save_now()
	return true


# ---- 开垦放置模式（UI 由 FarmChoiceUI 驱动，这里负责虚影与点击） ----

func _ensure_ghost():
	if plot_ghost != null and is_instance_valid(plot_ghost):
		return
	plot_ghost = PlotGhost.new()
	plot_ghost.name = "PlotGhost"
	plot_ghost.host = self
	plot_ghost.z_index = 60
	add_child(plot_ghost)


func enter_plot_mode():
	_ensure_ghost()
	plot_ghost.visible = true


func exit_plot_mode():
	if plot_ghost != null and is_instance_valid(plot_ghost):
		plot_ghost.visible = false


func _unhandled_input(event):
	if not GS.farm_choice_open:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_LEFT:
			var origin = world_to_map(get_global_mouse_position())
			if not claim_plot(origin):
				if GS.farm_quota > 0:
					Toast.show_message("这里不能开垦：需要四格连片的空地，且不能压住植物或虫子。")
			elif GS.farm_quota <= 0:
				FarmChoiceUI.end_placement()
		elif event.button_index == BUTTON_RIGHT:
			FarmChoiceUI.end_placement()
	elif event.is_action_pressed("ui_cancel"):
		FarmChoiceUI.end_placement()


func setup_farm_edges():
	_edge_maps.clear()
	for d in EDGE_DIRS:
		var em = get_node_or_null(d["name"])
		if em == null:
			em = TileMap.new()
			em.name = d["name"]
			add_child(em)
		em.cell_size = cell_size
		em.z_index = 0
		var ts = TileSet.new()
		ts.create_tile(1)
		ts.tile_set_texture(1, load("res://farm/" + d["file"]))
		ts.tile_set_region(1, Rect2(Vector2.ZERO, cell_size))
		ts.tile_set_tile_mode(1, 0) # TILE_MODE_SINGLE
		em.tile_set = ts
		_edge_maps.append({"map": em, "offset": d["offset"]})


func rebuild_farm_edges():
	if _edge_maps.empty():
		return
	for entry in _edge_maps:
		entry["map"].clear()

	var farm = {}
	for cell in get_used_cells():
		var id = get_cellv(cell)
		if id >= 7 and id <= 10:
			farm[cell] = true

	for cell in farm:
		for entry in _edge_maps:
			if not farm.has(cell + entry["offset"]):
				entry["map"].set_cellv(cell, 1)

# Pick one of the four seamless farmland tiles (7-10) deterministically so the
# plot keeps its variation after unlocking.
func farmland_variant(cell):
	return 7 + posmod(cell.x * 7 + cell.y * 13, 4)
