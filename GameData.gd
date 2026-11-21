extends Node

# 植物物种、图鉴条目与魔瓶卡池的静态数据。
# 每种植物 = 1 个基础条目 + 2 个变种条目，变种算独立图鉴条目。

const SPECIES_ORDER = ["tomato", "sunflower", "pumpkin", "moonflower"]

const SPECIES = {
	"tomato": {
		"name": "番茄",
		"scientific": "Solanum lycopersicum",
		"family": "茄科 · 番茄属",
		"origin": "南美洲安第斯山区",
		"season": "spring",
		"season_name": "春",
		"frames": 4,
		"health": 7,
		"level": 1,
		"scene": "res://plants/plant1/Plant1.tscn",
		"photo": "res://plants/plant1/growth_3_more_simple.svg",
		"pool": "basic",
		"lore": "番茄是喜温、喜光的茄科作物，原产于南美洲安第斯山区。充足日照和稳定水分能让果实顺利转色。",
		"variants": [
			{"name": "樱桃番茄", "scientific": "Solanum lycopersicum var. cerasiforme",
				"desc": "番茄的变种，果实小而圆、糖度较高，常作为鲜食水果栽培。", "color": [1.0, 0.55, 0.55]},
			{"name": "靛蓝玫瑰番茄", "scientific": "Solanum lycopersicum 'Indigo Rose'",
				"desc": "富含花青素的园艺品种，未熟果呈紫黑色，成熟后转为暗红色。", "color": [0.55, 0.35, 0.65]}
		]
	},
	"sunflower": {
		"name": "向日葵",
		"scientific": "Helianthus annuus",
		"family": "菊科 · 向日葵属",
		"origin": "北美洲",
		"season": "summer",
		"season_name": "夏",
		"frames": 6,
		"health": 5,
		"level": 2,
		"scene": "res://plants/plant2/Plant2.tscn",
		"photo": "res://plants/plant2/growth_5.svg",
		"pool": "medium",
		"lore": "向日葵喜光耐旱，原产于北美洲。幼嫩花盘会朝向太阳，成熟后逐渐固定方向。",
		"variants": [
			{"name": "泰迪熊向日葵", "scientific": "Helianthus annuus 'Teddy Bear'",
				"desc": "矮生重瓣品种，舌状花密集，整体呈毛绒球形，适合盆栽观赏。", "color": [1.0, 0.8, 0.25]},
			{"name": "红磨坊向日葵", "scientific": "Helianthus annuus 'Moulin Rouge'",
				"desc": "花瓣呈深红至酒红色的观赏品种，花盘比普通向日葵小。", "color": [0.9, 0.45, 0.2]}
		]
	},
	"pumpkin": {
		"name": "南瓜",
		"scientific": "Cucurbita moschata",
		"family": "葫芦科 · 南瓜属",
		"origin": "中美洲",
		"season": "autumn",
		"season_name": "秋",
		"frames": 6,
		"health": 3,
		"level": 3,
		"scene": "res://plants/plant3/Plant3.tscn",
		"photo": "res://plants/plant3/growth5.svg",
		"pool": "high",
		"lore": "南瓜喜温耐旱，原产于中美洲。藤蔓生长迅速，秋季成熟，果皮坚硬、耐储存。",
		"variants": [
			{"name": "奶油南瓜", "scientific": "Cucurbita moschata 'Butternut'",
				"desc": "长梨形的食用品种，果肉橙黄细腻、甜度高，耐储存。", "color": [1.0, 0.85, 0.55]},
			{"name": "贝贝南瓜", "scientific": "Cucurbita moschata 'Beibei'",
				"desc": "小型板栗南瓜，单果约 300 至 500 克，口感粉糯。", "color": [0.95, 0.6, 0.25]}
		]
	},
	"moonflower": {
		"name": "月见草",
		"scientific": "Oenothera biennis",
		"family": "柳叶菜科 · 月见草属",
		"origin": "北美洲",
		"season": "winter",
		"season_name": "冬",
		"frames": 9,
		"health": 4,
		"level": 4,
		"scene": "res://plants/winplant/WinPlant.tscn",
		"photo": "res://plants/winplant/frames_manual/growth8.svg",
		"pool": "rare",
		"lore": "月见草是二年生草本，原产于北美洲，傍晚开花，种子可榨油。它耐寒，适合在秋冬季节慢慢生长。",
		"variants": [
			{"name": "非洲太阳月见草", "scientific": "Oenothera biennis 'African Sun'",
				"desc": "月见草的园艺品种，株型紧凑、花色明黄，适合花境种植。", "color": [1.0, 0.9, 0.4]},
			{"name": "柠檬日落月见草", "scientific": "Oenothera 'Lemon Sunset'",
				"desc": "月见草属园艺杂交品种，花瓣由柠檬黄渐变为橙粉色。", "color": [1.0, 0.7, 0.55]}
		]
	}
}

const MUTATION_CHANCE = {
	"spring": 0.06,
	"summer": 0.25,
	"autumn": 0.10,
	"winter": 0.06
}

# 每次收获没有变异，下一次变异概率追加 15 个百分点。
const MUTATION_PITY_STEP = 0.15

# 每回合基础抽卡池
const BASIC_POOL = [
	{"id": "water_drop", "weight": 8},
	{"id": "water_drip", "weight": 5},
	{"id": "water_can", "weight": 3},
	{"id": "shield", "weight": 4},
	{"id": "whack", "weight": 4},
	{"id": "kapow", "weight": 2},
	{"id": "basic_plant", "weight": 5}
]

# 魔瓶卡池：不同植物给不同的池
const BOTTLE_POOLS = {
	"basic": [
		{"id": "water_pour", "weight": 4},
		{"id": "water_can", "weight": 3},
		{"id": "water_blast", "weight": 3},
		{"id": "shield", "weight": 3},
		{"id": "tough_shield", "weight": 3},
		{"id": "spiked_shield", "weight": 3},
		{"id": "kapow", "weight": 3},
		{"id": "power_fungi", "weight": 3},
		{"id": "vampire_fang", "weight": 2},
		{"id": "medium_plant", "weight": 2}
	],
	"medium": [
		{"id": "water_barrel", "weight": 4},
		{"id": "water_hose", "weight": 4},
		{"id": "water_blast", "weight": 3},
		{"id": "thorns", "weight": 3},
		{"id": "vampire_slash", "weight": 3},
		{"id": "technique", "weight": 3},
		{"id": "blood_dagger", "weight": 3},
		{"id": "draw3", "weight": 2},
		{"id": "medium_plant", "weight": 3},
		{"id": "high_plant", "weight": 1}
	],
	"high": [
		{"id": "water_rain", "weight": 4},
		{"id": "tsunami", "weight": 3},
		{"id": "overflow", "weight": 3},
		{"id": "magic_shield", "weight": 3},
		{"id": "vampire_blast", "weight": 3},
		{"id": "sacrifice", "weight": 2},
		{"id": "power_crystal", "weight": 3},
		{"id": "high_plant", "weight": 3},
		{"id": "win_plant", "weight": 1}
	],
	"rare": [
		{"id": "tsunami", "weight": 4},
		{"id": "sacrifice", "weight": 4},
		{"id": "vampire_blast", "weight": 4},
		{"id": "magic_shield", "weight": 3},
		{"id": "water_rain", "weight": 3},
		{"id": "win_plant", "weight": 5},
		{"id": "high_plant", "weight": 2}
	]
}


func species(id):
	return SPECIES.get(id, null)


func scene_for(id):
	var sp = SPECIES.get(id, null)
	if sp == null:
		return null
	return load(sp["scene"])


# 图鉴用的成熟期照片
func photo_for(id):
	var sp = SPECIES.get(id, null)
	if sp == null:
		return null
	return load(sp["photo"])


func variants_for(id):
	var sp = SPECIES.get(id, null)
	if sp == null:
		return []
	return sp["variants"]


func variant_color(id, index):
	var sp = SPECIES.get(id, null)
	if sp == null:
		return Color.white
	var vs = sp["variants"]
	if index < 0 or index >= vs.size():
		return Color.white
	var c = vs[index]["color"]
	return Color(c[0], c[1], c[2])


func mutation_chance(season, pity = 0):
	var base = MUTATION_CHANCE.get(season, 0.06)
	return min(1.0, base + MUTATION_PITY_STEP * pity)


func all_entry_ids():
	var out = []
	for sid in SPECIES_ORDER:
		out.append(sid)
		var sp = SPECIES[sid]
		for i in range(sp["variants"].size()):
			out.append(sid + "_v" + str(i))
	return out


# id 可以是 "tomato"，也可以是 "tomato_v0"
func entry(id):
	var sid = id
	var vi = -1
	var idx = id.find("_v")
	if idx > 0:
		sid = id.substr(0, idx)
		vi = int(id.substr(idx + 2))

	var sp = SPECIES.get(sid, null)
	if sp == null:
		return null

	var e = {
		"id": id,
		"species_id": sid,
		"variant_index": vi,
		"is_variant": vi >= 0,
		"name": sp["name"],
		"base_name": sp["name"],
		"scientific": sp["scientific"],
		"family": sp["family"],
		"origin": sp["origin"],
		"season": sp["season"],
		"season_name": sp["season_name"],
		"frames": sp["frames"],
		"health": sp["health"],
		"level": sp["level"],
		"lore": sp["lore"],
		"variant_desc": ""
	}

	if vi >= 0:
		var vs = sp["variants"]
		if vi < vs.size():
			e["name"] = vs[vi]["name"]
			e["variant_desc"] = vs[vi]["desc"]
			if vs[vi].has("scientific"):
				e["scientific"] = vs[vi]["scientific"]

	return e


func roll_basic_card_id():
	var total = 0
	for e in BASIC_POOL:
		total += e["weight"]

	var r = randi() % total
	for e in BASIC_POOL:
		r -= e["weight"]
		if r < 0:
			return e["id"]

	return BASIC_POOL[0]["id"]


# 从某个池子里不重复地抽若干张
func roll_offer(pool_id, count):
	var pool = BOTTLE_POOLS.get(pool_id, BOTTLE_POOLS["basic"])
	var remaining = []
	for e in pool:
		remaining.append(e)

	var out = []
	while out.size() < count and remaining.size() > 0:
		var total = 0
		for e in remaining:
			total += e["weight"]

		var r = randi() % total
		var idx = 0
		for i in range(remaining.size()):
			r -= remaining[i]["weight"]
			if r < 0:
				idx = i
				break

		out.append(remaining[idx]["id"])
		remaining.remove(idx)

	return out