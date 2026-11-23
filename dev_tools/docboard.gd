extends SceneTree

# 拍一张有植物的游戏内画面，给创作手记配图。
# 运行：Godot --path . --script res://dev_tools/docboard.gd

var game = null
var start_ms = 0
var stage = 0
var plants = []

const CELLS = [Vector2(-2, -3), Vector2(-1, -3), Vector2(-2, -2), Vector2(-1, -2)]
const SPECIES = ["tomato", "sunflower", "pumpkin", "moonflower"]
const FRAMES = [3, 5, 4, 6]


func _init():
	OS.window_size = Vector2(1080, 800)
	start_ms = OS.get_ticks_msec()


func _save(path):
	var img = get_root().get_texture().get_data()
	img.flip_y()
	img.save_png(path)
	print("saved " + path)


func _idle(_delta):
	var t = OS.get_ticks_msec() - start_ms

	if stage == 0 and t >= 100:
		get_root().get_node("Flags").skip_tutorial = true
		game = load("res://Game.tscn").instance()
		get_root().add_child(game)
		stage = 1
		return
	if stage == 1 and t >= 1200:
		var cam = game.get_node("Camera")
		cam.zoom = Vector2(1.05, 1.05)
		cam.position = Vector2(-128, -40)
		var map = game.get_node("TileMap")
		var gd = get_root().get_node("GameData")
		for i in range(CELLS.size()):
			var sp = gd.species(SPECIES[i])
			if sp == null:
				continue
			var cell = CELLS[i]
			var p = load(sp["scene"]).instance()
			p.species_id = SPECIES[i]
			p.mutation_rolled = true
			p.health = sp["health"]
			p.water = 2
			p.defense = 1 if i == 1 else 0
			map.add_child(p)
			p.position = map.map_to_world(cell)
			p.call("advance_growth", FRAMES[i])
			plants.append(p)
		stage = 2
		return
	if stage == 2 and t >= 2600:
		_save("D:/Godot/doc_board.png")
		stage = 3
		return
	if stage == 3 and t >= 3200:
		quit()