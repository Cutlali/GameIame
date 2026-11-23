extends SceneTree

# 开发工具：暂停状态下音效是否仍能播放（手记章节按钮点击音）。

var frames = 0
var started = false
var failures = []
var guide = null
var sfx = null


func _idle(_delta):
	frames += 1
	if not started:
		if frames < 3:
			return
		started = true
		sfx = get_root().get_node("SFX")
		if sfx.pause_mode != Node.PAUSE_MODE_PROCESS:
			failures.append("SFX root is not PAUSE_MODE_PROCESS")
		guide = load("res://ui/GuideBook.tscn").instance()
		get_root().add_child(guide)
		return

	if frames == 6:
		guide.open(true)
		if not paused:
			failures.append("guide did not pause the tree")
		guide._on_chapter_pressed(0)
		if not sfx.button_click.playing:
			failures.append("chapter click sfx did not play while paused")
		print("paused=%s click_playing=%s" % [str(paused), str(sfx.button_click.playing)])
		paused = false
		if failures.empty():
			print("SFX PAUSE CHECK OK")
		else:
			for f in failures:
				print("SFX PAUSE CHECK FAIL: " + f)
		quit()
