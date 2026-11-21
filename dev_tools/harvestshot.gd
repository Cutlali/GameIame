extends SceneTree

# 截一张收获二选一面板的图，检查排版与字体。

var frames = 0
var started = false
var game = null
var planted = false


func _idle(_delta):
	frames += 1
	if not started:
		if frames < 3:
			return
		started = true
		get_root().get_node("Flags").skip_tutorial = true
		game = load("res://Game.tscn").instance()
		get_root().add_child(game)
		return

	if frames < 45:
		return

	if not planted:
		planted = true
		var plant = load("res://plants/plant1/Plant1.tscn").instance()
		plant.species_id = "tomato"
		game.get_node("TileMap").add_child(plant)
		plant.position = Vector2(0, 0)
		get_root().get_node("HarvestManager").handle_harvest(plant)
		return

	var img = get_root().get_texture().get_data()
	img.flip_y()
	img.save_png("D:/Godot/newloop_harvest.png")
	print("saved newloop_harvest.png")
	quit()