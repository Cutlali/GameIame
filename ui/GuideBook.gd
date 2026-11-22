extends CanvasLayer

# 《四季图鉴指南》
# 一本随时可以翻开的书：左边目录，右边章节正文。
# 新手教程只讲最基础的一步；世界观与详细机制都收在这里。
# 页边的「旧园丁批注」会随图鉴收录条数逐条解锁。

const CHAPTERS = [
	{
		"title": "序章 · 魔瓶与图鉴",
		"body": "在乡下，你得到了一座荒废已久的农场。整理旧物时，你在石头下发现了两样东西：一只蒙尘的魔瓶，和一本空白的图鉴。\n\n魔瓶里藏着一座微小的世界。据说，那是某个已经消失的世界留下的最后一片土壤——那里所有的植物，都被虫子吃尽了。\n\n有人赶在最后一刻，把仅剩的种子封进瓶里；图鉴则记下了这些种子，也记下了前一位园丁的经验。\n\n你种下的每一株植物，都会在瓶中生根。每收录一条，魔瓶的力量就苏醒一分。",
		"note": "瓶子不是留给我的，是留给下一个还能种下去的人。",
		"note_unlock": 0
	},
	{
		"title": "四季的轮转",
		"body": "魔瓶以自身的力量维持着瓶中的四季。一年有 24 轮，每季 6 轮，春夏秋冬依次轮转。四季不只是风景——瓶中的生机靠它积攒，瓶中的虫子也靠它压制。\n\n春：瓶中生机最盛。每次浇水会推进 2 个生长帧，植物成熟得更快。\n\n夏：虫害频繁，但植物也更容易发生变异。变异会形成独立的图鉴条目。\n\n秋：收获时，魔瓶会给出四张候选牌，你可以从中选两张。\n\n冬：魔瓶会给出五张候选牌，只能选一张，但可以刷新一次候选。\n\n冬去春来，年份继续。四季不会停，除非魔瓶碎裂。",
		"note": "春天最像从前。我总在春天骗自己，一切还来得及。",
		"note_unlock": 2
	},
	{
		"title": "耕作基础",
		"body": "农场上的每一件事，都要通过卡牌完成。\n\n选中手牌，把它拖到农场上：种子牌落在翻好的土地上；水滴牌为植物补水；防护牌替植物挡下伤害。\n\n每株植物都有生命、水分与免疫三项属性，上限都是 10。每次回合结束时，水分会减少；水分耗尽，植物就会受伤。免疫则会在你的回合开始时减少 1 点。\n\n植物成熟后，你可以把它收录进图鉴，或交给魔瓶，换取一次抽取卡牌的机会。已经收录过的植物再次收获时，魔瓶会自动开始抽取。",
		"note": "先让一株植物活过一季，再谈别的。",
		"note_unlock": 0
	},
	{
		"title": "卡牌与能量",
		"body": "屏幕底部的卡牌就是你的手牌。滚动鼠标滚轮，可以左右翻看。\n\n每张牌右上角标着它的能量消耗；左下角的能量球显示本回合剩余的能量。能量不足时，这张牌无法打出。\n\n结束回合后，用过的牌会进入弃牌堆。抽牌堆耗尽时，弃牌堆会重新洗回抽牌堆。所以不必害怕用牌，但要算好这一回合的力气。",
		"note": "力气要用在活着的东西上。",
		"note_unlock": 3
	},
	{
		"title": "虫害与守护",
		"body": "瓶中的小世界并不安宁。那些虫子，从一开始就跟着种子一起被封了进来。\n\n你耕作得越久，瓶中的生机越盛，虫子就越早被唤醒。它们不是从外面来的——它们一直就在瓶子里，等着植物重新长起来。\n\n虫子会在回合结束时攻击植物。给植物附加免疫，1 点免疫就能替它挡下 1 点伤害；防护网与其他守护牌都能做到这一点。\n\n有些虫子会直接啃咬魔瓶；有些精英虫外壳坚硬、咬得更重。虫子杀不完，只能守住这一季。",
		"note": "我试过停手，虫子就安静。可停手，瓶子也会慢慢死去。",
		"note_unlock": 2
	},
	{
		"title": "魔瓶的损伤",
		"body": "植物与魔瓶命运相连。植物被虫子杀死时，魔瓶会失去 1 滴血，最多只有 3 滴。那不是普通的伤——是虫子在啃食瓶壁。\n\n当最后一滴血耗尽，虫灾就到了无法挽回的地步，四季会停滞。但这正是魔瓶最后的保险：它会连同虫群一起重置，退回第一年的春天。\n\n图鉴与已经开垦的农田都会保留下来。魔瓶会自行修复，而你已经种过、见过的东西，仍留在图鉴里。\n\n这道重启机制，是最后一位园丁在临终前加进去的。他没等到瓶子复原，但他给后来的人留下了重来一次的机会。\n\n瓶塞与修补类的卡牌，可以为你争取更多容错。",
		"note": "我把最后一滴力气，用来刻下重启的纹路。别谢我，继续种。",
		"note_unlock": 3
	},
	{
		"title": "图鉴与成长",
		"body": "图鉴记录的是你真正种出过的植物。它不会因为魔瓶碎裂而清空。\n\n图鉴不只是账本。它每完整一分，魔瓶就找回一分被虫子夺走的力量；当所有植物都被重新收录，魔瓶就能恢复完整，把瓶中的虫子彻底清除。\n\n收录得越多，魔瓶能给你的也越多：\n\n· 基础植物收录到 2 种时，能量上限 +1。\n· 基础植物收录到 3 种时，每回合多抽 1 张牌。\n· 基础植物收录到 4 种时，可以开垦一块新农田，并获得每轮抽牌 +1、能量上限 +1。\n· 累计收录 8 条图鉴时，可以再开垦一块新农田，并再次获得同样的成长。\n\n变异植物会形成独立的图鉴条目。把植物交给魔瓶，不会让这个条目永久错过——下次再种出来，仍然可以收录。",
		"note": "图鉴不是纪念册，是钥匙。把它填满。",
		"note_unlock": 4
	},
	{
		"title": "魔瓶的真相",
		"unlock": 8,
		"mid_unlock": 4,
		"locked_body": "这一页被一层薄薄的雾气盖住了。你只能辨认出一行字：\n\n“继续种下去。等图鉴足够厚，瓶子会自己开口。”\n\n（当前收录 %d 条。收录 4 条后，雾气会散开一些。）",
		"mid_body": "图鉴厚了一些，雾气散开了几行：\n\n魔瓶里的世界，曾经也是一个真正的世界。虫子先吃光了那里的植物，又啃穿了大地。最后一个人把仅剩的种子封进瓶里，也把虫子一起封了进去。\n\n他试过种回去。可生机越盛，虫子醒得越快。他没能等到图鉴填满的那一天。\n\n还有半页被撕掉了。剩下的字迹要等图鉴再厚一些才会显形。\n\n（当前收录 %d 条。收录 8 条后，这一页会完整显露。）",
		"body": "图鉴终于接近完整，最后一页的字迹也清晰了：\n\n那个世界是被虫子吃空的。最后一位园丁把仅剩的种子封进魔瓶，却没能把虫子挡在外面。他试过一次又一次——生机越盛，虫灾越重。最后，他在临终前给魔瓶刻下了重启的纹路：只要虫灾到了无法挽回的地步，魔瓶就会连同虫群一起重置。\n\n他没能走完的路，留给了你。\n\n图鉴不是纪念册，而是魔瓶的钥匙。把每一种植物都重新种出来、收录进去，魔瓶就能恢复完整的力量，把瓶中的虫子彻底清除。\n\n你不是第一个拿起这个瓶子的人。但也许，你会是最后一个。",
		"note": "你不是第一个拿起这个瓶子的人。但也许，你会是最后一个。",
		"note_unlock": 8
	}
]

var _current = 0
var _toc_buttons = []
var _last_focus = null

onready var _title_label = $Root/Book/Margin/VBox/Body/Scroll/Content/ChapterTitle
onready var _body_label = $Root/Book/Margin/VBox/Body/Scroll/Content/ChapterBody
onready var _note_box = $Root/Book/Margin/VBox/Body/Scroll/Content/Note
onready var _note_label = $Root/Book/Margin/VBox/Body/Scroll/Content/Note/NoteBody
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


func _entry_count():
	if has_node("/root/Encyclopedia"):
		return get_node("/root/Encyclopedia").discovered_count()
	return 0


func _chapter_body(index):
	var chapter = CHAPTERS[index]
	if not chapter.has("unlock"):
		return chapter["body"]
	var count = _entry_count()
	if count >= chapter["unlock"]:
		return chapter["body"]
	if count >= chapter["mid_unlock"]:
		return chapter["mid_body"] % count
	return chapter["locked_body"] % count


func _chapter_note(index):
	var chapter = CHAPTERS[index]
	if not chapter.has("note"):
		return ""
	if _entry_count() >= chapter["note_unlock"]:
		return chapter["note"]
	return "页边有几行褪色的字迹，还看不清。"


func select_chapter(index):
	if index < 0 or index >= CHAPTERS.size():
		return
	_current = index
	_title_label.text = CHAPTERS[index]["title"]
	_body_label.text = _chapter_body(index)
	var note = _chapter_note(index)
	_note_box.visible = note != ""
	_note_label.text = note
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