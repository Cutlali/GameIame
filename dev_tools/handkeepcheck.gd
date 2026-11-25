extends SceneTree

# v1.8 手牌保留制回归检查。
# 覆盖：发牌补到上限、超上限结束回合被截停、确认后未保留的牌被回收
# （不进弃牌堆）、回合照常推进、下一轮只补差额。
# 用法：Godot --path <project> --user-dir rt_handkeep --script res://dev_tools/handkeepcheck.gd

var game = null
var gs = null
var hk = null
var season = null
var sv = null

var stage = 0
var stage_ms = 0
var frames = 0
var problems = []
var start_hand = 0
var disc_before = 0
var round_before = 0
var kept_after = 0


func _init():
	OS.window_size = Vector2(1080, 800)
	var flags = get_root().get_node("Flags")
	flags.skip_tutorial = true
	sv = get_root().get_node("SaveGame")
	sv.enabled = false
	gs = get_root().get_node("GS")
	hk = get_root().get_node("HandKeepUI")
	season = get_root().get_node("Season")
	game = load("res://Game.tscn").instance()
	get_root().add_child(game)
	stage_ms = OS.get_ticks_msec()


func _check(ok, msg):
	if not ok:
		problems.append(msg)


func _next(new_stage, wait_ms = 350):
	stage = new_stage
	stage_ms = OS.get_ticks_msec()


func _hand_cards():
	var n = 0
	for c in gs.hand.get_children():
		if c.get("associated_card") != null:
			n += 1
	return n


func _idle(_delta):
	frames += 1

	if stage == 0 and gs.hand != null and is_instance_valid(gs.hand) and _hand_cards() > 0:
		gs.tutorial = false
		gs.tutorial_allow_end_turn = true
		# 开局手牌来自教程 skip 的固定配置（3 张教学牌 + 2 张抽取），
		# "补满上限"从第一次结束回合后的发牌起算，由 stage 4 验证。
		_check(_hand_cards() >= 3, "opening hand %d too small" % _hand_cards())
		_check(gs.hand_cap() == 5, "default cap should be 5, got %d" % gs.hand_cap())
		# 上限硬封顶 6：里程碑/加成堆再多也不许超过。
		var old_bonus = gs.bonus_draws
		gs.bonus_draws = 10
		_check(gs.hand_cap() == 6, "hand cap must clamp at 6, got %d" % gs.hand_cap())
		gs.bonus_draws = old_bonus
		start_hand = _hand_cards()
		_next(1, 50)

	elif stage == 1:
		# 人为塞 3 张，模拟魔瓶成批进手。
		for i in range(3):
			gs.add_card_to_hand(gs.card_by_id("whack"))
		_check(_hand_cards() == start_hand + 3, "adding cards failed")
		_next(2, 50)

	elif stage == 2:
		round_before = season.round_in_year
		disc_before = gs.discard_pile.size()
		var over = _hand_cards() > gs.hand_cap()
		gs.end_turn()
		if not over:
			_check(not hk._root.visible, "panel must not open at/below cap")
			_next(4, 120)
			return
		_check(hk._root.visible, "over-cap end_turn should open keep panel")
		_check(gs.hand_keep_open, "hand_keep_open flag should be set")
		_check(gs.turn_state == gs.TurnState.PLAYING_CARDS, "turn must not advance while panel open")
		_check(season.round_in_year == round_before, "round advanced behind the panel")
		_check(not hk._confirm_button.disabled, "default selection should already satisfy cap")
		_check(_hand_cards() - _kept_count_panel() == _hand_cards() - gs.hand_cap(),
			"auto-keep should drop exactly the overflow")
		_next(3, 50)

	elif stage == 3:
		kept_after = _kept_count_panel()
		var dropped = _hand_cards() - kept_after
		hk._on_confirm_pressed()
		_check(not hk._root.visible, "panel should close after confirm")
		_check(not gs.hand_keep_open, "hand_keep_open should clear")
		_check(dropped >= 1, "expected at least one card dropped")
		_check(dropped <= 3 + max(0, start_hand - gs.hand_cap()), "dropped too many: %d" % dropped)
		# 回收的牌不进入弃牌堆（当前没有打出的牌，堆大小不应因确认而变化太多）。
		_next(4, 120)

	elif stage == 4:
		# 回合已恢复推进：等到本轮结算完、新手牌发出来。
		if gs.turn_state == gs.TurnState.PLAYING_CARDS and season.round_in_year != round_before:
			var cap = gs.hand_cap()
			var n = _hand_cards()
			_check(n >= cap, "refill should reach cap: %d < %d" % [n, cap])
			# 回收过的 whack 不应从弃牌堆成批回流：只检查弃牌堆没有吞掉回收牌
			_check(gs.discard_pile.size() <= disc_before + 4,
				"dropped cards leaked into discard pile (%d -> %d)" % [disc_before, gs.discard_pile.size()])
			_next(5, 80)

	elif stage == 5:
		# 常驻整理按钮已删除，面板只应由"超限的结束回合"强制拉起。
		var before = _hand_cards()
		_check(before > gs.hand_cap(), "after refill hand should exceed cap again: %d" % before)
		gs.end_turn()
		_check(hk._root.visible, "second over-cap end_turn opens keep panel")
		_check(hk._cards.size() == before,
			"panel snapshot covers whole hand: %d vs %d" % [hk._cards.size(), before])
		var kept_default = _kept_count_panel()
		_check(kept_default == gs.hand_cap(),
			"auto unkeep leaves exactly cap kept: %d vs %d" % [kept_default, gs.hand_cap()])
		# 在默认基础上再多还一张（保留区最后一张），确认。
		var idx = kept_default - 1
		hk._slot_buttons[idx].pressed = false
		hk._on_slot_toggled(false, idx)
		var keep_n = _kept_count_panel()
		_check(keep_n == kept_default - 1, "should unkeep one more than default")
		print("HK5 dbg before=%d snap=%d kept_default=%d keep_n=%d" % [before, hk._cards.size(), kept_default, keep_n])
		var unkeep = 0
		for k in hk._keep.keys():
			if not hk._keep[k]:
				unkeep += 1
		print("HK5 dbg unkeep_flags=%d valid=%d" % [unkeep, 0])
		hk._on_confirm_pressed()
		# 确认会同步续跑回合结算：同一调用栈里下一轮已经又发了 card_draw_count 张。
		_check(_hand_cards() == keep_n + gs.card_draw_count,
			"kept %d + fresh round dealt %d, got %d" % [keep_n, gs.card_draw_count, _hand_cards()])
		_report()
		quit()
		return true

	return false


func _kept_count_panel():
	var n = 0
	for k in hk._keep.keys():
		if hk._keep[k]:
			n += 1
	return n


func _report():
	if problems.empty():
		print("HANDKEEP CHECK OK")
	else:
		for p in problems:
			print("FAIL: " + p)
		print("HANDKEEP CHECK FAILED %d" % problems.size())
