extends SceneTree

# 开发工具：瓶碎过场回归。
# 用法：
#   Godot --path <project> --user-dir rt_breakcheck --script res://dev_tools/bottlebreakcheck.gd
# 覆盖：首次碎瓶播三页过场 → 翻到手记新页 → 合上后自动重开；
#       之后的碎瓶不再播过场，仍显示原来的结算面板。

var frames = 0
var started = false
var done = false
var failures = []

var bottle = null
var flags = null
var guide = null
var gs = null


func _init():
	OS.window_size = Vector2(1080, 800)


func _fail(msg):
	failures.append(msg)
	print("FAIL: ", msg)


func _check(cond, msg):
	if not cond:
		_fail(msg)


func _idle(_delta):
	frames += 1
	if not started:
		if frames < 3:
			return
		started = true
		bottle = get_root().get_node("BottleManager")
		flags = get_root().get_node("Flags")
		gs = get_root().get_node("GS")
		# 手记不是 autoload，按游戏里的方式临时挂一份。
		guide = load("res://ui/GuideBook.tscn").instance()
		get_root().add_child(guide)
		flags.reset_guide_unlocks()
		bottle._shatter_open = false
		bottle._shatter_pending = false
		bottle._break_first_time = false
		bottle._shatter_root.visible = false
		bottle.refill()
		_run()
		done = true
		return
	if done and frames > 10:
		if failures.empty():
			print("BOTTLE BREAK CHECK OK")
		else:
			print("BOTTLE BREAK CHECK FAILED: ", failures.size())
		quit()


func _run():
	bottle._show_shatter()

	_check(flags.guide_bottle_shattered, "first break sets the guide flag")
	_check(bottle._shatter_open, "first break enters shatter state")
	_check(gs.shatter_open, "first break locks interactions")
	_check(bottle._break_first_time, "first break remembers it is the first")
	_check(bottle._break_cutscene != null, "first break plays the cutscene")
	_check(not bottle._shatter_root.visible, "first break skips the summary panel")
	if bottle._break_cutscene == null:
		return
	var cut = bottle._break_cutscene
	_check(cut.PANELS.size() == 3, "cutscene has three panels")
	_check(cut.layer == 150, "cutscene sits above the HUD")
	# 装饰层必须放行鼠标，否则点图片/字幕不会翻页。
	_check(cut._dots_label.mouse_filter == Control.MOUSE_FILTER_IGNORE, "footer lets clicks through")
	_check(cut._photo.get_parent().get_parent().mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"photo frame lets clicks through")

	# 点三下：第一页 → 第二页 → 第三页 → 读完。
	# 第一下走真实的 gui_input 信号，确认点击绑定的确生效。
	var root = cut.get_child(0)
	var click = InputEventMouseButton.new()
	click.button_index = BUTTON_LEFT
	click.pressed = true
	root.emit_signal("gui_input", click)
	_check(cut._current == 1, "gui click advances")
	cut._on_click()
	_check(cut._current == 2, "second click advances")
	cut._on_click()

	_check(bottle._break_cutscene == null, "cutscene releases itself")
	_check(guide.visible, "handbook opens after the cutscene")
	_check(guide._restricted, "new page forces a read")
	_check(guide._current == 9, "handbook lands on the new page")
	_check(guide.CHAPTERS[9]["title"] == "09  第八页 · 碎裂之后", "new page title")
	_check(guide._is_unlocked(9), "new page is unlocked")
	_check(not bottle._shatter_root.visible, "summary stays hidden while reading")
	_check(bottle._shatter_open, "run is still frozen while reading")

	guide.close()
	_check(not guide.visible, "handbook closes")
	_check(not bottle._shatter_open, "closing the handbook restarts the run")
	_check(not gs.shatter_open, "interaction lock clears after restart")
	_check(bottle.hp == bottle.MAX_HP, "restart refills the bottle")

	# 第二次碎瓶：不再播过场，回到原来的结算面板。
	bottle._show_shatter()
	_check(bottle._break_cutscene == null, "later break skips the cutscene")
	_check(not bottle._break_first_time, "later break is not the first")
	_check(bottle._shatter_root.visible, "later break shows the summary panel")
	_check(bottle._shatter_body.text.find("你走到了第") >= 0, "summary keeps the year report")
	_check(not guide.visible, "handbook stays closed on the second break")
	_check(bottle._shatter_open, "summary holds the run until restart is pressed")
	_check(gs.shatter_open, "interaction lock stays while the summary is open")

	bottle._on_shatter_restart_pressed()
	_check(not bottle._shatter_open, "summary restart closes the flow")
	_check(not bottle._shatter_root.visible, "summary hides after restart")
	_check(not gs.shatter_open, "summary restart clears the interaction lock")
	_check(bottle.hp == bottle.MAX_HP, "summary restart refills the bottle")