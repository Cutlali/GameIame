extends Label

var lines = [
"你好，\n\n希望这卷落满灰尘的卷轴能顺利送到你手中。我是曾经照料这片土地的前任农夫，我由衷希望你能比我更好地利用它。"
,"不过，我猜你对耕作这门技艺还相当生疏。我打算把经营这座农场所需的基础知识教给你。"
,"我们开始吧。\n\n首先，要浏览农场，请在地面上的任意位置按住鼠标左键并拖动鼠标。"
,"接下来，在农场里做任何事都必须打出卡牌。卡牌能完成许多不同的工作……种植植物、为植物浇水，以及击退害虫。每张卡牌都需要消耗能量才能打出，能量显示在左下角的能量球中，也标注在每张卡牌的右上角。"
,"你的卡牌排列在屏幕底部。使用鼠标滚轮可以左右移动它们，以便查看当前看不到的卡牌。"
,"你应该把一张基础种子种在翻好的土地上。左键点击手牌中的基础种子卡牌，然后把它拖到上方的农场里即可打出。\n\n这张卡牌会用绿色旋转圆圈标出可以种植的位置。"
,"种下种子后，你会注意到一个重要细节：每株植物都有一定的生命值。你要让植物活到完全成熟！"
,"现在，你需要给种子浇水。使用水滴卡牌为你的植物浇水。"
,"注意，每株植物都有一个水分指示。每次你的回合结束时，水分都会减少。如果植物没有水分，它就会受到伤害。"
,"植物的最后一项属性是免疫值，你可以用防护网卡牌以及其他卡牌来施加免疫。"
,"每 1 点免疫可以保护植物免受 1 点伤害。不过，植物会在你的回合开始时失去 1 点免疫。\n\n植物的各项属性上限均为 10。"
,"现在，在你尽可能多地打出卡牌之后，点击“结束回合”按钮来结束你的回合。然后你会看到水分产生的效果……如果场上有敌人，它们也会在这时发动攻击。"
,"现在是新的回合，你已经抽到了新的卡牌。"
,"卡牌的另一个主要用途是击退会袭击农场的害虫。使用你的“重击！”卡牌对那只虫子造成伤害。"
,"现在你已经掌握了农夫所需的所有基础知识。不过还有最后一个细节：你种这些植物究竟是为了什么？"
,"其实，每当你给植物浇水，它们就会成长一个阶段。当你浇水足够多次后，就会自动收获它们……此时你可以选择一张新卡牌加入牌组。当然，越珍贵的卡牌需要付出越多努力才能种出。"
,"更健康的植物往往也能产出更好的卡牌。"
,"你也可以选择收获植物来换取金钱，金钱可以在本地商店购买各种升级。"
,"最后，有一种稀有植物，我们世世代代努力了数百年，却始终未能种成。你可以通过培育珍贵卡牌来找到它的种子，然后去挑战种出这种难以捉摸的植物。"
,"去吧，开始耕作吧！"]

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
