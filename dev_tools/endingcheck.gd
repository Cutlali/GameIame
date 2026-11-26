extends SceneTree

# 终局检查：集齐图鉴必出“最后的种子”，种下后成熟进入结局分镜。

var problems = []
var stage = 0
var start_ms = 0


func _init():
	OS.window_size = Vector2(1080, 800)
	start_ms = OS.get_ticks_msec()


func _check(ok, msg):
	if not ok:
		problems.append(msg)


func _find_label(node, needle):
	if node is Label and node.text.find(needle) >= 0:
		return true
	for c in node.get_children():
		if _find_label(c, needle):
			return true
	return false


func _clear_hand(hand):
	for c in hand.get_children():
		hand.remove_child(c)
		c.queue_free()


func _idle(_delta):
	if stage != 0:
		return
	if OS.get_ticks_msec() - start_ms < 120:
		return
	stage = 1

	var gs = get_root().get_node("GS")
	var enc = get_root().get_node("Encyclopedia")
	var gamedata = get_root().get_node("GameData")
	var scene_trans = get_root().get_node("SceneTransitions")

	# 1. 卡牌与卡表
	var card = gs.card_final_seed
	_check(card != null, "final seed card exists")
	if card != null:
		_check(card.title == "最后的种子", "card title")
		_check(card.action == gs.Action.PLANT, "card plants")
		_check(card.species_id == "final_seed", "card species")
		_check(card.cost == 1, "card cost 1")
		_check(card.icon != null, "card icon")
		_check(gs.card_by_id("final_seed") == card, "card registered")

	# 2. 结局分镜
	var ending = load("res://Ending.tscn").instance()
	get_root().add_child(ending)
	_check(ending.PANELS.size() == 4, "ending has 4 panels")
	_check(_find_label(ending, "最后一颗种子"), "ending title")
	_check(ending._photo.texture != null, "ending first photo loads")
	_check(ending._caption_label.text.find("种子") >= 0, "ending first caption")
	_check(ending._finish_label != null, "ending finish stamp")
	_check(ending._finish_label.text.find("奇迹之种") >= 0, "ending stamp says miracle seed")
	_check(ending._finish_label.text.find("四季魔瓶") < 0, "ending stamp drops four seasons bottle")
	for i in range(ending.PANELS.size()):
		_check(load(ending.PANELS[i]["path"]) != null, "ending panel %d loads" % i)
	ending.queue_free()

	# 3. 图鉴未集齐时不发种子
	var hand = Node2D.new()
	get_root().add_child(hand)
	gs.hand = hand
	enc.reset_all()
	_check(not gs.maybe_grant_final_seed(false), "no seed before completion")
	_check(hand.get_child_count() == 0, "hand stays empty before completion")

	# 4. 图鉴集齐后必出且只出一张
	for id in gamedata.all_entry_ids():
		enc.discovered[id] = true
	_check(gs.maybe_grant_final_seed(false), "seed granted at completion")
	_check(hand.get_child_count() == 1, "one seed in hand")
	if hand.get_child_count() > 0:
		_check(hand.get_child(0).associated_card == card, "hand holds final seed")
	_check(not gs.maybe_grant_final_seed(false), "no duplicate seed")
	_check(hand.get_child_count() == 1, "still one seed")

	# 种子被丢进弃牌堆后，下一轮会捞回手牌而不是再发一张。
	_clear_hand(hand)
	gs.discard_pile.append(card)
	_check(gs.maybe_grant_final_seed(false), "seed recovered from discard pile")
	_check(hand.get_child_count() == 1, "recovered seed in hand")
	_check(not gs.discard_pile.has(card), "discard pile no longer holds seed")

	# 5. 终局植物：不参与变异、更结实、每次浇水 2 帧
	var plant = load("res://plants/winplant/WinPlant.tscn").instance()
	plant.is_final_plant = true
	plant.species_id = "final_seed"
	get_root().add_child(plant)
	_check(plant.health == 7, "final plant health 7, got %d" % plant.health)
	_check(plant.mutation_rolled, "final plant skips mutation roll")
	_check(not plant.mutated, "final plant never mutates")
	_check(plant.growth_steps() == 2, "final plant grows 2 per water")
	_check(plant.max_growth_frame() == 8, "final plant uses 9 frames")
	_check(plant.current_perk() == null, "final plant has no perk")
	_check(gs.has_final_seed_or_plant(), "plant counts as final seed holder")
	_clear_hand(hand)
	_check(gs.has_final_seed_or_plant(), "plant alone blocks another seed")
	_check(not gs.maybe_grant_final_seed(false), "no seed while final plant alive")

	# 6. 同一轮里先有一株普通植物成熟弹出收获窗，再让终局植物成熟：
	# 结局开始时必须把收获/选牌窗收掉，直接进剧情。
	var bottle = get_root().get_node("BottleManager")
	var harvest = get_root().get_node("HarvestManager")
	enc.reset_all()
	var second = load("res://plants/winplant/WinPlant.tscn").instance()
	second.species_id = "tomato"
	get_root().add_child(second)
	harvest.handle_harvest(second)
	_check(gs.harvest_open, "control: normal harvest opens the popup")
	_check(gs.waiting_for_card_selection, "control: normal harvest waits for a choice")
	bottle.charges.clear()
	bottle.charges.append("basic")
	bottle.charges.append("high")
	gs.ending_started = false
	plant.popup_menu()
	_check(gs.ending_started, "maturity starts ending")
	_check(scene_trans.next == gs.Ending, "transition targets ending scene")

	# 6b. 结局开始后：收获窗关闭、蓄能清空，后续成熟也不再弹选牌。
	_check(not gs.harvest_open, "harvest UI closed on ending")
	_check(not gs.waiting_for_card_selection, "card pick cancelled on ending")
	_check(bottle.charges.empty(), "bottle charges cleared on ending")
	harvest.handle_harvest(second)
	_check(not gs.harvest_open, "no harvest UI during ending")
	_check(not gs.waiting_for_card_selection, "no card pick during ending")
	_check(not bottle.is_busy(), "bottle stays idle during ending")
	second.queue_free()

	# 收尾，避免测试场景真的切走
	scene_trans.get_node("AnimationPlayer").stop(true)
	scene_trans.next = null
	gs.ending_started = false
	plant.queue_free()
	hand.queue_free()
	gs.hand = null
	enc.reset_all()

	if problems.empty():
		print("ENDING CHECK OK")
	else:
		for p in problems:
			print("ENDING CHECK FAIL: " + p)
	quit()
