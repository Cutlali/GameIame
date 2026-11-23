extends SceneTree

# 图鉴详情滚动检查：长文本不能溢出面板，纵向滚动条要能滚。

var problems = []
var stage = 0
var start_ms = 0
var ui = null
var scroll = null


func _init():
	OS.window_size = Vector2(1080, 800)
	start_ms = OS.get_ticks_msec()


func _check(ok, msg):
	if not ok:
		problems.append(msg)


func _save(path):
	var img = get_root().get_texture().get_data()
	img.flip_y()
	img.save_png(path)
	print("saved " + path)


func _idle(_delta):
	var t = OS.get_ticks_msec() - start_ms
	if stage == 0 and t >= 100:
		stage = 1
		var gs = get_root().get_node("GS")
		var enc = get_root().get_node("Encyclopedia")
		var gamedata = get_root().get_node("GameData")
		ui = get_root().get_node("EncyclopediaUI")

		gs.waiting_for_card_selection = false
		gs.shatter_open = false
		gs.harvest_open = false
		gs.bottle_open = false
		gs.year_summary_open = false
		gs.farm_choice_open = false
		gs.bestiary_open = false
		enc.reset_all()
		for id in gamedata.all_entry_ids():
			enc.discovered[id] = true

		ui.open()
		_check(ui._root.visible, "bestiary visible")
		scroll = ui._detail.get_parent()
		_check(scroll is ScrollContainer, "detail sits in a ScrollContainer")
		if scroll is ScrollContainer:
			_check(not scroll.scroll_horizontal_enabled, "horizontal scroll disabled")
			_check(scroll.get_v_scrollbar() != null, "vertical scrollbar exists")
		return

	if stage == 1 and t >= 500:
		stage = 2
		# 选一条 lore 最长的条目，确认详情可以纵向滚动。
		ui._show_detail("moonflower_v0")
		return

	if stage == 2 and t >= 900:
		stage = 3
		_check(ui._detail.text.length() > 120, "detail text is long")
		var bar = scroll.get_v_scrollbar()
		_check(bar.max_value > bar.page, "long detail overflows and can scroll")
		scroll.scroll_vertical = 100000
		return

	if stage == 3 and t >= 1300:
		stage = 4
		_check(scroll.scroll_vertical > 0, "vertical scroll moves")
		_save("D:/Godot/bestiary_scroll.png")
		ui.close()
		if problems.empty():
			print("BESTIARY CHECK OK")
		else:
			for p in problems:
				print("BESTIARY CHECK FAIL: " + p)
		quit()
