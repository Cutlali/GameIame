extends Control

# 序章：用羊皮纸一页页展开魔瓶与图鉴的来历。
# 点击任意处或按回车继续；最后一段出现后，按钮带玩家进入农场。

var _labels = []
var _revealed = 1
var _fading = false


func _ready():
	_labels = [
		$Panel/Margin/VBox/Body/L1,
		$Panel/Margin/VBox/Body/L2,
		$Panel/Margin/VBox/Body/L3,
		$Panel/Margin/VBox/Body/L4
	]
	for i in range(_labels.size()):
		var alpha = 1.0 if i == 0 else 0.0
		_labels[i].modulate = Color(1, 1, 1, alpha)
	if Flags.skip_tutorial:
		_labels[3].text = "你把石头下的旧卷轴留在了原地，只带走了魔瓶与图鉴。它们比想象中更沉。"
	_update_footer()


func _unhandled_input(event):
	if event.is_action_pressed("mouse") or event.is_action_pressed("ui_accept"):
		_advance()


func _on_Button_pressed():
	_advance()


func _advance():
	if _fading:
		return
	if _revealed >= _labels.size():
		SceneTransitions.change_scene_to(GS.Game)
		return

	var label = _labels[_revealed]
	_revealed += 1
	_fading = true
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(label, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1),
		0.45, Tween.TRANS_SINE, Tween.EASE_OUT)
	tween.connect("tween_all_completed", self, "_on_fade_done")
	tween.start()
	_update_footer()


func _on_fade_done():
	_fading = false


func _update_footer():
	var done = _revealed >= _labels.size()
	$Panel/Margin/VBox/Button.text = "走进农场" if done else "继续"
	$Panel/Margin/VBox/Hint.visible = not done
