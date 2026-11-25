extends Node

signal guide_page_unlocked(index, title)

var skip_tutorial = false
var hard_mode = false

# 瓶中手记的解锁标记。瓶碎重开后保留，新开一局时清空。
var guide_season_changed = false
var guide_variant_seen = false
var guide_pest_seen = false
var guide_bottle_damaged = false
var guide_milestone_seen = false
var guide_bottle_shattered = false


func reset_guide_unlocks():
	guide_season_changed = false
	guide_variant_seen = false
	guide_pest_seen = false
	guide_bottle_damaged = false
	guide_milestone_seen = false
	guide_bottle_shattered = false


# 第一次触发某页时点亮手记，并通知 HUD 弹一条“手记更新”的提示。
func unlock_guide(flag, index, title):
	if get(flag):
		return
	set(flag, true)
	emit_signal("guide_page_unlocked", index, title)
	# SaveGame 排在 autoload 末尾，解析期不能直引，运行时取节点。
	var sv = get_node_or_null("/root/SaveGame")
	if sv != null:
		sv.save_now()
