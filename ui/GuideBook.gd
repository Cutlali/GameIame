extends CanvasLayer

# 《瓶中手记》
# 上一个拿到魔瓶的人留下的笔记，最后一页由创造者写成。
# 页面正文与《四季魔瓶_指南完整文本_v1.5.2.docx》保持一致：
# 只保留手记正文与批注，不包含制作说明和灰色的解锁提示。

const CHAPTERS = [
	{
		"title": "夹在最前面的一页",
		"always": true,
		"body": "墨迹比其他页新，像是后来塞进去的。\n\n如果你翻开这本手记，说明瓶子选择了你。\n\n我不知道你是谁，也不知道你从哪里来。\n\n这本笔记，是我刚得到瓶子时写下的，应该能帮到你。我用某种方法把它和魔瓶关联在了一起——你使用魔瓶时，它会自己出现。可我没料到，笔记的内容也会跟着瓶中的变化走。等我发现这一点时，已经没时间了。\n\n剩下的页，只能靠你在探索魔瓶的过程中，一点点读全。\n\n你不是第一个拿起这个瓶子的人。但也许，你会是最后一个。"
	},
	{
		"title": "01  扉页 · 一只不该存在的瓶子",
		"always": true,
		"body": "一次偶然的机会，我得到了这个瓶子。\n\n它似乎有神奇的魔力——在瓶中可以种下作物，而作物成熟后会被图鉴收录。\n\n那些植物我从未见过。叶片的形状、花的颜色、甚至成熟时的气味，都不像是这个世界该有的东西。\n\n我试着种下第一颗种子，浇水，它真的活了。\n\n批注：\n· 种子要落在翻好的土地上。\n· 浇水可以使植物成长。"
	},
	{
		"title": "02  第一页 · 土里的规矩",
		"always": true,
		"body": "随着对魔瓶的探索，我渐渐发现每株植物好像都有共通点。\n\n所有的植物都需要浇水，倘若缺少水分，植物便会失去活力停止生长，魔瓶中也提供了储存水的水晶球，不同的植物似乎对缺水的耐受性不同，我试图记录这些植物的特性，慢慢地我发现了规律。\n\n影响植物活力的，我姑且称之为生命之源，每个植物都有生命之源，到目前为止，我尚且没有发现生命之源数超过7的植物。当水分耗尽时植物的生命之源便会流逝并停止生长，生命之源耗尽会怎么样我并未尝试，所以尚不清楚。\n\n此外，当植物成熟后，我发现图鉴中显现出了这株植物的样子，而植物消失了，看起来就像图鉴将这株植物吃掉了，而后当我再次种出相同的植物时，魔瓶将其吸收了，并给予了我一些特别的道具，这些道具拥有奇妙的力量，其中有一种似乎可以抵消对生命之源的消耗，即使植物缺少水分会停止生长，但在这种力量的保护下生命之源并不会流逝，不过在每次开始这种能量似乎会自行消散一部分，而有的道具甚至可以恢复生命之源...我试图给一株植物一直施加这些道具，但当到达一定限度时便不起作用了\n\n这个限度似乎是7？\n\n批注：\n· 植物的许多上限是 7。\n· 水分耗尽会消耗生命之源，能抵消生命之源损耗的力量会自行消散。\n· 魔瓶中的水晶球可以储存水\n· 未被图鉴收录的植物可以被收录图鉴，收录后会被魔瓶自动吸收，并换取道具。"
	},
	{
		"title": "03  第二页 · 瓶子里的魔力",
		"always": true,
		"body": "瓶子里的行为是消耗魔力的。\n\n在瓶中，大多数行为需要消耗魔力，而魔力似乎是有限的，这导致有些道具我还没来得及使用就被魔瓶收走了，真是不讲理的瓶子。但似乎随着培育魔力值会上升，还会有特殊道具可以短暂提升魔力值。\n\n批注：\n· 每个行为有魔力消耗，魔力不足无法使用对应道具甚至种植。\n· 回合结束多余道具会被魔瓶回收，有的道具可以短暂提升魔力值。\n· 第一年结束时，魔力值 +2"
	},
	{
		"title": "04  第三页 · 四季会轮转",
		"flag": "guide_season_changed",
		"body": "今天种植时发现，瓶中竟然有四季的轮转。\n\n一年有 24 轮，每季 6 轮，春夏秋冬依次轮转。四季不只是风景——不同的季节对于种植似乎有不同的影响，春天浇水会让植物快速生长。夏天的植物似乎总和别的季节不同。秋天收获时，魔瓶能让你挑选更多的道具，冬天有更多的道具候选，虽然只能选一次，但遇到不合适的道具貌似可以重置。\n\n批注：\n· 一年 24 轮，每季 6 轮。\n· 四个季节各有特色"
	},
	{
		"title": "05  第四页 · 变异的植物",
		"flag": "guide_variant_seen",
		"body": "今天收获时，我发现一株植物竟和往常所种植出的不一样。\n\n它的颜色、形状都和同种不一样。图鉴把它吸收了，并给了它一个单独的名字记成了独立的一条。\n\n我起初以为这是坏事。\n\n后来发现，在收获时这些变异的植物往往带着奇怪的本事：有的能护住旁边的植物，有的能让植物长得更加迅速，有的甚至能对瓶子产生影响。\n\n这种情况在夏季发生的频率尤为高，不知道它们为什么会有这样的变异，这瓶子还有多少我未曾了解的地方？\n\n批注：\n· 变异植物是独立图鉴条目。\n· 变异特性在收获时结算。"
	},
	{
		"title": "06  第五页 · 瓶子的力量",
		"always": true,
		"body": "随着我的种植，原先平静的瓶子似乎有了动静。\n\n收获瓶中的植物似乎可以给瓶子充能，随着植物的收获，瓶子的光渐渐强盛了起来，可是这有什么用呢？我暂时不知道。但感受着瓶中的力量，我能体会到浓郁的生机，似乎我可以将这些力量释放出来——我明白，这肯定会在关键时刻发挥作用。\n\n批注：\n· 收获成熟植物可以给魔瓶充能。\n· 充能满之后可以释放出来。"
	},
	{
		"title": "07  第六页 · 瓶子里的虫",
		"flag": "guide_pest_seen",
		"body": "今天，虫子出现了。\n\n不是从外面来的，是瓶子中的。\n\n随着我的耕种，瓶中生命的气息愈发强烈，但这种气息似乎吸引了这群不速之客。\n\n这些虫子会啃食我的植物！它们会让植物的生命之源快速流逝，但好在那种可以阻止生命之源流逝的力量也能阻挡虫子的攻击。我用的锄头赶走了它们，但它们总会卷土重来。魔瓶似乎料想到了这些虫群，给出的道具中有很多可以驱逐杀死这些虫子。\n\n虫子死后会加速我植株的生长，这倒是一个意外之喜。\n\n批注：\n· 虫子一直封在瓶里，生机越盛，醒得越快。\n· 虫子会在回合结束攻击植物。\n· 有的道具可以抵御虫子的进攻。"
	},
	{
		"title": "08  第七页 · 瓶壁上的裂纹",
		"flag": "guide_bottle_damaged",
		"body": "今天没注意，一株植物被虫群啃食殆尽了。随着植株的消失，魔瓶似乎也受到影响。\n\n我这才发现，植物和瓶子是连在一起的。植物被虫子杀死时，瓶子会因此产生裂纹。我不知道瓶子还能抵挡几次这样的伤害，但一定不会太多。\n\n我在瓶底发现了一圈很旧的纹路，不像是自然长出来的。我还没弄懂它是做什么的。也许，它会有很关键的作用。\n\n批注：\n· 植物死亡，魔瓶会受到损伤产生裂痕。\n· 瓶底有一圈不明纹路。"
	},
	{
		"title": "09  第八页 · 碎裂之后",
		"flag": "guide_bottle_shattered",
		"body": "瓶子碎了。\n\n碎片落进麦丛的那一刻，我以为一切都结束了。可过了一会儿，那些碎片忽然亮了起来，一块块飞回原处，沿着瓶底那圈旧纹路重新拼成了完整的瓶子。\n\n四季也跟着倒了回去，退回第一年的春天。虫群沉回瓶底，像什么都没发生过。\n\n图鉴、田地、已经解锁的种子都还在。只有这一页是新的——它在我翻开手记时，自己浮了出来。\n\n批注：\n· 瓶碎后四季退回第一年春天。\n· 图鉴、农田与已解锁的种子保留，瓶能清零。\n· 碎裂时，手记会多出一页。"
	},
	{
		"title": "10  第九页 · 图鉴的分量",
		"flag": "guide_milestone_seen",
		"body": "今天图鉴又厚了一点，瓶子竟然也跟着有了变化，比从前光芒更盛。\n\n我隐隐觉得，图鉴并非只是单纯的吸收植物。它每完整一分，瓶子就恢复部分力量。\n\n收录得越多，瓶子恢复的越多，或许我就能明白这瓶子的来历。\n\n批注：\n· 随着图鉴的解锁，瓶子也会随之发生变化。"
	},
	{
		"title": "11  最后一页 · 瓶子里的世界",
		"special": "final_page",
		"fog": "雾气很重，只有最后一行还露在外面。\n\n再收集七种以上的植物，这一页就会散开；集齐所有植物之后，还会有人留下话。",
		# 雾气下沿露出来的引子（阶段一）。
		"peek": "“这样的话，下一个得到瓶子的人，或许能让这场灾难迎来终结....”",
		# 阶段二：收录 7 种以上植物后散开的部分（上一位拥有者的手记）。
		"stage2": "图鉴厚了一些，雾气散开了几行：\n\n不知为何，在我所处的世界也渐渐发现了这种虫子。我并不认为这是一个好的预兆。瓶中的虫子有极强的破坏力，除了这些奇妙的植物，几乎没有其他办法可以抵抗。\n\n收录到图鉴中的植物似乎可以取出种子。我将种子取出，在我的世界开始种植。\n\n直觉告诉我，一场灾难要来了。\n\n但等我明白这一点时，已经没时间了。大规模的虫群迅速席卷了我的星球，我凭借种出的植物拼死抵抗，但瓶中的虫灾大大减缓了我培育植物的速度。一旦培养过快，瓶中的虫灾便会迅速壮大。我不能让魔瓶损毁，这是最后的希望，这也让我最终无力回天。\n\n看着魔瓶，我突然注意到了瓶底的纹路，这纹路精密繁复，不像是普通纹饰。\n\n经过无数次尝试，我明白了！\n\n原来瓶底那圈纹路，是在魔瓶被创造时铭刻的——只要虫灾到了无法挽回的地步，瓶子会连同虫群一起重置。创造者为了让日后得到它的人能快速培育出植物早已想好保底措施，可为什么这纹路会损坏呢？似乎集齐所有植物后我便会知晓这一切，但可惜我做不到了，来不及想这么多，我只能用最后的时间修复了这一圈纹路，并将这个魔瓶传送，希望可以帮助下一个世界。\n\n这样的话，下一个得到瓶子的人，或许能让这场灾难迎来终结....",
		# 阶段三：集齐所有植物后，创造者的留言。
		"stage3": "图鉴终于接近完整，最后一页的字迹也清晰了：\n\n我是魔瓶的创造者。当你看到这段话时，或许我的星球已经毁灭了。我将这段话与魔瓶相关联，希望可以提醒后来之人。\n\n我们星球的人对环境与植物不屑一顾，认为这些在科技面前不值一提。但突如其来的虫灾让他们付出了代价：这些虫子在星球之间迁徙，每到一个地方便将一个地方啃食殆尽，虫灾毁灭了我们的一切....唯有少数人依靠着培育奇妙的植物抵御虫灾活了下来，而魔瓶就是培育这些植物的容器。我们培育的所有植物都会记录在图鉴之中。\n\n但我们还是低估了虫群的力量。它们甚至入侵了魔瓶，在我们的培育中会出现虫群啃食我们的植物。所有植物都依托于魔瓶而存在，啃食植物也会让魔瓶受损。我们不得不给魔瓶一个重启机制：当虫灾到了无法挽回的地步，就将魔瓶重启。\n\n我们已经是强弩之末。不过魔瓶被入侵后似乎有了定位的能力，指向了某个方向。我不知道这个定位意味着什么，但在临死前，我会将这个魔瓶传送到那个位置，或许那是下一个虫灾肆虐的地方。不论你是谁，希望这个瓶子能帮助你。而当你集齐其中所有的植物后，将会得到.....那奇迹的种子。"
	}
]
var _current = 0
var _toc_buttons = []
var _last_focus = null
var _paused_by_guide = false
var _fog = null
var _fog_hint = null
var _peek_label = null
var _fog_tween = null

# 强制阅读模式：只显示指定页，每页都要点开，读全之前合不上。
var _restricted = false
var _required_pages = []
var _visited = {}
var _restricted_callback = null

onready var _title_label = $Root/Book/Margin/VBox/Body/Scroll/Content/ChapterTitle
onready var _body_label = $Root/Book/Margin/VBox/Body/Scroll/Content/ChapterBody
onready var _note_box = $Root/Book/Margin/VBox/Body/Scroll/Content/Note
onready var _note_label = $Root/Book/Margin/VBox/Body/Scroll/Content/Note/NoteBody
onready var _scroll = $Root/Book/Margin/VBox/Body/Scroll
onready var _toc = $Root/Book/Margin/VBox/Body/Toc
onready var _close_button = $Root/Book/Margin/VBox/Header/Close
onready var _footer = $Root/Book/Margin/VBox/Footer


func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	visible = false
	GS.guide = self
	_build_toc()
	_build_fog()
	_close_button.connect("pressed", self, "_on_close_pressed")
	select_chapter(0)
	_update_restriction_ui()


func _exit_tree():
	if GS.guide == self:
		GS.guide = null


func _font(size):
	var f = DynamicFont.new()
	f.font_data = load("res://fonts/SimHei.ttf")
	f.size = size
	return f


func _build_toc():
	var group = ButtonGroup.new()
	for i in range(CHAPTERS.size()):
		var b = Button.new()
		b.text = CHAPTERS[i]["title"]
		b.align = Button.ALIGN_LEFT
		b.toggle_mode = true
		b.group = group
		b.rect_min_size = Vector2(0, 36)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_font_override("font", _font(15))
		b.add_color_override("font_color", Color(0.30, 0.19, 0.12))
		b.add_color_override("font_color_hover", Color(0.20, 0.11, 0.06))
		b.add_color_override("font_color_pressed", Color(0.20, 0.11, 0.06))
		b.add_color_override("font_color_focus", Color(0.30, 0.19, 0.12))
		b.connect("pressed", self, "_on_chapter_pressed", [i])
		b.connect("mouse_entered", SFX.button_hover, "play_sfx")
		_toc.add_child(b)
		_toc_buttons.append(b)
	_refresh_toc()


func _build_fog():
	# 雾气盖在正文区域上；未解锁的章节只留下标题和一团灰雾。
	_fog = TextureRect.new()
	_fog.texture = load("res://ui/fog.png")
	_fog.expand = true
	_fog.stretch_mode = TextureRect.STRETCH_SCALE
	_fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fog.visible = false
	$Root/Book.add_child(_fog)

	_fog_hint = Label.new()
	_fog_hint.align = Label.ALIGN_CENTER
	_fog_hint.valign = Label.VALIGN_CENTER
	_fog_hint.autowrap = true
	_fog_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var f = _font(23)
	_fog_hint.add_font_override("font", f)
	_fog_hint.add_color_override("font_color", Color(0.25, 0.23, 0.20, 0.95))
	_fog_hint.visible = false
	$Root/Book.add_child(_fog_hint)

	# 雾气下沿露出来的最后一句：压在雾的上层，贴在页面底部。
	_peek_label = Label.new()
	_peek_label.align = Label.ALIGN_LEFT
	_peek_label.valign = Label.VALIGN_CENTER
	_peek_label.autowrap = true
	_peek_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_peek_label.add_font_override("font", _font(18))
	_peek_label.add_color_override("font_color", Color(0.24, 0.15, 0.09, 1))
	_peek_label.add_color_override("font_color_shadow", Color(1, 0.98, 0.92, 0.55))
	_peek_label.add_constant_override("shadow_offset_x", 0)
	_peek_label.add_constant_override("shadow_offset_y", 1)
	_peek_label.add_constant_override("line_spacing", 7)
	_peek_label.visible = false
	$Root/Book.add_child(_peek_label)

	_fog_tween = Tween.new()
	add_child(_fog_tween)


func _place_fog():
	if _fog == null or _fog_hint == null:
		return
	var book = $Root/Book
	var r = Rect2(_scroll.rect_global_position - book.rect_global_position, _scroll.rect_size)
	_fog.rect_position = r.position
	_fog.rect_size = r.size
	_fog_hint.rect_position = r.position + Vector2(34, 0)
	_fog_hint.rect_size = r.size - Vector2(68, 0)
	if _peek_label != null:
		# 一行排下，贴近页面底部，和正文左缘对齐。
		var peek_h = 34.0
		_peek_label.rect_position = Vector2(r.position.x + 10,
			r.position.y + r.size.y - peek_h - 20)
		_peek_label.rect_size = Vector2(r.size.x - 20, peek_h)


func _show_fog(index):
	if _fog_tween != null:
		_fog_tween.stop_all()
		_fog_tween.remove_all()
	_place_fog()
	var chapter = CHAPTERS[index]
	_fog_hint.text = chapter.get("fog",
		"这一页被灰色的雾气盖住了。\n\n继续在魔瓶里探索，等时机到了，雾气会自行散开。")
	_fog.modulate = Color(1, 1, 1, 1)
	_fog_hint.modulate = Color(1, 1, 1, 1)
	_fog.visible = true
	_fog_hint.visible = true
	if _peek_label != null:
		var peek = chapter.get("peek", "")
		_peek_label.text = peek
		_peek_label.modulate = Color(1, 1, 1, 1)
		_peek_label.visible = peek != ""


func _dissolve_fog():
	if not _fog.visible or _fog_tween == null:
		return
	# 正文已经露出来了，提示与雾外的末句立即退场，避免和正文叠字。
	if _fog_hint != null:
		_fog_hint.visible = false
	if _peek_label != null:
		_peek_label.visible = false
		_peek_label.modulate = Color(1, 1, 1, 1)
	_fog_tween.stop_all()
	_fog_tween.remove_all()
	_fog_tween.interpolate_property(_fog, "modulate:a", _fog.modulate.a, 0.0, 0.55,
		Tween.TRANS_SINE, Tween.EASE_OUT)
	_fog_tween.interpolate_callback(self, 0.58, "_hide_fog")
	_fog_tween.start()


func _hide_fog():
	_fog.visible = false
	_fog_hint.visible = false
	if _peek_label != null:
		_peek_label.visible = false
		_peek_label.modulate = Color(1, 1, 1, 1)


func _process(_delta):
	if visible and _fog != null and _fog.visible:
		_place_fog()


func _refresh_toc():
	for i in range(_toc_buttons.size()):
		var b = _toc_buttons[i]
		b.visible = _page_visible(i)
		var locked = not _is_unlocked(i)
		var idle = Color(0.47, 0.42, 0.37, 0.55) if locked else Color(0.30, 0.19, 0.12)
		var hot = Color(0.40, 0.35, 0.30, 0.70) if locked else Color(0.20, 0.11, 0.06)
		b.add_color_override("font_color", idle)
		b.add_color_override("font_color_hover", hot)
		b.add_color_override("font_color_pressed", hot)
		b.add_color_override("font_color_focus", idle)
		b.hint_tooltip = "这一页还被雾气盖着" if locked else ""


# 目录保留所有章节；强制阅读期间只保留指定页。
func _page_visible(index):
	if _restricted and not _required_pages.has(index):
		return false
	return true


func _is_unlocked(index):
	var chapter = CHAPTERS[index]
	if chapter.get("always", false):
		return true
	var special = chapter.get("special", "")
	if special == "final_page":
		return _final_stage() >= 2
	var flag = chapter.get("flag", "")
	if flag == "":
		return false
	return Flags.get(flag) == true


# 最后一页分三段（对应指南文档）：雾气引子 → 收录 7 种以上散开前半段
# → 集齐所有植物后创造者留言。
func _final_stage():
	var enc = get_node_or_null("/root/Encyclopedia")
	if enc == null:
		return 1
	if enc.all_species_represented():
		return 3
	if enc.species_represented_count() >= 7:
		return 2
	return 1


func _final_body():
	var ch = CHAPTERS[CHAPTERS.size() - 1]
	if _final_stage() >= 3:
		return ch["stage2"] + "\n\n" + ch["stage3"]
	return ch["stage2"]


func _entry_count():
	if has_node("/root/Encyclopedia"):
		return get_node("/root/Encyclopedia").discovered_count()
	return 0


func select_chapter(index):
	if index < 0 or index >= CHAPTERS.size():
		return
	if not _page_visible(index):
		return
	_current = index
	_title_label.text = CHAPTERS[index]["title"]
	# 批注已经写在正文里，页边批注框不再使用。
	_note_box.visible = false
	if _is_unlocked(index):
		var ch = CHAPTERS[index]
		if ch.get("special", "") == "final_page":
			_body_label.text = _final_body()
		else:
			_body_label.text = ch["body"]
		_body_label.visible = true
		if _fog != null and _fog.visible and _fog.modulate.a > 0.98:
			_dissolve_fog()
	else:
		_body_label.text = ""
		_body_label.visible = false
		_show_fog(index)
	if index < _toc_buttons.size():
		_toc_buttons[index].pressed = true
	_scroll.scroll_vertical = 0
	if _restricted:
		_visited[index] = true
		_update_restriction_ui()


func open(pause_game = false, keep_restriction = false):
	if not keep_restriction:
		_clear_restriction()
	if pause_game and not get_tree().paused:
		get_tree().paused = true
		_paused_by_guide = true
	_refresh_toc()
	if not _page_visible(_current):
		_current = _required_pages[0] if _restricted and not _required_pages.empty() else 0
	_last_focus = $Root.get_focus_owner()
	visible = true
	select_chapter(_current)
	_update_restriction_ui()
	if _close_button.disabled and not _toc_buttons.empty():
		_toc_buttons[_current].grab_focus()
	else:
		_close_button.grab_focus()


# 只翻开指定的几页，读完之前不让合上；读完关闭时回调，并解除暂停。
func open_required(pages, callback = null):
	_restricted = true
	_required_pages = pages.duplicate()
	_visited = {}
	for p in _required_pages:
		_visited[p] = false
	_restricted_callback = callback
	_current = _required_pages[0] if not _required_pages.empty() else 0
	open(true, true)


func _clear_restriction():
	_restricted = false
	_required_pages = []
	_visited = {}
	_restricted_callback = null
	if _footer != null:
		_footer.text = "按 Esc 合上指南"
	if _close_button != null:
		_close_button.disabled = false


func _all_required_read():
	for p in _required_pages:
		if not _visited.get(p, false):
			return false
	return true


func _update_restriction_ui():
	if not _restricted:
		_close_button.disabled = false
		_footer.text = "按 Esc 合上指南"
		return
	var read = 0
	for p in _required_pages:
		if _visited.get(p, false):
			read += 1
	_close_button.disabled = read < _required_pages.size()
	# 不提示“读完才能合上”，让页面自己说话。
	_footer.text = ""


func close():
	if _restricted and not _all_required_read():
		_update_restriction_ui()
		return
	visible = false
	var callback = _restricted_callback
	_restricted_callback = null
	_clear_restriction()
	if _paused_by_guide:
		_paused_by_guide = false
		get_tree().paused = false
	if _last_focus != null and is_instance_valid(_last_focus):
		_last_focus.grab_focus()
	if callback != null:
		callback.call_func()


func _on_chapter_pressed(index):
	SFX.button_click.play_sfx()
	select_chapter(index)


func _on_close_pressed():
	SFX.button_click.play_sfx()
	close()


func _unhandled_input(event):
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if _restricted and not _all_required_read():
			_update_restriction_ui()
			get_tree().set_input_as_handled()
			return
		close()
		get_tree().set_input_as_handled()
