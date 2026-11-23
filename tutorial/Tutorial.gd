extends Label

# 新手引导：不再复述规则，只教“手怎么动”。
# 流程：自动翻开手记前四页 → 种植 → 浇水 → 结束回合 → 虫子出现 → 翻手记 → 攻击。
# 每个阶段只放行当前需要的操作，其余入口由 GS 的教程锁和场景闸门挡住。

enum Stage {
	OPEN_GUIDE,
	PLANT,
	WATER,
	END_TURN,
	BUG_GUIDE,
	ATTACK,
	FINAL,
	DONE
}

var stage = Stage.OPEN_GUIDE
var _avatar = null
var _next_button = null
var _panel = null
var _bug_spawn_retries = 0


func contains_mouse(control: Control):
	var r = Rect2(Vector2.ZERO, control.rect_size)
	return r.has_point(control.get_local_mouse_position())


func _ready():
	GS.tutorial = true
	GS.tutorial_allow_guide = false
	GS.tutorial_allow_end_turn = false
	GS.tutorial_allowed_action = ""
	GS.card_draw_count = 5
	GS.turn_state = GS.TurnState.WAITING_FOR_TUTORIAL

	TutorialSteps.reset_all_state()
	TutorialSteps.tutorial = self
	TutorialSteps.need_end_turn_button = false

	_next_button = $NextButton
	_panel = $Panel
	# 每段提示最多两行，把默认很高的对话框收窄一点。
	# 文字区收窄一点，配合左侧头像让整个对话框在屏幕上居中。
	margin_left = -229.0
	margin_right = 311.0
	margin_bottom = margin_top + 152.0
	# 对话框往左多伸一块，头像放在框内，文字从右边留白后开始。
	_panel.margin_left = -112.0
	_panel.margin_right = 30.0
	_panel.margin_top = -20.0
	_panel.margin_bottom = 34.0
	_next_button.visible = false
	_make_avatar()

	if Flags.skip_tutorial:
		call_deferred("tutorial_skip")
		return

	text = "石头下面除了这只瓶子，还压着一本手记。"
	call_deferred("_open_first_guide")


func _make_avatar():
	# 头像放进对话框内部左侧，用圆角裁切成一枚小画像。
	var frame = Panel.new()
	frame.rect_clip_content = true
	var box = StyleBoxFlat.new()
	box.bg_color = Color(0.96, 0.92, 0.82, 1.0)
	box.border_color = Color(0.36, 0.24, 0.15, 0.85)
	box.border_width_left = 2
	box.border_width_right = 2
	box.border_width_top = 2
	box.border_width_bottom = 2
	box.corner_radius_top_left = 8
	box.corner_radius_top_right = 8
	box.corner_radius_bottom_left = 8
	box.corner_radius_bottom_right = 8
	frame.add_stylebox_override("panel", box)
	frame.margin_left = 18.0
	frame.margin_right = 102.0
	frame.margin_top = 54.0
	frame.margin_bottom = 138.0
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(frame)

	_avatar = TextureRect.new()
	_avatar.texture = load("res://prologue/avatar.jpg")
	_avatar.anchor_right = 1.0
	_avatar.anchor_bottom = 1.0
	_avatar.expand = true
	_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_avatar)


func _open_first_guide():
	if GS.guide == null:
		_on_first_guide_read()
		return
	GS.tutorial_allow_guide = true
	GS.guide.open_required([0, 1, 2, 3], funcref(self, "_on_first_guide_read"))


func _on_first_guide_read():
	GS.tutorial_allow_guide = false
	stage = Stage.PLANT
	GS.turn_state = GS.TurnState.PLAYING_CARDS
	GS.tutorial_allowed_action = "plant"
	tutorial_cards()
	text = "笔记说，种子要落在翻好的土上。\n那我来试试。"


func tutorial_cards():
	GS.add_card_to_hand(GS.card_basic_plant)
	GS.add_card_to_hand(GS.card_free_1x1_water)

	GS.draw_pile.push_back(GS.card_small_attack)
	GS.draw_pile.push_back(GS.card_medium_plant)

	GS.discard_pile.push_back(GS.card_buy_1x1_water)
	GS.discard_pile.push_back(GS.card_high_plant)
	GS.discard_pile.push_back(GS.card_small_attack)


func on_event(event_name):
	match event_name:
		"planted":
			if stage == Stage.PLANT:
				_start_water()
		"watered":
			if stage == Stage.WATER:
				_start_end_turn()
		"ended_turn":
			if stage == Stage.END_TURN:
				call_deferred("_start_bug")
		"attacked":
			if stage == Stage.ATTACK:
				_finish()


func _start_water():
	stage = Stage.WATER
	GS.tutorial_allowed_action = "water"
	text = "它真的冒芽了。\n笔记说，植物需要水。"


func _start_end_turn():
	stage = Stage.END_TURN
	GS.tutorial_allowed_action = ""
	GS.tutorial_allow_end_turn = true
	TutorialSteps.need_end_turn_button = true
	text = "种子喝饱了水，接下来交给时间。\n结束这一回合吧。"


func _start_bug():
	# 等新手牌真正发到手上，再刷虫子。
	if GS.turn_state != GS.TurnState.PLAYING_CARDS:
		_bug_spawn_retries += 1
		if _bug_spawn_retries < 60:
			call_deferred("_start_bug")
		return

	stage = Stage.BUG_GUIDE
	GS.tutorial_allowed_action = ""
	GS.tutorial_allow_end_turn = false
	TutorialSteps.need_end_turn_button = false

	var plants = get_tree().get_nodes_in_group("Plant")
	var lcoord = Vector2.ZERO
	if not plants.empty():
		lcoord = plants[0].position + Vector2(128 * 2, 0)

	# 教程里由引导按钮直接翻书，不要让 HUD 再弹一次“手记更新”。
	Flags.guide_pest_seen = true
	var bug = GS.spawn_bug_lcoord(lcoord)
	if bug != null:
		# 教程里的第一只虫只要一击就能赶走，避免留下半血的虫继续咬植物。
		bug.health = 1
		bug.spawn_now()

	_ensure_attack()
	text = "有东西在土里动……\n笔记里好像写过这个。"
	GS.tutorial_allow_guide = true
	_next_button.text = "翻开手记"
	_next_button.visible = true


func _on_NextButton_pressed():
	match stage:
		Stage.BUG_GUIDE:
			GS.tutorial_allow_guide = true
			Flags.guide_pest_seen = true
			_next_button.visible = false
			if GS.guide != null:
				GS.guide.open_required([6], funcref(self, "_on_bug_guide_read"))
			else:
				_on_bug_guide_read()
		Stage.FINAL:
			end_tutorial()


func _on_bug_guide_read():
	GS.tutorial_allow_guide = false
	stage = Stage.ATTACK
	GS.tutorial_allowed_action = "attack"
	_ensure_attack()
	text = "书上说，它们会啃食植物。\n先把它赶走。"
	_next_button.visible = false


func _ensure_attack():
	if GS.hand == null or not is_instance_valid(GS.hand):
		return
	for c in GS.hand.get_children():
		if c.associated_card != null and c.associated_card.action == GS.Action.ATTACK:
			return
	GS.add_card_to_hand(GS.card_small_attack)


func _finish():
	stage = Stage.FINAL
	GS.tutorial_allowed_action = ""
	text = "……好险。\n剩下的，手记里都写了。"
	_next_button.text = "继续"
	_next_button.visible = true


func end_tutorial():
	stage = Stage.DONE
	GS.tutorial = false
	GS.tutorial_mouse = false
	GS.tutorial_allow_guide = false
	GS.tutorial_allow_end_turn = false
	GS.tutorial_allowed_action = ""
	GS.card_draw_count = 5
	TutorialSteps.need_end_turn_button = false
	TutorialSteps.tutorial = null
	_next_button.visible = false
	queue_free()


# 调试和回归测试用：跳过教程，直接给一套能玩的手牌。
func tutorial_skip():
	GS.tutorial_allow_guide = false
	GS.tutorial_allow_end_turn = false
	GS.tutorial_allowed_action = ""
	tutorial_cards()
	GS.draw_card_to_hand()
	GS.draw_card_to_hand()
	GS.no_enemy_turns = 2
	end_tutorial()
	GS.turn_state = GS.TurnState.PLAYING_CARDS


func _process(delta):
	if not GS.tutorial:
		GS.tutorial_mouse = false
		return
	GS.tutorial_mouse = contains_mouse(self) or contains_mouse(_next_button)
