extends Node

export var improv_nrg = 0.0

var pan_fx: AudioEffectPanner = null

var pan_direction = 1.0

func _ready():
	$Improv.play()
	$Drone.play()

	$Improv.volume_db = -100

	var improv_bus = AudioServer.get_bus_index("Improv")
	var fx: AudioEffectPanner = AudioServer.get_bus_effect(improv_bus, 0)

	pan_fx = fx


# v1.8 场景配乐模式："menu"=旧氛围底（drone+即兴），"game"=游戏循环，
# "shatter"=瓶碎长曲（点重开按钮前一直放），"ending"=结局曲（单次）。
var _bgm_mode = ""

func set_mode(mode):
	if mode == _bgm_mode:
		return
	_bgm_mode = mode
	$GameMusic.stop()
	$ShatterMusic.stop()
	$EndingMusic.stop()
	$Drone.stop()
	$Improv.stop()
	match mode:
		"game":
			$GameMusic.stream.loop = true
			$GameMusic.play()
		"shatter":
			$ShatterMusic.stream.loop = true
			$ShatterMusic.play()
		"ending":
			$EndingMusic.stream.loop = false
			$EndingMusic.play()
		_:
			$Drone.play()
			$Improv.play()
			$Improv.volume_db = -100
	
func _process(delta):
	if not $AnimationPlayer.is_playing():
		pan_direction = 1.0
		if randi() % 100 <= 50:
			pan_direction = -1.0 # Rnadom pan direction
		
		var length = rand_range(1.0, 3.5)
		$AnimationPlayer.play("AddImprov", 0, 1.0 / length)
		
	$Improv.volume_db = linear2db(improv_nrg)
	
	pan_fx.pan = lerp(-0.7 * pan_direction, 0.7 * pan_direction, improv_nrg)
