extends Node2D

export var health = 3
var water = 0
var defense = 0

# 反伤甲提供的固定反伤，和变种特性叠加。
var reflect_damage = 0

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

# 终局植物：图鉴集齐后由“最后的种子”种下，成熟时进入结局。
var is_final_plant = false

# 嫁接卡带来的本次收获额外变异概率（0.3 = +30%）
var mutation_bonus = 0.0
# 变种特性只在第一次确认时套用一次
var _variant_setup_done = false
# 记录上一次按帧更新变种颜色时的帧号，避免每帧重复设置。
var _last_tint_frame = -1
var _mutation_rewarded = false
var _entry_resolved = false
var _resolved_id = ""
# 只有被虫害打掉血才让魔瓶受损；牺牲卡主动杀掉植物不算。
var died_by_pest = false

# If the plant is "consumed", that means the harvest popup has been
# shown, and the plant should be queue_freed()
var consumed = false

# 速成卡：即使没有水，也会在本回合结束时成熟收获。
var forced_mature = false

var spawn_sfx_timer = 0.15

func nowater_sfx():
	SFX.no_water.play_sfx()

func _ready():
	if GS.auto_water:
		water = 1
	
	$Plant.frames = anim_frames
	$Plant.scale = Vector2(plant_scale, plant_scale)

	if is_final_plant:
		# 终局植物不参与变异，并且更结实一些，保证玩家能把它种到成熟。
		mutation_rolled = true
		mutated = false
		health = 7
	else:
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

	# 靛蓝番茄 / 红磨坊向日葵的反伤 + 反伤甲。
	var reflect = reflect_damage
	var perk = current_perk()
	if perk != null:
		reflect += int(perk.get("reflect", 0))
	if reflect > 0 and attacker != null and is_instance_valid(attacker):
		if attacker.has_method("take_reflect_damage"):
			attacker.take_reflect_damage(reflect)
		else:
			attacker.take_damage(reflect)


func add_reflect(amount):
	reflect_damage += amount
	Toast.show_message("这株植物获得反伤护甲（被咬时反伤 %d 点）。" % reflect_damage)
	
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

	# 帧号被外部修改时（例如测试或动画）也同步变种颜色。
	if mutated and $Plant.frame != _last_tint_frame:
		_update_variant_tint()
	
	if spawn_sfx_timer > 0:
		spawn_sfx_timer -= delta
		if spawn_sfx_timer <= 0:
			SFX.rand_seeds()

	if is_final_plant:
		_update_final_glow(delta)


# 终局植物的呼吸式光晕：随生长阶段变大变亮，并轻微明暗起伏。
var _glow_time = 0.0

func _update_final_glow(delta):
	_glow_time += delta
	var aura = get_node_or_null("Aura")
	if aura == null:
		return
	var spark = get_node_or_null("Sparkles")

	# 枯死动画会把植株本体渐隐，光晕和星尘这时候也该一起收掉，
	# 不然会出现“植物没了光还在”的怪画面。
	if $Plant.modulate.a < 0.99 or not $Plant.visible:
		aura.visible = false
		if spark != null:
			spark.emitting = false
		return
	aura.visible = true

	var max_frame = float(max(1, max_growth_frame()))
	var lvl = clamp(float($Plant.frame) / max_frame, 0.0, 1.0)
	var pulse = 0.5 + 0.5 * sin(_glow_time * 1.7)

	# 种子刚种下时光晕小而暗，成熟后铺开、变亮。
	var w = lerp(0.55, 1.05, lvl) * (0.96 + 0.06 * pulse)
	var h = lerp(0.75, 1.45, lvl) * (0.96 + 0.06 * pulse)
	aura.scale = Vector2(w, h)
	aura.modulate.a = lerp(0.32, 0.62, lvl) + 0.06 * pulse
	aura.position.y = lerp(56.0, 50.0, lvl)

	if spark != null:
		spark.emitting = true
		spark.emission_sphere_radius = lerp(16.0, 42.0, lvl)
		spark.position.y = lerp(54.0, 50.0, lvl)


func take_turn():
	var anim = $AnimationPlayer
	
	anim.queue("Delay")
	
	if $Plant.frame == max_growth_frame() and (water >= 1 or forced_mature):
		anim.queue("PlantIsDone")
		consumed = true
	elif water >= 1:
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
	
	if amount > 7:
		amount = 7
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
	if amount > 7:
		amount = 7
	if amount < 0:
		amount = 0
	defense = amount
	
	$ShieldFX.play("Pop")
	
func set_water(amount):
	if amount > GS.PLANT_WATER_MAX:
		amount = GS.PLANT_WATER_MAX
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
	if is_final_plant:
		GS.start_ending()
		return
	HarvestManager.handle_harvest(self)


func current_perk():
	if not mutated:
		return null
	return GameData.variant_perk(species_id, variant_index)


# 决定这株植物是不是变种。种下时调用一次；如果调用时还没拿到 species_id，
# 后续浇水/收获时会再补一次。
func roll_mutation_if_needed():
	if is_final_plant or species_id == "" or mutation_rolled:
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

	# 很多变种要等开花、结果才看得出来，前中期保持正常颜色。
	_update_variant_tint()


# 变种颜色按生长阶段逐步显现：
# 最后一帧之前保持原色，成熟前一帧给一点暗示，成熟帧与图鉴照片完全一致。
func _update_variant_tint():
	if not mutated:
		$Plant.modulate = Color.white
		_last_tint_frame = $Plant.frame
		return

	var max_frame = max_growth_frame()
	var remaining = max_frame - $Plant.frame
	var strength = 0.0
	if remaining <= 0:
		strength = 1.0
	elif remaining == 1:
		strength = 0.35

	var c = GameData.variant_color(species_id, variant_index)
	$Plant.modulate = Color(1, 1, 1).linear_interpolate(c, strength)
	_last_tint_frame = $Plant.frame


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
			# v1.8：变异的高光反馈统一放到收获弹窗的"收获变异植物"音效，
			# 这里不再叠一段旧魔法音，避免双响。
		return _resolved_id

	RunStats.mutation_pity += 1
	_entry_resolved = true
	_resolved_id = species_id
	return _resolved_id


# 春季：1 次浇水推进 2 个生长帧；其他季节 1 帧。
# 非洲太阳月见草不受这个季节惩罚，始终按 2 帧生长。
func growth_steps():
	# 终局植物不属于任何一季，每次浇水都稳定推进 2 帧。
	if is_final_plant:
		return 2
	var steps = Season.growth_per_water()
	var perk = current_perk()
	if perk != null and perk.get("always_two_growth", false):
		steps = max(steps, 2)
	return steps


func max_growth_frame():
	return $Plant.frames.get_frame_count("default") - 1


func is_mature():
	return $Plant.frame >= max_growth_frame()


# 返回实际推进的帧数。已经成熟时会返回 0，
# 让催熟卡可以给玩家一个明确的反馈。
func advance_growth(steps):
	var max_frame = max_growth_frame()
	var before = $Plant.frame
	for i in range(steps):
		if $Plant.frame < max_frame:
			$Plant.frame += 1

	var advanced = $Plant.frame - before
	if advanced > 0:
		_update_variant_tint()
		if not $AnimationPlayer.is_playing() and has_node("PlantUpgradeParticles"):
			$PlantUpgradeParticles.restart()
	return advanced


func upgrade_plant():
	roll_mutation_if_needed()
	_apply_variant_setup()
	advance_growth(growth_steps())

# 速成：直接推到成熟帧，并在本回合结束时结算收获。
func force_mature():
	$Plant.frame = max_growth_frame()
	forced_mature = true
	_update_variant_tint()
	
func turn_over():
	# If we are being polled about our turn, then the card selection
	# dialog must be related to this plant.
	if GS.waiting_for_card_selection:
		return false
	return not $AnimationPlayer.is_playing()
	
func finalize_turn():
	if consumed:
		queue_free()
