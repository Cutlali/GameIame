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

	var whack = _display_desc(gs.card_by_id("whack"))
	if whack.find("[color=#3d3]4[/color]") < 0:
		failures.append("attack card did not show damage bonus: " + whack)

	var net = _display_desc(gs.card_by_id("net"))
	if net.find("[color=#3d3]4[/color]") < 0:
		failures.append("net did not show damage bonus: " + net)

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


# 3. 场上没有植物、手里也没有种子时，发牌必须补一张种子。
func _check_seed_guarantee():
	for plant in get_nodes_in_group("Plant"):
		plant.get_parent().remove_child(plant)
		plant.queue_free()

	if gs.hand != null and is_instance_valid(gs.hand):
		for c in gs.hand.get_children():
			gs.hand.remove_child(c)
			c.queue_free()

	var old_draws = gs.card_draw_count
	gs.card_draw_count = 0
	gs._deal_cards()
	gs.card_draw_count = old_draws

	if gs._hand_seed_count() != 1:
		failures.append("seed guarantee failed, seed count = %d" % gs._hand_seed_count())
	print("seed guarantee: empty field + empty hand -> seed dealt")


# 4. 变种颜色应该和图鉴一致，并且从种下起就生效。
func _check_variant_tint():
	var plant = _make_plant("res://plants/plant2/Plant2.tscn", "sunflower", 1)
	plant.position = Vector2(384, 0)
	var expected = game_data.variant_color("sunflower", 1)
	var sprite = plant.get_node("Plant")
	if sprite.modulate != expected:
		failures.append("variant tint does not match encyclopedia color: %s vs %s"
			% [sprite.modulate, expected])
	if plant.has_method("_announce_variant"):
		failures.append("variant toast announcement should be removed")

	var tint = sprite.modulate
	sprite.frame = 2
	if sprite.modulate != tint:
		failures.append("variant tint should persist across growth frames")

	plant.get_parent().remove_child(plant)
	plant.queue_free()
	print("variant tint: matches encyclopedia color and persists")


func _report():
	if failures.empty():
		print("BUGFIX CHECK OK")
	else:
		for f in failures:
			print("BUGFIX CHECK FAIL: " + f)
		print("BUGFIX CHECK FAILED (%d)" % failures.size())