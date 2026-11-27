extends SceneTree

# 手记与序章的结构冒烟检查。用真实时间等待补间，避免无头运行帧率过高。

var problems = []
var guide = null
var intro = null
var start_ms = 0
var stage = 0
var stage_ms = 0


func _init():
	OS.window_size = Vector2(1080, 800)
	start_ms = OS.get_ticks_msec()


func _check(ok, msg):
	if not ok:
		problems.append(msg)


func _visible_buttons(toc):
	var n = 0
	for c in toc.get_children():
		if c is Button and c.visible:
			n += 1
	return n


# 直接喂给序章根节点，验证点击处理本身（--script 模式不会真实派发鼠标事件）。
func _click(target, pos):
	var ev = InputEventMouseButton.new()
	ev.button_index = BUTTON_LEFT
	ev.pressed = true
	ev.position = pos
	ev.global_position = pos
	target.call("_gui_input", ev)


func _idle(_delta):
	var t = OS.get_ticks_msec() - start_ms

	if stage == 0 and t >= 60:
		var flags = get_root().get_node("Flags")
		flags.reset_guide_unlocks()
		guide = load("res://ui/GuideBook.tscn").instance()
		get_root().add_child(guide)
		stage = 1
		return

	if stage == 1 and t >= 220:
		var flags = get_root().get_node("Flags")
		guide.open()
		_check(guide.visible, "guide visible")
		var toc = guide.get_node("Root/Book/Margin/VBox/Body/Toc")
		var buttons = 0
		for c in toc.get_children():
			if c is Button:
				buttons += 1
		_check(buttons == guide.CHAPTERS.size(), "chapter buttons %d" % buttons)
		_check(guide.CHAPTERS.size() == 12, "notebook should have 12 pages")
		# 目录始终列全所有页，未解锁的章节只会被雾气盖住。
		_check(_visible_buttons(toc) == 12, "all 12 pages listed, got %d"
			% _visible_buttons(toc))
		_check(not guide._is_unlocked(4), "season locked at start")
		_check(not guide._is_unlocked(9), "shatter page locked at start")
		_check(not guide._is_unlocked(10), "milestone page locked at start")
		_check(not guide._is_unlocked(11), "final page locked at start")
		_check(guide._toc_buttons[4].hint_tooltip != "", "locked page gets fog tooltip")

		var body = guide.get_node("Root/Book/Margin/VBox/Body/Scroll/Content/ChapterBody")
		var title = guide.get_node("Root/Book/Margin/VBox/Body/Scroll/Content/ChapterTitle")
		var note_box = guide.get_node("Root/Book/Margin/VBox/Body/Scroll/Content/Note")
		_check(body.text.length() > 45, "chapter body text")
		_check(not note_box.visible, "side note box hidden, comments live in body")
		_check(body.text.find("最后一个") >= 0, "front page text")
		_check(title.text == "夹在最前面的一页", "front page title")
		_check(not guide._fog.visible, "unlocked page has no fog")

		# 未解锁的页也能翻开，但正文被雾气盖住。
		guide.select_chapter(4)
		_check(title.text == "04  第三页 · 四季会轮转", "locked chapter title")
		_check(not body.visible, "locked chapter body hidden")
		_check(guide._fog.visible, "locked chapter covered by fog")
		_check(guide._fog_hint.text.find("雾气") >= 0, "fog hint text")
		_check(not guide._peek_label.visible, "no peek line on ordinary locked page")

		# 解锁季节页，雾气散开。
		flags.guide_season_changed = true
		guide._refresh_toc()
		_check(guide._is_unlocked(4), "season page unlocked")
		_check(_visible_buttons(toc) == 12, "toc keeps every page, got %d"
			% _visible_buttons(toc))
		guide.select_chapter(4)
		_check(body.visible, "season body visible after unlock")
		_check(title.text == "04  第三页 · 四季会轮转", "season chapter title")
		_check(body.text.find("春天浇水") >= 0, "season page body")
		_check(body.text.find("批注：") >= 0, "comments included in body")
		_check(guide._fog_tween != null, "fog starts dissolving")
		stage = 5
		return

	if stage == 5 and t >= 1300:
		var flags = get_root().get_node("Flags")
		var toc = guide.get_node("Root/Book/Margin/VBox/Body/Toc")
		var body = guide.get_node("Root/Book/Margin/VBox/Body/Scroll/Content/ChapterBody")
		var title = guide.get_node("Root/Book/Margin/VBox/Body/Scroll/Content/ChapterTitle")
		_check(not guide._fog.visible, "fog hidden after dissolve")

		# 解锁虫害页（新编号 07）。
		flags.guide_pest_seen = true
		guide._refresh_toc()
		guide.select_chapter(7)
		_check(title.text == "07  第六页 · 瓶子里的虫", "pest chapter title")
		_check(body.text.find("抵御虫子的进攻") >= 0, "pest page comments")

		# 瓶子力量是新增的常驻页（06）。
		_check(guide._is_unlocked(6), "bottle power page always visible")
		_check(guide.CHAPTERS[6]["title"].find("瓶子的力量") >= 0, "new chapter inserted")

		# 最后一页：前七种集齐之前只有雾 + 引子句。
		flags.guide_variant_seen = true
		flags.guide_bottle_damaged = true
		flags.guide_milestone_seen = true
		guide._refresh_toc()
		_check(not guide._is_unlocked(11), "final page still foged below seven species")
		guide.select_chapter(11)
		_check(title.text == "11  最后一页 · 瓶子里的世界", "final chapter title")
		_check(not body.visible, "final body hidden before seven species")
		_check(guide._fog.visible, "final page fog visible")
		_check(guide._fog_hint.text.find("七种") >= 0, "fog hint mentions seven species")
		# 雾气盖住正文，但最后一句要露出来当引子。
		_check(guide._peek_label.visible, "peek line visible under fog")
		_check(guide._peek_label.text.find("灾难迎来终结") >= 0, "peek line text")
		_check(guide._peek_label.get_line_count() == 1, "peek line stays on one row, got %d"
			% guide._peek_label.get_line_count())
		_check(guide._peek_label.rect_position.y > guide._fog.rect_position.y + guide._fog.rect_size.y * 0.6,
			"peek line sits at the bottom of the page")

		# 收录到 7 个物种：阶段二（上一位拥有者的手记）散开。
		var enc = get_root().get_node("Encyclopedia")
		var old_entries = enc.discovered
		var gd = get_root().get_node("GameData")
		var seven = {}
		for i in range(7):
			seven[gd.SPECIES_ORDER[i]] = true
		enc.discovered = seven
		guide._refresh_toc()
		_check(guide._is_unlocked(11), "final page opens at seven species")
		guide.select_chapter(11)
		_check(body.visible, "stage 2 body visible after seven species")
		_check(body.text.find("下一个得到瓶子的人") >= 0, "stage 2 previous-owner text")
		_check(body.text.find("看着魔瓶") >= 0, "stage 2 discovery paragraph")
		_check(body.text.find("我是魔瓶的创造者") < 0, "stage 3 hidden before full species")
		_check(body.text.find("阶段") < 0, "no stage labels in body")
		guide._hide_fog()
		_check(not guide._peek_label.visible, "peek line gone once page is open")

		# 集齐所有植物：阶段三（创造者留言）接在同一个后页上。
		var full = {}
		for sid in gd.SPECIES_ORDER:
			full[sid] = true
		enc.discovered = full
		guide._refresh_toc()
		guide.select_chapter(11)
		_check(body.visible, "stage 3 visible at full species")
		_check(body.text.find("我是魔瓶的创造者") >= 0, "creator text")
		_check(body.text.find("奇迹的种子") >= 0, "creator seed hint")
		_check(body.text.find("下一个得到瓶子的人") >= 0, "stage 2 kept below stage 3")
		enc.discovered = old_entries

		# 首次瓶碎：手记多出一页“碎裂之后”。
		flags.guide_bottle_shattered = true
		guide._refresh_toc()
		_check(guide._is_unlocked(9), "shatter page unlocks after first break")
		guide.select_chapter(9)
		_check(title.text == "09  第八页 · 碎裂之后", "shatter chapter title")
		_check(body.text.find("碎片") >= 0, "shatter page body")

		guide.close()
		_check(not guide.visible, "guide closes")
		flags.reset_guide_unlocks()

		# 强制阅读：只留指定四页，最后一页藏起来，没读全不能合上。
		guide.open_required([0, 1, 2, 3])
		_check(guide.visible, "required guide visible")
		_check(guide._restricted, "required mode on")
		_check(_visible_buttons(toc) == 4, "required mode shows only 4 pages, got %d"
			% _visible_buttons(toc))
		_check(guide._close_button.disabled, "close disabled before reading")
		guide.close()
		_check(guide.visible, "required guide stays open before reading")
		for i in [0, 1, 2, 3]:
			guide.select_chapter(i)
		_check(not guide._close_button.disabled, "close enabled after all pages read")
		guide.close()
		_check(not guide.visible, "required guide closes after reading")
		_check(not guide._restricted, "required mode cleared after close")
		guide.queue_free()

		intro = load("res://Intro.tscn").instance()
		get_root().add_child(intro)
		stage = 2
		return

	if stage == 2 and t >= 400:
		_check(intro.PANELS.size() == 6, "intro has 6 panels")
		_check(intro._photo.texture != null, "intro photo loaded")
		_check(intro._index == 0, "intro starts at panel 1")
		_check(intro._photo.modulate.a > 0.9, "intro panel 1 visible")
		_check(intro._next_button.text == "走进农场", "intro button text")
		_check(not intro._next_button.visible, "intro button hidden before finish")
		_check(intro._caption_label.text.length() > 0, "intro caption filled")
		# 连点两下必须连翻两格，而不是被淡入动画吞掉。
		_click(intro, Vector2(540, 400))
		_click(intro, Vector2(540, 400))
		stage = 3
		stage_ms = t
		return

	if stage == 3 and t >= stage_ms + 300:
		_check(intro._index == 2, "two quick clicks advance to panel 3, got %d" % intro._index)
		_check(intro._photo.modulate.a > 0.9, "intro panel 3 fully shown")
		_click(intro, Vector2(540, 400))
		_click(intro, Vector2(540, 400))
		_click(intro, Vector2(540, 400))
		stage = 4
		stage_ms = t
		return

	if stage == 4 and t >= stage_ms + 300:
		_check(intro._index == 5, "clicked through to panel 6, got %d" % intro._index)
		_check(intro._photo.modulate.a > 0.9, "intro panel 6 fully shown")
		_check(intro._next_button.visible, "intro final button visible")
		_check(not intro._hint_label.visible, "intro hint hidden")
		var filled = 0
		for ch in intro._dots_label.text:
			if ch == "●":
				filled += 1
		_check(filled == 6, "intro progress dots filled, got %d" % filled)
		if problems.empty():
			print("GUIDE CHECK OK")
		else:
			for p in problems:
				print("GUIDE CHECK FAIL: " + p)
		quit()
