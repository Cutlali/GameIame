extends CanvasLayer

# v1.8 开垦名额制：图鉴里程碑只负责发名额，不再弹"选方位"窗口。
# 有名额时右下角出现"开垦农田"按钮，点击进入放置模式：
# 光标处有 2×2 虚影（绿=可垦，红=不行），左键落铲、右键或 Esc 退出。
# 地块合法性与铺砖在 TheTileMap（claim_plot），这里只管按钮与提示。

var _root: Control
var _farm_button: Button
var _hint: Label


func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	layer = 122
	_build_ui()


func _build_ui():
	_root = Control.new()
	_root.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# 按钮放在"整理手牌"左侧同一高度带，避开手牌扇形区。
	_farm_button = Button.new()
	_farm_button.text = "开垦农田"
	_farm_button.anchor_left = 1.0
	_farm_button.anchor_top = 1.0
	_farm_button.anchor_right = 1.0
	_farm_button.anchor_bottom = 1.0
	_farm_button.margin_left = -326.0
	_farm_button.margin_top = -152.0
	_farm_button.margin_right = -186.0
	_farm_button.margin_bottom = -114.0
	var font = DynamicFont.new()
	font.font_data = load("res://fonts/SimHei.ttf")
	font.size = 15
	_farm_button.add_font_override("font", font)
	_farm_button.focus_mode = Control.FOCUS_NONE
	_farm_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_farm_button.connect("pressed", self, "_on_start_pressed")
	_farm_button.visible = false
	_root.add_child(_farm_button)

	_hint = Label.new()
	_hint.anchor_left = 0.5
	_hint.anchor_right = 0.5
	_hint.margin_left = -360.0
	_hint.margin_right = 360.0
	_hint.margin_top = 14.0
	_hint.margin_bottom = 50.0
	_hint.align = Label.ALIGN_CENTER
	_hint.valign = Label.VALIGN_CENTER
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hf = DynamicFont.new()
	hf.font_data = load("res://fonts/SimHei.ttf")
	hf.size = 17
	hf.outline_size = 4
	hf.outline_color = Color(0.10, 0.12, 0.10, 0.9)
	_hint.add_font_override("font", hf)
	_hint.add_color_override("font_color", Color(0.92, 0.98, 0.90))
	_hint.visible = false
	_root.add_child(_hint)


func _process(_delta):
	var idle = not GS.tutorial \
			and GS.tilemap != null and is_instance_valid(GS.tilemap) \
			and GS.turn_state == GS.TurnState.PLAYING_CARDS \
			and not get_tree().paused \
			and not GS.bottle_open and not GS.bestiary_open \
			and not GS.harvest_open and not GS.year_summary_open \
			and not GS.shatter_open and not GS.hand_keep_open
	_farm_button.visible = idle and GS.farm_quota > 0 and not GS.farm_choice_open
	_farm_button.text = "开垦农田 ×%d" % GS.farm_quota

	_hint.visible = GS.farm_choice_open
	if GS.farm_choice_open:
		_hint.text = "开垦模式：左键在光标处落 2×2（绿框可垦）· 右键 / Esc 退出 · 剩余名额 %d" \
			% GS.farm_quota


func _on_start_pressed():
	SFX.button_click.play_sfx()
	start_placement()


func start_placement():
	if GS.farm_quota <= 0:
		return
	if GS.tilemap == null or not is_instance_valid(GS.tilemap):
		return
	GS.farm_choice_open = true
	GS.tilemap.enter_plot_mode()


func end_placement():
	GS.farm_choice_open = false
	if GS.tilemap != null and is_instance_valid(GS.tilemap):
		GS.tilemap.exit_plot_mode()


func reset_all():
	end_placement()
