extends SceneTree

# 载入真实 Game.tscn，检查 HUD / 季节 / 手牌，以及年度总结、暂停退出的暂停状态。

var _frames = 0
var _game = null


func _init():
	var flags = get_root().get_node_or_null("Flags")
	if flags != null:
		flags.skip_tutorial = true
	var packed = load("res://Game.tscn")
	_game = packed.instance()
	get_root().add_child(_game)


func _idle(_delta):
	_frames += 1
	if _frames != 30:
		return false

	var ok = true
	var hud = _game.get_node_or_null("CanvasLayer/Panel")
	if hud == null:
		print("FAIL: HUD missing")
		ok = false
	else:
		print("HUD: ", hud.get_class(), " script=", hud.get_script() != null)

	var season = get_root().get_node("Season")
	print("season: ", season.season_name(), " year ", season.year, " round ", season.round_in_year)

	var gs = get_root().get_node("GS")
	var hand_count = 0
	if gs.hand != null and is_instance_valid(gs.hand):
		hand_count = gs.hand.get_child_count()
	print("turn_state: ", gs.turn_state, " hand: ", hand_count)

	var bottle = get_root().get_node("BottleManager")
	var bestiary = get_root().get_node("EncyclopediaUI")
	print("ui roots: bottle=", bottle._root != null, " bestiary=", bestiary._root != null)

	# --- 图鉴羊皮纸风格 ---
	bestiary.open()
	if not bestiary._root.visible:
		print("FAIL: bestiary did not open")
		ok = false
	var title_color = bestiary._title.get_color("font_color", "Label")
	if bestiary._root.theme == null or not (title_color.r < 0.4 and title_color.g < 0.3):
		print("FAIL: bestiary not using parchment theme")
		ok = false
	bestiary.close()

	# --- 魔力球可见性（2026-11-25 曾因删节点残留 visible=false 被整颗藏掉） ---
	var orb = _game.get_node_or_null("CanvasLayer/EnergyOrbHolder/EnergyOrb")
	if orb == null or not orb.visible:
		print("FAIL: EnergyOrb (魔力球) missing or hidden")
		ok = false
	else:
		print("energy orb visible")

	# --- HUD 指南图标：打开时暂停，关闭时恢复 ---
	if hud != null:
		if hud._guide_button == null or hud._guide_button.icon == null:
			print("FAIL: HUD guide icon missing")
			ok = false
		else:
			hud._on_guide_pressed()
			var game_guide = _game.get_node_or_null("GuideBook")
			if game_guide == null or not (game_guide.visible and paused):
				print("FAIL: HUD guide did not open and pause")
				ok = false
			else:
				game_guide.close()
				if game_guide.visible or paused:
					print("FAIL: HUD guide close did not restore game")
					ok = false

				# 事件解锁新页：角标亮起，点头记直接翻到新页。
				var flags = get_root().get_node("Flags")
				flags.guide_season_changed = false
				flags.unlock_guide("guide_season_changed", 4, "四季会轮转")
				if hud._new_guide_index != 4 or not hud._guide_badge.visible:
					print("FAIL: guide badge did not light up")
					ok = false
				hud._on_guide_pressed()
				if game_guide._current != 4:
					print("FAIL: guide did not jump to new page, current=%d" % game_guide._current)
					ok = false
				if hud._guide_badge.visible or hud._new_guide_index != -1:
					print("FAIL: guide badge did not clear after reading")
					ok = false
				game_guide.close()

	# --- 农田规模 ---
	var tilemap = _game.get_node_or_null("TileMap")
	if tilemap != null:
		var plantable = 0
		for cell in tilemap.get_used_cells():
			if tilemap.get_cellv(cell) in [3, 7, 8, 9, 10]:
				plantable += 1
		# 开局应该只有中央 2x2 四格农田。
		print("farm: initial=", plantable)
		if plantable != 4:
			print("FAIL: initial farm should be 4 cells")
			ok = false

	# --- 年终总结 ---
	season.round_in_year = 24
	season.advance_round()
	var summary = get_root().get_node("YearSummary")
	if not (summary._root.visible and paused and season.year == 2):
		print("FAIL: year end summary not shown / not paused")
		ok = false
	else:
		print("year end: paused=", paused, " title=", summary._title.text.replace("\n", " "))
	summary._on_button_pressed()
	if paused or summary._root.visible:
		print("FAIL: year summary did not resume")
		ok = false
	else:
		print("year summary continue: paused=", paused)

	# --- 暂停 -> 退出 -> 中途总结 ---
	var pause_menu = _game.get_node_or_null("PauseMenu")
	if pause_menu == null:
		print("FAIL: PauseMenu missing")
		ok = false
	else:
		pause_menu.pause()
		var pause_guide = _game.get_node_or_null("GuideBook")
		if pause_guide == null:
			print("FAIL: pause guide missing")
			ok = false
		else:
			pause_menu._on_GuideButton_pressed()
			if not (pause_guide.visible and paused):
				print("FAIL: pause guide did not open while paused")
				ok = false
			pause_guide.close()
			if pause_guide.visible or not paused:
				print("FAIL: pause guide close broke pause state")
				ok = false
		pause_menu._on_QuitButton_pressed()
		if not (summary._root.visible and paused and summary._final):
			print("FAIL: quit summary not shown / not paused")
			ok = false
		else:
			print("quit summary: paused=", paused, " title=", summary._title.text)
		summary._on_button_pressed()
		if paused:
			print("FAIL: quit summary did not unpause")
			ok = false
		else:
			print("quit summary button: paused=", paused)

	print("FULL GAME CHECK OK" if ok else "FULL GAME CHECK FAILED")
	quit()
	return true