extends Node

# 图鉴进度与里程碑。
# 变种算独立条目；里程碑按图鉴条目数推进，变种也算数，
# 这样反复刷同一物种的变种也有成长，结局则只看物种是否集齐。

signal entry_discovered(entry_id)
signal milestone_claimed(text)

const MILESTONES = [
	# 手牌上限最多加 1 次（封顶 6，GS.HAND_CAP_MAX）；后续里程碑改发现实资源。
	{"entries": 2, "type": "draw", "amount": 1, "text": "手牌上限 +1（回合结束最多留 6 张）"},
	{"entries": 4, "type": "orb", "amount": 5, "text": "水晶球储水 +5"},
	{"entries": 6, "type": "plots", "text": "获得 1 块开垦名额：可在任意空地自选 2×2 位置开垦（能量上限 +1）"},
	{"entries": 10, "type": "plots", "text": "又获得 1 块开垦名额（能量上限 +1）"},
	# 物种扩到 15 个（45 条）之后，里程碑得排到后面还留有盼头，
	# 但四块空地是上限，所以只再排两次开垦。
	{"entries": 14, "type": "power", "amount": 3, "text": "瓶能 +3"},
	{"entries": 20, "type": "plots", "text": "再获得 1 块开垦名额（能量上限 +1）"},
	{"entries": 26, "type": "energy", "amount": 1, "text": "能量上限永久 +1"},
	{"entries": 33, "type": "plots", "text": "最后一块开垦名额到手（能量上限 +1）"},
	{"entries": 40, "type": "power", "amount": 6, "text": "瓶能 +6——图鉴快满了，瓶子也沉不住气了"}
]

var discovered = {}
var milestone_index = 0


func reset_all():
	discovered = {}
	milestone_index = 0


func is_discovered(id):
	return discovered.has(id)


func discover(id):
	if discovered.has(id):
		return false

	discovered[id] = true
	RunStats.entries_found += 1
	emit_signal("entry_discovered", id)
	_check_milestones()
	if discovered_count() >= total_entries():
		Toast.show_message("图鉴已全部收录完成！")
	# SaveGame 是排在最后的 autoload，脚本互指必须走运行时，否则编译期成环。
	var sv = get_node_or_null("/root/SaveGame")
	if sv != null:
		sv.save_now()
	return true


# 读档专用：整体灌入已收录条目与里程碑进度，不触发任何奖励。
func restore(ids, milestone):
	discovered = {}
	for entry_id in ids:
		discovered[entry_id] = true
	milestone_index = milestone


func discovered_count():
	return discovered.size()


func total_entries():
	return GameData.all_entry_ids().size()


func base_discovered_count():
	var n = 0
	for sid in GameData.SPECIES_ORDER:
		if discovered.has(sid):
			n += 1
	return n


# 一个物种只要收录了基础条目或任一变种，就算"见过"。
func species_seen(sid):
	if discovered.has(sid):
		return true
	for i in range(GameData.variants_for(sid).size()):
		if discovered.has(sid + "_v" + str(i)):
			return true
	return false


# 结局门槛：集齐所有物种（每个物种的基础或任一变种都行）。
func all_species_represented():
	for sid in GameData.SPECIES_ORDER:
		if not species_seen(sid):
			return false
	return true


func species_represented_count():
	var n = 0
	for sid in GameData.SPECIES_ORDER:
		if species_seen(sid):
			n += 1
	return n


func next_milestone_text():
	if milestone_index >= MILESTONES.size():
		return "所有图鉴里程碑已完成"
	var m = MILESTONES[milestone_index]
	return "下一里程碑：收录 %d 条图鉴（当前 %d 条）" % [m["entries"], discovered_count()]


func _check_milestones():
	while milestone_index < MILESTONES.size():
		var m = MILESTONES[milestone_index]
		var value = discovered_count() if m.has("entries") else base_discovered_count()
		var need = m["entries"] if m.has("entries") else m["species"]
		if value < need:
			break
		_apply_milestone(m)
		milestone_index += 1


func _apply_milestone(m):
	Flags.unlock_guide("guide_milestone_seen", 9, "图鉴的分量")
	match m["type"]:
		"energy":
			GS.add_permanent_energy(m["amount"])
			GS.energy = min(GS.energy + m["amount"], GS.energy_max)
		"draw":
			GS.bonus_draws += m["amount"]
		"orb":
			GS.orb_water += int(m["amount"])
		"power":
			# BottleManager 排在后面，裸标识符会撞编译环，运行时取节点。
			var bm = get_node_or_null("/root/BottleManager")
			if bm != null:
				bm.add_power(int(m["amount"]))
		"plots":
			GS.queue_farm_choice()

	Toast.show_message("图鉴里程碑：" + m["text"])
	emit_signal("milestone_claimed", m["text"])