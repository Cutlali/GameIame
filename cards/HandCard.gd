extends Area2D

const STATE_IN_HAND = 0
const STATE_HOVER = 1
const STATE_PICKUP = 2
const STATE_DISCARD = 3

var state = STATE_IN_HAND

var associated_card

# The rotation of the card while it is not hovered. Updated by the CardManager
var in_hand_rotation = 0

var in_hand_position = Vector2.ZERO
var in_hand_hover_position = Vector2.ZERO

func is_picked_up():
	return state == STATE_PICKUP

func release():
	# TODO: Figure out how this will work with picked up cards
	if state == STATE_HOVER:
		state = STATE_IN_HAND
		
func hover():
	if state == STATE_IN_HAND:
		state = STATE_HOVER

func update_transform():
	var target_scale = 1.0
	var target_rot = in_hand_rotation
	var target_pos = in_hand_position
	
	var pos_t = 0.15
	var scale_t = 0.2
	z_index = 0
	if state == STATE_HOVER or state == STATE_PICKUP:
		target_scale = 1.3
		target_rot = 0
		target_pos = in_hand_hover_position
		z_index = 100
	if state == STATE_PICKUP:
		# Position should be locked
		target_pos = position
		target_scale = 0.7
		
	if state == STATE_DISCARD:
		target_rot = TAU * 0.25
		target_pos = GS.get_discard_pos()
		target_scale = 0.0
		
		pos_t = 0.04
		scale_t = 0.04
		
	scale.x += (target_scale - scale.x) * scale_t
	scale.y = scale.x
	
	rotation += (target_rot - rotation) * 0.1
	position += (target_pos - position) * pos_t
	
func play_self():
	if associated_card.action == GS.Action.PLANT:
		GS.cursor.new_plant(associated_card)
	if associated_card.action == GS.Action.WATER:
		GS.cursor.water(associated_card)
	if associated_card.action == GS.Action.ATTACK:
		GS.cursor.attack(associated_card)
	if associated_card.action == GS.Action.DEFEND:
		GS.cursor.defend(associated_card)
	if associated_card.action == GS.Action.DRAIN_WATER_DMG_RNG:
		GS.cursor.drain_water_dmg_rng(associated_card)
	if associated_card.action == GS.Action.DRAIN_WATER_DMG_ALL:
		GS.cursor.drain_water_dmg_all(associated_card)
	if associated_card.action == GS.Action.HEAL_DMG_NEAR:
		GS.cursor.heal_dmg_near(associated_card)
	if associated_card.action == GS.Action.DEF_DMG_NEAR:
		GS.cursor.def_dmg_near(associated_card)
	if associated_card.action == GS.Action.ADD_DAMAGE:
		GS.cursor.add_damage(associated_card)
	if associated_card.action == GS.Action.DEF_ALL:
		GS.cursor.def_all(associated_card)
	if associated_card.action == GS.Action.HEAL_ALL_DMG:
		GS.cursor.heal_all_dmg(associated_card)
	if associated_card.action == GS.Action.SACRIF:
		GS.cursor.sacrif(associated_card)
	if associated_card.action == GS.Action.DRAW_3:
		GS.draw_card_to_hand()
		GS.draw_card_to_hand()
		GS.draw_card_to_hand()
	if associated_card.action == GS.Action.PLUS_ENERGY:
		# 数量就是这张牌给几点能量（凝露 1 / 甘泉 2 / 涌泉 3）。
		# 免费能量那张没设数量，按 1 点算，保持老行为。
		var wanted = max(1, associated_card.quantity)
		var room = max(0, GS.energy_max - GS.energy)
		GS.energy += min(wanted, room)
		if wanted > room:
			Toast.show_message("能量已经顶到上限，多出来的 %d 点散掉了。" % (wanted - room))
	if associated_card.action == GS.Action.HASTEN:
		GS.cursor.hasten(associated_card)
	if associated_card.action == GS.Action.GRAFT:
		GS.cursor.graft(associated_card)
	if associated_card.action == GS.Action.NET:
		GS.cursor.net(associated_card)
	if associated_card.action == GS.Action.ATTACK_ALL:
		GS.cursor.attack_all(associated_card)
	if associated_card.action == GS.Action.THORNS:
		GS.cursor.thorns_armor(associated_card)
	if associated_card.action == GS.Action.MATURE:
		GS.cursor.mature(associated_card)
		
	GS.energy -= associated_card.cost
	discard()

	_play_card_sfx()

# v1.8 声包：特定牌用专属音效，其余仍走通用出牌声。
func _play_card_sfx():
	var b = associated_card
	if b == GS.card_water1_3x3:
		SFX.water_barrel.play_sfx()
		return
	if b == GS.card_water2_2x2:
		SFX.water_hose.play_sfx()
		return
	if b.action == GS.Action.HEAL_DMG_NEAR:
		# 吸血獠牙（低费）与吸血斩（高费）分档。
		if b.cost <= 1:
			SFX.drain_low.play_sfx()
		else:
			SFX.drain_high.play_sfx()
		return
	if b.action == GS.Action.HEAL_ALL_DMG:
		SFX.drain_high.play_sfx()
		return
	if b == GS.card_small_attack:
		SFX.attack_single.play_sfx()
		return
	if b == GS.card_dmg2:
		SFX.attack_heavy.play_sfx()
		return
	SFX.card_play.play_sfx()
	
func discard():
	_move_to_dummy()
	state = STATE_DISCARD
	# 速成/水晶球之水是一次性卡，不污染牌库循环。
	if associated_card != null and not associated_card.transient:
		GS.discard_pile.push_back(associated_card)

# 回合末整理时被弃掉的牌：走同一段飞出动画，但不回弃牌堆，
# 从本局循环里真正删掉（牌库越打越薄，留强弃弱）。
func destroy():
	_move_to_dummy()
	state = STATE_DISCARD

func _move_to_dummy():
	var new_parent = get_node("../../CardDummy")
	get_parent().remove_child(self)
	new_parent.add_child(self)
	
func try_play_self():
	GS.release_current_card(self)

	# 教程期间只放行当前阶段需要的牌，避免把种子/水滴浪费在空地上。
	if not GS.tutorial_card_allowed(associated_card):
		Toast.show_message("先按手记的提示来。")
		state = STATE_HOVER
		return

	# 水牌可以直接拖到右上角的水晶球上，把水量存起来。
	if associated_card.action == GS.Action.WATER and GS.is_over_orb():
		if GS.play_water_into_orb(associated_card):
			Toast.show_message("水晶球存下了 %d 点水。" % associated_card.quantity)
			discard()
			SFX.card_play.play_sfx()
			return
		# 水晶球之水是从球里取出来的，不能再存回去。
		state = STATE_HOVER
		return

#	if associated_card.action == GS.Action.PLANT \
#		or associated_card.action == GS.Action.WATER \
#		or associated_card.action == GS.Action.ATTACK \
#		or associated_card.action == GS.Action.DEFEND:
	if GS.cursor.may_play_card():
		play_self()
		return
	
	# If we can't play the card, simply return to hover state.
	state = STATE_HOVER
	
func update_modulate():
	var playable = (associated_card.cost <= GS.energy)
	if associated_card.from_orb and GS.orb_water <= 0:
		playable = false
	var mod = Color.white
	if not playable:
		mod = Color(0.4, 0.4, 0.4, 1.0)
	modulate = mod
	
func _physics_process(delta):
	if state == STATE_DISCARD:
		# Disable input
		collision_layer = 0
		collision_mask = 0
		input_pickable = false 
		
		if scale.x < 0.07:
			queue_free()
	
	if state == STATE_PICKUP:
		global_position = get_global_mouse_position()
		position.y += 98 + 30
		
		if Input.is_action_just_released("mouse"):
			try_play_self()
	
	if state == STATE_HOVER:
		if GS.energy >= associated_card.cost:
			if Input.is_action_just_pressed("mouse"):
				state = STATE_PICKUP
				GS.set_current_card(self)
			
	update_transform()
	update_modulate()
