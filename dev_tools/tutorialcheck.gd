extends SceneTree

# 新手引导全流程检查：强制读手记 → 种植 → 浇水 → 结束回合 → 虫子 → 读虫页 → 攻击 → 收尾。
# 用事件总线模拟“打出对应类型的牌”，种田与战斗的数值细节由其他测试覆盖。

var game = null
var flags = null
var gs = null
var steps = null
var guide = null
var tut = null
var start_ms = 0
var stage = 0
var stage_ms = 0
var problems = []


func _init():
	OS.window_size = Vector2(1080, 800)
	start_ms = OS.get_ticks_msec()
	stage_ms = start_ms
	flags = get_root().get_node("Flags")
	flags.skip_tutorial = false
	game = load("res://Game.tscn").instance()
	get_root().add_child(game)
	gs = get_root().get_node("GS")
	steps = get_root().get_node("TutorialSteps")


func _check(ok, msg):
	if not ok:
		problems.append(msg)


func _next(new_stage):
	stage = new_stage
	stage_ms = OS.get_ticks_msec()


func _elapsed():
	return OS.get_ticks_msec() - stage_ms


func _visible_toc():
	var toc = guide.get_node("Root/Book/Margin/VBox/Body/Toc")
	var n = 0
	for c in toc.get_children():
		if c is Button and c.visible:
			n += 1
	return n


func _hand_has(action):
	if gs.hand == null or not is_instance_valid(gs.hand):
		return false
	for c in gs.hand.get_children():
		if c.associated_card != null and c.associated_card.action == action:
			return true
	return false


func _finish():
	if problems.empty():
		print("TUTORIAL CHECK OK")
	else:
		for p in problems:
			print("TUTORIAL CHECK FAIL: " + p)
	quit()


func _idle(_delta):
	if game == null:
		return
	tut = game.get_node_or_null("CanvasLayer/Tutorial")
	guide = game.get_node_or_null("GuideBook")
	var t = OS.get_ticks_msec() - start_ms

	if stage == 0 and t >= 400:
		_check(gs.tutorial, "tutorial flag set")
		_check(tut != null, "tutorial node exists")
		_check(guide != null and guide.visible, "forced guide opened")
		if guide != null and guide.visible:
			_check(guide._restricted, "guide restricted")
			_check(_visible_toc() == 4, "only 4 pages during intro, got %d" % _visible_toc())
			_check(guide._close_button.disabled, "close disabled during intro")
			for i in [0, 1, 2, 3]:
				guide.select_chapter(i)
			guide.close()
			_check(not guide.visible, "forced guide closes after reading")
		_next(1)
		return

	if stage == 1 and _elapsed() >= 200:
		_check(tut.stage == 1, "stage PLANT, got %d" % tut.stage)
		_check(gs.turn_state == gs.TurnState.PLAYING_CARDS, "cards playable after reading")
		_check(gs.tutorial_allowed_action == "plant", "only plant allowed")
		_check(_hand_has(gs.Action.PLANT), "plant card in hand")
		steps.mark_have_planted()
		_next(2)
		return

	if stage == 2 and _elapsed() >= 200:
		_check(tut.stage == 2, "stage WATER, got %d" % tut.stage)
		_check(gs.tutorial_allowed_action == "water", "only water allowed")
		steps.mark_have_watered()
		_next(3)
		return

	if stage == 3 and _elapsed() >= 200:
		_check(tut.stage == 3, "stage END_TURN, got %d" % tut.stage)
		_check(gs.tutorial_allow_end_turn, "end turn unlocked")
		gs.end_turn()
		_next(4)
		return

	if stage == 4:
		if tut.stage == 4:
			_check(gs.tutorial_allow_end_turn == false, "end turn locked again for bug")
			var bugs = get_nodes_in_group("Enemy")
			_check(not bugs.empty(), "tutorial bug spawned")
			if not bugs.empty():
				_check(bugs[0].health == 1, "tutorial bug has 1 hp")
			_check(tut._next_button.visible, "read guide button visible")
			_check(tut._next_button.text == "翻开手记", "read guide button text")
			tut._on_NextButton_pressed()
			_next(5)
			return
		if _elapsed() >= 9000:
			problems.append("timed out waiting for bug stage, stage=%d state=%d"
				% [tut.stage, gs.turn_state])
			_finish()

	if stage == 5 and _elapsed() >= 200:
		_check(guide.visible and guide._restricted, "bug page opened in restricted mode")
		_check(_visible_toc() == 1, "only bug page visible, got %d" % _visible_toc())
		guide.select_chapter(6)
		guide.close()
		_next(6)
		return

	if stage == 6 and _elapsed() >= 200:
		_check(tut.stage == 5, "stage ATTACK, got %d" % tut.stage)
		_check(gs.tutorial_allowed_action == "attack", "only attack allowed")
		_check(_hand_has(gs.Action.ATTACK), "attack card in hand")
		steps.mark_have_attacked()
		_next(7)
		return

	if stage == 7 and _elapsed() >= 200:
		_check(tut.stage == 6, "stage FINAL, got %d" % tut.stage)
		_check(tut._next_button.visible and tut._next_button.text == "继续",
			"final continue button")
		tut._on_NextButton_pressed()
		_next(8)
		return

	if stage == 8 and _elapsed() >= 400:
		_check(not gs.tutorial, "tutorial flag cleared")
		_check(gs.tutorial_allowed_action == "", "action lock cleared")
		_check(game.get_node("CanvasLayer/Panel").visible, "HUD visible after tutorial")
		_check(not paused, "game unpaused after tutorial")
		_finish()
