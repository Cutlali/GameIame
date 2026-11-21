extends CanvasLayer

# 右下角轻量提示条。所有系统共用，避免每个 UI 各自造一套。

const LIFETIME = 3.2
const MAX_ITEMS = 5

var _box: VBoxContainer


func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	layer = 119

	_box = VBoxContainer.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.alignment = BoxContainer.ALIGN_END
	_box.anchor_left = 1.0
	_box.anchor_top = 1.0
	_box.anchor_right = 1.0
	_box.anchor_bottom = 1.0
	_box.margin_left = -680.0
	_box.margin_top = -300.0
	_box.margin_right = -24.0
	_box.margin_bottom = -120.0
	add_child(_box)


func _process(_delta):
	# 全屏面板打开时让位，避免压住按钮或说明文字。
	if _box == null:
		return
	_box.visible = not (GS.bottle_open or GS.harvest_open or GS.bestiary_open \
		or GS.year_summary_open or GS.farm_choice_open or GS.shatter_open)


func show_message(text):
	if _box == null or text == "":
		return

	while _box.get_child_count() >= MAX_ITEMS:
		var old = _box.get_child(0)
		_box.remove_child(old)
		old.queue_free()

	var label = Label.new()
	label.text = text
	label.align = Label.ALIGN_RIGHT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap = true

	var font = DynamicFont.new()
	font.font_data = load("res://fonts/SimHei.ttf")
	font.size = 20
	label.add_font_override("font", font)
	label.add_color_override("font_color", Color(1, 1, 1, 1))
	label.add_color_override("font_color_shadow", Color(0, 0, 0, 0.9))
	label.add_constant_override("shadow_offset_x", 2)
	label.add_constant_override("shadow_offset_y", 2)

	_box.add_child(label)

	var timer = get_tree().create_timer(LIFETIME)
	timer.connect("timeout", self, "_remove_label", [label])


func _remove_label(label):
	if label == null or not is_instance_valid(label):
		return
	if label.get_parent() == _box:
		_box.remove_child(label)
	label.queue_free()


func clear():
	if _box == null:
		return
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()