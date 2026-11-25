extends Sprite

export var dynamic_display = false

var associated_card = null

var last_checked = 0

# 力量类卡牌只给“下一次造成伤害”的牌加成。
# 水牌、催熟、嫁接这些牌虽然也用 $DQ 占位，但不吃伤害加成。
func _uses_damage_bonus():
	if associated_card == null:
		return false
	match associated_card.action:
		GS.Action.ATTACK, GS.Action.NET, GS.Action.ATTACK_ALL, \
		GS.Action.DRAIN_WATER_DMG_RNG, GS.Action.DRAIN_WATER_DMG_ALL, \
		GS.Action.HEAL_DMG_NEAR, GS.Action.DEF_DMG_NEAR, \
		GS.Action.HEAL_ALL_DMG, GS.Action.SACRIF:
			return true
	return false


func update_display():
	var bonus = last_checked if _uses_damage_bonus() else 0
	var q = associated_card.quantity + bonus
	
	var dq = String(q)
	if bonus != 0:
		dq = "[color=#3d3]" + dq + "[/color]"
	
	$Desc.bbcode_text = "[center]" + associated_card.desc.replace("$DQ", dq) + "[/center]"

func set_color(color: Color):
	$Title.add_color_override("font_color", color)
	$Desc.add_color_override("default_color", color)
	$Cost.add_color_override("font_color", color)

func _ready():
	var cat = associated_card.cat
	
	if cat == GS.CAT_ATK:
		texture = GS.CardTexAtk
	elif cat == GS.CAT_DEF:
		texture = GS.CardTexDef
		set_color(Color.lightgray)
	elif cat == GS.CAT_WATER:
		texture = GS.CardTexWater
	elif cat == GS.CAT_SEED:
		texture = GS.CardTexSeed
		
	if associated_card.icon != null:
		$Icon.texture = associated_card.icon
	
	update_display()

func _process(delta):
	if not dynamic_display:
		return
	# 重开、读档这类时刻 GS.cursor 会短暂为 null，而手牌还挂在树上，
	# 这时候不刷加成，等光标重新就位再说。
	if GS.cursor == null:
		return

	# 不消耗伤害加成的牌永远显示自己的原始数值。
	if not _uses_damage_bonus():
		if last_checked != 0:
			last_checked = 0
			update_display()
		return

	if GS.cursor.current_damage_add != last_checked:
		last_checked = GS.cursor.current_damage_add
		update_display()
