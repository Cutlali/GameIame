extends TextureRect

export var description = ""
export var cost = 5

var bought = false

export var is_energy = true

export var up_num = 1

func _ready():
	$Button.text = "购买（" + String(cost) + " 金币）"
	
	$Button.connect("pressed", self, "_on_buy")
	
func _on_buy():
	if bought:
		return
	
	if is_energy and GS.energy_max >= GS.ENERGY_CAP:
		return
	
	if GS.gold >= cost:
		bought = true
		GS.gold -= cost
		
		if is_energy:
			var before = GS.energy_max
			GS.add_permanent_energy(1)
			if GS.energy_max > before:
				GS.energy = min(GS.energy + 1, GS.energy_max)
		else:
			if up_num == 1 or up_num == 2:
				GS.queue_farm_choice()
			elif up_num == 3:
				GS.card_draw_count += 1
			elif up_num == 4:
				GS.auto_water = true
			



func _process(delta):
	if bought:
		$Button.hide()
	else:
		$Button.show()
		$Button.disabled = (GS.gold < cost) or (is_energy and GS.energy_max >= GS.ENERGY_CAP)

