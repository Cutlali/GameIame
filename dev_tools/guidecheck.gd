extends SceneTree

# 指南与序章的结构冒烟检查。用真实时间等待补间，避免无头运行帧率过高。

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


func _idle(_delta):
	var t = OS.get_ticks_msec() - start_ms

	if stage == 0 and t >= 60:
		guide = load("res://ui/GuideBook.tscn").instance()
		get_root().add_child(guide)
		stage = 1
		return

	if stage == 1 and t >= 220:
		guide.open()
		_check(guide.visible, "guide visible")
		var toc = guide.get_node("Root/Book/Margin/VBox/Body/Toc")
		var buttons = 0
		for c in toc.get_children():
			if c is Button:
				buttons += 1
		_check(buttons == guide.CHAPTERS.size(), "chapter buttons %d" % buttons)
		var body = guide.get_node("Root/Book/Margin/VBox/Body/Scroll/Content/ChapterBody")
		var title = guide.get_node("Root/Book/Margin/VBox/Body/Scroll/Content/ChapterTitle")
		var note_box = guide.get_node("Root/Book/Margin/VBox/Body/Scroll/Content/Note")
		var note_label = guide.get_node("Root/Book/Margin/VBox/Body/Scroll/Content/Note/NoteBody")
		_check(body.text.length() > 45, "chapter body text")
		_check(note_box.visible, "first gardener note visible")
		_check(note_label.text.find("下一个") >= 0, "first gardener note text")
		guide.select_chapter(7)
		_check(title.text == "魔瓶的真相", "last chapter title")
		_check(body.text.find("雾气") >= 0, "last chapter locked at 0 entries")
		var enc = get_root().get_node("Encyclopedia")
		var old_entries = enc.discovered
		enc.discovered = {"a": true, "b": true, "c": true, "d": true}
		guide.select_chapter(7)
		_check(body.text.find("半页被撕掉") >= 0, "last chapter mid reveal at 4")
		_check(note_label.text.find("还看不清") >= 0, "last note locked at 4")
		guide.select_chapter(6)
		_check(note_label.text.find("填满") >= 0, "growth note unlocked at 4")
		enc.discovered = {"a": true, "b": true, "c": true, "d": true,
			"e": true, "f": true, "g": true, "h": true}
		guide.select_chapter(7)
		_check(body.text.find("最后一页") >= 0, "last chapter full reveal at 8")
		_check(note_label.text.find("最后一个") >= 0, "last note unlocked at 8")
		enc.discovered = old_entries
		guide.select_chapter(0)
		_check(note_box.visible and note_label.text.find("下一个") >= 0, "note restored with entries")
		guide.select_chapter(4)
		_check(body.text.find("一直就在瓶子里") >= 0, "bug origin lore")
		guide.select_chapter(1)
		_check(body.text.find("春：") >= 0, "season chapter body")
		_check(title.text == "四季的轮转", "season chapter title")
		guide.close()
		_check(not guide.visible, "guide closes")
		guide.queue_free()
		intro = load("res://Intro.tscn").instance()
		get_root().add_child(intro)
		stage = 2
		return

	if stage == 2 and t >= 400:
		var l1 = intro.get_node("Panel/Margin/VBox/Body/L1")
		var l2 = intro.get_node("Panel/Margin/VBox/Body/L2")
		var btn = intro.get_node("Panel/Margin/VBox/Button")
		_check(l1.modulate.a > 0.9, "intro L1 visible")
		_check(l2.modulate.a < 0.1, "intro L2 hidden")
		_check(btn.text == "继续", "intro button text")
		_check(intro.get_node("Panel").rect_size.x >= 860, "intro panel width")
		intro.call("_advance")
		stage = 3
		return

	if stage == 3 and t >= 1100:
		_check(intro.get_node("Panel/Margin/VBox/Body/L2").modulate.a > 0.9, "intro L2 revealed")
		intro.call("_advance")
		stage = 4
		return

	if stage == 4 and t >= 1800:
		_check(intro.get_node("Panel/Margin/VBox/Body/L3").modulate.a > 0.9, "intro L3 revealed")
		intro.call("_advance")
		stage = 5
		return

	if stage == 5 and t >= 2500:
		_check(intro.get_node("Panel/Margin/VBox/Body/L4").modulate.a > 0.9, "intro L4 revealed")
		_check(intro.get_node("Panel/Margin/VBox/Button").text == "走进农场", "intro final button")
		_check(not intro.get_node("Panel/Margin/VBox/Hint").visible, "intro hint hidden")
		if problems.empty():
			print("GUIDE CHECK OK")
		else:
			for p in problems:
				print("GUIDE CHECK FAIL: " + p)
		quit()
