extends Node

enum Action {
	PLANT,
	WATER,
	ATTACK,
	DEFEND,
	DRAIN_WATER_DMG_RNG,
	DRAIN_WATER_DMG_ALL,
	HEAL_DMG_NEAR,
	DEF_DMG_NEAR,
	
	ADD_DAMAGE,
	
	DEF_ALL,
	HEAL_ALL_DMG,
	
	SACRIF,
	
	DRAW_3,
	PLUS_ENERGY,

	HASTEN,
	GRAFT,
	CORK,
	NET
}

enum Water {
	W1x1,
	W2x2,
	W3x3
}

enum TurnState {
	UNDEFINED,
	WAITING_FOR_TUTORIAL,
	PLAYING_CARDS,
	UPDATING
}

const CAT_WATER = 1
const CAT_DEF = 2
const CAT_ATK = 3
const CAT_SEED = 4

var CardTexWater = preload("res://cards/card_water.svg")
var CardTexDef = preload("res://cards/card_tank.svg")
var CardTexAtk = preload("res://cards/card_attak.svg")
var CardTexSeed = preload("res://cards/card_seeds.svg")

var turn_state = TurnState.UNDEFINED
var waiting_for_card_selection = false

var card_selector_ui = null
var gold = 0
var energy = 3
var energy_max = 3

var shop_open = false
var upper_panel_mouse = false
var tutorial_mouse = false
var new_cards_mouse = false
var end_turn_mouse = false

# 图鉴里程碑带来的额外抽卡数
var bonus_draws = 0

# 新循环的界面互斥标记
var harvest_open = false
var bottle_open = false
var bestiary_open = false
var year_summary_open = false
var farm_choice_open = false
var shatter_open = false

# 图鉴里程碑触发的开垦选择，避免在收获/魔瓶界面弹出来。
var pending_farm_choices = 0

# 一轮结算结束后先处理魔瓶抽取，全部收下后再发新手牌。
var pending_new_hand = false

func popup_card_selection(card_set: Array):
	waiting_for_card_selection = true
	card_selector_ui.setup_cards(card_set)
	card_selector_ui.popup()
	
func popup_card_winner():
	waiting_for_card_selection = true
	card_selector_ui.setup_win()
	card_selector_ui.popup()

class Card:
	var title: String
	var desc: String
	var cost: int
	var action
	
	var water_shape
	
	# Amount of damage, water, or defense
	var quantity
	
	# Amount of drain for health or water
	var drain
	
	var mult
	
	# Category / build, these things influence card generation
	var cat
	
	var icon
	
	# 卡牌 ID（魔瓶池、存档、调试都靠它）
	var id = ""
	
	# 种子卡对应的植物物种 ID；非种子卡为空
	var species_id = ""
	
	func _init(title_: String, desc_: String, cost_: int, action_):
		title = title_
		desc = desc_
		cost = cost_
		action = action_
		
		quantity = 1
		drain = 1
		
		cat = 0
		icon = null
		
	func shape(water_shape_):
		water_shape = water_shape_
		return self
		
	func with_quantity(amount_):
		quantity = amount_
		return self
		
	func with_drain(amount_):
		drain = amount_
		return self
		
	func with_mult(m):
		mult = m
		return self
		
	func with_cat(c):
		cat = c
		return self
		
	func with_icon(ic):
		icon = ic
		return self
		
	func with_species(s):
		species_id = s
		return self

# The "global state" node. This is where global variables are usually stored,
# as well as things like scene preloads.

var card_basic_plant : Card = Card.new(
	"番茄种子",
	"种下一株番茄。番茄是春季作物，生长快、生命值高。",
	1,
	Action.PLANT).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/basic_seeds.svg")).with_species("tomato")
	
var card_medium_plant : Card = Card.new(
	"向日葵种子",
	"种下一株向日葵。向日葵是夏季作物，需要更多照料。",
	2,
	Action.PLANT).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/middling_seeds.svg")).with_species("sunflower")
	
var card_high_plant : Card = Card.new(
	"南瓜种子",
	"种下一株南瓜。南瓜是秋季作物，藤蔓生长旺盛。",
	3,
	Action.PLANT).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/quality_seeds.svg")).with_species("pumpkin")
	
var card_free_1x1_water : Card = Card.new(
	"水滴",
	"为 1x1 的区域施加 1 点水分",
	0,
	Action.WATER
).shape(Water.W1x1).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/water_drop.svg"))

var card_buy_1x1_water : Card = Card.new(
	"浸润",
	"为 1x1 的区域施加 $DQ 点水分",
	1,
	Action.WATER
).shape(Water.W1x1).with_quantity(2).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/water_drip.svg"))

var card_small_attack : Card = Card.new(
	"重击！",
	"对单个敌人造成 $DQ 点伤害",
	1,
	Action.ATTACK
).with_quantity(1).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/whack.svg"))

var card_small_defend : Card = Card.new(
	"防护网",
	"为单株植物施加 1 点免疫",
	1,
	Action.DEFEND
).with_quantity(1).with_cat(CAT_DEF).with_icon(preload("res://cards/icons/netting_shield.svg"))

# Low water cards

var card_drain1_dmg3 : Card = Card.new(
	"水匕首",
	"从一株植物吸取 1 点水分，并对随机敌人造成 $DQ 点伤害",
	0,
	Action.DRAIN_WATER_DMG_RNG
).with_quantity(3).with_drain(1).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/water_dagger.svg"))

var card_water2_1x1 : Card = Card.new(
	"倾注",
	"为 1x1 的区域施加 2 点水分",
	1,
	Action.WATER
).shape(Water.W1x1).with_quantity(2).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/pour_one.svg"))

var card_water1_2x2 : Card = Card.new(
	"水壶",
	"为 2x2 的区域施加 1 点水分",
	3,
	Action.WATER
).shape(Water.W2x2).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/water_can.svg"))

# Medium water cards

var card_water1_3x3 : Card = Card.new(
	"水桶",
	"为 3x3 的区域施加 1 点水分",
	3,
	Action.WATER
).shape(Water.W3x3).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/water_barrel.svg"))

var card_water2_2x2 : Card = Card.new(
	"水管",
	"为 2x2 的区域施加 2 点水分",
	4,
	Action.WATER
).shape(Water.W2x2).with_quantity(2).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/hose.svg"))

var card_drain3_rng5 : Card = Card.new(
	"水爆",
	"从一株植物吸取 1 点水分，并对随机敌人造成 $DQ 点伤害",
	1,
	Action.DRAIN_WATER_DMG_RNG
).with_drain(1).with_quantity(4).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/water_blast.svg"))

# High water cards

var card_water5 : Card = Card.new(
	"降雨",
	"为单株植物施加 5 点水分",
	3,
	Action.WATER
).shape(Water.W1x1).with_quantity(5).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/rainfall.svg"))

var card_drain7_dmgall5 : Card = Card.new(
	"海啸",
	"从一株植物吸取 4 点水分，并对所有敌人造成 $DQ 点伤害",
	4,
	Action.DRAIN_WATER_DMG_ALL
).with_quantity(5).with_drain(4).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/tsunami.svg"))

var card_drain3_dmgall1 : Card = Card.new(
	"溢流",
	"从一株植物吸取 2 点水分，并对所有敌人造成 $DQ 点伤害",
	2,
	Action.DRAIN_WATER_DMG_ALL
).with_quantity(2).with_drain(2).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/overflow.svg"))

# Low tank cards

var card_3def_1 : Card = Card.new(
	"坚盾",
	"为单株植物施加 3 点免疫",
	1,
	Action.DEFEND
).with_quantity(3).with_cat(CAT_DEF).with_icon(preload("res://cards/icons/tough_shield.svg"))

var card_heal1_dmg1 : Card = Card.new(
	"吸血獠牙",
	"为一株植物恢复 1 点生命，并对最近的敌人造成 $DQ 点伤害",
	1,
	Action.HEAL_DMG_NEAR
).with_quantity(1).with_drain(1).with_cat(CAT_DEF).with_icon(preload("res://cards/icons/vampire_fang.svg")) # Drain is healing for this

var card_def2_dmg1 : Card = Card.new(
	"尖刺盾",
	"为一株植物施加 2 点免疫，并对最近的敌人造成 $DQ 点伤害",
	1,
	Action.DEF_DMG_NEAR
).with_quantity(1).with_drain(2).with_cat(CAT_DEF).with_icon(preload("res://cards/icons/spiked_shield.svg")) # Drain is healing for this # Drain is healing for this

# Medium tank cards

var card_heal2_dmg2 : Card = Card.new(
	"吸血斩",
	"为一株植物恢复 3 点生命，并对最近的敌人造成 $DQ 点伤害",
	3,
	Action.HEAL_DMG_NEAR
).with_quantity(2).with_drain(3).with_cat(CAT_DEF).with_icon(preload("res://cards/icons/vampire_slash.svg")) # Drain is healing for this # Drain is healing for this

var card_def3_dmg3 : Card = Card.new(
	"荆棘",
	"为一株植物施加 3 点免疫，并对最近的敌人造成 $DQ 点伤害",
	3,
	Action.DEF_DMG_NEAR
).with_quantity(3).with_drain(3).with_cat(CAT_DEF).with_icon(preload("res://cards/icons/thorns.svg")) # Drain is healing for this

# Rare tank cards: TODO

var card_def2_all : Card = Card.new(
	"魔法护盾",
	"为所有植物施加 2 点免疫",
	4,
	Action.DEF_ALL
).with_quantity(2).with_cat(CAT_DEF).with_icon(preload("res://cards/icons/magic_shield.svg")) # Drain is healing for this

var card_heal_attack_all : Card = Card.new(
	"吸血爆",
	"为所有植物恢复 2 点生命，并对所有敌人造成 $DQ 点伤害",
	4,
	Action.HEAL_ALL_DMG
).with_drain(2).with_quantity(1).with_cat(CAT_DEF).with_icon(preload("res://cards/icons/vampire_blast.svg"))

# Low attack-focus cards

var card_dmg2 : Card = Card.new(
	"砰！",
	"对单个敌人造成 $DQ 点伤害",
	1,
	Action.ATTACK
).with_quantity(2).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/kapow.svg"))

var card_add1_expensive: Card = Card.new(
	"力量菌菇",
	"为你的下一次攻击增加 1 点伤害",
	1,
	Action.ADD_DAMAGE
).with_quantity(1).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/power_fungi.svg"))

var card_sacrif1_1enem : Card = Card.new(
	"血匕首",
	"消耗 1 点植物生命，并对生命值最低的敌人造成 $DQ 点伤害",
	1,
	Action.SACRIF
).with_quantity(4).with_drain(1).with_mult(1).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/blood_dagger.svg"))

# Medium attack cards

var card_add2 : Card = Card.new(
	"技巧",
	"为你的下一次攻击增加 2 点伤害",
	2,
	Action.ADD_DAMAGE
).with_quantity(2).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/technique.svg"))

var card_sacrif2_2enem : Card = Card.new(
	"血刃",
	"消耗 2 点植物生命，并对生命值最低的 2 个敌人造成 $DQ 点伤害",
	4,
	Action.SACRIF
).with_quantity(4).with_drain(2).with_mult(2).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/blood_blade.svg"))

var card_free_atk : Card = Card.new(
	"嗖！",
	"对一个敌人造成 $DQ 点伤害",
	0,
	Action.ATTACK
).with_quantity(1).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/zing.svg"))

# Rare attack cards

var card_add1_cheap : Card = Card.new(
	"力量水晶",
	"为你的下一次攻击增加 1 点伤害",
	0,
	Action.ADD_DAMAGE
).with_quantity(1).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/power_crystal.svg"))

var card_sacrifice : Card = Card.new(
	"献祭",
	"牺牲一株植物，并对所有敌人造成 $DQ 点伤害",
	5,
	Action.SACRIF
).with_quantity(4).with_drain(0).with_mult(-1).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/sacrifice.svg"))

# GENERAL RARE CARDS

var card_win_plant : Card = Card.new(
	"月见草种子",
	"种下一株月见草。月见草是冬季作物，也是魔瓶中最稀有的种子。",
	3,
	Action.PLANT
).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/mystical_seeds.svg")).with_species("moonflower")

var card_energy : Card = Card.new(
	"免费能量",
	"获得 1 点能量",
	0,
	Action.PLUS_ENERGY
).with_icon(preload("res://cards/icons/free_energy.svg"))

# GENERAL MED CARDS

var card_cards : Card = Card.new(
	"灵光一现",
	"抽 3 张牌",
	1,
	Action.DRAW_3
).with_icon(preload("res://cards/icons/cool_drawing.svg"))

# 新循环：节奏、变异投资与控场
var card_hasten : Card = Card.new(
	"催熟",
	"让一株植物立即生长 $DQ 帧",
	1,
	Action.HASTEN
).with_quantity(2).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/power_crystal.svg"))

var card_graft : Card = Card.new(
	"嫁接",
	"让一株植物下次收获的变异概率提高 $DQ%",
	1,
	Action.GRAFT
).with_quantity(30).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/technique.svg"))

var card_cork : Card = Card.new(
	"瓶塞",
	"为魔瓶抵挡下一次伤害",
	1,
	Action.CORK
).with_cat(CAT_DEF).with_icon(preload("res://cards/icons/tough_shield.svg"))

var card_net : Card = Card.new(
	"捕虫网",
	"对一只虫子造成 $DQ 点伤害，并让它下回合无法攻击",
	1,
	Action.NET
).with_quantity(1).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/zing.svg"))

# 卡牌 ID → 卡牌实例。魔瓶池、基础抽卡、调试都通过这里取牌。
var card_registry = {}

func build_card_registry():
	card_registry = {
		"water_drop": card_free_1x1_water,
		"water_drip": card_buy_1x1_water,
		"water_can": card_water1_2x2,
		"water_pour": card_water2_1x1,
		"water_barrel": card_water1_3x3,
		"water_hose": card_water2_2x2,
		"water_blast": card_drain3_rng5,
		"water_rain": card_water5,
		"tsunami": card_drain7_dmgall5,
		"overflow": card_drain3_dmgall1,
		"water_dagger": card_drain1_dmg3,
		"shield": card_small_defend,
		"tough_shield": card_3def_1,
		"spiked_shield": card_def2_dmg1,
		"magic_shield": card_def2_all,
		"thorns": card_def3_dmg3,
		"vampire_fang": card_heal1_dmg1,
		"vampire_slash": card_heal2_dmg2,
		"vampire_blast": card_heal_attack_all,
		"whack": card_small_attack,
		"kapow": card_dmg2,
		"free_atk": card_free_atk,
		"power_fungi": card_add1_expensive,
		"technique": card_add2,
		"power_crystal": card_add1_cheap,
		"blood_dagger": card_sacrif1_1enem,
		"blood_blade": card_sacrif2_2enem,
		"sacrifice": card_sacrifice,
		"draw3": card_cards,
		"energy": card_energy,
		"hasten": card_hasten,
		"graft": card_graft,
		"cork": card_cork,
		"net": card_net,
		"basic_plant": card_basic_plant,
		"medium_plant": card_medium_plant,
		"high_plant": card_high_plant,
		"win_plant": card_win_plant
	}
	for key in card_registry.keys():
		card_registry[key].id = key


func card_by_id(id):
	return card_registry.get(id, null)


func make_basic_card():
	var c = card_by_id(GameData.roll_basic_card_id())
	if c == null:
		return card_free_1x1_water
	return c


var Game = preload("res://Game.tscn")
var MainMenu = preload("res://MainMenu.tscn")
var Intro = preload("res://Intro.tscn")
var HandCard = preload("res://cards/HandCard.tscn")
var CardBase = preload("res://cards/CardBase.tscn")

var Plant1 = preload("res://plants/plant1/Plant1.tscn")
var Plant2 = preload("res://plants/plant2/Plant2.tscn")
var Plant3 = preload("res://plants/plant3/Plant3.tscn")
var PlantWin = preload("res://plants/winplant/WinPlant.tscn")

var Bug = preload("res://bugs/Bug.tscn")

var hand = null

var current_picked_up_card = null
var cursor: Cursor = null

var tilemap = null

func set_current_card(card: Node):
	if current_picked_up_card != null:
		current_picked_up_card.release()
		current_picked_up_card = null
	current_picked_up_card = card
	
func release_current_card(card: Node):
	if current_picked_up_card == card:
		current_picked_up_card = null

func get_card_base(card: Card):
	var b = CardBase.instance()
	b.get_node("Title").text = card.title
	b.get_node("Desc").text = card.desc
	b.get_node("Cost").text = String(card.cost)
	b.associated_card = card
	return b
	
func spawn_bug_intcoord(x: int, y: int):
	var b = Bug.instance()
	
	tilemap.add_child(b)
	b.position = Vector2(x, y) * 128
	
func spawn_bug_lcoord(pos):
	var b = Bug.instance()
	tilemap.add_child(b)
	
	b.position = pos
	
	return b
	
func get_object_at_map_lcoord(coord: Vector2):
	for obj in get_tree().get_nodes_in_group("Object"):
		var p = obj.position
		if (p - coord).length_squared() < 16:
			return obj
	return null
	
func get_plant_at_map_lcoord(coord: Vector2):
	for obj in get_tree().get_nodes_in_group("Plant"):
		var p = obj.position
		if (p - coord).length_squared() < 16:
			return obj
	return null
	
func get_enemy_at_map_lcoord(coord: Vector2):
	for obj in get_tree().get_nodes_in_group("Enemy"):
		var p = obj.position
		if (p - coord).length_squared() < 16:
			return obj
	return null
	
func get_random_enemy():
	var nodes = get_tree().get_nodes_in_group("Enemy")
	
	if nodes.empty():
		return null
	
	return nodes[randi() % nodes.size()]
	
func get_nearest_enemy(position):
	var node = null
	var dist = 0
	
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		var to_enem = (enemy.position - position).length()
		if node == null:
			node = enemy
			dist = to_enem
		elif to_enem < dist:
			node = enemy
			dist = to_enem
			
	return node
	
	
func get_lowest_health_enemy(exclude = null):
	var node = null
	var dist = 0
	
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if enemy == exclude:
			continue
		
		if node == null:
			node = enemy
			dist = enemy.health
		elif enemy.health < dist:
			node = enemy
			dist = enemy.health
			
	return node


func add_card_to_hand(card: Card):
	var h = HandCard.instance()
	var b = get_card_base(card)
	
	b.dynamic_display = true
	
	h.associated_card = card
	
	h.add_child(b)
	
	hand.add_child(h)

func _ready():
	OS.set_window_maximized(true)
	
	build_card_registry()
	reset_all_state()
	
var current_turns = null
var current_obj = null
	
func turn_processor():
	for plant in get_tree().get_nodes_in_group("Plant"):
		current_obj = plant
		plant.take_turn()
		yield()
		
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		current_obj = enemy
		enemy.take_turn()
		yield()
		
	current_obj = null
	return null
	
enum SpawnOpt {
	Bug2,
	Bug3,
	Bug5,
	Bug9
}
var spawn_1bug2 = [SpawnOpt.Bug2]
var spawn_2bug2 = [SpawnOpt.Bug2, SpawnOpt.Bug2]
var spawn_3bug2 = [SpawnOpt.Bug2, SpawnOpt.Bug2, SpawnOpt.Bug2]
var spawn_2bug3 = [SpawnOpt.Bug3, SpawnOpt.Bug3]
var spawn_3bug3 = [SpawnOpt.Bug3, SpawnOpt.Bug3, SpawnOpt.Bug3]
var spawn_4bug3 = [SpawnOpt.Bug3, SpawnOpt.Bug3, SpawnOpt.Bug3, SpawnOpt.Bug3]
var spawn_bug5 = [SpawnOpt.Bug5]
var spawn_2bug5 = [SpawnOpt.Bug5, SpawnOpt.Bug5]
var spawn_3bug_w5 = [SpawnOpt.Bug5, SpawnOpt.Bug3, SpawnOpt.Bug3]
var spawn_bug9 = [SpawnOpt.Bug9, SpawnOpt.Bug2, SpawnOpt.Bug2]
var spawn_5bug = [SpawnOpt.Bug5, SpawnOpt.Bug5, SpawnOpt.Bug3, SpawnOpt.Bug2, SpawnOpt.Bug2]
var spawn_configs = [
	spawn_1bug2,
	spawn_1bug2,
	spawn_1bug2,
	spawn_2bug2,
	spawn_2bug2,
	spawn_2bug2,
	spawn_2bug2,
	spawn_3bug2,
	spawn_2bug2,
	spawn_2bug3,
	spawn_2bug3,
	spawn_3bug2,
	spawn_2bug3,
	spawn_3bug3,
	spawn_2bug3,
	spawn_2bug3,
	spawn_4bug3,
	spawn_2bug3,
	spawn_bug5,
	spawn_3bug3,
	spawn_bug5,
	spawn_2bug5,
	spawn_3bug3,
	spawn_2bug3,
	spawn_3bug_w5,
	spawn_3bug3,
	spawn_2bug5,
	spawn_3bug3,
	spawn_bug9,
	spawn_3bug3,
	spawn_2bug3,
	spawn_5bug,
	spawn_3bug3,
	spawn_3bug_w5,
	spawn_2bug3
]

var next_spawn = 0
	
func spawn_enemies():
	 # DEBUG
	
	var cfg = spawn_configs[next_spawn].duplicate()
	if Season.is_summer():
		cfg.append(SpawnOpt.Bug3)
	# TODO: Keep using "difficult" configs
	next_spawn += 1
	if next_spawn >= spawn_configs.size():
		next_spawn = 11 - 2 # Allow some easy
	
	# Enemies are spawned near plants
	var plants = get_tree().get_nodes_in_group("Plant")
	
	# Can't spawn if there are no plants, also wil cause div by zero
	if plants.size() == 0:
		return
	
	var count_enemys = get_tree().get_nodes_in_group("Enemy").size()
	var summer = Season.is_summer()
	var enemy_cap = 6 if summer else 5
	
	# Three times
	for item in cfg:
		# 夏季虫害更多：上限提高，且配置额外补一只
		if count_enemys >= enemy_cap:
			return
		
		# Try 100 times to spawn an enemy
		for attempt in range(0, 100):
			var p = plants[randi() % plants.size()]
			var x = (randi() % 5) - 2
			var y = (randi() % 5) - 2
			var pos = p.position + Vector2(x, y) * 128
			
			var existing = get_object_at_map_lcoord(pos)
			if existing == null:
				var bug = Bug.instance()
				bug.position = pos
				tilemap.add_child(bug)
				
				if item == SpawnOpt.Bug2:
					bug.health = 2
				if item == SpawnOpt.Bug3:
					bug.health = 3
				if item == SpawnOpt.Bug5:
					bug.health = 5
				if item == SpawnOpt.Bug9:
					bug.health = 9
				count_enemys += 1
				break
	
func end_turn():
	# Must be in PLAYING_CARDS or WAITING_FOR_TUTORIAL state
	if turn_state != TurnState.PLAYING_CARDS or shatter_open:
		return
	
	SFX.end_turn.play_sfx()
	
	hand.clear_hand()
	current_picked_up_card = null
	
	# You get 3 free turns between enemies...? Summer: 2.
	var spawn_gap = 2 if Season.is_summer() else 3
	if no_enemy_turns >= spawn_gap or some_enemy_turns >= 12:
		spawn_enemies()
		# Give some bonus for fighting enemies
		no_enemy_turns = -int(some_enemy_turns / 2)
		some_enemy_turns = 0
	
	turn_state = TurnState.UPDATING
	current_turns = turn_processor()
	if current_turns == null:
		_finish_round_processing()


# 植物和虫子结算完后，先把本轮积攒的魔瓶抽取处理掉，
# 再发下一轮手牌，避免收获多次时连续弹窗打断节奏。
func _finish_round_processing():
	# 魔瓶抽取或瓶碎还没处理完时，先不派新手牌。
	if has_node("/root/BottleManager") and BottleManager.is_busy():
		pending_new_hand = true
		return
	deal_new_hand()

# Used for plant markers!
var global_sine_timer = 0

func _process(delta):
	if Input.is_action_just_pressed("fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
	
	global_sine_timer += 0.4 * delta
	if global_sine_timer >= 1:
		global_sine_timer -= 1
		
var draw_pile = []
var discard_pile = []

var camera = null
	
func shuffle_cards():
	discard_pile.shuffle()
	draw_pile = discard_pile
	discard_pile = []
	
func draw_card():
	if not draw_pile.empty():
		return draw_pile.pop_front()
		
	# 弃牌堆里是魔瓶给的高级牌，先洗回来
	if not discard_pile.empty():
		shuffle_cards()
		return draw_pile.pop_front()
		
	# 基础牌不再需要有限的牌库：每轮从基础池现抽
	return make_basic_card()
	
func draw_card_to_hand():
	var c = draw_card()
	if c == null:
		return
	add_card_to_hand(c)
	
var card_draw_count = 5
		
func deal_new_hand():
	Season.advance_round()
	
	if get_tree().get_nodes_in_group("Enemy").empty():
		no_enemy_turns += 1
	else:
		some_enemy_turns += 1
	
	TutorialSteps.mark_have_ended_turn()
	
	for plant in get_tree().get_nodes_in_group("Plant"):
		plant.set_defense(plant.defense - 1)
	
	_deal_cards()


# 只发这一轮的手牌，不推进季节。瓶碎重开时也走这里。
func _deal_cards():
	var draws = card_draw_count + bonus_draws
	for i in range(0, draws):
		var c = draw_card()
		if c == null:
			break
		add_card_to_hand(c)
	
	# 轻量兜底：只有在一张水牌都没有时补一张，避免整轮完全停滞。
	# 不再按植物数量固定塞水牌。
	if get_tree().get_nodes_in_group("Plant").size() > 0 and _hand_water_count() == 0:
		add_card_to_hand(card_free_1x1_water)
		Toast.show_message("手牌里没有水牌，补一张水滴应急。")
	
	turn_state = TurnState.PLAYING_CARDS
	
	energy = energy_max
	
	SFX.card_deal.play_sfx()


func _hand_water_count():
	if hand == null or not is_instance_valid(hand):
		return 0
	var n = 0
	for c in hand.get_children():
		if c.associated_card != null and c.associated_card.action == Action.WATER:
			n += 1
	return n


# 瓶碎结算：图鉴与已开垦农田保留，只把年份、季节和场上单位清回起点。
func restart_after_shatter():
	if has_node("/root/BottleManager"):
		BottleManager.force_close()

	if hand != null and is_instance_valid(hand):
		for c in hand.get_children():
			hand.remove_child(c)
			c.queue_free()
	draw_pile = []
	discard_pile = []

	for plant in get_tree().get_nodes_in_group("Plant"):
		var pp = plant.get_parent()
		if pp != null:
			pp.remove_child(plant)
		plant.queue_free()
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		var ep = enemy.get_parent()
		if ep != null:
			ep.remove_child(enemy)
		enemy.queue_free()

	current_turns = null
	current_obj = null
	current_picked_up_card = null
	pending_new_hand = false
	no_enemy_turns = 0
	some_enemy_turns = 0
	next_spawn = 0

	Season.year = 1
	Season.round_in_year = 1
	Season.change_season(0, false, true)
	RunStats.year = 1
	RunStats.reset_year()
	RunStats.mutation_pity = 0

	# energy_max / bonus_draws 来自图鉴与开垦，属于要保留的进度。
	energy = energy_max
	_deal_cards()


		
func _physics_process(delta):
	# 等魔瓶把本轮积攒的抽取全部结算完，再发下一轮手牌。
	if pending_new_hand:
		if has_node("/root/BottleManager") and BottleManager.is_busy():
			return
		pending_new_hand = false
		deal_new_hand()
		return

	if current_turns != null:
		if not is_instance_valid(current_obj):
			current_turns = current_turns.resume()
			
			if current_turns == null:
				_finish_round_processing()
		elif current_obj.turn_over():
			current_obj.finalize_turn()
			current_turns = current_turns.resume()
			
			if current_turns == null:
				_finish_round_processing()
				

func get_discard_pos():
	var s = get_viewport().size
	var cam_zoom = camera.zoom
	return camera.global_position + s * 0.5 * cam_zoom + Vector2(0, 200) * cam_zoom
	
# Should this get reset?
var tutorial = true

# Number of turns without any enemies...
# Enemies will be spawned regularly
var no_enemy_turns = 0

var some_enemy_turns = 0

var auto_water = false
	
func reset_all_state():
	tutorial = true # SHould this get reset?
	if has_node("/root/TutorialSteps"):
		TutorialSteps.tutorial = null
		TutorialSteps.reset_all_state()
	
	if has_node("/root/CardCreation"):
		CardCreation.reset_all_state()
	
	turn_state = TurnState.UNDEFINED
	waiting_for_card_selection = false

	card_selector_ui = null
	gold = 0
	
	energy_max = 3
	energy = energy_max
	
	hand = null

	current_picked_up_card = null
	cursor = null
	
	current_turns = null
	current_obj = null
	
	global_sine_timer = 0
	
	draw_pile = []
	discard_pile = []

	camera = null
	
	tilemap = null
	
	card_draw_count = 5 # Will be set by tutorial
	
	no_enemy_turns = 0
	some_enemy_turns = 0
	
	shop_open = false
	upper_panel_mouse = false
	tutorial_mouse = false
	new_cards_mouse = false
	end_turn_mouse = false
	
	bonus_draws = 0
	
	harvest_open = false
	bottle_open = false
	bestiary_open = false
	year_summary_open = false
	farm_choice_open = false
	shatter_open = false
	
	pending_farm_choices = 0
	pending_new_hand = false
	
	auto_water = false
	
	next_spawn = 0
	if has_node("/root/Flags") and Flags.hard_mode:
		# Start with much harder bugs
		next_spawn = 12
	
	# 这些 autoload 比 GS 晚创建，启动时可能还不存在
	if has_node("/root/RunStats"):
		RunStats.reset_all()
	if has_node("/root/Encyclopedia"):
		Encyclopedia.reset_all()
	if has_node("/root/BottleManager"):
		BottleManager.reset_all()
	if has_node("/root/HarvestManager"):
		HarvestManager.reset_all()
	if has_node("/root/YearSummary"):
		YearSummary.reset_all()
	if has_node("/root/EncyclopediaUI"):
		EncyclopediaUI.close()
	if has_node("/root/FarmChoiceUI"):
		FarmChoiceUI.reset_all()
	if has_node("/root/Toast"):
		Toast.clear()


# 图鉴里程碑给一次开垦机会，由玩家自己选位置。
func queue_farm_choice():
	pending_farm_choices += 1

