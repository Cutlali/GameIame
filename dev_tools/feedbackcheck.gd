extends SceneTree

# 开发工具：音效与收获图片反馈检查。
# 用法：
#   Godot --path <project> --script res://dev_tools/feedbackcheck.gd
# 检查新增音效节点、变异音效触发、收获图片显示、年终音效触发。

const OUT_DIR = "D:/Godot/"

var game = null
var started = false
var frames = 0
var stage = 0
var wait_until = 0
var failures = []

var sfx = null
var season = null
var run_stats = null
var harvest = null
var year_summary = null


func _idle(_delta):
	frames += 1
	if not started:
		if frames < 3:
			return
		started = true
		sfx = get_root().get_node("SFX")
		season = get_root().get_node("Season")
		run_stats = get_root().get_node("RunStats")
		harvest = get_root().get_node("HarvestManager")
		year_summary = get_root().get_node("YearSummary")
		get_root().get_node("Flags").skip_tutorial = true
		game = load("res://Game.tscn").instance()
		get_root().add_child(game)
		return

	if frames < 40:
		return
	if OS.get_ticks_msec() < wait_until:
		return

	match stage:
		0:
			_check_sfx_nodes()
			_open_variant()
			stage = 1
			wait_until = OS.get_ticks_msec() + 300
		1:
			_shot("feedback_mutation")
			_check_variant_popup()
			harvest.force_close()
			stage = 2
			wait_until = OS.get_ticks_msec() + 150
		2:
			_check_year_end_sfx()
			stage = 3
			wait_until = OS.get_ticks_msec() + 1200
		3:
			# 年终总结会暂停场景树，音效播放器必须保持 PROCESS，不能刚响就被掐掉。
			if not sfx.year_end.playing:
				failures.append("year end sfx stopped while tree paused")
			_shot("feedback_year_end")
			_report()
			quit()


func _check_sfx_nodes():
	for n in ["YearEnd", "Mutation"]:
		var p = sfx.get_node_or_null(n)
		if p == null:
			failures.append("sfx node missing: " + n)
		elif p.stream == null:
			failures.append("sfx stream missing: " + n)
	if sfx.year_end == null:
		failures.append("SFX.year_end reference missing")
	if sfx.mutation == null:
		failures.append("SFX.mutation reference missing")
	print("sfx nodes: YearEnd/Mutation loaded")


func _open_variant():
	run_stats.mutation_pity = 7
	var plant = load("res://plants/plant1/Plant1.tscn").instance()
	plant.species_id = "tomato"
	game.get_node("TileMap").add_child(plant)
	plant.position = Vector2(0, 0)

	var eid = plant.resolve_entry_id()
	if eid.find("_v") < 0:
		failures.append("forced mutation did not produce variant id")
	if not sfx.mutation.playing:
		failures.append("mutation sfx did not start")

	harvest.handle_harvest(plant)
	if not harvest._root.visible:
		failures.append("variant harvest popup did not open")
	print("variant entry: " + eid)


func _check_variant_popup():
	if harvest._photo == null or harvest._photo.texture == null:
		failures.append("harvest popup photo missing")
	if harvest._photo_caption == null or harvest._photo_caption.text.find("茄科") < 0:
		failures.append("harvest popup photo caption wrong")
	if harvest._title.text.find("变异") < 0:
		failures.append("variant title missing")
	print("variant popup: title=%s, caption=%s" % [
		harvest._title.text, harvest._photo_caption.text])


func _check_year_end_sfx():
	season.round_in_year = 24
	var before = season.year
	season.advance_round()
	if season.year != before + 1:
		failures.append("year did not advance")
	if not year_summary._root.visible:
		failures.append("year summary did not show")
	if not sfx.year_end.playing:
		failures.append("year end sfx did not start")
	print("year end: %d -> %d, summary=%s, sfx=%s" % [
		before, season.year, str(year_summary._root.visible), str(sfx.year_end.playing)])


func _shot(name):
	var img = get_root().get_texture().get_data()
	if img == null:
		return
	img.flip_y()
	img.save_png(OUT_DIR + name + ".png")
	print("saved " + name + ".png")


func _report():
	if failures.empty():
		print("FEEDBACK CHECK OK")
	else:
		print("FEEDBACK CHECK FAILED:")
		for f in failures:
			print(" - " + f)