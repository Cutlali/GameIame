extends Label

var lines = [
"你从石头下拾起了魔瓶与图鉴。\n\n瓶中的小世界荒芜已久，四季也沉睡了。先让第一株植物在这里生根吧。"
,"按住鼠标左键拖动，可以看看这片土地。"
,"这座农场的一切工作，都要靠卡牌完成。左下角的能量球是这一回合的力气，每张牌右上角标着它的消耗。"
,"手牌排列在屏幕底部。滚动鼠标滚轮，可以翻看其余的牌。"
,"先看看手牌，让魔瓶重新长出一点绿色吧。"
,"选中「番茄种子」，把它拖到发绿的土块上。种子落土，瓶中的小世界便会记下它。"
,"每一株植物都有生命。它需要水，也需要有人替它挡住虫子。"
,"用「水滴」牌为它浇水。春季的魔瓶生机最盛，一次浇水能让它多长两帧。"
,"水分会随回合流逝。土地干涸时，植物会受伤。记得常回来看看。"
,"虫子靠近时，用「防护网」为植物添上免疫。1 点免疫，替它挡下 1 点伤害。"
,"免疫像一层会消散的护罩：每到你的回合，它就薄一分。植物的生命、水分与免疫，最多都只能积到 10。"
,"这一回合能做的都做完了。点击「结束回合」，让魔瓶继续转动。"
,"新的一轮，新的手牌。瓶中的时间又向前走了一点。"
,"有虫子醒了。用「重击！」把它从植物身边赶走。"
,"很好。你已经能让这片土地运转起来了。"
,"植物成熟后，图鉴会记下它，魔瓶也会以新的卡牌回报你。图鉴越完整，魔瓶越强。"
,"但瓶中的世界并不安稳。植物若被虫子杀死，魔瓶就会受损；伤到最后一滴，四季会停滞。好在它还能自行修复。"
,"更详细的四季、耕作与魔瓶的来历，都写在《四季图鉴指南》里——主菜单或暂停菜单都能翻开它。\n\n去吧，土地在等你。"]

var current_line = 0
var turns_with_reqs = [5, 7, 9, 11, 13]

func contains_mouse(control: Control):
	var r = Rect2(Vector2.ZERO, control.rect_size)
	return r.has_point(control.get_local_mouse_position())

func end_tutorial():
	GS.tutorial = false
	GS.tutorial_mouse = false
	GS.card_draw_count = 5 # Back to normal card count
	queue_free()

func _ready():
	TutorialSteps.tutorial = self
	
	update_tutorial()
	GS.turn_state = GS.TurnState.WAITING_FOR_TUTORIAL
	GS.card_draw_count = 2 # Only draw the Whack! card plus some filler

	if Flags.skip_tutorial:
		call_deferred("tutorial_skip")

	# DEBUGGING
	# call_deferred("tutorial_debug")

func tutorial_skip():
	tutorial_cards()
	GS.draw_card_to_hand()
	GS.draw_card_to_hand()
	GS.no_enemy_turns = 2
	end_tutorial()
	GS.turn_state = GS.TurnState.PLAYING_CARDS

func debug_all_cards():
	GS.add_card_to_hand(GS.card_basic_plant)	
	GS.add_card_to_hand(GS.card_medium_plant)	
	GS.add_card_to_hand(GS.card_high_plant)	
	GS.add_card_to_hand(GS.card_free_1x1_water)
	GS.add_card_to_hand(GS.card_buy_1x1_water)
	GS.add_card_to_hand(GS.card_small_attack)
	GS.add_card_to_hand(GS.card_small_defend)
	GS.add_card_to_hand(GS.card_drain1_dmg3)
	GS.add_card_to_hand(GS.card_water2_1x1)
	GS.add_card_to_hand(GS.card_water1_2x2)
	GS.add_card_to_hand(GS.card_water1_3x3)
	GS.add_card_to_hand(GS.card_water2_2x2)
	GS.add_card_to_hand(GS.card_drain3_rng5)
	GS.add_card_to_hand(GS.card_water5)
	GS.add_card_to_hand(GS.card_drain7_dmgall5)
	GS.add_card_to_hand(GS.card_drain3_dmgall1)
	GS.add_card_to_hand(GS.card_3def_1)
	GS.add_card_to_hand(GS.card_heal1_dmg1)
	GS.add_card_to_hand(GS.card_def2_dmg1)
	GS.add_card_to_hand(GS.card_heal2_dmg2)
	GS.add_card_to_hand(GS.card_def3_dmg3)
	GS.add_card_to_hand(GS.card_def2_all)
	GS.add_card_to_hand(GS.card_heal_attack_all)
	GS.add_card_to_hand(GS.card_dmg2)
	GS.add_card_to_hand(GS.card_add1_expensive)
	GS.add_card_to_hand(GS.card_sacrif1_1enem)
	GS.add_card_to_hand(GS.card_add2)
	GS.add_card_to_hand(GS.card_sacrif2_2enem)
	GS.add_card_to_hand(GS.card_free_atk)
	GS.add_card_to_hand(GS.card_add1_cheap)
	GS.add_card_to_hand(GS.card_sacrifice)
	GS.add_card_to_hand(GS.card_win_plant)
	GS.add_card_to_hand(GS.card_energy)
	GS.add_card_to_hand(GS.card_cards)

func tutorial_debug():
	tutorial_cards()
	end_tutorial()
	GS.turn_state = GS.TurnState.PLAYING_CARDS
	
	#debug_all_cards()
#
#	GS.add_card_to_hand(GS.card_small_attack)
	GS.add_card_to_hand(GS.card_water5)
	GS.add_card_to_hand(GS.card_water5)
	GS.add_card_to_hand(GS.card_3def_1)
	GS.add_card_to_hand(GS.card_3def_1)
	GS.add_card_to_hand(GS.card_3def_1)
	GS.add_card_to_hand(GS.card_3def_1)
	GS.add_card_to_hand(GS.card_3def_1)
	GS.add_card_to_hand(GS.card_win_plant)
	#GS.add_card_to_hand(GS.card_basic_plant)
#	GS.add_card_to_hand(GS.card_basic_plant)
#	GS.add_card_to_hand(GS.card_basic_plant)
#	GS.add_card_to_hand(GS.card_add1_expensive)
##	GS.add_card_to_hand(GS.card_def2_all)
#	GS.add_card_to_hand(GS.card_heal_attack_all)
#	GS.add_card_to_hand(GS.card_sacrif2_2enem)
#	GS.add_card_to_hand(GS.card_energy)
#	GS.add_card_to_hand(GS.card_cards)
##	GS.add_card_to_hand(GS.card_free_atk)
#	GS.add_card_to_hand(GS.card_sacrifice)
	GS.gold += 200
	GS.energy += 200
	
	for enem in get_tree().get_nodes_in_group("Enemy"):
		enem.spawn_now()


func tutorial_cards():
	GS.add_card_to_hand(GS.card_basic_plant)
	#GS.add_card_to_hand(GS.card_basic_plant)
	GS.add_card_to_hand(GS.card_free_1x1_water)
	GS.add_card_to_hand(GS.card_small_defend)
	
	GS.draw_pile.push_back(GS.card_small_attack)
	#GS.draw_pile.push_back(GS.card_medium_plant)
	
	GS.draw_pile.push_back(GS.card_medium_plant)
	
	GS.discard_pile.push_back(GS.card_buy_1x1_water)
	#GS.discard_pile.push_back(GS.card_buy_1x1_water)
	#GS.discard_pile.push_back(GS.card_buy_1x1_water)
	
	GS.discard_pile.push_back(GS.card_high_plant)
	#GS.discard_pile.push_back(GS.card_high_plant)
	
	
	GS.discard_pile.push_back(GS.card_small_attack)
	#GS.discard_pile.push_back(GS.card_small_attack)
	#GS.discard_pile.push_back(GS.card_small_defend)

func update_tutorial():
	if current_line >= lines.size():
		end_tutorial()
		return
	
	text = lines[current_line]
	
	TutorialSteps.need_end_turn_button = (current_line == 11)
	
	$NextButton.visible = not (current_line in turns_with_reqs)
	
	if current_line == 4:
		tutorial_cards()
		GS.turn_state = GS.TurnState.PLAYING_CARDS
		
	if current_line == 13:
		var plants = get_tree().get_nodes_in_group("Plant")
		var lcoord = Vector2.ZERO
		
		if not plants.empty():
			var plant = plants[0]
			lcoord = plant.position + Vector2(128 * 2, 0)
		
		GS.spawn_bug_lcoord(lcoord).spawn_now()
	
func step_tutorial():
	current_line += 1
	update_tutorial()
	
func _process(delta):
	if not GS.tutorial:
		GS.tutorial_mouse = false
		return
		
	GS.tutorial_mouse = contains_mouse(self) or contains_mouse($NextButton)
	
	if TutorialSteps.marked_step >= current_line:
		$NextButton.visible = true

func _on_NextButton_pressed():
	step_tutorial()
