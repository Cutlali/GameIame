extends SceneTree

# 手记与序章的结构冒烟检查。用真实时间等待补间，避免无头运行帧率过高。

var problems = []
var guide = null
var intro = null
var start_ms = 0
var stage = 0


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
		_check(guide.CHAPTERS.size() == 10, "notebook should have 10 pages")
		# 初始只显示：夹页、01-03、最后一页。
		_check(_visible_buttons(toc) == 5, "only 5 pages visible at start, got %d"
			% _visible_buttons(toc))

		var body = guide.get_node("Root/Book/Margin/VBox/Body/Scroll/Content/ChapterBody")
		var title = guide.get_node("Root/Book/Margin/VBox/Body/Scroll/Content/ChapterTitle")
		var note_box = guide.get_node("Root/Book/Margin/VBox/Body/Scroll/Content/Note")
		_check(body.text.length() > 45, "chapter body text")
		_check(not note_box.visible, "side note box hidden, comments live in body")
		_check(body.text.find("最后一个") >= 0, "front page text")
		_check(title.text == "夹在最前面的一页", "front page title")

		# 锁定页不能被选中。
		guide.select_chapter(7)
		_check(title.text == "夹在最前面的一页", "locked chapter must not open")

		# 解锁季节页。
		flags.guide_season_changed = true
		guide._refresh_toc()
		_check(_visible_buttons(toc) == 6, "season page visible after unlock")
		guide.select_chapter(4)
		_check(title.text == "04  第三页 · 四季会轮转", "season chapter title")
		_check(body.text.find("春天浇水") >= 0, "season page body")
		_check(body.text.find("批注：") >= 0, "comments included in body")

		# 解锁虫害页。
		flags.guide_pest_seen = true
		guide._refresh_toc()
		guide.select_chapter(6)
		_check(title.text == "06  第五页 · 瓶子里的虫", "pest chapter title")
		_check(body.text.find("虫子杀不完") >= 0, "pest page comments")

		# 最后一页三段式文本。
		var enc = get_root().get_node("Encyclopedia")
		var old_entries = enc.discovered
		guide.select_chapter(9)
		_check(title.text == "09  最后一页 · 瓶子里的世界", "last chapter title")
		_check(body.text.find("阶段一") >= 0, "last chapter stage 1 at 0 entries")
		_check(body.text.find("雾气") >= 0, "last chapter locked at 0 entries")

		enc.discovered = {"a": true, "b": true, "c": true, "d": true}
		guide.select_chapter(9)
		_check(body.text.find("阶段二") >= 0, "last chapter stage 2 at 4 entries")
		_check(body.text.find("直觉告诉我") >= 0, "last chapter mid reveal at 4")

		enc.discovered = {"a": true, "b": true, "c": true, "d": true,
			"e": true, "f": true, "g": true, "h": true}
		guide.select_chapter(9)
		_check(body.text.find("阶段三") >= 0, "last chapter stage 3 at 8 entries")
		_check(body.text.find("我是魔瓶的创造者") >= 0, "last chapter full reveal at 8")
		enc.discovered = old_entries

		# 解锁全部页面后，目录里有 10 页。
		flags.guide_variant_seen = true
		flags.guide_bottle_damaged = true
		flags.guide_milestone_seen = true
		guide._refresh_toc()
		_check(_visible_buttons(toc) == 10, "all pages visible after all unlocks")

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
		return

	if stage == 3 and t >= 700:
		_check(intro._index == 2, "two quick clicks advance to panel 3, got %d" % intro._index)
		_check(intro._photo.modulate.a > 0.9, "intro panel 3 fully shown")
		_click(intro, Vector2(540, 400))
		_click(intro, Vector2(540, 400))
		_click(intro, Vector2(540, 400))
		stage = 4
		return

	if stage == 4 and t >= 1000:
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
