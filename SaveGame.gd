extends Node

# 存档层：把跨局进度写成 JSON 放进 user://。
# HTML5 导出时 user:// 自动映射到浏览器 IndexedDB，刷新页面也能回来。
#
# 两类数据：
# - 元进度（图鉴、耕地、永久加成、教程/序章标记、历史最高年份）——
#   新开一局才会清空，瓶碎重开全部保留。
# - 局内进度（年份、季节、轮次、水晶球、瓶血、统计）——
#   每轮发牌后快照一次，"继续农场"按这一份回到对应季节的空田。
#
# dev_tools 通过 `--script` 启动时自动禁用读写，测试跑不到玩家真实存档。

const SAVE_PATH = "user://four_seasons_save.json"
const SAVE_VERSION = 1

const GUIDE_FLAGS = [
	"guide_season_changed",
	"guide_variant_seen",
	"guide_pest_seen",
	"guide_bottle_damaged",
	"guide_milestone_seen",
	"guide_bottle_shattered"
]

var enabled = true
var has_save = false

# 只有本会话真正开始/继续过一局，才允许落盘，
# 避免"启动后什么都没玩就退出"把旧档覆盖成空档。
var applied = false
var pending_run_restore = false

# SaveGame 自己负责的字段（游戏逻辑不直接读写这些）
var prologue_seen = false
var tutorial_done = false
var max_year_reached = 1
# 历史到过的绝对季门 =(年份-1)*4+季节序号；决定种子进池，瓶碎不缩回。
var max_gate_reached = 0
var hard_mode = false
var guide_flags = {}
var discovered_ids = []
var milestone_index = 0
var parcels = []   # 旧存档兼容：固定地块序号 0..3
var plots = []     # [[x, y, shape], ...] 已开垦 1×2 的左上角格子和方向（2=旧档 2×2）
var meta = {"bonus_draws": 0, "permanent_energy_bonus": 0}
var run = {}

# 手牌快照要等场景开局发牌动作（tutorial_skip 等）落定后再重建。
var _pending_hand_ids = []
var _pending_hand_frames = 0


func _ready():
	for arg in OS.get_cmdline_args():
		if arg == "--script" or arg.begins_with("--script="):
			enabled = false
			break
	# Godot 3 里 GDScript 够不到 WM 关闭/失焦通知（无信号，枚举常量也取不到），
	# 关窗兜底改挂在显式"退出"按钮路径上（MainMenu/PauseMenu 里先 save 再 quit）。
	# 直接点窗口 X / 杀进程最多丢一轮：每轮发牌前都已有快照。
	if enabled:
		load_save()


func in_game():
	return GS.tilemap != null and is_instance_valid(GS.tilemap) and Season.is_in_game()


# ---- 读 ----

func load_save():
	var f = File.new()
	if not f.file_exists(SAVE_PATH):
		return
	var err = f.open(SAVE_PATH, File.READ)
	if err != OK:
		return
	var text = f.get_as_text()
	f.close()

	# 本引擎里 JSON 标识符解析为单例：JSON.parse 直接返回 JSONParseResult，
	# 用 .error / .result 取码取数据（不支持 JSON.new 实例式写法）。
	var parsed = JSON.parse(text)
	if parsed.error != OK or typeof(parsed.result) != TYPE_DICTIONARY:
		return
	var data = parsed.result
	if int(data.get("version", 0)) != SAVE_VERSION:
		return

	prologue_seen = bool(data.get("prologue_seen", false))
	tutorial_done = bool(data.get("tutorial_done", false))
	max_year_reached = int(data.get("max_year_reached", 1))
	# 旧档没有这个字段：按已到的年份推一个保守的季门（该年年初）。
	max_gate_reached = int(data.get("max_gate_reached", (max_year_reached - 1) * 4))
	hard_mode = bool(data.get("hard_mode", false))

	guide_flags = {}
	for key in GUIDE_FLAGS:
		guide_flags[key] = bool(data.get("guide", {}).get(key, false))

	var enc = data.get("encyclopedia", {})
	discovered_ids = []
	for id in enc.get("discovered", []):
		discovered_ids.append(str(id))
	milestone_index = int(enc.get("milestone_index", 0))

	var m = data.get("meta", {})
	meta = {
		"bonus_draws": int(m.get("bonus_draws", 0)),
		"permanent_energy_bonus": int(m.get("permanent_energy_bonus", 0))
	}

	parcels = []
	for p in data.get("parcels", []):
		parcels.append(int(p))

	var r = data.get("run", {})
	run = {}
	if typeof(r) == TYPE_DICTIONARY and not r.empty():
		run = r

	plots = []
	for po in run.get("plots", []):
		if typeof(po) == TYPE_ARRAY and po.size() >= 2:
			# 旧档只有 [x, y]，代表 v1.8 的 2×2 地块；新档第三位是 0/1 横竖。
			var shape = 2
			if po.size() >= 3:
				shape = int(po[2])
			plots.append([int(po[0]), int(po[1]), shape])

	has_save = true


# ---- 写 ----

func save_now():
	if not enabled or not applied:
		return
	# 读档恢复还没盖回实时状态时不落盘，
	# 免得场景 ready 期间的杂项触发把"恢复前"的空状态写进存档。
	if pending_run_restore:
		return
	# 从各单例的实时状态采集回本节点，再整体落盘
	hard_mode = Flags.hard_mode
	for key in GUIDE_FLAGS:
		guide_flags[key] = bool(Flags.get(key))
	discovered_ids = Encyclopedia.discovered.keys()
	milestone_index = Encyclopedia.milestone_index
	meta = {
		"bonus_draws": GS.bonus_draws,
		"permanent_energy_bonus": GS.permanent_energy_bonus
	}
	if in_game():
		plots = []
		for o in GS.tilemap.claimed_plots:
			plots.append([int(o.x), int(o.y), GS.tilemap.plot_shape_for(o)])
		parcels = []
		run = _capture_run()

	var data = {
		"version": SAVE_VERSION,
		"prologue_seen": prologue_seen,
		"tutorial_done": tutorial_done,
		"max_year_reached": max_year_reached,
		"max_gate_reached": max_gate_reached,
		"hard_mode": hard_mode,
		"guide": guide_flags,
		"encyclopedia": {"discovered": discovered_ids, "milestone_index": milestone_index},
		"meta": meta,
		"parcels": parcels,
		"run": run
	}

	var f = File.new()
	var err = f.open(SAVE_PATH, File.WRITE)
	if err != OK:
		return
	f.store_string(JSON.print(data, "  "))
	f.close()
	has_save = true


func _capture_run():
	return {
		"year": Season.year,
		"season_index": Season.current_index,
		"round_in_year": Season.round_in_year,
		"rounds_in_season": Season.rounds_in_season,
		"orb_water": GS.orb_water,
		"bottle_hp": BottleManager.hp,
		"bottle_power": BottleManager.power,
		"mutation_pity": RunStats.mutation_pity,
		"next_spawn": GS.next_spawn,
		"no_enemy_turns": GS.no_enemy_turns,
		"some_enemy_turns": GS.some_enemy_turns,
		"stats_year": RunStats.year,
		"plots": plots,
		"farm_quota": GS.farm_quota,
		"charges": BottleManager.charges.duplicate(),
		"plants": _capture_plants(),
		"hand": _capture_hand(),
		"stats": {
			"water_spent": RunStats.water_spent,
			"plantings": RunStats.plantings,
			"harvests": RunStats.harvests,
			"entries_found": RunStats.entries_found,
			"variants_found": RunStats.variants_found,
			"bottle_uses": RunStats.bottle_uses,
			"plants_lost": RunStats.plants_lost,
			"pests_killed": RunStats.pests_killed
		}
	}


func _capture_plants():
	var out = []
	for node in get_tree().get_nodes_in_group("Plant"):
		var p = node
		if not is_instance_valid(p) or p.consumed:
			continue
		out.append({
			"x": int(p.position.x), "y": int(p.position.y),
			"sid": p.species_id,
			"mut": 1 if p.mutated else 0,
			"vix": int(p.variant_index),
			"hp": int(p.health), "w": int(p.water), "def": int(p.defense),
			"refl": int(p.reflect_damage),
			"frame": int(p.get_node("Plant").frame),
			"forced": 1 if p.forced_mature else 0,
			"final": 1 if p.is_final_plant else 0
		})
	return out


func _capture_hand():
	var out = []
	if GS.hand == null or not is_instance_valid(GS.hand):
		return out
	for hc in GS.hand.get_children():
		if hc.get("associated_card") == null:
			continue
		var id = _card_id_of(hc.associated_card)
		if id != "":
			out.append(id)
	return out


func _card_id_of(card):
	for k in GS.card_registry.keys():
		if GS.card_registry[k] == card:
			return k
	return ""


# v1.8：场景里活着的植物也要跨退出保留。
func _restore_plant(t, pd):
	var is_final = int(pd.get("final", 0)) == 1
	var sid = String(pd.get("sid", ""))
	var p = null
	if is_final:
		p = GS.PlantWin.instance()
		p.card_level = 4
		p.is_final_plant = true
	else:
		var scene = GameData.scene_for(sid)
		if scene == null:
			return
		p = scene.instance()
		var sp = GameData.species(sid)
		if sp != null:
			p.card_level = sp["level"]
		p.species_id = sid
		# 快照里已经带着变异结果，别让 _ready 再掷一次骰子。
		p.mutation_rolled = true
		p.mutated = int(pd.get("mut", 0)) == 1
		p.variant_index = int(pd.get("vix", 0))
	p.health = int(pd.get("hp", p.health))
	p.position = Vector2(int(pd.get("x", 0)), int(pd.get("y", 0)))
	t.add_child(p)
	p.set_water(int(pd.get("w", 0)))
	p.set_defense(int(pd.get("def", 0)))
	p.reflect_damage = int(pd.get("refl", 0))
	if int(pd.get("forced", 0)) == 1:
		p.forced_mature = true
	var mx = p.max_growth_frame()
	var fr = int(clamp(int(pd.get("frame", 0)), 0, mx))
	p.get_node("Plant").frame = fr
	p._update_variant_tint()
	p.update_markers_visibility()
	p.heart_update()


# 开局发牌是延迟发生的（tutorial_skip 或首回合流程），手牌重建也要错开帧。
func _process(_delta):
	if _pending_hand_ids.empty():
		return
	_pending_hand_frames += 1
	if _pending_hand_frames < 8:
		return
	_pending_hand_frames = 0
	if GS.hand == null or not is_instance_valid(GS.hand):
		return
	for i in range(GS.hand.get_child_count() - 1, -1, -1):
		var n = GS.hand.get_child(i)
		GS.hand.remove_child(n)
		n.queue_free()
	for id in _pending_hand_ids:
		var c = GS.card_by_id(id)
		if c != null:
			GS.add_card_to_hand(c)
	_pending_hand_ids = []


# ---- 开局入口 ----

# 主菜单"继续农场"：进场景之前先把元进度灌回各单例，
# 田块/历法要等 TileMap ready 之后由 apply_run() 补。
func apply_meta():
	applied = true
	pending_run_restore = true

	Flags.hard_mode = hard_mode
	Flags.skip_tutorial = tutorial_done
	for key in GUIDE_FLAGS:
		Flags.set(key, bool(guide_flags.get(key, false)))

	Encyclopedia.restore(discovered_ids, milestone_index)
	GS.bonus_draws = int(meta.get("bonus_draws", 0))
	GS.permanent_energy_bonus = int(meta.get("permanent_energy_bonus", 0))


# TheTileMap._ready 末尾延迟调用：恢复耕地与历法，不重放开垦副作用。
func apply_run():
	if not pending_run_restore:
		return
	pending_run_restore = false

	var t = GS.tilemap
	if t == null or not is_instance_valid(t):
		return

	# 自由开垦：新格式 run.plots；旧档 parcels 序号自动迁移成左上角。
	# 两格宽的旧档地块（没有第三位）仍按 2×2 补回，避免读档后农田缩水。
	t.claimed_plots = []
	t.plot_horizontal = {}
	t.legacy_2x2_plots = {}
	for po in run.get("plots", []):
		var origin = Vector2(int(po[0]), int(po[1]))
		if origin in t.claimed_plots:
			continue
		var shape = 2
		if po.size() >= 3:
			shape = int(po[2])
		var cells = t.legacy_plot_cells(origin)
		if shape != 2:
			cells = t.plot_cells(origin, shape == 1)
		for cell in cells:
			t.set_cellv(cell, t.farmland_variant(cell))
		t.claimed_plots.append(origin)
		if shape == 2:
			t.legacy_2x2_plots[origin] = true
		elif shape == 1:
			t.plot_horizontal[origin] = true
	for idx in parcels:
		var legacy = t.legacy_parcel_origin(idx)
		if legacy == null or legacy in t.claimed_plots:
			continue
		for cell in t.legacy_plot_cells(legacy):
			t.set_cellv(cell, t.farmland_variant(cell))
		t.claimed_plots.append(legacy)
		t.legacy_2x2_plots[legacy] = true
	t.rebuild_farm_edges()
	GS.farm_quota = int(run.get("farm_quota", 0))

	Season.restore_calendar(
		int(run.get("year", 1)),
		int(run.get("round_in_year", 1)),
		int(run.get("season_index", 0)),
		int(run.get("rounds_in_season", 1)))
	RunStats.year = int(run.get("stats_year", int(run.get("year", 1))))

	var s = run.get("stats", {})
	RunStats.water_spent = int(s.get("water_spent", 0))
	RunStats.plantings = int(s.get("plantings", 0))
	RunStats.harvests = int(s.get("harvests", 0))
	RunStats.entries_found = int(s.get("entries_found", 0))
	RunStats.variants_found = int(s.get("variants_found", 0))
	RunStats.bottle_uses = int(s.get("bottle_uses", 0))
	RunStats.plants_lost = int(s.get("plants_lost", 0))
	RunStats.pests_killed = int(s.get("pests_killed", 0))
	RunStats.mutation_pity = int(run.get("mutation_pity", 0))

	GS.orb_water = int(run.get("orb_water", 0))
	GS.next_spawn = int(run.get("next_spawn", 0))
	GS.no_enemy_turns = int(run.get("no_enemy_turns", 0))
	GS.some_enemy_turns = int(run.get("some_enemy_turns", 0))
	GS.refresh_energy_max()
	GS.energy = GS.energy_max

	BottleManager.hp = int(clamp(int(run.get("bottle_hp", BottleManager.MAX_HP)), 1, BottleManager.MAX_HP))
	BottleManager.power = int(clamp(int(run.get("bottle_power", 0)), 0, BottleManager.MAX_POWER))
	BottleManager.emit_signal("hp_changed", BottleManager.hp, BottleManager.MAX_HP)
	BottleManager.emit_signal("power_changed", BottleManager.power, BottleManager.MAX_POWER)

	# 魔瓶待抽取队列 + 场上植物快照。
	BottleManager.charges.clear()
	for c in run.get("charges", []):
		BottleManager.charges.append(String(c))
	for pd in run.get("plants", []):
		_restore_plant(t, pd)

	# 手牌快照延迟重建（开局发牌是 deferred 的），见 _process。
	_pending_hand_ids = []
	for id in run.get("hand", []):
		_pending_hand_ids.append(String(id))
	_pending_hand_frames = 0

	save_now()


# 主菜单"开始游戏"：整个存档推倒重来。
func start_new():
	applied = true
	pending_run_restore = false
	prologue_seen = false
	tutorial_done = false
	max_year_reached = 1
	max_gate_reached = 0
	hard_mode = Flags.hard_mode
	guide_flags = {}
	discovered_ids = []
	milestone_index = 0
	parcels = []
	plots = []
	_pending_hand_ids = []
	meta = {"bonus_draws": 0, "permanent_energy_bonus": 0}
	run = {}
	has_save = false

	# 本引擎的 File 没有 remove，改用写开再关把存档清成 0 字节；
	# 读取时空文件 JSON 解析自然失败，has_save 保持 false，效果等同删除。
	var f = File.new()
	if f.file_exists(SAVE_PATH):
		if f.open(SAVE_PATH, File.WRITE) == OK:
			f.close()


# ---- 标记点 ----

func mark_prologue_seen():
	if not enabled or not applied:
		return
	prologue_seen = true
	save_now()


func mark_tutorial_done():
	if not enabled or not applied:
		return
	tutorial_done = true
	Flags.skip_tutorial = true
	save_now()


func note_year_reached(year):
	if year > max_year_reached:
		max_year_reached = year


func note_gate_reached(gate):
	if gate > max_gate_reached:
		max_gate_reached = gate


# 主菜单"继续农场"按钮上的一行小字。
func summary_text():
	var year = int(run.get("year", 1))
	var plot_n = int(run.get("plots", []).size())
	if plot_n == 0:
		plot_n = parcels.size()
	return "第 %d 年 · 图鉴 %d/%d 条 · 开垦 %d 块" % [
		year, discovered_ids.size(), GameData.all_entry_ids().size(), plot_n]
