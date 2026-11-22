extends SceneTree

# 只做脚本加载检查，确保改动过的脚本没有解析错误。

func _init():
	var paths = [
		"res://GS.gd",
		"res://GameData.gd",
		"res://plants/Plant.gd",
		"res://bugs/Bug.gd",
		"res://HarvestManager.gd",
		"res://BottleManager.gd",
		"res://cursor/Cursor.gd",
		"res://cards/HandCard.gd",
		"res://cards/CardBase.gd",
		"res://ui/EncyclopediaUI.gd",
		"res://ui/YearSummary.gd",
		"res://SeasonManager.gd",
		"res://ui/MainMenu.gd",
		"res://Intro.gd",
		"res://tutorial/Tutorial.gd",
		"res://ui/PauseMenu.gd",
		"res://ui/GuideBook.gd"
	]
	var failures = 0
	for p in paths:
		var s = load(p)
		if s == null:
			print("PARSE FAIL: " + p)
			failures += 1
		else:
			print("PARSE OK: " + p)
	print("PARSE CHECK DONE failures=%d" % failures)
	quit()