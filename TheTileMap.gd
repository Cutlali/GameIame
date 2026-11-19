extends TileMap


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	GS.tilemap = self
	setup_farmland_tiles()
	convert_plant_spots()

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

# Legacy plantable cells used tile id 3; swap them for the seamless soil.
func convert_plant_spots():
	for cell in get_used_cells():
		if get_cellv(cell) == 3:
			set_cellv(cell, farmland_variant(cell))

func up1():
	for t in $Up1.get_used_cells():
		set_cellv(t, farmland_variant(t))

func up2():
	for t in $Up2.get_used_cells():
		set_cellv(t, farmland_variant(t))

# Pick one of the four seamless farmland tiles (7-10) deterministically so the
# plot keeps its variation after unlocking.
func farmland_variant(cell):
	return 7 + posmod(cell.x * 7 + cell.y * 13, 4)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
