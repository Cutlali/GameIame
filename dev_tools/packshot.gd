extends SceneTree

# 开发工具：预览 Pixel Crawler 素材包树木替换后的四季效果。
# 只在本脚本内临时换图，不改动工程里的正式素材。
# 用法：
#   Godot --path <project> --script res://dev_tools/packshot.gd
# 输出：D:/Godot/pack_spring.png、pack_summer.png、pack_autumn.png、pack_winter.png

const OUT_DIR = "D:/Godot/"
const CAM_POS = Vector2(0, -480)
const CAM_ZOOM = 1.3
const TREE_CAM_POS = Vector2(-1000, -1050)
const TREE_CAM_ZOOM = 0.8
const SEASONS = ["spring", "summer", "autumn", "winter"]
const FARM_FILES = [
	"dirt_pixel.png", "grass_pixel.png", "plant_spot.png",
	"dirt_pixel_2.png", "dirt_pixel_3.png", "dirt_pixel_4.png",
	"farmland_1.png", "farmland_2.png", "farmland_3.png", "farmland_4.png"
]
const TREE_FILES = ["tree_big.png", "tree_small.png", "tree_pine.png"]

var game = null
var map = null
var season_mgr = null
var frames = 0
var stage = 0
var wait_until = 0
var applied = false


func _init():
	game = load("res://Game.tscn").instance()
	get_root().add_child(game)
	var ui = game.get_node_or_null("CanvasLayer")
	if ui != null:
		ui.visible = false
	var cards = game.get_node_or_null("Camera/Cards")
	if cards != null:
		cards.visible = false


func _idle(_delta):
	frames += 1

	if season_mgr == null:
		season_mgr = get_root().get_node_or_null("Season")
		if season_mgr == null:
			if frames > 200:
				print("Season autoload not found")
				quit()
			return
		var hud = season_mgr.get("_hud_layer")
		if hud != null:
			hud.visible = false

	if frames == 8:
		var cam = game.get_node_or_null("Camera")
		if cam != null:
			cam.position = CAM_POS
			cam.zoom = Vector2(CAM_ZOOM, CAM_ZOOM)
		map = game.get_node_or_null("TileMap")

	if frames < 24:
		return

	if stage >= SEASONS.size():
		quit()
		return

	if OS.get_ticks_msec() < wait_until:
		return

	if not applied:
		_apply(SEASONS[stage])
		applied = true
		wait_until = OS.get_ticks_msec() + 900
	else:
		_capture_view("pack_%s_trees" % SEASONS[stage], TREE_CAM_POS, TREE_CAM_ZOOM)
		_capture_view("pack_%s_board" % SEASONS[stage], CAM_POS, CAM_ZOOM)
		stage += 1
		applied = false
		wait_until = OS.get_ticks_msec() + 300


func _apply(season):
	if map == null:
		return
	for i in range(FARM_FILES.size()):
		var id = i + 1
		var path = "res://farm/" + FARM_FILES[i]
		if season != "spring":
			path = "res://seasons/%s/farm/%s" % [season, FARM_FILES[i]]
		if ResourceLoader.exists(path) and id in map.tile_set.get_tiles_ids():
			map.tile_set.tile_set_texture(id, load(path))

	var decor = map.get_node_or_null("Decor")
	if decor == null:
		return
	for node in decor.get_children():
		if not (node is Sprite) or node.texture == null:
			continue
		var file = node.texture.resource_path.get_file()
		if file in TREE_FILES:
			var p = "res://seasons_pack/%s/decor/%s" % [season, file]
			if ResourceLoader.exists(p):
				var tex = load(p)
				node.texture = tex
				node.offset = Vector2(0, -tex.get_height() / 2.0)
	print("applied " + season)


func _capture_view(name, pos, zoom):
	var cam = game.get_node_or_null("Camera")
	if cam != null:
		cam.position = pos
		cam.zoom = Vector2(zoom, zoom)
	VisualServer.force_draw()
	VisualServer.force_draw()
	var img = get_root().get_texture().get_data()
	img.flip_y()
	img.save_png(OUT_DIR + name + ".png")
	print("saved " + name + ".png")