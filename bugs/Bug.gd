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

func spawn_now():
	spawned = true
	$AnimationPlayer.play("Spawn")

#func _ready():
#	spawned = true
#	$AnimationPlayer.play("Spawn")

func _physics_process(delta):
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
	health -= amount
	if health <= 0:
		var stats = get_node_or_null("/root/RunStats")
		if stats != null:
			stats.pests_killed += 1
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
	_stun_tween.interpolate_property(self, "modulate", modulate, Color.white, 0.55)
	_stun_tween.start()


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
	
	var act = compute_action()
	
	if act == ActionType.ATTACK_CLOSEST:
		attack(find_closest())
		
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
	current_plant_target.slash_health(1, self)
	
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
