extends SceneTree
var game
var frames = 0
var stage = 0
var wait = 0
var season_mgr

func _init():
	print("init start")
	game = load("res://Game.tscn").instance()
	get_root().add_child(game)
	print("game added")

func _idle(_d):
	frames += 1
	if frames % 10 == 0:
		print("frames ", frames)
	if season_mgr == null:
		season_mgr = get_root().get_node_or_null("Season")
		if season_mgr == null:
			return
		print("season found")
	if frames < 20:
		return
	if OS.get_ticks_msec() < wait:
		return
	if stage > 3:
		quit()
		return
	if stage > 0:
		season_mgr.change_season(stage, false, true)
	var decor = game.get_node_or_null("TileMap/Decor")
	var paths = []
	if decor != null:
		for n in decor.get_children():
			if n is Sprite and n.texture != null and n.texture.resource_path.find("tree_") >= 0:
				paths.append(n.texture.resource_path)
				if paths.size() >= 4:
					break
	print("stage ", stage, " season=", season_mgr.current_season, " ", paths)
	stage += 1
	wait = OS.get_ticks_msec() + 250
