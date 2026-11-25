extends Node2D

enum ActionType {
	ATTACK_CLOSEST
}

export var health = 3

export var actions: Array = [ActionType.ATTACK_CLOSEST]

var next_action = 0

var current_plant_target = null

var spawned = false

# 捕虫网：让这只虫跳过下一次攻击。
var stun_turns = 0
var _stun_tween: Tween

# 年度压力虫：
# 瓶虱每 3 回合直接啃咬一次魔瓶；精英虫有外壳、咬得更重；
# 巨虫是大规模虫群里压场的那一只——血最厚、壳最硬、咬得最狠，但动作慢半拍。
var is_bottle_biter = false
var is_elite = false
var is_giant = false
# 飞虫：悬停 + 每回合扑向最渴的植物。
var is_flyer = false
var _fly_tween = null
var _bob_seed = 0.0
var armor = 0
var bite_damage = 1
var bottle_bite_timer = 2
# 巨虫两回合才咬一次，用它记下这回合是否跳过。
var _giant_pause = false

var base_modulate = Color(1, 1, 1)


func _ready():
	Flags.unlock_guide("guide_pest_seen", 7, "瓶子里的虫")

	# 虫害逐年升级：咬植物的伤害每年 +1，外壳也逐年变硬。
	var year_bonus = 0
	if has_node("/root/Season"):
		year_bonus = max(0, Season.year - 1)
	bite_damage = 1 + year_bonus

	# 每种虫子用不同的外形和颜色区分。
	# v1.8：试玩反馈虫子偏小，整体放大约 1.24 倍（巨虫画布本来就满，稍增即可）。
	if is_flyer:
		base_modulate = Color(0.76, 0.88, 0.98)
		$Sprite.texture = load("res://bugs/bug_aphid.png")
		scale = Vector2(1.12, 1.12)
		_bob_seed = rand_range(0.0, 64.0)
	elif is_giant:
		scale = Vector2(1.18, 1.18)
		# 巨虫与普通虫共用 64x64 画布，靠画得更满（约 54x28）显出体型，
		# 所以不用再缩放，只调颜色与属性。
		bite_damage += 2
		armor = 2 + int(year_bonus / 2)
		base_modulate = Color(0.72, 0.55, 0.86)
		$Sprite.texture = load("res://bugs/bug_giant.png")
	elif is_elite:
		bite_damage += 1
		armor = 1 + int(year_bonus / 2)
		base_modulate = Color(0.98, 0.84, 0.46)
		$Sprite.texture = load("res://bugs/bug_locust.png")
	elif is_bottle_biter:
		base_modulate = Color(0.82, 0.68, 1.0)
		$Sprite.texture = load("res://bugs/bug_beetle.png")
	elif health >= 9:
		base_modulate = Color(0.94, 0.52, 0.52)
		$Sprite.texture = load("res://bugs/bug_locust.png")
	elif health >= 5:
		base_modulate = Color(1.0, 0.76, 0.60)
		$Sprite.texture = load("res://bugs/bug_beetle.png")
	elif health >= 3:
		base_modulate = Color(0.86, 0.80, 0.62)
		$Sprite.texture = load("res://bugs/bug_aphid.png")
	else:
		base_modulate = Color(0.76, 0.90, 0.68)
		$Sprite.texture = load("res://bugs/bug_aphid.png")
	if not is_flyer:
		scale = Vector2(1.24, 1.24)
	modulate = base_modulate
	update()

func spawn_now():
	spawned = true
	$AnimationPlayer.play("Spawn")

#func _ready():
#	spawned = true
#	$AnimationPlayer.play("Spawn")

func _physics_process(delta):
	# 血量只写数字；瓶虱/精英虫靠外形和左上角标记区分。
	$HeartMarker/HealthNum.text = String(health)

	# 飞虫悬停：无动画时轻轻上下浮动。
	if is_flyer and not $AnimationPlayer.is_playing():
		$Sprite.position.y = 52.0 + sin((GS.global_sine_timer * 64.0 + _bob_seed) * PI / 32.0) * 4.0
	
	# If our animation is done, also check the target's animation.
	if not $AnimationPlayer.is_playing():
		if is_instance_valid(current_plant_target):
			if not current_plant_target.get_node("AnimationPlayer").is_playing():
				current_plant_target = null
				
func dec_health():
	if health <= 0:
		return
	var amount = attack_queue.pop_front()
	if amount == null:
		amount = 1
	# 精英虫的外壳至少挡掉 1 点伤害，但不会完全免疫。
	if armor > 0:
		amount = max(1, amount - armor)
	health -= amount
	if health <= 0:
		var stats = get_node_or_null("/root/RunStats")
		if stats != null:
			stats.pests_killed += 1
		# 虫子死亡奖励：一张 0 费速成卡，每轮最多 3 张。
		var gs = get_node_or_null("/root/GS")
		if gs != null:
			gs.grant_mature_reward()
		remove_from_group("Enemy")
		remove_from_group("Object")
		$AnimationPlayer.queue("OutOfHealth")
		
var attack_queue = []
		
func take_damage(amount):
	if health <= 0:
		return
	attack_queue.push_back(amount)
	$AnimationPlayer.play("Slash")


# 反伤不应该打断虫子正在播放的咬击动画。
func take_reflect_damage(amount):
	if health <= 0:
		return
	attack_queue.push_back(amount)
	if $AnimationPlayer.current_animation == "Attack":
		$AnimationPlayer.queue("Slash")
	else:
		$AnimationPlayer.play("Slash")


func stun_next_attack():
	stun_turns = max(stun_turns, 1)
	_flash_stun()


func _flash_stun():
	if _stun_tween != null and is_instance_valid(_stun_tween):
		_stun_tween.stop_all()
	else:
		_stun_tween = Tween.new()
		add_child(_stun_tween)
	modulate = Color(1.0, 0.92, 0.55)
	_stun_tween.interpolate_property(self, "modulate", modulate, base_modulate, 0.55)
	_stun_tween.start()


func _draw():
	# 飞虫的影子画在地面上，配合悬停读出"浮空"。
	if is_flyer:
		draw_set_transform(Vector2(64, 84), 0, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, 14, Color(0.0, 0.0, 0.0, 0.18))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# 特殊虫的标记画在血条上方，不占用血量数字。
	if is_giant:
		# 双层甲壳记号：比精英虫的单层硬壳更压人。
		var x = 120.0
		var y = 2.0
		draw_rect(Rect2(x, y + 2, 20, 14), Color(0.30, 0.24, 0.38))
		draw_rect(Rect2(x + 2, y + 4, 16, 4), Color(0.80, 0.72, 0.92))
		draw_rect(Rect2(x + 2, y + 10, 16, 3), Color(0.58, 0.50, 0.72))
		draw_rect(Rect2(x, y + 2, 20, 14), Color(0.16, 0.12, 0.22), false, 1.0)
	elif is_bottle_biter:
		var x = 120.0
		var y = 6.0
		draw_rect(Rect2(x + 5, y, 6, 4), Color(0.52, 0.34, 0.78))
		draw_rect(Rect2(x + 3, y + 4, 10, 14), Color(0.76, 0.60, 1.0))
		draw_rect(Rect2(x + 3, y + 4, 10, 14), Color(0.40, 0.26, 0.62), false, 1.0)
		draw_line(Vector2(x + 5, y + 9), Vector2(x + 8, y + 13),
			Color(0.98, 0.95, 1.0), 1.0)
		draw_line(Vector2(x + 8, y + 13), Vector2(x + 6, y + 16),
			Color(0.98, 0.95, 1.0), 1.0)
	elif is_elite:
		var pts = PoolVector2Array([
			Vector2(128, 4), Vector2(138, 9), Vector2(136, 20),
			Vector2(128, 26), Vector2(120, 20), Vector2(118, 9)
		])
		draw_colored_polygon(pts, Color(0.92, 0.74, 0.30, 0.95))
		var outline = pts
		outline.append(pts[0])
		draw_polyline(outline, Color(0.42, 0.24, 0.06), 1.0)


func pull_action():
	var result = actions[next_action]
	
	next_action += 1
	if next_action >= actions.size():
		next_action = 0
		
	return result

func compute_action():
	var op = actions[next_action]
	
	# Here we can implement some branching logic... basically a very
	# simple bytecode... if we want more complex enemy behaviors.
	
	return op

func take_turn():
	$AnimationPlayer.queue("Delay")
	
	if not spawned:
		spawned = true
		$AnimationPlayer.queue("Spawn")
		return

	if stun_turns > 0:
		stun_turns -= 1
		current_plant_target = null
		_flash_stun()
		return

	# 巨虫体型笨重，隔一回合才咬一次，给玩家留出集火的窗口。
	if is_giant:
		_giant_pause = not _giant_pause
		if _giant_pause:
			current_plant_target = null
			return

	# 瓶虱每 3 回合直取魔瓶，其余回合照常咬植物。
	if is_bottle_biter:
		if bottle_bite_timer <= 0:
			bottle_bite_timer = 2
			bite_bottle()
			return
		bottle_bite_timer -= 1
	
	# 飞虫：先飞扑到最渴的植物旁边，再下口；爬虫守在原地不动。
	if is_flyer:
		var tgt = find_thirstiest()
		if tgt == null:
			tgt = find_closest()
		if tgt == null:
			return
		current_plant_target = tgt
		var dest = _landing_cell(tgt)
		if dest != position:
			if _fly_tween != null and is_instance_valid(_fly_tween):
				_fly_tween.stop_all()
				_fly_tween.queue_free()
			_fly_tween = Tween.new()
			add_child(_fly_tween)
			_fly_tween.interpolate_property(self, "position", position, dest, 0.45,
				Tween.TRANS_SINE, Tween.EASE_IN_OUT)
			# 飞到位后再下口：interpolate_method 没有“带参数回调”的用法，
			# 这里要用 interpolate_callback，否则运行时会报参数数量错误。
			_fly_tween.interpolate_callback(self, 0.45, "attack", tgt)
			_fly_tween.start()
		else:
			attack(tgt)
		return

	var act = compute_action()
	
	if act == ActionType.ATTACK_CLOSEST:
		attack(find_closest())


func find_thirstiest():
	var best = null
	for plant in get_tree().get_nodes_in_group("Plant"):
		if not is_instance_valid(plant) or plant.consumed:
			continue
		if plant.is_final_plant:
			continue
		if best == null or plant.water < best.water:
			best = plant
	return best


func _landing_cell(plant):
	var dirs = [Vector2(128, 0), Vector2(-128, 0), Vector2(0, 128), Vector2(0, -128)]
	dirs.shuffle()
	for d in dirs:
		var p = plant.position + d
		if GS.get_object_at_map_lcoord(p) == null:
			return p
	return plant.position + Vector2(128, 0)

func bite_bottle():
	$AnimationPlayer.play("Attack")
	# 直接啃瓶的伤害增长得慢一些，避免高年份一轮碎瓶。
	var year_bonus = 0
	if has_node("/root/Season"):
		year_bonus = max(0, Season.year - 1)
	BottleManager.damage(1 + int(year_bonus / 2))
		
func turn_over():
	if _fly_tween != null and is_instance_valid(_fly_tween) and _fly_tween.is_active():
		return false
	if is_instance_valid(current_plant_target):
		if current_plant_target.get_node("AnimationPlayer").is_playing():
			return false
	return not $AnimationPlayer.is_playing()
	
func attack(plant):
	if not is_instance_valid(plant):
		return
	
	$AnimationPlayer.play("Attack")
	current_plant_target = plant
	
func play_target_anim():
	if not is_instance_valid(current_plant_target):
		return
	current_plant_target.slash_health(bite_damage, self)
	
func find_closest():
	var closest = null
	var dist = 0
	for plant in get_tree().get_nodes_in_group("Plant"):
		if plant.consumed: # Consumed plants will queue_free() immediately
			continue
		
		if closest == null:
			closest = plant
			dist = (plant.position - position).length()
		else:
			var test = (plant.position - position).length()
			if test < dist:
				closest = plant
				dist = test
	return closest
	
func finalize_turn():
	pass
