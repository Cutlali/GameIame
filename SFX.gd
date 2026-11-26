extends Node

# Godot 3 的 ogg/mp3 导入默认 loop=true：一次性音效全带上无限重播。
# 这里统一关掉本场景内所有 ogg/mp3 流的循环（BGM 在 Music.gd 里按需再开）。
func _ready():
	for c in get_children():
		if c is AudioStreamPlayer and c.stream != null:
			if c.stream is AudioStreamOGGVorbis or c.stream is AudioStreamMP3:
				c.stream.loop = false

onready var card_1 = $Card1
onready var card_2 = $Card2
onready var card_3 = $Card3
onready var card_4 = $Card4
onready var card_play = $CardPlay

onready var whack = $Whack

onready var card_deal = $CardDeal

onready var button_hover = $ButtonHover
onready var button_click = $ButtonClick

onready var end_turn = $EndTurn

onready var plant_jingle = $PlantJingle
onready var no_water = $NoWater

onready var win_jingle = $WinJingle

onready var year_end = $YearEnd
onready var mutation = $Mutation

# v1.8 声包（桌面"声"文件夹）：种植/收获/水系牌/吸血牌/单体攻击/
# 虫群出现/魔瓶受击·技能·碎裂/四季转场。
onready var plant_1 = $Plant1
onready var plant_2 = $Plant2
onready var plant_3 = $Plant3
onready var plant_4 = $Plant4
onready var plant_5 = $Plant5
onready var plant_6 = $Plant6

onready var harvest_1 = $Harvest1
onready var harvest_2 = $Harvest2
onready var harvest_3 = $Harvest3
onready var harvest_4 = $Harvest4
onready var harvest_variant = $HarvestVariant

onready var water_barrel = $WaterBarrel
onready var water_hose = $WaterHose
onready var drain_low = $DrainLow
onready var drain_high = $DrainHigh
onready var attack_single = $AttackSingle
onready var attack_heavy = $AttackHeavy

onready var bottle_hurt = $BottleHurt
onready var bottle_power = $BottlePower
onready var bottle_shatter = $BottleShatter

onready var season_spring = $SeasonSpring
onready var season_summer = $SeasonSummer
onready var season_autumn = $SeasonAutumn
onready var season_winter = $SeasonWinter

onready var _season_sfx = [season_spring, season_summer, season_autumn, season_winter]

# 2026-11 声包补充：虫子咬击，水与血代价的攻击，蜂群。
onready var bug_bite_1 = $BugBite1
onready var bug_bite_2 = $BugBite2
onready var bug_bite_3 = $BugBite3
onready var bug_bite_4 = $BugBite4

onready var attack_water_low = $AttackWaterLow
onready var attack_water_high = $AttackWaterHigh
onready var attack_blood_low = $AttackBloodLow
onready var attack_blood_high = $AttackBloodHigh
onready var swarm_attack = $SwarmAttack

# 浇水牌：0 费 / 1 费专属声，2 费以上共用随机那条。
onready var water_free = $WaterFree
onready var water_cost1 = $WaterCost1
onready var water_random = $WaterRandom

onready var _bug_bites = [bug_bite_1, bug_bite_2, bug_bite_3, bug_bite_4]

# 浇水牌按费用分档：0 费水滴、1 费浸润/倾注各有专属音；
# 水桶/水管在外层已经用独立音效，其余 2 费以上（水壶、降雨）走随机档。
func play_water_card(cost):
	if cost <= 0:
		water_free.play_sfx()
	elif cost == 1:
		water_cost1.play_sfx()
	else:
		water_random.play_sfx()

func rand_card():
	var cards = [card_1, card_2, card_3, card_4]
	cards[randi() % cards.size()].play_sfx()

func rand_seeds():
	# 播撒作物的声音：新旧共 8 条轮着来，纯粹为了多样化。
	var s = [$Seed1, $Seed2, plant_1, plant_2, plant_3, plant_4, plant_5, plant_6]
	s[randi() % s.size()].play_sfx()

func rand_water():
	var s = [$Water1, $Water2]
	s[randi() % s.size()].play_sfx()

func rand_harvest(is_variant):
	if is_variant:
		harvest_variant.play_sfx()
		return
	var s = [harvest_1, harvest_2, harvest_3, harvest_4]
	s[randi() % s.size()].play_sfx()

func rand_bug_bite():
	_bug_bites[randi() % _bug_bites.size()].play_sfx()

func play_season_transition(index):
	stop_season_sfxs()
	if index >= 0 and index < _season_sfx.size():
		_season_sfx[index].play_usual()

func stop_season_sfxs():
	for p in _season_sfx:
		p.stop()
