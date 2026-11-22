extends CanvasLayer

# 《四季图鉴指南》
# 一本随时可以翻开的书：左边目录，右边章节正文。
# 新手教程只讲最基础的一步；世界观与详细机制都收在这里。

const CHAPTERS = [
	{
		"title": "序章 · 魔瓶与图鉴",
		"body": "在乡下，你得到了一座荒废已久的农场。整理旧物时，你在石头下发现了两样东西：一只蒙尘的魔瓶，和一本空白的图鉴。\n\n魔瓶里藏着一座微小的世界。你种下的每一株植物，都会在这座小世界里生根、生长；而图鉴，会记下你亲手种出的每一种植物。\n\n图鉴并非摆设。每多收录一条，魔瓶的力量就苏醒一分——你能携带的能量、每回合能抽到的牌，都会随之增长。\n\n至于魔瓶从何而来、又为何选择你，图鉴的最后一页似乎藏着答案。"
	},
	{
		"title": "四季的轮转",
		"body": "魔瓶以自身的力量维持着瓶中的四季。一年有 24 轮，每季 6 轮，春夏秋冬依次轮转。\n\n春：瓶中生机最盛。每次浇水会推进 2 个生长帧，植物成熟得更快。\n\n夏：虫害频繁，但植物也更容易发生变异。变异会形成独立的图鉴条目。\n\n秋：收获时，魔瓶会给出四张候选牌，你可以从中选两张。\n\n冬：魔瓶会给出五张候选牌，只能选一张，但可以刷新一次候选。\n\n冬去春来，年份继续。四季不会停，除非魔瓶碎裂。"
	},
	{
		"title": "耕作基础",
		"body": "农场上的每一件事，都要通过卡牌完成。\n\n选中手牌，把它拖到农场上：种子牌落在翻好的土地上；水滴牌为植物补水；防护牌替植物挡下伤害。\n\n每株植物都有生命、水分与免疫三项属性，上限都是 10。每次回合结束时，水分会减少；水分耗尽，植物就会受伤。免疫则会在你的回合开始时减少 1 点。\n\n植物成熟后，你可以把它收录进图鉴，或交给魔瓶，换取一次抽取卡牌的机会。已经收录过的植物再次收获时，魔瓶会自动开始抽取。"
	},
	{
		"title": "卡牌与能量",
		"body": "屏幕底部的卡牌就是你的手牌。滚动鼠标滚轮，可以左右翻看。\n\n每张牌右上角标着它的能量消耗；左下角的能量球显示本回合剩余的能量。能量不足时，这张牌无法打出。\n\n结束回合后，用过的牌会进入弃牌堆。抽牌堆耗尽时，弃牌堆会重新洗回抽牌堆。所以不必害怕用牌，但要算好这一回合的力气。"
	},
	{
		"title": "虫害与守护",
		"body": "瓶中的小世界并不安宁。你耕作得越久，越会惊动藏在暗处的虫子。\n\n虫子会在回合结束时攻击植物。给植物附加免疫，1 点免疫就能替它挡下 1 点伤害；防护网与其他守护牌都能做到这一点。\n\n有些虫子会直接啃咬魔瓶；有些精英虫外壳坚硬、咬得更重。留意局面，别让一株植物独自承受所有攻击。"
	},
	{
		"title": "魔瓶的损伤",
		"body": "植物与魔瓶命运相连。植物被虫子杀死时，魔瓶会失去 1 滴血，最多只有 3 滴。\n\n当最后一滴血耗尽，四季会停滞，这一次耕作只能结束。但你不会失去一切：图鉴与已经开垦的农田都会保留下来。\n\n魔瓶会自行修复。带着图鉴重新开始后，你会回到第一年的春天，而已经见过、种过的东西，仍然留在图鉴里。\n\n瓶塞与修补类的卡牌，可以为你争取更多容错。"
	},
	{
		"title": "图鉴与成长",
		"body": "图鉴记录的是你真正种出过的植物。它不会因为魔瓶碎裂而清空。\n\n收录得越多，魔瓶能给你的也越多：\n\n· 基础植物收录到 2 种时，能量上限 +1。\n· 基础植物收录到 3 种时，每回合多抽 1 张牌。\n· 基础植物收录到 4 种时，可以开垦一块新农田，并获得每轮抽牌 +1、能量上限 +1。\n· 累计收录 8 条图鉴时，可以再开垦一块新农田，并再次获得同样的成长。\n\n变异植物会形成独立的图鉴条目。把植物交给魔瓶，不会让这个条目永久错过——下次再种出来，仍然可以收录。"
	},
	{
		"title": "魔瓶的真相",
		"unlock": 8,
		"mid_unlock": 4,
		"locked_body": "这一页被一层薄薄的雾气盖住了。你只能辨认出一行字：\n\n“继续种下去。等图鉴足够厚，瓶子会自己开口。”\n\n（当前收录 %d 条。收录 4 条后，雾气会散开一些。）",
		"mid_body": "图鉴厚了一些，雾气也散开了几行：\n\n魔瓶并不是一件农具。它更像一座被折叠起来的世界，而图鉴是它的钥匙。每填满一页，锁就松动一分。\n\n还有半页被撕掉了。剩下的字迹要等图鉴再厚一些才会显形。\n\n（当前收录 %d 条。收录 8 条后，这一页会完整显露。）",
		"body": "图鉴接近完整时，你发现了一些不该出现在农场里的记录：没有名字的植物、倒着生长的根，以及一页被撕掉的四季图。\n\n魔瓶并不是一件农具。它更像一座被折叠起来的世界，而图鉴是它的钥匙。每一页被填满，锁就松动一分。\n\n有人说，最后一页写的是魔瓶的来处；也有人说，写的是打开它的人。\n\n继续种下去吧。答案不会自己长出来。"
	}
]

var _current = 0
var _toc_buttons = []
var _last_focus = null

onready var _title_label = $Root/Book/Margin/VBox/Body/Scroll/Content/ChapterTitle
onready var _body_label = $Root/Book/Margin/VBox/Body/Scroll/Content/ChapterBody
onready var _scroll = $Root/Book/Margin/VBox/Body/Scroll
onready var _toc = $Root/Book/Margin/VBox/Body/Toc
onready var _close_button = $Root/Book/Margin/VBox/Header/Close


func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	visible = false
	_build_toc()
	_close_button.connect("pressed", self, "close")
	select_chapter(0)


func _font(size):
	var f = DynamicFont.new()
	f.font_data = load("res://fonts/SimHei.ttf")
	f.size = size
	return f


func _build_toc():
	var group = ButtonGroup.new()
	for i in range(CHAPTERS.size()):
		var b = Button.new()
		b.text = "%02d  %s" % [i + 1, CHAPTERS[i]["title"]]
		b.align = Button.ALIGN_LEFT
		b.toggle_mode = true
		b.group = group
		b.rect_min_size = Vector2(0, 40)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_font_override("font", _font(16))
		b.add_color_override("font_color", Color(0.30, 0.19, 0.12))
		b.add_color_override("font_color_hover", Color(0.20, 0.11, 0.06))
		b.add_color_override("font_color_pressed", Color(0.20, 0.11, 0.06))
		b.add_color_override("font_color_focus", Color(0.30, 0.19, 0.12))
		b.connect("pressed", self, "_on_chapter_pressed", [i])
		_toc.add_child(b)
		_toc_buttons.append(b)


func _chapter_body(index):
	var chapter = CHAPTERS[index]
	if not chapter.has("unlock"):
		return chapter["body"]
	var count = 0
	if has_node("/root/Encyclopedia"):
		count = get_node("/root/Encyclopedia").discovered_count()
	if count >= chapter["unlock"]:
		return chapter["body"]
	if count >= chapter["mid_unlock"]:
		return chapter["mid_body"] % count
	return chapter["locked_body"] % count


func select_chapter(index):
	if index < 0 or index >= CHAPTERS.size():
		return
	_current = index
	_title_label.text = CHAPTERS[index]["title"]
	_body_label.text = _chapter_body(index)
	if index < _toc_buttons.size():
		_toc_buttons[index].pressed = true
	_scroll.scroll_vertical = 0


func open():
	_last_focus = $Root.get_focus_owner()
	visible = true
	select_chapter(_current)
	_close_button.grab_focus()


func close():
	visible = false
	if _last_focus != null and is_instance_valid(_last_focus):
		_last_focus.grab_focus()


func _on_chapter_pressed(index):
	select_chapter(index)


func _unhandled_input(event):
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_tree().set_input_as_handled()
