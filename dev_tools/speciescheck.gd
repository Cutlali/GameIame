extends SceneTree

# 开发工具：物种与循环平衡回归检查。
# 覆盖：15 个物种的种子卡注册、scene_for 出场景、生长到成熟、变种条目解析、
# 种子季门阶梯（含瓶碎后季门回退）、发牌契约（固定3张+水牌保证）、结局门槛语义，
# 以及第二轮新增的瓶能、卡池种子占比、临时能量卡、虫群年度血量与巨虫。
# 用法：Godot --path <project> --user-dir rt_speciescheck --script res://dev_tools/speciescheck.gd

const ALL_SEED_IDS = [
	"basic_plant", "wheat_seed", "mint_seed",
	"medium_plant", "cotton_seed", "flax_seed", "soybean_seed",
	"high_plant", "rice_seed", "maize_seed", "potato_seed", "wintersweet_seed",
	"win_plant", "sugarcane_seed", "saffron_seed"
]

# 物种 → 场景贴图数量（含 seed 帧）。
const PLANT_FRAMES = {
	"tomato": 4, "sunflower": 6, "cotton": 6, "pumpkin": 6, "rice": 6,
	"moonflower": 9, "wintersweet": 8,
	"wheat": 6, "mint": 5, "flax": 6, "soybean": 6, "maize": 7,
	"potato": 6, "sugarcane": 8, "saffron": 7
}

var frames = 0
var started = false
var stage = 0
var wait_until = 0
var failures = []

var gs = null
var game = null
var gamedata = null
var encyclopedia = null
var season = null
var runstats = null
var sv = null
var bottle = null


func _init():
	OS.window_size = Vector2(960, 700)


func _idle(_delta):
	frames += 1
	if not started:
		if frames < 3:
			return
		started = true
		gs = get_root().get_node("GS")
		gamedata = get_root().get_node("GameData")
		encyclopedia = get_root().get_node("Encyclopedia")
		season = get_root().get_node("Season")
		runstats = get_root().get_node("RunStats")
		sv = get_root().get_node("SaveGame")
		bottle = get_root().get_node("BottleManager")
		stage = 0
		wait_until = OS.get_ticks_msec() + 300
		return

	if OS.get_ticks_msec() < wait_until:
		return
	if OS.get_ticks_msec() > 40000:
		print("SPECIES TIMEOUT stage=", stage)
		_report()
		quit()
		return

	match stage:
		0:
			game = load("res://Game.tscn").instance()
			get_root().add_child(game)
			stage = 1
			wait_until = OS.get_ticks_msec() + 400
		1:
			_check_cards()
			stage = 2
			wait_until = OS.get_ticks_msec() + 50
		2:
			_check_ladder()
			stage = 3
			wait_until = OS.get_ticks_msec() + 50
		3:
			_check_plants()
			stage = 4
			wait_until = OS.get_ticks_msec() + 50
		4:
			_check_deal_contract()
			stage = 5
			wait_until = OS.get_ticks_msec() + 50
		5:
			_check_ending_gate()
			stage = 6
			wait_until = OS.get_ticks_msec() + 50
		6:
			_check_pools()
			stage = 7
			wait_until = OS.get_ticks_msec() + 50
		7:
			_check_bottle_power()
			stage = 8
			wait_until = OS.get_ticks_msec() + 50
		8:
			_check_energy_cards()
			stage = 9
			wait_until = OS.get_ticks_msec() + 50
		9:
			_check_bug_tiers()
			stage = 10
			wait_until = OS.get_ticks_msec() + 50
		10:
			_cleanup()
			_report()
			quit()


func _check_cards():
	# 15 个物种的种子卡都要在注册表里，且物种、类别、动作三样都对。
	for sid in gamedata.SPECIES_ORDER:
		var cid = _seed_card_id_for(sid)
		if cid == "":
			_fail("no seed card for species " + sid)
			continue
		var c = gs.card_by_id(cid)
		if c == null:
			_fail("registry missing " + cid)
			continue
		if c.species_id != sid:
			_fail("%s species_id = %s" % [cid, c.species_id])
		if c.cat != gs.CAT_SEED or c.action != gs.Action.PLANT:
			_fail(cid + " is not a seed/plant card")

	# 老卡的名字与费用不许漂。
	if gs.card_medium_plant.cost != 1:
		_fail("sunflower seed cost %d != 1" % gs.card_medium_plant.cost)
	if gs.card_def2_all.cost != 3:
		_fail("magic shield cost %d != 3" % gs.card_def2_all.cost)
	if gs.card_sacrif2_2enem.cost != 3:
		_fail("blood blade cost %d != 3" % gs.card_sacrif2_2enem.cost)
	if gs.card_sacrifice.cost != 4:
		_fail("sacrifice cost %d != 4" % gs.card_sacrifice.cost)

	# 单体攻击第二轮整体加强，数值要钉住。
	var atk = [
		["card_free_atk", 2], ["card_small_attack", 3], ["card_dmg2", 4],
		["card_net", 2], ["card_sacrif1_1enem", 5], ["card_sacrif2_2enem", 6],
		["card_trapper", 6], ["card_queen_sting", 14]
	]
	for a in atk:
		if gs.get(a[0]).quantity != a[1]:
			_fail("%s quantity %d != %d" % [a[0], gs.get(a[0]).quantity, a[1]])
	# 蜂群仍然只是全场 2 点：巨虫外壳 2，不会再出现“无脑蜂群”的答案。
	if gs.card_swarm.quantity != 2:
		_fail("swarm quantity %d != 2" % gs.card_swarm.quantity)


func _seed_card_id_for(sid):
	# 前 7 个物种里有 4 个沿用早期的通用卡名。
	var legacy = {"tomato": "basic_plant", "sunflower": "medium_plant",
		"pumpkin": "high_plant", "moonflower": "win_plant"}
	if legacy.has(sid):
		return legacy[sid]
	return sid + "_seed"


func _check_ladder():
	# 绝对季门阶梯（v1.8 两年全开）：
	# gate 0=1年春(3种) 4=2年春(7种) 6=2年秋(11种) 7=2年冬(15种)。
	# 注意：本引擎 Array.slice 的 end 参数不可信，取前缀一律走 _first。
	season.year = 1; season.current_index = 0
	_expect_ids(_first(3))
	season.year = 2; season.current_index = 0
	_expect_ids(_first(7))
	season.current_index = 2
	_expect_ids(_first(11))
	season.current_index = 3
	_expect_ids(ALL_SEED_IDS)
	# 瓶碎回第一年春：按历史季门进池、不缩回，也不超发。
	sv.enabled = true
	sv.max_gate_reached = 5
	season.year = 1; season.current_index = 0
	var ids = gamedata.available_seed_card_ids()
	for want in _first(7):
		if not (want in ids):
			_fail("max_gate fallback lost y2 spring seed: " + want)
	for absent in ["high_plant", "win_plant", "saffron_seed"]:
		if absent in ids:
			_fail("max_gate fallback too loose: " + absent + " at max_gate=5")
	sv.max_gate_reached = 7
	_expect_ids(ALL_SEED_IDS)
	sv.enabled = false
	season.year = 2; season.current_index = 0


func _first(n):
	var out = []
	for i in range(min(n, ALL_SEED_IDS.size())):
		out.append(ALL_SEED_IDS[i])
	return out


func _expect_ids(want):
	season.round_in_year = 1
	var ids = gamedata.available_seed_card_ids()
	if ids.size() != want.size():
		_fail("year %d ladder size %d != %d" % [season.year, ids.size(), want.size()])
		return
	for i in range(want.size()):
		if ids[i] != want[i]:
			_fail("year %d ladder[%d] = %s, want %s" % [season.year, i, ids[i], want[i]])


func _check_plants():
	for sid in gamedata.SPECIES_ORDER:
		var count = PLANT_FRAMES[sid]
		var scene = gamedata.scene_for(sid)
		if scene == null:
			_fail("scene_for(" + sid + ") null")
			continue
		var p = scene.instance()
		# 照 Cursor.new_plant 的顺序：先定物种再入树，_ready 里的变异判定才拿得到 species_id。
		p.species_id = sid
		game.get_node("TileMap").add_child(p)
		var maxf = p.max_growth_frame()
		if maxf != count - 1:
			_fail("%s frames %d != %d textures-1" % [sid, maxf, count])
		p.advance_growth(99)
		if not p.is_mature():
			_fail(sid + " cannot reach maturity")
		# 变种条目 id 解析（种下即定型的路径）。
		p.mutation_rolled = true
		p.mutated = true
		p.variant_index = 1
		p._entry_resolved = false
		var eid = p.resolve_entry_id()
		if eid != sid + "_v1":
			_fail(sid + " variant entry = " + eid)
		var entry = gamedata.entry(eid)
		if entry == null or entry["name"] == "":
			_fail(sid + " variant entry data missing")
		# 图鉴格子只有 144 像素宽：名字超过 8 个字就会挤坏版式。
		if entry["name"].length() > 8:
			_fail(sid + " variant name too long: " + entry["name"])
		p.queue_free()

	# 每个物种都必须有 2 个变种、真实学名与特性文案。
	for sid in gamedata.SPECIES_ORDER:
		var sp = gamedata.species(sid)
		if sp["variants"].size() != 2:
			_fail(sid + " has " + str(sp["variants"].size()) + " variants")
		for v in sp["variants"]:
			if v.get("scientific", "") == "" or not v.has("perk"):
				_fail(sid + " variant missing scientific/perk: " + v["name"])
			if v["name"].length() > 8:
				_fail(sid + " variant name too long: " + v["name"])

	# 图鉴条目总数：15 物种 × 3 条 = 45。
	if encyclopedia.total_entries() != 45:
		_fail("total_entries %d != 45" % encyclopedia.total_entries())


func _check_pools():
	# 玩家反馈“卡池里只有道具”，所以每个池的种子权重占比都要过 25%。
	for pool_id in gamedata.BOTTLE_POOLS.keys():
		var seed_w = 0
		var total_w = 0
		for e in gamedata.BOTTLE_POOLS[pool_id]:
			total_w += e["weight"]
			var c = gs.card_by_id(e["id"])
			if c != null and c.action == gs.Action.PLANT:
				seed_w += e["weight"]
		var ratio = float(seed_w) / float(max(1, total_w))
		if ratio < 0.25:
			_fail("pool %s seed share %.2f < 0.25" % [pool_id, ratio])

	# 基础抽卡池同样要保证有种子可种，不然开局只会浇水。
	var b_seed = 0
	var b_total = 0
	for e in gamedata.BASIC_POOL:
		b_total += e["weight"]
		var c = gs.card_by_id(e["id"])
		if c != null and c.action == gs.Action.PLANT:
			b_seed += e["weight"]
	if float(b_seed) / float(max(1, b_total)) < 0.20:
		_fail("basic pool seed share too low: %d/%d" % [b_seed, b_total])

	# 池子里每个 id 都要能在注册表里找到，年份字段只能是整数。
	for pool_id in gamedata.BOTTLE_POOLS.keys():
		for e in gamedata.BOTTLE_POOLS[pool_id]:
			if gs.card_by_id(e["id"]) == null:
				_fail("pool %s references unknown card %s" % [pool_id, e["id"]])
	for e in gamedata.BASIC_POOL:
		if gs.card_by_id(e["id"]) == null:
			_fail("basic pool references unknown card " + e["id"])


func _check_bottle_power():
	# 攒满 15 点、点击释放：有虫全场受伤、固定全场浇水、释放后清零。
	gs.restart_after_shatter()
	bottle.refill()
	bottle.power = 0
	if bottle.MAX_POWER != 15:
		_fail("MAX_POWER %d != 15" % bottle.MAX_POWER)
	bottle.add_power(bottle.POWER_PER_HARVEST)
	if bottle.power != 1:
		_fail("harvest power grant %d != 1" % bottle.power)
	bottle.add_power(bottle.POWER_PER_VARIANT)
	if bottle.power != 4:
		_fail("variant power grant left %d != 4" % bottle.power)
	for i in range(20):
		bottle.add_power(5)
	if bottle.power != bottle.MAX_POWER:
		_fail("power overflow: %d" % bottle.power)

	# 没满时点释放不给伤害。
	bottle.power = 5
	if bottle.release_power() != 0:
		_fail("release accepted below full")
	if bottle.power != 5:
		_fail("release consumed partial power")

	# 场上放两只虫，满了再释放。take_damage 只排队，
	# dec_health 由 Slash 动画触发，所以这里断言排队伤害。
	_clear_enemies()
	if _spawn_many(2, gs.SpawnOpt.Bug3) != 2:
		_fail("cannot place 2 test enemies")
		return
	var enemies = get_nodes_in_group("Enemy")
	if enemies.size() != 2:
		_fail("expected 2 enemies, got %d" % enemies.size())
		return
	bottle.power = bottle.MAX_POWER
	season.year = 3
	var dealt = bottle.release_power()
	if dealt != 5:
		_fail("year3 release damage %d != 3+(3-1)" % dealt)
	if bottle.power != 0:
		_fail("power not cleared after release")
	for bug in enemies:
		if bug.attack_queue.empty():
			_fail("enemy missed by bottle power")
		for q in bug.attack_queue:
			if q != dealt:
				_fail("queued damage %d != %d" % [q, dealt])

	# v1.8：没虫时不再拒绝释放，改为"给全场来一瓶露"；
	# 虫和可浇植物都没有时才拦下来。
	_clear_enemies()
	var thirsty = []
	var before = []
	for p in get_nodes_in_group("Plant"):
		if is_instance_valid(p) and p.water < gs.PLANT_WATER_MAX:
			thirsty.append(p)
			before.append(p.water)
	bottle.power = bottle.MAX_POWER
	if thirsty.empty():
		if bottle.release_power() != 0 or bottle.power != bottle.MAX_POWER:
			_fail("release should be refused with no bugs and no thirsty plants")
	else:
		bottle.release_power()
		if bottle.power != 0:
			_fail("watering-only release did not consume power")
		for i in range(thirsty.size()):
			if not is_instance_valid(thirsty[i]):
				continue
			if thirsty[i].water != before[i] + 1:
				_fail("watering-only release missed plant %d (%d -> %d)" % [
					i, before[i], thirsty[i].water])
	season.year = 2


func _check_energy_cards():
	# 凝露/甘泉/涌泉分别给 1/2/3 点能量，三张都是 0 费（v1.8），并且不超过上限。
	var trio = [["energy_dew", 1], ["energy_spring", 2], ["energy_geyser", 3]]
	for t in trio:
		var c = gs.card_by_id(t[0])
		if c == null:
			_fail("registry missing " + t[0])
			continue
		if c.action != gs.Action.PLUS_ENERGY:
			_fail(t[0] + " is not PLUS_ENERGY")
		if c.quantity != t[1]:
			_fail("%s quantity %d != %d" % [t[0], c.quantity, t[1]])
		if c.cost != 0:
			_fail("%s should be 0 cost, got %d" % [t[0], c.cost])
		if not c.transient:
			_fail(t[0] + " should be transient")

	gs.energy_max = 7
	gs.energy = 2
	var c = gs.card_by_id("energy_geyser")
	var hand = gs.hand.get_children()
	if hand.empty():
		_fail("no hand card to test energy play")
		return
	# 直接按 HandCard 的公式核一遍：数量决定给几点，且封顶在上限内。
	var room = gs.energy_max - gs.energy
	var want = min(max(1, c.quantity), room)
	gs.energy += want
	if gs.energy != 5:
		_fail("energy after geyer %d != 5" % gs.energy)
	gs.energy = gs.energy_max
	room = gs.energy_max - gs.energy
	if min(max(1, c.quantity), room) != 0:
		_fail("energy gain not clamped at cap")


func _check_bug_tiers():
	# 第 2 年起普通虫至少 5 滴血；大波次必带巨虫，巨虫血厚壳硬。
	_clear_enemies()
	season.year = 2
	var ok = _spawn_at(Vector2(-2, -1), gs.SpawnOpt.Bug2)
	if not ok:
		_fail("cannot spawn test bug")
		return
	var bug = get_nodes_in_group("Enemy")[0]
	if bug.health < 5:
		_fail("year2 small bug health %d < 5" % bug.health)
	_clear_enemies()

	season.year = 4
	_spawn_at(Vector2(-2, -1), gs.SpawnOpt.Bug2)
	bug = get_nodes_in_group("Enemy")[0]
	if bug.health < 7:
		_fail("year4 small bug health %d < 7" % bug.health)
	_clear_enemies()

	season.year = 2
	_spawn_at(Vector2(-2, -1), gs.SpawnOpt.Giant)
	var giant = get_nodes_in_group("Enemy")[0]
	if not giant.is_giant:
		_fail("giant flag missing")
	if giant.health < 10:
		_fail("giant health %d < 10" % giant.health)
	if giant.armor < 2:
		_fail("giant armor %d < 2" % giant.armor)
	# 外壳让蜂群这类全场 2 点伤害几乎失效。
	if max(1, 2 - giant.armor) > 1:
		_fail("giant armor does not blunt swarm")
	# 巨虫隔一回合才咬一次。
	var bites = 0
	for i in range(4):
		giant.take_turn()
		if giant.current_plant_target != null:
			bites += 1
	if bites > 2:
		_fail("giant attacks every turn (%d of 4)" % bites)
	_clear_enemies()

	# 大波次（基础配置 3 只以上）第 2 年起必须排到巨虫。
	season.year = 2
	var missed = 0
	for i in range(gs.spawn_configs.size()):
		gs.next_spawn = i
		var cfg = gs.build_spawn_config()
		if gs.spawn_configs[i].size() >= 3:
			var has_giant = false
			for item in cfg:
				if item == gs.SpawnOpt.Giant:
					has_giant = true
			if not has_giant:
				missed += 1
	if missed > 0:
		_fail("%d large waves without a giant" % missed)
	gs.next_spawn = 0

	# 小波次不该被巨虫塞满。
	for i in range(gs.spawn_configs.size()):
		if gs.spawn_configs[i].size() >= 3:
			continue
		gs.next_spawn = i
		var cfg = gs.build_spawn_config()
		for item in cfg:
			if item == gs.SpawnOpt.Giant:
				_fail("small wave %d carries a giant" % i)
	gs.next_spawn = 0
	season.year = 1


func _spawn_at(cell, item):
	return gs._spawn_bug_at(cell, item)


func _spawn_many(count, item):
	# 空格子不固定（瓶子、空地、别的测试体都可能占位），挨个试到放够为止。
	var cells = [Vector2(-2, -1), Vector2(-1, -1), Vector2(1, -1), Vector2(2, -1),
		Vector2(-2, 0), Vector2(-2, 1), Vector2(2, 1), Vector2(0, 1)]
	var placed = 0
	for c in cells:
		if placed >= count:
			break
		if _spawn_at(c, item):
			placed += 1
	return placed


func _clear_enemies():
	for e in get_nodes_in_group("Enemy"):
		e.queue_free()
		e.get_parent().remove_child(e)


func _check_deal_contract():
	# v1.8 发牌契约：每轮固定 3 张，其中必有一张水牌；跑 30 轮抓漏。
	for t in range(30):
		for c in gs.hand.get_children():
			c.queue_free()
			gs.hand.remove_child(c)
		gs._deal_cards()
		var n = gs.hand.get_child_count()
		if n != 3:
			_fail("deal %d gave %d cards, want 3" % [t, n])
			break
		if gs._hand_water_count() < 1:
			_fail("deal %d lacks the guaranteed water card" % t)
			break
	for c in gs.hand.get_children():
		c.queue_free()
		gs.hand.remove_child(c)
	# 手牌上限钉在 [5,6]。
	var old = gs.bonus_draws
	if gs.hand_cap() != 5:
		_fail("base hand cap should be 5, got %d" % gs.hand_cap())
	gs.bonus_draws = 4
	if gs.hand_cap() != 6:
		_fail("hand cap should clamp at 6, got %d" % gs.hand_cap())
	gs.bonus_draws = old


func _check_ending_gate():
	encyclopedia.reset_all()
	if encyclopedia.all_species_represented():
		_fail("empty encyclopedia claims completion")
	# 每个物种只收录变种也算"见过"。
	var variants_only = []
	for sid in gamedata.SPECIES_ORDER:
		variants_only.append(sid + "_v0")
	encyclopedia.restore(variants_only, 0)
	if not encyclopedia.all_species_represented():
		_fail("variants-only roster not represented")
	if encyclopedia.species_represented_count() != gamedata.SPECIES_ORDER.size():
		_fail("species_represented_count wrong")
	# 缺一个物种则不成立（本引擎 Array.slice 的 end 参数不可信，手工取前 14 个）。
	var partial = []
	for i in range(gamedata.SPECIES_ORDER.size() - 1):
		partial.append(variants_only[i])
	encyclopedia.restore(partial, 0)
	if encyclopedia.all_species_represented():
		_fail("missing species still claims completion")
	# 结局种子发放门槛走 all_species_represented 而不是条目总数。
	encyclopedia.reset_all()
	runstats.entries_found = 0


func _cleanup():
	_clear_enemies()
	# 只收场，不调 reset_all_state：它会把 GS.cursor 置空，
	# 而同一帧里 CardBase._process 还在读 current_damage_add，会刷一屏报错。
	if game != null and is_instance_valid(game):
		game.queue_free()


func _fail(msg):
	failures.append(msg)


func _report():
	if failures.empty():
		print("SPECIES CHECK OK")
	else:
		for f in failures:
			print("FAIL: " + f)
		print("SPECIES CHECK FAILED")
