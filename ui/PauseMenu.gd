extends CanvasLayer

func _ready():
	visible = get_tree().paused

func pause():
	get_tree().paused = true
	show()
	
func unpause():
	get_tree().paused = false
	hide()
	
func toggle_pause():
	if get_tree().paused:
		unpause()
	else:
		pause()

func _on_ResumeButton_pressed():
	unpause()

func _on_GuideButton_pressed():
	$GuideBook.open()

func _on_QuitButton_pressed():
	# 中途退出先给一份年度总结，再由玩家决定回主菜单。
	# 总结面板自己会冻结/恢复场景，这里不提前解除暂停。
	if Season.is_in_game():
		hide()
		YearSummary.show_summary(Season.year, true)
	else:
		unpause()
		SceneTransitions.change_scene_to(GS.MainMenu)
	
func _process(delta):
	# 指南打开时由书自己处理输入，避免 P 键把暂停菜单翻到书后面。
	if has_node("GuideBook") and $GuideBook.visible:
		return
	# 年度总结/开垦选择自己管理暂停，避免 P 键把冻结中的农场放出来。
	if GS.year_summary_open or GS.farm_choice_open or GS.shatter_open:
		return
	if Input.is_action_just_pressed("pause_button"):
		toggle_pause()
