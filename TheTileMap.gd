extends TileMap

# 初始农田只有中央 2x2 四格。图鉴里程碑会让玩家从四块空地中选一块开垦。
# 每开垦一块：农田 +2x2，同时每轮抽牌 +1、能量上限 +1，保证新田真的能种得过来。

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
var claimed_parcels = []


# Called when the node enters the scene tree for the first time.
func _ready():
	GS.tilemap = self
	claimed_parcels = []
	setup_farmland_tiles()
	prepare_initial_farm()
	setup_farm_edges()
	rebuild_farm_edges()
	Season.bind_tilemap(self)

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


# 返回 false 表示这块地已经开垦过或索引无效。
func claim_parcel(index):
	if index < 0 or index >= PARCELS.size():
		return false
	if index in claimed_parcels:
		return false

	for cell in PARCELS[index]["cells"]:
		set_cellv(cell, farmland_variant(cell))
	claimed_parcels.append(index)

	# 新田需要配套的照顾能力，否则只会多出一块空地。
	# 抽牌解决“有没有牌”，能量上限解决“打不打得出去”。
	GS.bonus_draws += 1
	GS.energy_max += 1
	if GS.turn_state == GS.TurnState.PLAYING_CARDS:
		GS.energy = min(GS.energy + 1, GS.energy_max)

	rebuild_farm_edges()
	return true


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
