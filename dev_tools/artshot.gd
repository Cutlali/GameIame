extends SceneTree

# 开发工具：像素素材的场景内验收截图。
# 用法：
#   Godot --path <project> --user-dir rt_artshot --script res://dev_tools/artshot.gd
# 输出：D:/Godot/artshot_farm1..5.png / artshot_bugs.png / artshot_power.png
#      / artshot_hand.png / artshot_enc.png
# 15 个物种分 5 张拍（每批 3 个，沿用已验收的三格坐标），
# 虫类另拍一张 1:1 对照，魔瓶技能满能时再拍一张 HUD。

const OUT_DIR = "D:/Godot/"

# 每批三格：场景路径、物种 id、坐标。
# 坐标排成相邻的一行，配合 _frame_plants 的固定机位，
# 截图里植株必然落在画面中央同一个方块内，方便程序化裁图验收。
# 每批三格的落点。Camera 由 Game 里的脚本自己维护，
# 在 artshot 里改 cam.position/zoom 会被覆盖，所以沿用历届验收截图都在用的
# 这三个坐标与机位，保证作物一定落在画面可视区里。
const CELL_ROW = [Vector2(-256, -128), Vector2(0, -64), Vector2(256, -128)]
const BUG_ROW = [Vector2(-320, -170), Vector2(-110, -170), Vector2(100, -170), Vector2(310, -170)]

const GROUPS = [
	[["res://plants/plant1/Plant1.tscn", "tomato"],
	 ["res://plants/plant2/Plant2.tscn", "sunflower"],
	 ["res://plants/plant4/Plant4.tscn", "cotton"]],
	[["res://plants/plant3/Plant3.tscn", "pumpkin"],
	 ["res://plants/plant5/Plant5.tscn", "rice"],
	 ["res://plants/plant6/Plant6.tscn", "wintersweet"]],
	[["res://plants/winplant/WinPlant.tscn", "moonflower"],
	 ["res://plants/plant7/Plant7.tscn", "wheat"],
	 ["res://plants/plant8/Plant8.tscn", "mint"]],
	[["res://plants/plant9/Plant9.tscn", "flax"],
	 ["res://plants/plant10/Plant10.tscn", "soybean"],
	 ["res://plants/plant11/Plant11.tscn", "maize"]],
	[["res://plants/plant12/Plant12.tscn", "potato"],
	 ["res://plants/plant13/Plant13.tscn", "sugarcane"],
	 ["res://plants/plant14/Plant14.tscn", "saffron"]],
]

var frames = 0
var started = false
var game = null
var bugs = []
var steps = []
var next_at = 50
var group_index = 0


func _idle(_delta):
	frames += 1
	if not started:
		if frames < 3:
			return
		started = true
		get_root().get_node("Flags").skip_tutorial = true
		game = load("res://Game.tscn").instance()
		get_root().add_child(game)
		steps = []
		for i in range(GROUPS.size()):
			steps.append(funcref(self, "_farm_setup"))
			steps.append(funcref(self, "_farm_shot"))
		steps.append(funcref(self, "_bugs_setup"))
		steps.append(funcref(self, "_bugs_shot"))
		steps.append(funcref(self, "_power_setup"))
		steps.append(funcref(self, "_power_shot"))
		steps.append(funcref(self, "_hand_setup"))
		steps.append(funcref(self, "_hand_shot"))
		steps.append(funcref(self, "_enc_setup"))
		steps.append(funcref(self, "_enc_shot"))
		return

	if steps.empty() or frames < next_at:
		return
	var step = steps.pop_front()
	step.call_func()
	next_at = frames + 12


func _frame_row():
	# 沿用历轮验收的机位（Camera 自己会覆盖这里，实际以画面里的可视区为准）。
	var cam = game.get_node_or_null("Camera")
	if cam != null:
		cam.position = Vector2(64, 120)
		cam.zoom = Vector2(1.35, 1.35)


func _farm_setup():
	_frame_row()
	_clear_plants()
	var group = GROUPS[group_index]
	group_index += 1
	for i in range(group.size()):
		var p = group[i]
		var pl = load(p[0]).instance()
		pl.species_id = p[1]
		game.get_node("TileMap").add_child(pl)
		pl.position = CELL_ROW[i]
		var spr = pl.get_node("Plant")
		spr.animation = "default"
		spr.stop()
		spr.frame = pl.max_growth_frame()


func _clear_plants():
	# Plant.gd 没有 class_name，只能按脚本比对认出植物节点。
	var plant_script = load("res://plants/Plant.gd")
	for child in game.get_node("TileMap").get_children():
		if child.get_script() == plant_script:
			child.queue_free()


func _farm_shot():
	_capture("artshot_farm%d" % group_index)


func _bugs_setup():
	_frame_row()
	_clear_plants()
	_clear_bugs()
	# 四档虫 1:1 并排，用来核对巨虫和同规模画布下的视觉体重。
	# Bug._ready 按 is_giant / is_elite / health 选贴图，所以标记要在入树之前设好。
	var defs = [
		[2, 0, {}],
		[5, 1, {}],
		[10, 2, {}],
		[14, 3, {"giant": true}],
	]
	bugs = []
	for d in defs:
		var bug = load("res://bugs/Bug.tscn").instance()
		bug.health = d[0]
		if d[2].has("giant"):
			bug.is_giant = true
		game.get_node("TileMap").add_child(bug)
		bug.position = BUG_ROW[d[1]]
		bug.spawned = true
		bugs.append(bug)


func _bugs_shot():
	_show_bugs()
	_capture("artshot_bugs")


func _power_setup():
	_frame_row()
	var bm = get_root().get_node("BottleManager")
	bm.power = bm.MAX_POWER
	var gs = get_root().get_node("GS")
	gs.energy = gs.energy_max


func _power_shot():
	# HUD 在 _process 里轮询瓶能，给一帧时间刷新。
	_capture("artshot_power")


func _hand_setup():
	var gs = get_root().get_node("GS")
	# 手牌上限 5/6 是“跨回合携带上限”，新回合还会固定再发 3 张，
	# 所以真实最大手牌是 8 张。验收图按 8 张拍，别用测试强塞到 11 张
	# 把右下角的结束回合按钮压住。
	if gs.hand != null and is_instance_valid(gs.hand):
		for c in gs.hand.get_children():
			gs.hand.remove_child(c)
			c.queue_free()
	for cid in ["water_drop", "whack", "basic_plant", "wheat_seed",
			"maize_seed", "saffron_seed", "trapper", "queen_sting"]:
		var c = gs.card_by_id(cid)
		if c != null:
			gs.add_card_to_hand(c)


func _hand_shot():
	_capture("artshot_hand")


func _enc_setup():
	var enc = get_root().get_node("Encyclopedia")
	for sid in get_root().get_node("GameData").SPECIES_ORDER:
		enc.discover(sid)
		enc.discover(sid + "_v0")
		enc.discover(sid + "_v1")
	var ui = get_root().get_node("EncyclopediaUI")
	ui.open()


func _enc_shot():
	_capture("artshot_enc")
	quit()


func _show_bugs():
	# RESET 停帧后虫贴图缩成 1e-05，截图前手动回落到出生完成态。
	for bug in bugs:
		if is_instance_valid(bug):
			bug.get_node("Sprite").scale = Vector2(1, 1)
			bug.get_node("HeartMarker").scale = Vector2(1, 1)
			bug.update()


func _clear_bugs():
	for e in get_nodes_in_group("Enemy"):
		e.queue_free()
		e.get_parent().remove_child(e)


func _capture(name):
	VisualServer.force_draw()
	VisualServer.force_draw()
	var img = get_root().get_texture().get_data()
	img.flip_y()
	img.save_png(OUT_DIR + name + ".png")
	print("saved " + name + ".png")
