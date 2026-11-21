extends Node

# 一局游戏里的年度统计。年终总结读取这里的数据。

var year = 1

var water_spent = 0
var plantings = 0
var harvests = 0
var entries_found = 0
var variants_found = 0
var bottle_uses = 0
var plants_lost = 0
var pests_killed = 0

# 连续收获没有出现变异时累加，出现变异后清零。
# 跨年保留，避免每年开头都重新攒一遍概率。
var mutation_pity = 0


func reset_year():
	water_spent = 0
	plantings = 0
	harvests = 0
	entries_found = 0
	variants_found = 0
	bottle_uses = 0
	plants_lost = 0
	pests_killed = 0


func reset_all():
	year = 1
	mutation_pity = 0
	reset_year()


func summary_lines():
	return [
		"本年耗水：%d 点" % water_spent,
		"种植：%d 次" % plantings,
		"收获：%d 次" % harvests,
		"图鉴新增：%d 条" % entries_found,
		"发现变异：%d 次" % variants_found,
		"魔瓶转化：%d 次" % bottle_uses,
		"损失植物：%d 株" % plants_lost,
		"击退虫害：%d 只" % pests_killed
	]