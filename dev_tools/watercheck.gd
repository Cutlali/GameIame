extends SceneTree

# 水壶 / 水桶 / 水管 的数值、形状与水晶球入库量检查。

var problems = []
var stage = 0
var start_ms = 0


func _init():
	start_ms = OS.get_ticks_msec()


func _check(ok, msg):
	if not ok:
		problems.append(msg)


func _idle(_delta):
	var t = OS.get_ticks_msec() - start_ms
	if stage != 0 or t < 100:
		return
	stage = 1
	var gs = get_root().get_node("GS")

	var can = gs.card_water1_2x2
	_check(can.title == "水壶", "can title")
	_check(can.cost == 3, "can keeps 3 cost")
	_check(can.water_shape == gs.Water.W2x2, "can is 2x2")
	_check(can.quantity == 2, "can waters 2 per tile")
	_check(can.orb_quantity == 4, "can banks 4")
	_check(can.desc.find("$DQ") >= 0, "can desc uses quantity placeholder")
	_check(can.desc.find("4") < 0, "can desc hides bank amount")

	var barrel = gs.card_water1_3x3
	_check(barrel.title == "水桶", "barrel title")
	_check(barrel.cost == 5, "barrel costs 5")
	_check(barrel.water_shape == gs.Water.W3x3, "barrel is 3x3")
	_check(barrel.quantity == 2, "barrel waters 2 per tile")
	_check(barrel.orb_quantity == 8, "barrel banks 8")
	_check(barrel.desc.find("$DQ") >= 0, "barrel desc uses quantity placeholder")
	_check(barrel.desc.find("8") < 0, "barrel desc hides bank amount")

	var hose = gs.card_water2_2x2
	_check(hose.title == "水管", "hose title")
	_check(hose.cost == 2, "hose costs 2")
	_check(hose.water_shape == gs.Water.W1x2, "hose is 1x2")
	_check(hose.quantity == 2, "hose waters 2 per tile")
	_check(hose.orb_quantity == 3, "hose banks 3")
	_check(hose.desc.find("1x2") >= 0, "hose desc says 1x2")
	_check(hose.desc.find("3") < 0, "hose desc hides bank amount")

	var rain = gs.card_water5
	_check(rain.title == "降雨", "rain title")
	_check(rain.cost == 3 and rain.quantity == 5, "rain unchanged")
	_check(rain.water_shape == gs.Water.W1x1, "rain unchanged shape")
	_check(rain.orb_quantity == 0, "rain banks its quantity")

	# 倒进水晶球：存入 orb_quantity，浇地时仍用 quantity。
	gs.orb_water = 0
	gs.energy = 7
	_check(gs.play_water_into_orb(can), "can played into orb")
	_check(gs.orb_water == 4, "can stored 4, got %d" % gs.orb_water)
	_check(gs.energy == 4, "can spent 3 energy, got %d" % gs.energy)

	gs.orb_water = 0
	gs.energy = 7
	_check(gs.play_water_into_orb(barrel), "barrel played into orb")
	_check(gs.orb_water == 8, "barrel stored 8, got %d" % gs.orb_water)
	_check(gs.energy == 2, "barrel spent 5 energy, got %d" % gs.energy)

	gs.orb_water = 0
	gs.energy = 7
	_check(gs.play_water_into_orb(hose), "hose played into orb")
	_check(gs.orb_water == 3, "hose stored 3, got %d" % gs.orb_water)
	_check(gs.energy == 5, "hose spent 2 energy, got %d" % gs.energy)

	var cursor_scene = load("res://cursor/Cursor.tscn").instance()
	var node = cursor_scene.get_node_or_null("CursorWater1x2")
	_check(node != null, "cursor has 1x2 shape")
	if node != null:
		_check(node.texture != null, "cursor 1x2 texture loaded")
	cursor_scene.free()

	if problems.empty():
		print("WATER CHECK OK")
	else:
		for p in problems:
			print("WATER CHECK FAIL: " + p)
	quit()
