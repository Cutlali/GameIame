extends SceneTree

# 开发工具：本轮四个 bug 的回归测试。
# 用法：
#   Godot --path <project> --script res://dev_tools/bugfixcheck.gd

var frames = 0
var started = false
var game = null
var failures = []

var gs = null
var game_data = null


func _idle(_delta):
	frames += 1
	if not started:
		if frames < 3:
			return
		started = true
		gs = get_root().get_node("GS")
		game_data = get_root().get_node("GameData")
		get_root().get_node("Flags").skip_tutorial = true
		game = load("res://Game.tscn").instance()
		get_root().add_child(game)
		return

	if frames < 45:
		return

	_check_damage_bonus_display()
	_check_hasten_near_maturity()
	_check_seed_guarantee()
	_check_variant_tint()
	_report()
	quit()


func _display_desc(card):
	var b = gs.get_card_base(card)
	b.dynamic_display = true
	get_root().add_child(b)
	b._process(0)
	var text = b.get_node("Desc").bbcode_text
	b.get_parent().remove_child(b)
	b.queue_free()
	return text


# 1. 力量加成只影响伤害牌，不能污染水牌 / 催熟 / 嫁接。
func _check_damage_bonus_display():
	gs.cursor.current_damage_add = 3

	var water = _display_desc(gs.card_by_id("water_drip"))
	if water.find("施加 2 点水分") < 0:
		failures.append("water card showed damage bonus: " + water)

	var hasten = _display_desc(gs.card_by_id("hasten"))
	if hasten.find("生长 2 帧") < 0:
		failures.append("hasten showed damage bonus: " + hasten)

	var graft = _display_desc(gs.card_by_id("graft"))
	if graft.find("提高 30%") < 0:
		failures.append("graft showed damage bonus: " + graft)

	# 伤害数字要跟着卡面走，所以期望值从卡的 quantity 推出来，
	# 免得以后调整基础伤害（第二轮就把重击从 1 抬到 3）时又把检查写死过期。
	var bonus = gs.cursor.current_damage_add
	for cid in ["whack", "net"]:
		var card = gs.card_by_id(cid)
		var shown = "[color=#3d3]" + str(card.quantity + bonus) + "[/color]"
		var desc = _display_desc(card)
		if desc.find(shown) < 0:
			failures.append("%s did not show damage bonus: %s" % [cid, desc])

	gs.cursor.current_damage_add = 0
	print("damage bonus display: water / hasten / graft excluded, attack / net included")


func _make_plant(scene_path, sid, variant = -1):
	var p = load(scene_path).instance()
	p.species_id = sid
	p.mutation_rolled = true
	p.mutated = variant >= 0
	p.variant_index = max(0, variant)
	game.get_node("TileMap").add_child(p)
	return p


# 2. 剩最后一帧时催熟 2 帧，应该正好到成熟帧；再次催熟不越界。
func _check_hasten_near_maturity():
	var plant = _make_plant("res://plants/plant1/Plant1.tscn", "tomato", -1)
	plant.position = Vector2(-384, 0)

	var sprite = plant.get_node("Plant")
	var max_frame = plant.max_growth_frame()
	sprite.frame = max_frame - 1

	gs.cursor.position = plant.position
	gs.cursor.hasten(gs.card_by_id("hasten"))

	if sprite.frame != max_frame:
		failures.append("hasten at max-1 did not reach mature frame: %d" % sprite.frame)
	if not plant.is_mature():
		failures.append("plant should report mature after hasten")

	var advanced = plant.advance_growth(2)
	if advanced != 0 or sprite.frame != max_frame:
		failures.append("hasten past maturity should not advance or overflow")

	plant.get_parent().remove_child(plant)
	plant.queue_free()
	print("hasten near maturity: max-1 -> mature, no overflow")


# 3. 每轮发牌契约：固定 3 张，必有 1 张水牌、1 张已解锁种子。
func _check_seed_guarantee():
	for plant in get_nodes_in_group("Plant"):
		plant.get_parent().remove_child(plant)
		plant.queue_free()

	var old_draws = gs.card_draw_count
	gs.pending_mature_rewards = 0
	var available = game_data.available_seed_card_ids()
	for r in range(20):
		if gs.hand != null and is_instance_valid(gs.hand):
			for c in gs.hand.get_children():
				gs.hand.remove_child(c)
				c.queue_free()

		gs._deal_cards()
		if gs.hand.get_child_count() != 3:
			failures.append("deal %d: expected 3 cards, got %d"
				% [r, gs.hand.get_child_count()])
		if gs._hand_water_count() < 1:
			failures.append("deal %d: lacks the guaranteed water card" % r)
		var seed_ok = false
		for c in gs.hand.get_children():
			var ac = c.associated_card
			if ac != null and ac.action == gs.Action.PLANT and String(ac.id) in available:
				seed_ok = true
		if not seed_ok:
			failures.append("deal %d: lacks an unlocked seed" % r)
	gs.card_draw_count = old_draws
	print("deal contract: fixed 3 + water + unlocked seed ok (20 rounds)")


func _color_close(a, b, eps = 0.001):
	return abs(a.r - b.r) < eps and abs(a.g - b.g) < eps \
		and abs(a.b - b.b) < eps and abs(a.a - b.a) < eps


# 4. 变种颜色要等植物长到后段才显现，成熟帧与图鉴一致。
#    早期成长帧保持原色，符合“有些变种只有成熟才看得出来”。
func _check_variant_tint():
	var plant = _make_plant("res://plants/plant2/Plant2.tscn", "sunflower", 1)
	plant.position = Vector2(384, 0)
	var expected = game_data.variant_color("sunflower", 1)
	var sprite = plant.get_node("Plant")
	var max_frame = plant.max_growth_frame()

	sprite.frame = 0
	plant._update_variant_tint()
	if not _color_close(sprite.modulate, Color.white):
		failures.append("variant should stay normal-colored during early growth")

	sprite.frame = max_frame - 1
	plant._update_variant_tint()
	if _color_close(sprite.modulate, Color.white) \
		or _color_close(sprite.modulate, expected):
		failures.append("penultimate frame should show a partial variant hint")

	sprite.frame = max_frame
	plant._update_variant_tint()
	if not _color_close(sprite.modulate, expected):
		failures.append("mature variant tint does not match encyclopedia color: %s vs %s"
			% [sprite.modulate, expected])
	if plant.has_method("_announce_variant"):
		failures.append("variant toast announcement should be removed")

	plant.get_parent().remove_child(plant)
	plant.queue_free()
	print("variant tint: hidden early, partial hint at max-1, full color when mature")


func _report():
	if failures.empty():
		print("BUGFIX CHECK OK")
	else:
		for f in failures:
			print("BUGFIX CHECK FAIL: " + f)
		print("BUGFIX CHECK FAILED (%d)" % failures.size())