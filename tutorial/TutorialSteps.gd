extends Node

# 教程的事件总线。Cursor / GS 在完成动作时调用这里，由 Tutorial 决定要不要推进阶段。

var marked_step = 0
var tutorial = null
var need_end_turn_button = false


func reset_all_state():
	marked_step = 0
	tutorial = null
	need_end_turn_button = false


func should_display_end_turn():
	return need_end_turn_button


func _notify(event_name):
	if is_instance_valid(tutorial):
		tutorial.on_event(event_name)


func mark_have_planted():
	marked_step = max(marked_step, 1)
	_notify("planted")


func mark_have_watered():
	marked_step = max(marked_step, 2)
	_notify("watered")


func mark_have_defended():
	marked_step = max(marked_step, 3)


func mark_have_ended_turn():
	marked_step = max(marked_step, 4)
	_notify("ended_turn")


func mark_have_attacked():
	marked_step = max(marked_step, 5)
	_notify("attacked")
