extends Node2D

export var health = 3
var water = 0
var defense = 0

var health_disp = 3
var water_disp = 0
var defense_disp = 0

export var plant_scale = 1.0

export var card_level = 1

export var anim_frames: SpriteFrames

# 新循环：植物物种与变异。变异在收获时判定，变种是独立图鉴条目。
var species_id = ""
var mutated = false
var variant_index = 0
var mutation_rolled = false
var _died = false

# 嫁接卡带来的本次收获额外变异概率（0.3 = +30%）
var mutation_bonus = 0.0
# 变种特性只在第一次确认时套用一次
var _variant_setup_done = false
var _variant_announced = false
var _mutation_rewarded = false
var _entry_resolved = false
var _resolved_id = ""
# 只有被虫害打掉血才让魔瓶受损；牺牲卡主动杀掉植物不算。
var died_by_pest = false

# If the plant is "consumed", that means the card / gold popup has been
# shown, and the plant should be queue_freed()
var consumed = false

var spawn_sfx_timer = 0.15

func nowater_sfx():
	SFX.no_water.play_sfx()

func _ready():
	if GS.auto_water:
		water = 1
	
	$Plant.frames = anim_frames
	$Plant.scale = Vector2(plant_scale, plant_scale)

	# 变异在种下时就已经决定，玩家可以围绕这株变种做构筑；
	# 图鉴收录与音效仍然留到收获时揭晓。
	roll_mutation_if_needed()
	_apply_variant_setup()
	
	heart_update()
	defense_update()
	water_update()
	

func centered_lpf_noise(in_pos):
	var r = rand_range(0, 32)
	var th = rand_range(0, 6.28)
	var pos = Vector2(64, 64) + polar2cartesian(r, th)
	
	return in_pos + (pos - in_pos) * 0.005
	
func sine_y_offset(node, offset):
	var theta = GS.global_sine_timer * 64 + offset
	var y = sin(theta * (PI / 32.0))
	
	node.position.y = y
	
func slash_health(amount, attacker = null):
	$AnimationPlayer.play("Slash")
	SFX.whack.play_sfx()

	# 靛蓝番茄 / 红磨坊向日葵的反伤：咬到它就等于咬到自己。
	var perk = current_perk()
	if perk != null and attacker != null and is_instance_valid(attacker):
		var reflect = int(perk.get("reflect", 0))
		if reflect > 0:
			if attacker.has_method("take_reflect_damage"):
				attacker.take_reflect_damage(reflect)
			else:
				attacker.take_damage(reflect)
	
# Can be called from animations to explicitly update the visibility at some point.
func update_markers_visibility():
	$H/HeartMarker.visible = (health > -1) # I guess
	$W/WaterMarker.visible = (water > 0)
	$D/DefenseMarker.visible = (defense > 0)

func update_display():
	#$H/HeartMarker/HealthNum.text = String(health)
	#$W/WaterMarker/WaterNum.text = String(water)
	#$D/DefenseMarker/DefenseNum.text = String(defense)
	
	# Don't update visibility while the animation is going...?
	if not $AnimationPlayer.is_playing():
		update_markers_visibility()
	
	# Randomly move markers and plant sprite for a little bit more life.
	# One option for this: JitterFX.gd, inspired by the main menu of my game
	# HaleyHeartbeat
	#$HeartMarker.position = centered_lpf_noise($HeartMarker.position)
	#$WaterMarker.position = centered_lpf_noise($WaterMarker.position)
	#$DefenseMarker.position = centered_lpf_noise($DefenseMarker.position)
	
	#$Plant.position = centered_lpf_noise($Plant.position)
	
	# Another option: sine wave, may look nicer than noise for this purpose.
	sine_y_offset($H, 28)
	sine_y_offset($W, 64)
	sine_y_offset($D, 100)
	

func _process(delta):
	update_display()
	
	if spawn_sfx_timer > 0:
		spawn_sfx_timer -= delta
		if spawn_sfx_timer <= 0:
			SFX.rand_seeds()
	
func take_turn():
	var anim = $AnimationPlayer
	
	anim.queue("Delay")
	
	if water >= 1:
		#print($Plant.frame)
		#print($Plant.frames.frames.size() - 1)
		if $Plant.frame == $Plant.frames.get_frame_count("default") - 1:
			anim.queue("PlantIsDone")
			consumed = true
		else:
			anim.queue("WaterPlant")
	else:
		anim.queue("NoWater")
		
func water_sfx():
	SFX.rand_water()
	
func dec_health():	
	var amount = 1
	
	# TODO: Animate shield rather than heart...
	if defense > 0:
		defense -= amount
		$ShieldFX.play("Pop")
		if defense < 0:
			amount = -defense
			defense = 0
		else:
			return
	
	health -= amount
	$HeartFX.play("Pop")
	if health <= 0:
		died_by_pest = true
		_count_death()
		$AnimationPlayer.queue("OutOfHealth")
		
func set_health(amount):
	if health <= 0:
		return
	
	if amount > 10:
		amount = 10
	health = amount
	
	$HeartFX.play("Pop")
	
	if health <= 0:
		_count_death()
		$AnimationPlayer.queue("OutOfHealth")


func _count_death():
	if _died:
		return
	_died = true
	var stats = get_node_or_null("/root/RunStats")
	if stats != null:
		stats.plants_lost += 1
	# 魔瓶维持四季；植物被虫害打死时掉 1 滴血。
	# 成熟与否都算，但玩家自己用牺牲卡杀掉的不扣。
	if died_by_pest:
		var bottle = get_node_or_null("/root/BottleManager")
		if bottle != null:
			bottle.damage(1)
		
func set_defense(amount):
	if amount > 10:
		amount = 10
	if amount < 0:
		amount = 0
	defense = amount
	
	$ShieldFX.play("Pop")
	
func set_water(amount):
	if amount > 10:
		amount = 10
	if amount < 0:
		amount = 0
	water = amount
	
	$WaterFX.play("Pop")

func heart_update():
	health_disp = health
	$H/HeartMarker/HealthNum.text = String(health_disp)
	
func defense_update():
	defense_disp = defense
	$D/DefenseMarker/DefenseNum.text = String(defense)
	
func water_update():
	water_disp = water
	$W/WaterMarker/WaterNum.text = String(water)

	#
	#

func water_plant():
	set_water(water - 1)
	
func popup_menu():
	HarvestManager.handle_harvest(self)


func current_perk():
	if not mutated:
		return null
	return GameData.variant_perk(species_id, variant_index)


# 决定这株植物是不是变种。种下时调用一次；如果调用时还没拿到 species_id，
# 后续浇水/收获时会再补一次。
func roll_mutation_if_needed():
	if species_id == "" or mutation_rolled:
		return
	mutation_rolled = true
	var chance = GameData.mutation_chance(Season.current_season, RunStats.mutation_pity)
	chance = min(1.0, chance + mutation_bonus)
	if randf() < chance:
		mutated = true
		variant_index = randi() % 2
	else:
		mutated = false


func _apply_variant_setup():
	if _variant_setup_done or not mutated:
		return
	_variant_setup_done = true

	var perk = current_perk()
	if perk != null:
		var frames_bonus = int(perk.get("frames_bonus", 0))
		if frames_bonus > 0:
			var max_frame = $Plant.frames.get_frame_count("default") - 1
			# 用加法而不是覆盖：嫁接让普通株中途变成变种时，
			# 不应该把它已经长出的帧数退回去。
			$Plant.frame = min(max_frame, $Plant.frame + frames_bonus)

	# 给变种一点颜色倾向，玩家在田里就能看出这株不一般。
	var c = GameData.variant_color(species_id, variant_index)
	$Plant.modulate = Color(1, 1, 1).linear_interpolate(Color(c.r, c.g, c.b), 0.22)

	_announce_variant()


func _announce_variant():
	if _variant_announced:
		return
	_variant_announced = true
	if GS.tutorial:
		return
	var sp = GameData.species(species_id)
	if sp != null:
		Toast.show_message("这株%s看起来有些不一样，也许会发生变异。" % sp["name"])


func add_mutation_bonus(amount):
	mutation_bonus += amount
	# 种下时已经判定过“没有变异”的植物，嫁接会给它一次新的机会。
	# 这样嫁接才是真正的投资，而不是一张对已定型植物无效的牌。
	if mutation_rolled and not mutated:
		var chance = GameData.mutation_chance(Season.current_season, RunStats.mutation_pity)
		chance = min(1.0, chance + mutation_bonus)
		if randf() < chance:
			mutated = true
			variant_index = randi() % 2
			_apply_variant_setup()


# 收获时确认条目。变种是独立图鉴条目。
func resolve_entry_id():
	if species_id == "":
		return ""
	if _entry_resolved:
		return _resolved_id

	roll_mutation_if_needed()
	_apply_variant_setup()

	if mutated:
		_entry_resolved = true
		_resolved_id = species_id + "_v" + str(variant_index)
		if not _mutation_rewarded:
			_mutation_rewarded = true
			RunStats.mutation_pity = 0
			# 变异是高光时刻，用一段上扬的魔法音效强调，区别于普通收获。
			SFX.mutation.play_usual()
		return _resolved_id

	RunStats.mutation_pity += 1
	_entry_resolved = true
	_resolved_id = species_id
	return _resolved_id


# 春季：1 次浇水推进 2 个生长帧；其他季节 1 帧。
# 非洲太阳月见草不受这个季节惩罚，始终按 2 帧生长。
func growth_steps():
	var steps = Season.growth_per_water()
	var perk = current_perk()
	if perk != null and perk.get("always_two_growth", false):
		steps = max(steps, 2)
	return steps


func advance_growth(steps):
	var max_frame = $Plant.frames.get_frame_count("default") - 1
	for i in range(steps):
		if $Plant.frame < max_frame:
			$Plant.frame += 1


func upgrade_plant():
	roll_mutation_if_needed()
	_apply_variant_setup()
	advance_growth(growth_steps())
	
func turn_over():
	# If we are being polled about our turn, then the card selection
	# dialog must be related to this plant.
	if GS.waiting_for_card_selection:
		return false
	return not $AnimationPlayer.is_playing()
	
func finalize_turn():
	if consumed:
		queue_free()
