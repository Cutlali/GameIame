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
# 瓶虱每 3 回合直接啃咬一次魔瓶；精英虫有外壳、咬得更重。
var is_bottle_biter = false
var is_elite = false
var armor = 0
var bite_damage = 1
var bottle_bite_timer = 2

var base_modulate = Color(1, 1, 1)


func _ready():
	Flags.unlock_guide("guide_pest_seen", 6, "瓶子里的虫")

	# 虫害逐年升级：咬植物的伤害每年 +1，外壳也逐年变硬。
	var year_bonus = 0
	if has_node("/root/Season"):
		year_bonus = max(0, Season.year - 1)
	bite_damage = 1 + year_bonus

	# 每种虫子用不同的外形和颜色区分。
	if is_elite:
		bite_damage += 1
		armor = 1 + int(year_bonus / 2)
		base_modulate = Color(0.98, 0.84, 0.46)
		$Sprite.texture = load("res://bugs/bug9.svg")
	elif is_bottle_biter:
		base_modulate = Color(0.82, 0.68, 1.0)
		$Sprite.texture = load("res://bugs/bug3.svg")
	elif health >= 9:
		base_modulate = Color(0.94, 0.52, 0.52)
		$Sprite.texture = load("res://bugs/bug9.svg")
	elif health >= 5:
		base_modulate = Color(1.0, 0.76, 0.60)
		$Sprite.texture = load("res://bugs/bug5.svg")
	elif health >= 3:
		base_modulate = Color(0.86, 0.80, 0.62)
		$Sprite.texture = load("res://bugs/bug3.svg")
	else:
		base_modulate = Color(0.76, 0.90, 0.68)
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
	# 特殊虫的标记画在血条上方，不占用血量数字。
	if is_bottle_biter:
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

	# 瓶虱每 3 回合直取魔瓶，其余回合照常咬植物。
	if is_bottle_biter:
		if bottle_bite_timer <= 0:
			bottle_bite_timer = 2
			bite_bottle()
			return
		bottle_bite_timer -= 1
	
	var act = compute_action()
	
	if act == ActionType.ATTACK_CLOSEST:
		attack(find_closest())

func bite_bottle():
	$AnimationPlayer.play("Attack")
	# 直接啃瓶的伤害增长得慢一些，避免高年份一轮碎瓶。
	var year_bonus = 0
	if has_node("/root/Season"):
		year_bonus = max(0, Season.year - 1)
	BottleManager.damage(1 + int(year_bonus / 2))
		
func turn_over():
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
