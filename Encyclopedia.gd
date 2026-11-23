extends Node

# 图鉴进度与里程碑。
# 变种算独立条目；里程碑只数基础物种，避免反复刷同一个物种的变种。

signal entry_discovered(entry_id)
signal milestone_claimed(text)

const MILESTONES = [
	{"species": 2, "type": "draw", "amount": 1, "text": "每回合多抽 1 张"},
	{"species": 3, "type": "draw", "amount": 1, "text": "每回合多抽 1 张"},
	{"species": 4, "type": "plots", "text": "可以开垦一块新农田（每轮抽牌 +1，能量上限 +1）"},
	{"entries": 8, "type": "plots", "text": "可以再开垦一块新农田（每轮抽牌 +1，能量上限 +1）"}
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
	return true


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


func next_milestone_text():
	if milestone_index >= MILESTONES.size():
		return "所有图鉴里程碑已完成"
	var m = MILESTONES[milestone_index]
	if m.has("entries"):
		return "下一里程碑：收录 %d 条图鉴（当前 %d 条）" % [
			m["entries"], discovered_count()]
	return "下一里程碑：收录 %d 种基础植物（当前 %d 种）" % [
		m["species"], base_discovered_count()]


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
	Flags.unlock_guide("guide_milestone_seen", 8, "图鉴的分量")
	match m["type"]:
		"energy":
			GS.add_permanent_energy(m["amount"])
			GS.energy = min(GS.energy + m["amount"], GS.energy_max)
		"draw":
			GS.bonus_draws += m["amount"]
		"plots":
			GS.queue_farm_choice()

	Toast.show_message("图鉴里程碑：" + m["text"])
	emit_signal("milestone_claimed", m["text"])