extends SceneTree

# v1.5.2 新机制回归：
#   - 能量 3 → 5（第二年）→ 7（开垦），最高 7，瓶碎只回退年份部分
#   - 植物生命 / 水分 / 护盾上限 7
#   - 虫子死亡给 0 费速成卡，每轮最多 3 张
#   - 速成卡直接推进到成熟帧
#   - 水晶球：水牌直接打到球上存水、HUD 取水、打出扣水、瓶碎清空
# 用法：
#   Godot --path <project> --script res://dev_tools/v152mechanicscheck.gd

var frames = 0
var started = false
var game = null
var gs = null
var season = null
var failures = []


func _idle(_delta):
	frames += 1
	if not started:
		if frames < 3:
			return false
		started = true
		get_root().get_node("Flags").skip_tutorial = true
		gs = get_root().get_node("GS")
		season = get_root().get_node("Season")
		game = load("res://Game.tscn").instance()
		get_root().add_child(game)
		return false

	if frames < 45:
		return false

	_check_energy_curve()
	_check_plant_caps()
	_check_mature_reward_cap()
	_check_bug_death_reward()
	_check_mature_card()
	_check_orb()
	_check_orb_drag_card()
	_report()
	quit()
	return true


func _fail(msg):
	failures.append(msg)


func _clear_hand():
	if gs.hand != null and is_instance_valid(gs.hand):
		gs.hand.clear_hand()


func _count_mature_in_hand():
	var n = 0
	if gs.hand == null or not is_instance_valid(gs.hand):
		return 0
	for c in gs.hand.get_children():
		if c.associated_card != null and c.associated_card.action == gs.Action.MATURE:
			n += 1
	return n


func _count_orb_in_hand():
	if gs.hand == null or not is_instance_valid(gs.hand):
		return 0
	var n = 0
	for c in gs.hand.get_children():
		if c.associated_card != null and c.associated_card.from_orb:
			n += 1
	return n


func _make_plant(scene_path, sid, pos):
	var p = load(scene_path).instance()
	p.species_id = sid
	p.mutation_rolled = true
	game.get_node("TileMap").add_child(p)
	p.position = pos
	return p


func _drop_plant(p):
	if p != null and is_instance_valid(p):
		var parent = p.get_parent()
		if parent != null:
			parent.remove_child(p)
		p.queue_free()


# 1. 能量曲线与瓶碎回退。
func _check_energy_curve():
	gs.permanent_energy_bonus = 0
	gs.energy_max = gs.BASE_ENERGY
	gs.energy = gs.BASE_ENERGY

	season.year = 1
	gs.refresh_energy_max()
	if gs.energy_max != 3:
		_fail("year 1 energy should be 3, got %d" % gs.energy_max)

	season.year = 2
	gs.refresh_energy_max()
	if gs.energy_max != 5:
		_fail("year 2 energy should be 5, got %d" % gs.energy_max)

	season.year = 5
	gs.refresh_energy_max()
	if gs.energy_max != 5:
		_fail("energy should not grow with later years, got %d" % gs.energy_max)

	gs.add_permanent_energy(1)
	if gs.energy_max != 6:
		_fail("first permanent +1 should reach 6, got %d" % gs.energy_max)
	gs.add_permanent_energy(1)
	if gs.energy_max != 7:
		_fail("second permanent +1 should reach 7, got %d" % gs.energy_max)
	gs.add_permanent_energy(1)
	if gs.energy_max != 7:
		_fail("energy must cap at 7, got %d" % gs.energy_max)

	# 瓶碎：年份回退，开垦/图鉴的永久加成保留。
	gs.restart_after_shatter()
	if season.year != 1:
		_fail("shatter should reset year to 1, got %d" % season.year)
	if gs.energy_max != 6:
		_fail("shatter should keep 3 permanent energy -> 6, got %d" % gs.energy_max)

	gs.permanent_energy_bonus = 0
	gs.refresh_energy_max()
	gs.energy = gs.energy_max
	print("energy curve: 3 -> 5 -> 6 -> 7 cap, shatter keeps permanent bonus")


# 2. 生命 / 水分 / 护盾上限统一为 7。
func _check_plant_caps():
	var p = _make_plant("res://plants/plant1/Plant1.tscn", "tomato", Vector2(-384, 0))
	p.set_health(99)
	p.set_water(99)
	p.set_defense(99)
	if p.health != 7:
		_fail("plant health should cap at 7, got %d" % p.health)
	if p.water != 7:
		_fail("plant water should cap at 7, got %d" % p.water)
	if p.defense != 7:
		_fail("plant defense should cap at 7, got %d" % p.defense)
	_drop_plant(p)
	print("plant caps: health / water / defense all 7")


# 3. 速成奖励每轮最多 3 张，超出转为待发放。
func _check_mature_reward_cap():
	_clear_hand()
	gs.mature_rewards_this_round = 0
	gs.pending_mature_rewards = 0
	gs.turn_state = gs.TurnState.PLAYING_CARDS

	for i in range(4):
		gs.grant_mature_reward()

	if _count_mature_in_hand() != 3:
		_fail("mature rewards should cap at 3 per round, got %d" % _count_mature_in_hand())

	gs.turn_state = gs.TurnState.UPDATING
	gs.mature_rewards_this_round = 0
	gs.grant_mature_reward()
	if gs.pending_mature_rewards != 1:
		_fail("enemy-turn reward should be queued, got %d" % gs.pending_mature_rewards)

	gs.pending_mature_rewards = 0
	gs.mature_rewards_this_round = 0
	print("mature reward: max 3 per round, enemy-turn rewards queued")


# 4. 虫子死亡时给一张速成卡。
func _check_bug_death_reward():
	_clear_hand()
	gs.mature_rewards_this_round = 0
	gs.turn_state = gs.TurnState.PLAYING_CARDS
	var before = _count_mature_in_hand()

	var bug = load("res://bugs/Bug.tscn").instance()
	game.get_node("TileMap").add_child(bug)
	bug.position = Vector2(0, 384)
	bug.health = 1
	bug.dec_health()

	if _count_mature_in_hand() != before + 1:
		_fail("bug death did not grant a mature card")
	bug.get_parent().remove_child(bug)
	bug.queue_free()
	gs.mature_rewards_this_round = 0
	print("bug death: 1 mature card granted")


# 5. 速成卡直接把植物推到成熟帧。
func _check_mature_card():
	var p = _make_plant("res://plants/plant2/Plant2.tscn", "sunflower", Vector2(384, 0))
	var target = p.max_growth_frame()
	p.advance_growth(1)
	gs.cursor.position = p.position
	gs.cursor.mature(gs.card_mature)
	if p.get_node("Plant").frame != target:
		_fail("mature card should jump to the mature frame")
	if not p.forced_mature:
		_fail("mature card should set forced_mature")
	if not p.is_mature():
		_fail("plant should report mature after mature card")
	_drop_plant(p)
	print("mature card: plant forced to mature frame")


# 6. 水牌投入水晶球、取水、扣水、清空。
func _check_orb():
	gs.orb_water = 0
	gs.energy = gs.energy_max
	var p = _make_plant("res://plants/plant1/Plant1.tscn", "tomato", Vector2(-128, 0))

	# 浇满植物不再自动存水。
	p.set_water(6)
	gs.cursor.position = p.position
	gs.cursor.water(gs.card_buy_1x1_water) # 2 点水，只能浇入 1 点
	if p.water != 7:
		_fail("watering a nearly full plant should cap at 7, got %d" % p.water)
	if gs.orb_water != 0:
		_fail("overflow must not be stored automatically, got %d" % gs.orb_water)

	# 水牌直接打到水晶球：整张牌的水量进储存。
	var energy_before = gs.energy
	if not gs.play_water_into_orb(gs.card_buy_1x1_water):
		_fail("water card should be storable in the crystal orb")
	if gs.orb_water != 2:
		_fail("orb should store the card's full quantity 2, got %d" % gs.orb_water)
	if gs.energy != energy_before - gs.card_buy_1x1_water.cost:
		_fail("storing water should spend the card's energy cost")

	# 从球里取出的水不能原样存回去。
	if gs.play_water_into_orb(gs.card_orb_water):
		_fail("orb water must not be stored back into the orb")

	# HUD 取水：同一份水不能重复取成多张手牌。
	_clear_hand()
	gs.turn_state = gs.TurnState.PLAYING_CARDS
	var hud = game.get_node_or_null("CanvasLayer/Panel")
	if hud == null:
		_fail("HUD missing")
	else:
		gs.orb_water = 1
		hud._on_orb_pressed()
		hud._on_orb_pressed()
		if _count_orb_in_hand() != 1:
			_fail("orb should only hand out as many cards as stored water, got %d"
				% _count_orb_in_hand())

	# 打出水晶球之水：扣 1 点储水并浇 1 点。
	p.set_water(0)
	gs.cursor.position = p.position
	gs.cursor.water(gs.card_orb_water)
	if gs.orb_water != 0:
		_fail("playing orb water should consume 1 stored water, got %d" % gs.orb_water)
	if p.water != 1:
		_fail("orb water should water the plant by 1, got %d" % p.water)

	# 瓶碎后水晶球清空。
	gs.orb_water = 4
	gs.restart_after_shatter()
	if gs.orb_water != 0:
		_fail("shatter should empty the crystal orb, got %d" % gs.orb_water)
	gs.permanent_energy_bonus = 0
	gs.refresh_energy_max()
	_drop_plant(p)
	print("crystal orb: water cards stored by drag, no auto overflow, shatter clears")


# 7. 拖拽水牌到水晶球时的 HandCard 分支。
func _check_orb_drag_card():
	_clear_hand()
	var real_hud = gs.hud

	var src = GDScript.new()
	src.source_code = "extends Node\nfunc is_mouse_over_orb():\n\treturn true\n"
	src.reload()
	var stub = Node.new()
	stub.set_script(src)
	get_root().add_child(stub)
	gs.hud = stub

	gs.orb_water = 0
	gs.energy = gs.energy_max
	gs.turn_state = gs.TurnState.PLAYING_CARDS
	gs.add_card_to_hand(gs.card_buy_1x1_water)

	var hc = null
	for c in gs.hand.get_children():
		if c.associated_card == gs.card_buy_1x1_water:
			hc = c
	if hc == null:
		_fail("water card should be added to hand for drag test")
	else:
		var energy_before = gs.energy
		hc.try_play_self()
		if gs.orb_water != 2:
			_fail("dragging a water card onto the orb should store 2, got %d"
				% gs.orb_water)
		if gs.energy != energy_before - gs.card_buy_1x1_water.cost:
			_fail("dragging a water card onto the orb should spend its cost")
		if hc.get_parent() == gs.hand:
			_fail("water card should leave the hand after being stored")

	gs.hud = real_hud
	stub.queue_free()
	_clear_hand()
	print("orb drag: water card releases onto orb and stores its water")


func _report():
	if failures.empty():
		print("V152 MECHANICS CHECK OK")
	else:
		for f in failures:
			print("V152 MECHANICS CHECK FAIL: " + f)
		print("V152 MECHANICS CHECK FAILED (%d)" % failures.size())