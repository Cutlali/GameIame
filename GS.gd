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
	CORK, # 已废弃：瓶塞随第四次试玩移除，保留枚举防序号漂移
	NET,

	ATTACK_ALL,
	HEAL_BOTTLE,
	THORNS,

	MATURE
}

enum Water {
	W1x1,
	W1x2,
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

# 能量：基础 3 点，第一年结束后 +2，之后只靠开垦新田 +1，总上限 7。
const BASE_ENERGY = 3
const ENERGY_CAP = 7
const YEAR_ENERGY_BONUS = 2

# 植物生命、水分、护盾的统一上限。
const PLANT_WATER_MAX = 7

var CardTexWater = preload("res://cards/card_water.svg")
var CardTexDef = preload("res://cards/card_tank.svg")
var CardTexAtk = preload("res://cards/card_attak.svg")
var CardTexSeed = preload("res://cards/card_seeds.svg")

var turn_state = TurnState.UNDEFINED
var waiting_for_card_selection = false

var energy = 3
var energy_max = 3

# 来自图鉴/开垦/商店的永久能量加成，瓶碎重开后保留。
var permanent_energy_bonus = 0

# 水晶球储水。无上限，瓶碎重开后清空。
var orb_water = 0

# 虫子死亡奖励：每轮最多 3 张速成卡，敌方回合拿到的顺延到下一轮。
var mature_rewards_this_round = 0
var pending_mature_rewards = 0

var upper_panel_mouse = false
var tutorial_mouse = false
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
var hand_keep_open = false

# v1.8 开垦名额：图鉴里程碑发放，玩家在任意 2×2 空地自选位置使用。
var farm_quota = 0

# 一轮结算结束后先处理魔瓶抽取，全部收下后再发新手牌。
var pending_new_hand = false

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

	# 临时卡：打出或回合结束消失，不进入弃牌堆。
	var transient = false

	# 水晶球之水：打出时从水晶球存量里扣 1 点。
	var from_orb = false

	# 打在水晶球里时存入的水量；0 表示与每格水量相同。
	# 浇地时始终用 quantity，这个值只影响“倒进球里”。
	var orb_quantity = 0

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

	func with_orb_quantity(amount_):
		orb_quantity = amount_
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

	func as_transient():
		transient = true
		return self

	func from_crystal_orb():
		from_orb = true
		transient = true
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
	1,
	Action.PLANT).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/middling_seeds.svg")).with_species("sunflower")
	
var card_high_plant : Card = Card.new(
	"南瓜种子",
	"种下一株南瓜。南瓜是秋季作物，藤蔓生长旺盛。",
	3,
	Action.PLANT).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/quality_seeds.svg")).with_species("pumpkin")

# 第二年起的进阶种子，阶段④配专属像素图标。
var card_cotton_seed : Card = Card.new(
	"棉花种子",
	"种下一株棉花。棉花是秋季作物，棉铃裂开时收下一团白绒。",
	2,
	Action.PLANT).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/cotton_seeds.png")).with_species("cotton")

var card_rice_seed : Card = Card.new(
	"水稻种子",
	"种下一株水稻。水稻是夏季作物，整株生长都离不开水。",
	3,
	Action.PLANT).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/rice_seeds.png")).with_species("rice")

var card_wintersweet_seed : Card = Card.new(
	"腊梅种子",
	"种下一株腊梅。腊梅是冬季开花的稀有木本，凌寒而开、香气清冽。",
	3,
	Action.PLANT).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/wintersweet_seeds.png")).with_species("wintersweet")

# ===== 第二轮扩充的 8 个新物种种子。
# 专属像素图标由素材脚本生成，build_card_registry 末尾按文件是否存在替换；
# 这里先挂通用种子袋，素材缺席时游戏也照样能跑。
var card_wheat_seed : Card = Card.new(
	"小麦种子",
	"种下一株小麦。麦苗挨过一冬，抽穗时穗子会把秆子压弯。",
	1,
	Action.PLANT).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/basic_seeds.svg")).with_species("wheat")

var card_mint_seed : Card = Card.new(
	"薄荷种子",
	"种下一株薄荷。根茎横着走，掐一截又能另起一丛。",
	1,
	Action.PLANT).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/basic_seeds.svg")).with_species("mint")

var card_flax_seed : Card = Card.new(
	"亚麻种子",
	"种下一株亚麻。茎细如鞭，天蓝的花早上开、午后就落。",
	2,
	Action.PLANT).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/basic_seeds.svg")).with_species("flax")

var card_soybean_seed : Card = Card.new(
	"大豆种子",
	"种下一株大豆。根瘤自己制氮，收完的地力反而更好。",
	2,
	Action.PLANT).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/basic_seeds.svg")).with_species("soybean")

var card_maize_seed : Card = Card.new(
	"玉米种子",
	"种下一株玉米。顶上一把雄穗，腰间接一穗苞叶裹着的果穗。",
	3,
	Action.PLANT).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/basic_seeds.svg")).with_species("maize")

var card_potato_seed : Card = Card.new(
	"马铃薯种子",
	"种下一株马铃薯。能吃的是土里的块茎，秧子一枯就能挖。",
	3,
	Action.PLANT).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/basic_seeds.svg")).with_species("potato")

var card_sugarcane_seed : Card = Card.new(
	"甘蔗种子",
	"种下一株甘蔗。节间贮满糖汁，入冬正是砍下来榨的时节。",
	3,
	Action.PLANT).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/mystical_seeds.svg")).with_species("sugarcane")

var card_saffron_seed : Card = Card.new(
	"藏红花种子",
	"种下一株藏红花。秋末开淡紫的花，金贵的是花里那三根红柱头。",
	3,
	Action.PLANT).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/mystical_seeds.svg")).with_species("saffron")
	
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
).with_quantity(3).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/whack.svg"))

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
	"为 2x2 的区域施加 $DQ 点水分",
	3,
	Action.WATER
).shape(Water.W2x2).with_quantity(2).with_orb_quantity(4).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/water_can.svg"))

# Medium water cards

var card_water1_3x3 : Card = Card.new(
	"水桶",
	"为 3x3 的区域施加 $DQ 点水分",
	5,
	Action.WATER
).shape(Water.W3x3).with_quantity(2).with_orb_quantity(8).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/water_barrel.svg"))

var card_water2_2x2 : Card = Card.new(
	"水管",
	"为 1x2 的区域施加 $DQ 点水分",
	2,
	Action.WATER
).shape(Water.W1x2).with_quantity(2).with_orb_quantity(3).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/hose.svg"))

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
	3,
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
).with_quantity(4).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/kapow.svg"))

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
).with_quantity(5).with_drain(1).with_mult(1).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/blood_dagger.svg"))

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
	3,
	Action.SACRIF
).with_quantity(6).with_drain(2).with_mult(2).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/blood_blade.svg"))

var card_free_atk : Card = Card.new(
	"嗖！",
	"对一个敌人造成 $DQ 点伤害",
	0,
	Action.ATTACK
).with_quantity(2).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/zing.svg"))

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
	4,
	Action.SACRIF
).with_quantity(4).with_drain(0).with_mult(-1).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/sacrifice.svg"))

# 虫群变大之后，全场伤害越来越难收掉高血量的那一只，
# 所以补两张专注单体的硬伤害牌：一张中阶稳定出力，一张稀有阶一击定音。
var card_trapper : Card = Card.new(
	"捕虫夹",
	"合拢夹住单个敌人，造成 $DQ 点伤害",
	2,
	Action.ATTACK
).with_quantity(6).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/whack.svg"))

var card_queen_sting : Card = Card.new(
	"蜂后之刺",
	"盯住最厚的那层壳扎下去：对单个敌人造成 $DQ 点伤害",
	4,
	Action.ATTACK
).with_quantity(14).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/blood_blade.svg"))

# GENERAL RARE CARDS

var card_win_plant : Card = Card.new(
	"月见草种子",
	"种下一株月见草。月见草是冬季作物，也是魔瓶中最稀有的种子。",
	3,
	Action.PLANT
).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/mystical_seeds.svg")).with_species("moonflower")

# 终局种子：图鉴集齐后由魔瓶送出，成熟时进入结局。
var card_final_seed : Card = Card.new(
	"最后的种子",
	"从魔瓶最深处浮出的一颗种子。它不属于任何一季，却把四季都收在里面。",
	1,
	Action.PLANT
).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/mystical_seeds.svg")).with_species("final_seed")

var card_energy : Card = Card.new(
	"免费能量",
	"获得 1 点能量",
	0,
	Action.PLUS_ENERGY
).with_icon(preload("res://cards/icons/free_energy.svg"))

# 临时魔法：把瓶里的魔力当场倒进这一回合。能量本来就每回合清零，
# 所以这三张牌打出即弃，不留在牌库里占位置。
var card_energy_dew : Card = Card.new(
	"凝露",
	"立刻获得 $DQ 点能量，用完即散。",
	0,
	Action.PLUS_ENERGY
).with_quantity(1).with_icon(preload("res://cards/icons/free_energy.svg")).as_transient()

var card_energy_spring : Card = Card.new(
	"甘泉",
	"立刻获得 $DQ 点能量，用完即散。",
	0,
	Action.PLUS_ENERGY
).with_quantity(2).with_icon(preload("res://cards/icons/free_energy.svg")).as_transient()

var card_energy_geyser : Card = Card.new(
	"涌泉",
	"立刻获得 $DQ 点能量，用完即散。",
	0,
	Action.PLUS_ENERGY
).with_quantity(3).with_icon(preload("res://cards/icons/free_energy.svg")).as_transient()

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

var card_net : Card = Card.new(
	"捕虫网",
	"对一只虫子造成 $DQ 点伤害，并让它下回合无法攻击",
	1,
	Action.NET
).with_quantity(2).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/zing.svg"))

# 逐年解锁的应对工具：新压力到来的同一年，魔瓶会开始提供解法。
var card_swarm : Card = Card.new(
	"蜂群",
	"对所有敌人造成 $DQ 点伤害",
	3,
	Action.ATTACK_ALL
).with_quantity(2).with_cat(CAT_ATK).with_icon(preload("res://cards/icons/vampire_blast.svg"))

# 修补卡与瓶塞都已在 v1.8 删除：魔瓶 3 滴血不可逆、无缓兵之计。
# HEAL_BOTTLE 枚举保留占位，避免后面的动作序号漂移。

var card_thorns_armor : Card = Card.new(
	"反伤甲",
	"为一株植物施加 2 点护盾，被虫咬时反伤 2 点",
	2,
	Action.THORNS
).with_quantity(2).with_drain(2).with_cat(CAT_DEF).with_icon(preload("res://cards/icons/thorns.svg"))

# 虫子死亡奖励：0 费，让一株植物立刻成熟。
var card_mature : Card = Card.new(
	"速成",
	"让一株植物立刻成熟，结束回合时收获。",
	0,
	Action.MATURE
).with_cat(CAT_SEED).with_icon(preload("res://cards/icons/power_crystal.svg")).as_transient()

# 水晶球取水：0 费，打出时从储水里扣 1 点。
var card_orb_water : Card = Card.new(
	"水晶球之水",
	"从水晶球取出 1 点水，浇给一株植物。",
	0,
	Action.WATER
).shape(Water.W1x1).with_quantity(1).with_cat(CAT_WATER).with_icon(preload("res://cards/icons/water_drop.svg")).from_crystal_orb()

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
		"energy_dew": card_energy_dew,
		"energy_spring": card_energy_spring,
		"energy_geyser": card_energy_geyser,
		"trapper": card_trapper,
		"queen_sting": card_queen_sting,
		"hasten": card_hasten,
		"graft": card_graft,
		"net": card_net,
		"swarm": card_swarm,
		"thorns_armor": card_thorns_armor,
		"mature": card_mature,
		"orb_water": card_orb_water,
		"basic_plant": card_basic_plant,
		"medium_plant": card_medium_plant,
		"cotton_seed": card_cotton_seed,
		"high_plant": card_high_plant,
		"rice_seed": card_rice_seed,
		"wintersweet_seed": card_wintersweet_seed,
		"wheat_seed": card_wheat_seed,
		"mint_seed": card_mint_seed,
		"flax_seed": card_flax_seed,
		"soybean_seed": card_soybean_seed,
		"maize_seed": card_maize_seed,
		"potato_seed": card_potato_seed,
		"sugarcane_seed": card_sugarcane_seed,
		"saffron_seed": card_saffron_seed,
		"win_plant": card_win_plant,
		"final_seed": card_final_seed
	}
	for key in card_registry.keys():
		card_registry[key].id = key
	apply_special_icons()


# 第二轮新卡的专属像素图标。素材由 .promo 脚本生成，
# 文件还没到位时退回上面挂的通用图标，保证游戏不会因为缺图崩掉。
const SPECIAL_ICONS = {
	"wheat_seed": "res://cards/icons/wheat_seeds.png",
	"mint_seed": "res://cards/icons/mint_seeds.png",
	"flax_seed": "res://cards/icons/flax_seeds.png",
	"soybean_seed": "res://cards/icons/soybean_seeds.png",
	"maize_seed": "res://cards/icons/maize_seeds.png",
	"potato_seed": "res://cards/icons/potato_seeds.png",
	"sugarcane_seed": "res://cards/icons/sugarcane_seeds.png",
	"saffron_seed": "res://cards/icons/saffron_seeds.png",
	"energy_dew": "res://cards/icons/energy_dew.png",
	"energy_spring": "res://cards/icons/energy_spring.png",
	"energy_geyser": "res://cards/icons/energy_geyser.png",
	"trapper": "res://cards/icons/trapper.png",
	"queen_sting": "res://cards/icons/queen_sting.png"
}


func apply_special_icons():
	for cid in SPECIAL_ICONS.keys():
		var path = SPECIAL_ICONS[cid]
		var card = card_registry.get(cid, null)
		if card != null and ResourceLoader.exists(path):
			card.icon = load(path)


func card_by_id(id):
	return card_registry.get(id, null)


func make_basic_card():
	var c = card_by_id(GameData.roll_basic_card_id())
	if c == null:
		return card_free_1x1_water
	return c


# 每轮发牌的水位保证：从基础池的水牌里按权重随一张。
func make_water_card():
	var entries = []
	var total = 0
	for e in GameData.BASIC_POOL:
		var c = card_by_id(String(e["id"]))
		if c != null and c.cat == CAT_WATER:
			entries.append(e)
			total += int(e["weight"])
	if entries.empty():
		return card_free_1x1_water
	var r = randi() % total
	for e in entries:
		r -= int(e["weight"])
		if r < 0:
			return card_by_id(String(e["id"]))
	return card_by_id(String(entries[0]["id"]))


var Game = preload("res://Game.tscn")
var MainMenu = preload("res://MainMenu.tscn")
var Intro = preload("res://Intro.tscn")
var Ending = preload("res://Ending.tscn")

# 结局只播一次；重开新局时在 reset_all_state() 里清掉。
var ending_started = false
var HandCard = preload("res://cards/HandCard.tscn")
var CardBase = preload("res://cards/CardBase.tscn")

var Plant1 = preload("res://plants/plant1/Plant1.tscn")
var Plant2 = preload("res://plants/plant2/Plant2.tscn")
var Plant3 = preload("res://plants/plant3/Plant3.tscn")
var PlantWin = preload("res://plants/winplant/WinPlant.tscn")

var Bug = preload("res://bugs/Bug.tscn")

var hand = null
# 右上角 HUD，水晶球的命中判定由它提供。
var hud = null
# 游戏内的《瓶中手记》，教程和事件提示都要直接翻到某一页。
var guide = null

# 教程阶段锁：只允许当前阶段需要的操作。
var tutorial_allow_guide = false
var tutorial_allow_end_turn = false
var tutorial_allowed_action = ""


# 教程期间只放行当前阶段需要的卡牌，避免把关键牌浪费在空地上。
func tutorial_card_allowed(card):
	if not tutorial:
		return true
	if card == null:
		return false
	match tutorial_allowed_action:
		"plant":
			return card.action == Action.PLANT
		"water":
			return card.action == Action.WATER
		"attack":
			return card.action == Action.ATTACK
	return false

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
	if hand == null or not is_instance_valid(hand):
		return
	var h = HandCard.instance()
	var b = get_card_base(card)
	
	b.dynamic_display = true
	
	h.associated_card = card
	
	h.add_child(b)
	
	hand.add_child(h)


# 能量上限 = 基础 3 + 历史最高年到过第 2 年再 +2 + 永久加成（开垦/图鉴/商店），最高 7。
# 用历史最高年份是因为瓶碎回到第一年时，玩家攒下的力量不回落。
func refresh_energy_max():
	var year_bonus = 0
	var gate_year = Season.year
	# SaveGame 是排在最后的 autoload，编译期直引会成环，运行时取节点。
	var sv = get_node_or_null("/root/SaveGame")
	if sv != null and sv.enabled:
		gate_year = max(Season.year, sv.max_year_reached)
	if gate_year >= 2:
		year_bonus = YEAR_ENERGY_BONUS
	var target = BASE_ENERGY + year_bonus + permanent_energy_bonus
	if target > ENERGY_CAP:
		target = ENERGY_CAP
	energy_max = target


func add_permanent_energy(amount):
	permanent_energy_bonus += amount
	refresh_energy_max()


func store_orb_water(amount):
	if amount <= 0:
		return
	orb_water += amount


# 鼠标是否正停在水晶球上（拖拽水牌时用来判断投放目标）。
func is_over_orb():
	return hud != null and is_instance_valid(hud) and hud.is_mouse_over_orb()


# 把水牌直接打在水晶球上：水量全部存进球里，不浇地、不溢出。
# 水晶球之水本身是从球里取出来的，不能再存回去。
func play_water_into_orb(card):
	if card == null or card.from_orb or card.quantity <= 0:
		return false
	var stored = card.orb_quantity if card.orb_quantity > 0 else card.quantity
	store_orb_water(stored)
	energy -= card.cost
	if energy < 0:
		energy = 0
	TutorialSteps.mark_stored_orb()
	return true


# 手牌里已经取出的水晶球之水数量，用来限制从 HUD 重复取水。
func orb_water_in_hand():
	var n = 0
	if hand == null or not is_instance_valid(hand):
		return 0
	for c in hand.get_children():
		if c.associated_card != null and c.associated_card.from_orb:
			n += 1
	return n


# 一只虫子死亡 → 一张 0 费速成卡。
# 手牌存在时直接进手牌；敌方回合拿到的先存着，下一轮发牌时补进来。
func grant_mature_reward():
	if mature_rewards_this_round >= 3:
		return
	mature_rewards_this_round += 1
	if turn_state == TurnState.PLAYING_CARDS and hand != null and is_instance_valid(hand):
		add_card_to_hand(card_mature)
	else:
		pending_mature_rewards += 1

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
	Bug9,
	BottleBiter,
	Elite,
	Giant,
	Fly
}

var flyers_seen = false
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
# 第一次遇到巨虫时给一句解释，之后不再啰嗦。
var giants_seen = false

func _spawn_bug_at(pos, item):
	if get_object_at_map_lcoord(pos) != null:
		return false

	var year = Season.year
	var bug = Bug.instance()
	bug.position = pos
	if item == SpawnOpt.Bug2:
		bug.health = 2
	elif item == SpawnOpt.Bug3:
		bug.health = 3
	elif item == SpawnOpt.Bug5:
		bug.health = 5
	elif item == SpawnOpt.Bug9:
		bug.health = 9
	elif item == SpawnOpt.BottleBiter:
		# 瓶虱：会隔几回合直接啃咬魔瓶。
		bug.health = 3
		bug.is_bottle_biter = true
	elif item == SpawnOpt.Elite:
		# 精英虫：血更厚、有外壳、咬得更重。
		bug.health = 6
		bug.is_elite = true
	elif item == SpawnOpt.Fly:
		# 飞虫：血薄但每回合换位扑向最渴的植物，靠走位而不是血量制造压力。
		bug.health = 2
		bug.is_flyer = true
		if not flyers_seen:
			flyers_seen = true
			Toast.show_message("一只飞虫贴着瓶壁盘旋：它不守原地，哪株最渴扑向哪株。")
	elif item == SpawnOpt.Giant:
		# 巨虫：大波次的压场角色。自带年份成长，动作慢但咬得狠。
		bug.health = 10 + 2 * max(0, year - 2)
		bug.is_giant = true
		if not giants_seen:
			giants_seen = true
			Toast.show_message("一只巨虫挤进了瓶底：壳厚血多，得攒够单体伤害才打得动。")
	if item != SpawnOpt.Giant and item != SpawnOpt.Fly:
		# 年度成长：从第 2 年起把普通虫的最低血量抬到 3+年份
		# （2 年 5 滴、3 年 6 滴、4 年 7 滴……），
		# 一张砰！再也顺手带不掉一只虫，蜂群这类全场伤害也不再万能。
		var hp_floor = 2 if year <= 1 else 3 + year
		bug.health = max(bug.health + max(0, year - 1), hp_floor)
	tilemap.add_child(bug)
	return true

func build_spawn_config():
	# 年度压力：虫子数量逐年增加，第 3 年出现瓶虱、第 4 年出现精英虫。
	var year = Season.year
	var cfg = spawn_configs[next_spawn].duplicate()
	if Season.is_summer():
		cfg.append(SpawnOpt.Bug3)
	if year >= 2:
		cfg.append(SpawnOpt.Bug2)
		# 飞虫从第 2 年起登场，第 4 年起可能成双。
		if randf() < 0.55:
			cfg.append(SpawnOpt.Fly)
		if year >= 4 and randf() < 0.35:
			cfg.append(SpawnOpt.Fly)
	if year >= 3:
		cfg.append(SpawnOpt.Bug3)
	if year >= 4:
		cfg.append(SpawnOpt.Bug5)
	if year >= 5:
		cfg.append(SpawnOpt.Bug3)
	if year >= 3 and randf() < 0.45:
		cfg.append(SpawnOpt.BottleBiter)
	if year >= 4 and randf() < 0.40:
		cfg.append(SpawnOpt.Elite)
	# 大波次必带一只巨虫：基础配置就有 3 只以上、且年份到第 2 年之后，
	# 虫群里一定压着一只血厚壳硬的，单体攻击牌终于有值得打的靶子。
	# 放在队首，避免被虫群上限挤掉。
	if year >= 2 and spawn_configs[next_spawn].size() >= 3:
		cfg.push_front(SpawnOpt.Giant)
	return cfg

func spawn_enemies():
	var year = Season.year
	var cfg = build_spawn_config()

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
	# 场上虫子越多，年份越往后，能容纳的虫群上限也越高。
	var enemy_cap = (7 if summer else 6) + max(0, year - 1)

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

			if _spawn_bug_at(pos, item):
				count_enemys += 1

				# 第 2 年起，普通虫会叫来一只贴身的同伴。
				if year >= 2 and item == SpawnOpt.Bug2 and count_enemys < enemy_cap and randf() < 0.45:
					var dirs = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]
					dirs.shuffle()
					for d in dirs:
						if _spawn_bug_at(pos + d * 128, SpawnOpt.Bug2):
							count_enemys += 1
							break
				break
	
func end_turn():
	# Must be in PLAYING_CARDS or WAITING_FOR_TUTORIAL state
	if turn_state != TurnState.PLAYING_CARDS or shatter_open:
		return
	# 开垦放置模式进行中不允许结束回合。
	if farm_choice_open:
		return
	# 教程没教到“结束回合”之前，按钮和快捷键都不该生效。
	if tutorial and not tutorial_allow_end_turn:
		return
	if hand_keep_open:
		return

	# 第三轮试玩改：手牌跨回合保留，上限 = 5 + 里程碑/开垦加成。
	# 只有超出上限时（多半是魔瓶成批进手）才弹“选留”面板，未保留的牌被魔瓶回收。
	if _hand_count() > hand_cap():
		HandKeepUI.open_panel()
		return

	_finish_end_turn()


func _finish_end_turn():
	SFX.end_turn.play_sfx()

	# 手牌保留，不再整手清掉；留在手上的牌继续占手牌位。
	current_picked_up_card = null
	
	# 空场时很快来虫；场上有虫时也会周期性增援，年份越高间隔越短。
	var year = Season.year
	var spawn_gap = 2 if Season.is_summer() else 3
	var active_gap = max(3, 5 - int((year - 1) / 2))
	if no_enemy_turns >= spawn_gap or some_enemy_turns >= active_gap:
		spawn_enemies()
		no_enemy_turns = 0
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

# 调试一键集齐（F9）：只在编辑器进程或带 --devmode 启动时生效，
# 正式导出的网页版不响应。收满图鉴后，下一次发牌魔瓶照规则
# 送出"最后的种子"，可以直接走到结局。
func _unhandled_input(event):
	if not (Engine.editor_hint or OS.get_cmdline_args().has("--devmode")):
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and event.scancode == KEY_F9:
		dev_collect_all()


func dev_collect_all():
	var ids = GameData.all_entry_ids()
	for id in ids:
		Encyclopedia.discover(id)
	Toast.show_message("调试：图鉴已集齐（%d 条）。下一次发牌会送出最后的种子。" % ids.size())
	
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
	

# 手牌规则（第四轮试玩定稿）：每轮固定抽 3 张、其中 1 张必是水；
# 保留制下回合结束最多留 5 张，成长（里程碑/棱彩卡组）最多加到 6 张封顶。
var card_draw_count = 3

const HAND_BASE = 5
const HAND_CAP_MAX = 6

func hand_cap():
	return int(clamp(HAND_BASE + bonus_draws, HAND_BASE, HAND_CAP_MAX))


func _hand_count():
	if hand == null or not is_instance_valid(hand):
		return 0
	return hand.get_child_count()


# 集齐所有植物（每个物种至少一条图鉴）之后，魔瓶会稳定送出一颗”最后的种子”。
# 手牌里已经有这张卡、或者田里已经种着终局植物时不再重复发放。
func has_final_seed_or_plant():
	if hand != null and is_instance_valid(hand):
		for c in hand.get_children():
			if c.associated_card == card_final_seed:
				return true
	for p in get_tree().get_nodes_in_group("Plant"):
		if is_instance_valid(p) and p.get("is_final_plant"):
			return true
	return false


func maybe_grant_final_seed(announce = true):
	if ending_started:
		return false
	if not Encyclopedia.all_species_represented():
		return false
	if has_final_seed_or_plant():
		return false
	if hand == null or not is_instance_valid(hand):
		return false

	# 种子可能还在牌堆/弃牌堆里，直接捞回手牌，避免又发一张。
	var pile_index = draw_pile.find(card_final_seed)
	if pile_index >= 0:
		draw_pile.remove(pile_index)
	else:
		pile_index = discard_pile.find(card_final_seed)
		if pile_index >= 0:
			discard_pile.remove(pile_index)

	add_card_to_hand(card_final_seed)
	if announce:
		Toast.show_message("已集齐所有植物。魔瓶深处浮出一颗新的种子。")
	return true


# 终局植物成熟：淡出农场，播放结局分镜。
func start_ending():
	if ending_started:
		return
	ending_started = true
	if has_node("/root/BottleManager"):
		BottleManager.force_close()
	if has_node("/root/HarvestManager"):
		HarvestManager.force_close()
	if has_node("/root/EncyclopediaUI"):
		EncyclopediaUI.close()
	if has_node("/root/YearSummary"):
		YearSummary.reset_all()
	waiting_for_card_selection = false
	harvest_open = false
	bottle_open = false
	bestiary_open = false
	year_summary_open = false
	var sv = get_node_or_null("/root/SaveGame")
	if sv != null:
		sv.save_now()
	SceneTransitions.change_scene_to(Ending)


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
	mature_rewards_this_round = 0

	# 第四轮定稿：每轮固定抽 3 张，第 1 张必是水牌，其余两张纯看运气。
	# （旧的"补满上限 + 种子保底 + 无水兜底"整套移除——水由规则保证，
	# 种子和其余牌交给池子概率，回合结束的上限由选留面板把关。）
	var w = make_water_card()
	if w != null:
		add_card_to_hand(w)
	for i in range(1, max(1, card_draw_count)):
		var c = draw_card()
		if c == null:
			break
		add_card_to_hand(c)

	# 敌方回合（反伤/护甲）杀掉的虫子，奖励顺延到这一轮。
	var carried = pending_mature_rewards
	pending_mature_rewards = 0
	for i in range(carried):
		add_card_to_hand(card_mature)
		mature_rewards_this_round += 1

	# 集齐植物后的终局保底：即使上一次没种下，也会重新出现在手牌里。
	maybe_grant_final_seed()

	turn_state = TurnState.PLAYING_CARDS

	energy = energy_max

	SFX.card_deal.play_sfx()
	var sv = get_node_or_null("/root/SaveGame")
	if sv != null:
		sv.save_now()


func _hand_water_count():
	if hand == null or not is_instance_valid(hand):
		return 0
	var n = 0
	for c in hand.get_children():
		if c.associated_card != null and c.associated_card.action == Action.WATER:
			n += 1
	return n


func _hand_seed_count():
	if hand == null or not is_instance_valid(hand):
		return 0
	var n = 0
	for c in hand.get_children():
		if c.associated_card != null and c.associated_card.action == Action.PLANT:
			n += 1
	return n


# 瓶碎结算：相当于一次"带着积累的软重开"。
# 清空的只有场上虫与作物、手牌、水晶球和瓶血；
# 图鉴、耕地、永久加成、历史最高年份（决定种子解锁与能量上限）全部保留。
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
	Season.restore_calendar(1, 1, 0, 1)
	RunStats.year = 1
	RunStats.reset_year()
	RunStats.mutation_pity = 0

	# 永久加成与历史最高年份保留；能量上限按最高年份走，碎瓶不回落。
	refresh_energy_max()
	orb_water = 0
	mature_rewards_this_round = 0
	pending_mature_rewards = 0
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
	ending_started = false
	tutorial = true # SHould this get reset?
	tutorial_allow_guide = false
	tutorial_allow_end_turn = false
	tutorial_allowed_action = ""
	guide = null
	if has_node("/root/TutorialSteps"):
		TutorialSteps.tutorial = null
		TutorialSteps.reset_all_state()
	
	if has_node("/root/CardCreation"):
		CardCreation.reset_all_state()

	if has_node("/root/Flags"):
		Flags.reset_guide_unlocks()

	turn_state = TurnState.UNDEFINED
	waiting_for_card_selection = false

	
	permanent_energy_bonus = 0
	energy_max = BASE_ENERGY
	energy = energy_max
	orb_water = 0
	mature_rewards_this_round = 0
	pending_mature_rewards = 0
	
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
	
	card_draw_count = 3 # 教程也会设一遍
	
	no_enemy_turns = 0
	some_enemy_turns = 0
	
	upper_panel_mouse = false
	tutorial_mouse = false
	end_turn_mouse = false
	
	bonus_draws = 0
	
	harvest_open = false
	bottle_open = false
	bestiary_open = false
	year_summary_open = false
	farm_choice_open = false
	shatter_open = false
	hand_keep_open = false
	
	farm_quota = 0
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
	farm_quota += 1

