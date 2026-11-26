extends Node

# 植物物种、图鉴条目与魔瓶卡池的静态数据。
# 每种植物 = 1 个基础条目 + 2 个变种条目，变种算独立图鉴条目。

const SPECIES_ORDER = [
	"tomato", "sunflower", "cotton", "pumpkin", "rice", "moonflower", "wintersweet",
	"wheat", "mint", "flax", "soybean", "maize", "potato", "sugarcane", "saffron"
]

const SPECIES = {
	"tomato": {
		"name": "番茄",
		"scientific": "Solanum lycopersicum",
		"family": "茄科 · 番茄属",
		"origin": "南美洲安第斯山区",
		"season": "spring",
		"season_name": "春",
		"frames": 4,
		"health": 7,
		"level": 1,
		"scene": "res://plants/plant1/Plant1.tscn",
		"photo": "res://plants/plant1/growth_3.png",
		"pool": "basic",
		"lore": "番茄是喜温、喜光的茄科作物，原产于南美洲安第斯山区。充足日照和稳定水分能让果实顺利转色。",
		"variants": [
			{"name": "樱桃番茄", "scientific": "Solanum lycopersicum var. cerasiforme",
				"desc": "番茄的变种，果实小而圆、糖度较高，常作为鲜食水果栽培。", "color": [1.0, 0.55, 0.55],
				"perk": {"frames_bonus": 1, "text": "成熟快 1 帧"}},
			{"name": "靛蓝玫瑰番茄", "scientific": "Solanum lycopersicum 'Indigo Rose'",
				"desc": "富含花青素的园艺品种，未熟果呈紫黑色，成熟后转为暗红色。", "color": [0.55, 0.35, 0.65],
				"perk": {"reflect": 1, "text": "被虫咬时反伤 1 点"}}
		]
	},
	"sunflower": {
		"name": "向日葵",
		"scientific": "Helianthus annuus",
		"family": "菊科 · 向日葵属",
		"origin": "北美洲",
		"season": "summer",
		"season_name": "夏",
		"frames": 6,
		"health": 5,
		"level": 2,
		"scene": "res://plants/plant2/Plant2.tscn",
		"photo": "res://plants/plant2/growth_5.png",
		"pool": "medium",
		"lore": "向日葵喜光耐旱，原产于北美洲。幼嫩花盘会朝向太阳，成熟后逐渐固定方向。",
		"variants": [
			{"name": "泰迪熊向日葵", "scientific": "Helianthus annuus 'Teddy Bear'",
				"desc": "矮生重瓣品种，舌状花密集，整体呈毛绒球形，适合盆栽观赏。", "color": [1.0, 0.8, 0.25],
				"perk": {"harvest_shield": 1, "text": "收获时为相邻植物 +1 护盾"}},
			{"name": "红磨坊向日葵", "scientific": "Helianthus annuus 'Moulin Rouge'",
				"desc": "花瓣呈深红至酒红色的观赏品种，花盘比普通向日葵小。", "color": [0.9, 0.45, 0.2],
				"perk": {"reflect": 2, "text": "被虫咬时反伤 2 点"}}
		]
	},
	"cotton": {
		"name": "棉花",
		"scientific": "Gossypium hirsutum",
		"family": "锦葵科 · 棉属",
		"origin": "热带美洲与南亚",
		"season": "autumn",
		"season_name": "秋",
		"frames": 6,
		"health": 4,
		"level": 2,
		"scene": "res://plants/plant4/Plant4.tscn",
		"photo": "res://plants/plant4/growth_5.png",
		"pool": "medium",
		"lore": "棉花是锦葵科棉属的喜温纤维作物，原产于热带美洲与南亚。棉铃在秋季成熟开裂，棉纤维是世界上最重要的天然纺织原料。",
		"variants": [
			{"name": "中棉12号", "scientific": "Gossypium hirsutum 'Zhongmiansuo 12'",
				"desc": "我国自主育成的陆地棉主推品种，全称中棉所12号，耐旱耐盐碱、产量稳定，曾长期是国内种植面积最大的棉型。", "color": [1.0, 0.96, 0.86],
				"perk": {"frames_bonus": 1, "text": "成熟快 1 帧"}},
			{"name": "吉扎45海岛棉", "scientific": "Gossypium barbadense 'Giza 45'",
				"desc": "尼罗河流域的著名长绒棉，纤维细长强韧、带有丝光感，是高档纺织品原料。", "color": [0.78, 0.88, 0.82],
				"perk": {"harvest_shield": 1, "text": "收获时为相邻植物 +1 护盾"}}
		]
	},
	"pumpkin": {
		"name": "南瓜",
		"scientific": "Cucurbita moschata",
		"family": "葫芦科 · 南瓜属",
		"origin": "中美洲",
		"season": "autumn",
		"season_name": "秋",
		"frames": 6,
		"health": 3,
		"level": 3,
		"scene": "res://plants/plant3/Plant3.tscn",
		"photo": "res://plants/plant3/growth_5.png",
		"pool": "high",
		"lore": "南瓜喜温耐旱，原产于中美洲。藤蔓生长迅速，秋季成熟，果皮坚硬、耐储存。",
		"variants": [
			{"name": "奶油南瓜", "scientific": "Cucurbita moschata 'Butternut'",
				"desc": "长梨形的食用品种，果肉橙黄细腻、甜度高，耐储存。", "color": [1.0, 0.85, 0.55],
				"perk": {"harvest_charge": 3, "text": "收获时瓶能 +3"}},
			{"name": "贝贝南瓜", "scientific": "Cucurbita moschata 'Beibei'",
				"desc": "小型板栗南瓜，单果约 300 至 500 克，口感粉糯。", "color": [0.95, 0.6, 0.25],
				"perk": {"frames_bonus": 1, "text": "成熟快 1 帧"}}
		]
	},
	"rice": {
		"name": "水稻",
		"scientific": "Oryza sativa",
		"family": "禾本科 · 稻属",
		"origin": "中国长江流域",
		"season": "summer",
		"season_name": "夏",
		"frames": 6,
		"health": 3,
		"level": 3,
		"scene": "res://plants/plant5/Plant5.tscn",
		"photo": "res://plants/plant5/growth_5.png",
		"pool": "high",
		"lore": "水稻是禾本科稻属的一年生草本，起源于中国长江流域。喜温喜湿，整株生成都离不开水，抽穗后穗头随成熟逐渐低垂。",
		"variants": [
			{"name": "越光粳稻", "scientific": "Oryza sativa subsp. japonica 'Koshihikari'",
				"desc": "经典粳稻品种，耐寒性较好，籽粒饱满圆润，煮饭后软糯回甜、气味清香。", "color": [0.86, 0.9, 0.6],
				"perk": {"harvest_charge": 3, "text": "收获时瓶能 +3"}},
			{"name": "巴斯马蒂籼稻", "scientific": "Oryza sativa subsp. indica 'Basmati 370'",
				"desc": "喜马拉雅山麓的著名香籼稻，籽粒细长，煮熟带有坚果香气，是印度香米的代表品种。", "color": [1.0, 0.92, 0.62],
				"perk": {"harvest_charge": 2, "text": "收获时瓶能 +2"}}
		]
	},
	"moonflower": {
		"name": "月见草",
		"scientific": "Oenothera biennis",
		"family": "柳叶菜科 · 月见草属",
		"origin": "北美洲",
		"season": "winter",
		"season_name": "冬",
		"frames": 9,
		"health": 4,
		"level": 4,
		"scene": "res://plants/winplant/WinPlant.tscn",
		"photo": "res://plants/winplant/growth_8.png",
		"pool": "rare",
		"lore": "月见草是二年生草本，原产于北美洲，傍晚开花，种子可榨油。它耐寒，适合在秋冬季节慢慢生长。",
		"variants": [
			{"name": "非洲太阳月见草", "scientific": "Oenothera biennis 'African Sun'",
				"desc": "月见草的园艺品种，株型紧凑、花色明黄，适合花境种植。", "color": [1.0, 0.9, 0.4],
				"perk": {"always_two_growth": true, "text": "不受季节生长速度惩罚"}},
			{"name": "柠檬日落月见草", "scientific": "Oenothera 'Lemon Sunset'",
				"desc": "月见草属园艺杂交品种，花瓣由柠檬黄渐变为橙粉色。", "color": [1.0, 0.7, 0.55],
				"perk": {"harvest_charge": 2, "text": "收获时瓶能 +2"}}
		]
	},
	"wintersweet": {
		"name": "腊梅",
		"scientific": "Chimonanthus praecox",
		"family": "蜡梅科 · 蜡梅属",
		"origin": "中国中部",
		"season": "winter",
		"season_name": "冬",
		"frames": 8,
		"health": 3,
		"level": 4,
		"scene": "res://plants/plant6/Plant6.tscn",
		"photo": "res://plants/plant6/growth_8.png",
		"pool": "rare",
		"lore": "腊梅是蜡梅科的冬季落叶灌木，原产中国中部，严冬开花，花瓣质感如蜡、香气清冽，本字写作蜡梅。",
		"variants": [
			{"name": "素心腊梅", "scientific": "Chimonanthus praecox f. concolor",
				"desc": "内轮花被片纯黄无紫条纹的传统名品，花大香浓，被视为腊梅中的上品。", "color": [1.0, 0.93, 0.55],
				"perk": {"frames_bonus": 1, "text": "成熟快 1 帧"}},
			{"name": "狗牙腊梅", "scientific": "Chimonanthus praecox 'Caninum'",
				"desc": "常见的野生本砧类型，花瓣尖薄如犬齿，花略小但香气最浓，根系强健最耐寒。", "color": [0.9, 0.86, 0.68],
				"perk": {"reflect": 1, "text": "被虫咬时反伤 1 点"}}
		]
	},
	# ===== 第二轮扩充的 8 个物种（小麦/薄荷 1 年、亚麻/大豆 2 年、
	# 玉米/马铃薯 3 年、甘蔗/藏红花 4 年），字段含义与上面完全一致。=====
	"wheat": {
		"name": "小麦",
		"scientific": "Triticum aestivum",
		"family": "禾本科 · 小麦属",
		"origin": "西亚新月地带",
		"season": "summer",
		"season_name": "夏",
		"frames": 6,
		"health": 6,
		"level": 1,
		"scene": "res://plants/plant7/Plant7.tscn",
		"photo": "res://plants/plant7/growth_5.png",
		"pool": "basic",
		"lore": "小麦是禾本科小麦属的一年生谷物，原产西亚新月地带，全世界养活的口粮里它占的头把交椅。冬小麦秋播、挨过一冬，翌年抽穗结实，麦芒朝外护着穗子，成熟时整片田由青转金。",
		"variants": [
			{"name": "济麦22", "scientific": "Triticum aestivum 'Jimai 22'",
				"desc": "山东育成的冬小麦主推品种，分蘖多、抗倒伏，靠亩穗数取胜，曾多年是国内种植面积第一的小麦。", "color": [1.0, 0.86, 0.5],
				"perk": {"frames_bonus": 1, "text": "成熟快 1 帧"}},
			{"name": "杜兰硬粒小麦", "scientific": "Triticum durum 'Capeitti'",
				"desc": "四倍体的硬粒小麦，籽粒坚硬、蛋白质含量远高于普通小麦，是意大利通心粉和北非古斯古斯的原料。", "color": [0.95, 0.72, 0.42],
				"perk": {"harvest_charge": 3, "text": "收获时瓶能 +3"}}
		]
	},
	"mint": {
		"name": "薄荷",
		"scientific": "Mentha canadensis",
		"family": "唇形科 · 薄荷属",
		"origin": "欧亚温带",
		"season": "spring",
		"season_name": "春",
		"frames": 5,
		"health": 7,
		"level": 1,
		"scene": "res://plants/plant8/Plant8.tscn",
		"photo": "res://plants/plant8/growth_4.png",
		"pool": "basic",
		"lore": "薄荷是唇形科薄荷属的多年生香草，茎是方的、叶成对生长，全株油腺一掐就冒香气。它靠地下根茎横向蔓延，掐断一截就能另起一丛，是最难清干净也最容易复壮的作物。",
		"variants": [
			{"name": "留兰香薄荷", "scientific": "Mentha spicata",
				"desc": "不含薄荷脑的清甜类型，叶片皱而尖，气味温和，多国用来入茶、配餐与做甜点。", "color": [0.6, 1.0, 0.7],
				"perk": {"harvest_shield": 1, "text": "收获时为相邻植物 +1 护盾"}},
			{"name": "胡椒薄荷", "scientific": "Mentha × piperita",
				"desc": "薄荷与水薄荷的天然杂交种，茎带紫色、薄荷脑含量高，气味冲鼻，多数虫类不爱靠近。", "color": [0.75, 0.6, 0.95],
				"perk": {"reflect": 1, "text": "被虫咬时反伤 1 点"}}
		]
	},
	"flax": {
		"name": "亚麻",
		"scientific": "Linum usitatissimum",
		"family": "亚麻科 · 亚麻属",
		"origin": "地中海东部至中亚",
		"season": "spring",
		"season_name": "春",
		"frames": 6,
		"health": 4,
		"level": 2,
		"scene": "res://plants/plant9/Plant9.tscn",
		"photo": "res://plants/plant9/growth_5.png",
		"pool": "medium",
		"lore": "亚麻是亚麻科亚麻属的一年生草本，茎细得像鞭子，清晨开出五瓣天蓝的花、午后就落。它是人类最古老的纤维作物之一：茎皮撕出来纺成亚麻布，籽粒榨出亚麻籽油。",
		"variants": [
			{"name": "黑亚16号亚麻", "scientific": "Linum usitatissimum 'Heiya 16'",
				"desc": "黑龙江育成的纤用亚麻，茎秆高直、工艺长度长。高纬凉爽地带日照时间长，它一天能蹿一大截。", "color": [0.6, 0.8, 1.0],
				"perk": {"always_two_growth": true, "text": "不受季节生长速度惩罚"}},
			{"name": "陇油7号胡麻", "scientific": "Linum usitatissimum 'Longyou 7'",
				"desc": "西北旱地的油用亚麻，当地叫胡麻。籽粒圆小、含油率高，是亚麻籽油的主要来源，耐旱得很。", "color": [0.85, 0.7, 0.55],
				"perk": {"harvest_charge": 3, "text": "收获时瓶能 +3"}}
		]
	},
	"soybean": {
		"name": "大豆",
		"scientific": "Glycine max",
		"family": "豆科 · 大豆属",
		"origin": "中国东部",
		"season": "autumn",
		"season_name": "秋",
		"frames": 6,
		"health": 5,
		"level": 2,
		"scene": "res://plants/plant10/Plant10.tscn",
		"photo": "res://plants/plant10/growth_5.png",
		"pool": "medium",
		"lore": "大豆是豆科大豆属的一年生草本，原产中国。根上的根瘤菌能把空气里的氮固定进土里，所以种过大豆的地力反而变好；鼓荚之后全株转黄，摇起来豆粒在荚里哗哗作响。",
		"variants": [
			{"name": "黑河43大豆", "scientific": "Glycine max 'Heihe 43'",
				"desc": "高纬寒地育成的早熟品种，生育期短、含油率高，正是这类品种把大豆种植带一路往北推。", "color": [0.9, 0.95, 0.6],
				"perk": {"frames_bonus": 1, "text": "成熟快 1 帧"}},
			{"name": "中黄13大豆", "scientific": "Glycine max 'Zhonghuang 13'",
				"desc": "中国农科院育成的高蛋白广适品种，长期是国内播种面积第一的大豆，根瘤固氮、养地效果突出。", "color": [1.0, 0.88, 0.45],
				"perk": {"harvest_charge": 2, "text": "收获时瓶能 +2"}}
		]
	},
	"maize": {
		"name": "玉米",
		"scientific": "Zea mays",
		"family": "禾本科 · 玉蜀黍属",
		"origin": "中美洲",
		"season": "summer",
		"season_name": "夏",
		"frames": 7,
		"health": 4,
		"level": 3,
		"scene": "res://plants/plant11/Plant11.tscn",
		"photo": "res://plants/plant11/growth_6.png",
		"pool": "high",
		"lore": "玉米是禾本科玉蜀黍属的高大草本，原产中美洲。顶端先抽雄穗散粉，穗位再长出裹在苞叶里的果穗，花丝一排排伸出去等粉。一株往往只结一两穗，所以它长得最高、吃水也最狠。",
		"variants": [
			{"name": "郑单958玉米", "scientific": "Zea mays 'Zhengdan 958'",
				"desc": "河南育成的紧凑型杂交种，叶片上冲、耐密植、抗倒伏，长期是国内播种面积最大的玉米品种。", "color": [0.8, 1.0, 0.5],
				"perk": {"always_two_growth": true, "text": "不受季节生长速度惩罚"}},
			{"name": "京科糯2000", "scientific": "Zea mays 'Jingke Nuo 2000'",
				"desc": "北京育成的白糯玉米品种，籽粒角质、几乎全是支链淀粉，苞叶紧包穗形整齐，是鲜食玉米的主力。", "color": [1.0, 0.8, 0.75],
				"perk": {"harvest_shield": 1, "text": "收获时为相邻植物 +1 护盾"}}
		]
	},
	"potato": {
		"name": "马铃薯",
		"scientific": "Solanum tuberosum",
		"family": "茄科 · 茄属",
		"origin": "南美洲安第斯山区",
		"season": "spring",
		"season_name": "春",
		"frames": 6,
		"health": 4,
		"level": 3,
		"scene": "res://plants/plant12/Plant12.tscn",
		"photo": "res://plants/plant12/growth_5.png",
		"pool": "high",
		"lore": "马铃薯是茄科茄属的草本，原产南美安第斯山区。能吃的部分不是根，而是地下茎末端膨大的块茎；地上开五裂的白花或紫花，秧子一枯，土里就挂着一串薯。",
		"variants": [
			{"name": "克新1号马铃薯", "scientific": "Solanum tuberosum 'Kexin 1'",
				"desc": "黑龙江育成的早熟粮菜兼用品种，薯形椭圆、皮肉皆黄，是国内推广面积最大的马铃薯之一。", "color": [0.9, 0.78, 0.62],
				"perk": {"harvest_shield": 1, "text": "收获时为相邻植物 +1 护盾"}},
			{"name": "费乌瑞它马铃薯", "scientific": "Solanum tuberosum 'Frieslander'",
				"desc": "荷兰引入的极早熟品种，薯皮光滑、芽眼很浅，地上秧子窜得快，能比别人早一周挖薯。", "color": [1.0, 0.9, 0.6],
				"perk": {"frames_bonus": 1, "text": "成熟快 1 帧"}}
		]
	},
	"sugarcane": {
		"name": "甘蔗",
		"scientific": "Saccharum officinarum",
		"family": "禾本科 · 甘蔗属",
		"origin": "新几内亚及东南亚",
		"season": "winter",
		"season_name": "冬",
		"frames": 8,
		"health": 4,
		"level": 4,
		"scene": "res://plants/plant13/Plant13.tscn",
		"photo": "res://plants/plant13/growth_7.png",
		"pool": "rare",
		"lore": "甘蔗是禾本科甘蔗属的高大草本，原产新几内亚一带。茎节分明、节间贮满糖汁，表面覆着一层白色蜡粉；入冬正是榨季，糖攒到最足的时候砍倒进碾坊。",
		"variants": [
			{"name": "新台糖22号甘蔗", "scientific": "Saccharum officinarum 'NSTC No.22'",
				"desc": "育成的糖蔗主推品种，宿根性强、分蘖多、蔗糖分高，在华南长期是榨糖的主力。", "color": [0.75, 0.9, 0.8],
				"perk": {"harvest_charge": 3, "text": "收获时瓶能 +3"}},
			{"name": "拔地拉果蔗", "scientific": "Saccharum officinarum 'Badila'",
				"desc": "俗称黑皮蔗的经典果蔗，茎粗节长、纤维软、甜得清爽，是拿去啃的而不是拿去榨的。", "color": [0.65, 0.55, 0.8],
				"perk": {"harvest_charge": 2, "text": "收获时瓶能 +2"}}
		]
	},
	"saffron": {
		"name": "藏红花",
		"scientific": "Crocus sativus",
		"family": "鸢尾科 · 番红花属",
		"origin": "西南亚及地中海",
		"season": "autumn",
		"season_name": "秋",
		"frames": 7,
		"health": 3,
		"level": 4,
		"scene": "res://plants/plant14/Plant14.tscn",
		"photo": "res://plants/plant14/growth_6.png",
		"pool": "rare",
		"lore": "藏红花就是番红花，鸢尾科番红花属的球根草本，秋末才抽花：淡紫的六瓣花杯里垂出三根深红柱头。值钱的就是那三根丝，十万朵花才烘得出公斤级，是世界上最贵的香料。",
		"variants": [
			{"name": "萨戈尔西红花", "scientific": "Crocus sativus 'Sargol'",
				"desc": "等级最高的柱头规格，只留红色顶端、不带黄白花柱，色深味烈；苦味苷含量高，虫类不爱碰。", "color": [0.85, 0.5, 0.85],
				"perk": {"reflect": 1, "text": "被虫咬时反伤 1 点"}},
			{"name": "拉曼查西红花", "scientific": "Crocus sativus 'La Mancha'",
				"desc": "西班牙拉曼查高原的传统品系，柱头长而柔韧，自古入药入膳，当地认为它最能解郁活血。", "color": [0.95, 0.6, 0.75],
				"perk": {"harvest_charge": 2, "text": "收获时瓶能 +2"}}
		]
	}
}

const MUTATION_CHANCE = {
	"spring": 0.06,
	"summer": 0.25,
	"autumn": 0.10,
	"winter": 0.06
}

# 每次收获没有变异，下一次变异概率追加 15 个百分点。
const MUTATION_PITY_STEP = 0.15

# 每回合基础抽卡池。带 min_year / min_season 的条目要到对应"绝对季门"后才出现。
# 季门 = (年份-1)*4 + 季节序号(春夏秋冬=0..3)。
# 种子阶梯（进池后永久保留，瓶碎不收回）：
#   1年春 番茄 / 小麦 / 薄荷
#   1年夏 向日葵 / 棉花
#   1年秋 南瓜 / 水稻
#   1年冬 腊梅 / 月见草 / 甘蔗 / 藏红花
#   2年春 亚麻 / 大豆
#   2年夏 玉米 / 马铃薯
# 前 11 种在第一年就能见到，剩下 4 种分两季、每季 2 种，在第二年夏天前全部进池。
const BASIC_POOL = [
	{"id": "water_drop", "weight": 8},
	{"id": "water_drip", "weight": 5},
	{"id": "water_can", "weight": 3},
	{"id": "shield", "weight": 4},
	{"id": "whack", "weight": 4},
	{"id": "kapow", "weight": 2},
	{"id": "hasten", "weight": 3},
	{"id": "graft", "weight": 2},
	{"id": "net", "weight": 3},
	{"id": "energy_dew", "weight": 2},
	{"id": "basic_plant", "weight": 4},
	{"id": "wheat_seed", "weight": 3},
	{"id": "mint_seed", "weight": 3},
	{"id": "swarm", "weight": 2, "min_year": 2},
	{"id": "thorns_armor", "weight": 2, "min_year": 4},
	{"id": "medium_plant", "weight": 2, "min_season": "summer"},
	{"id": "cotton_seed", "weight": 2, "min_season": "summer"},
	{"id": "energy_spring", "weight": 2, "min_year": 2},
	{"id": "high_plant", "weight": 2, "min_season": "autumn"},
	{"id": "rice_seed", "weight": 2, "min_season": "autumn"},
	{"id": "wintersweet_seed", "weight": 2, "min_season": "winter"},
	{"id": "win_plant", "weight": 1, "min_season": "winter"},
	{"id": "sugarcane_seed", "weight": 1, "min_season": "winter"},
	{"id": "saffron_seed", "weight": 1, "min_season": "winter"},
	{"id": "flax_seed", "weight": 2, "min_year": 2, "min_season": "spring"},
	{"id": "soybean_seed", "weight": 2, "min_year": 2, "min_season": "spring"},
	{"id": "maize_seed", "weight": 2, "min_year": 2, "min_season": "summer"},
	{"id": "potato_seed", "weight": 2, "min_year": 2, "min_season": "summer"}
]

# 种子卡全集。发牌保底（手里至少两张种子）从这个列表里补。
# 不含"最后的种子"——那张由结局保底单独发放。
const SEED_CARDS = [
	{"id": "basic_plant", "min_year": 1},
	{"id": "wheat_seed", "min_year": 1},
	{"id": "mint_seed", "min_year": 1},
	{"id": "medium_plant", "min_season": "summer"},
	{"id": "cotton_seed", "min_season": "summer"},
	{"id": "high_plant", "min_season": "autumn"},
	{"id": "rice_seed", "min_season": "autumn"},
	{"id": "wintersweet_seed", "min_season": "winter"},
	{"id": "win_plant", "min_season": "winter"},
	{"id": "sugarcane_seed", "min_season": "winter"},
	{"id": "saffron_seed", "min_season": "winter"},
	{"id": "flax_seed", "min_year": 2, "min_season": "spring"},
	{"id": "soybean_seed", "min_year": 2, "min_season": "spring"},
	{"id": "maize_seed", "min_year": 2, "min_season": "summer"},
	{"id": "potato_seed", "min_year": 2, "min_season": "summer"}
]

# 种子卡 id → 物种 id。抽卡时用它判断“这个物种玩家是否已经拥有”。
const SEED_SPECIES = {
	"basic_plant": "tomato",
	"wheat_seed": "wheat",
	"mint_seed": "mint",
	"medium_plant": "sunflower",
	"cotton_seed": "cotton",
	"flax_seed": "flax",
	"soybean_seed": "soybean",
	"high_plant": "pumpkin",
	"rice_seed": "rice",
	"maize_seed": "maize",
	"potato_seed": "potato",
	"wintersweet_seed": "wintersweet",
	"win_plant": "moonflower",
	"sugarcane_seed": "sugarcane",
	"saffron_seed": "saffron"
}


func species_of_seed_card(card_id):
	return String(SEED_SPECIES.get(String(card_id), ""))


# 图鉴里已经拥有该物种（基础条目或任一变种）就算拥有，抽卡时不再优先。
func species_owned(sid):
	if sid == "":
		return true
	var enc = get_node_or_null("/root/Encyclopedia")
	return enc != null and enc.species_seen(sid)


# 魔瓶卡池：收获某种植物后充能对应的池。
# 规则：每个池只放本阶及更低阶的种子，再加各阶道具；
# 上一阶的种子只靠更高阶的收获来带出，避免低阶池直接开出顶级种子。
# 种子权重合计约占各池 32%~50%，收获后至少三成就有概率摸到新种子。
const BOTTLE_POOLS = {
	"basic": [
		{"id": "basic_plant", "weight": 4},
		{"id": "wheat_seed", "weight": 3},
		{"id": "mint_seed", "weight": 3},
		{"id": "water_pour", "weight": 3},
		{"id": "water_can", "weight": 2},
		{"id": "water_blast", "weight": 2},
		{"id": "shield", "weight": 2},
		{"id": "tough_shield", "weight": 2},
		{"id": "spiked_shield", "weight": 2},
		{"id": "kapow", "weight": 2},
		{"id": "power_fungi", "weight": 2},
		{"id": "vampire_fang", "weight": 2},
		{"id": "water_dagger", "weight": 2},
		{"id": "hasten", "weight": 2},
		{"id": "graft", "weight": 2},
		{"id": "net", "weight": 2},
		{"id": "energy_dew", "weight": 2},
		{"id": "medium_plant", "weight": 2, "min_season": "summer"},
		{"id": "cotton_seed", "weight": 2, "min_season": "summer"},
		{"id": "flax_seed", "weight": 2, "min_year": 2, "min_season": "spring"},
		{"id": "energy_spring", "weight": 1, "min_year": 2},
		{"id": "swarm", "weight": 2, "min_year": 2},
		{"id": "soybean_seed", "weight": 2, "min_year": 2, "min_season": "spring"}
	],
	"medium": [
		{"id": "medium_plant", "weight": 4},
		{"id": "cotton_seed", "weight": 3},
		{"id": "flax_seed", "weight": 3, "min_year": 2, "min_season": "spring"},
		{"id": "soybean_seed", "weight": 3, "min_year": 2, "min_season": "spring"},
		{"id": "basic_plant", "weight": 2},
		{"id": "wheat_seed", "weight": 2},
		{"id": "mint_seed", "weight": 2},
		{"id": "water_barrel", "weight": 3},
		{"id": "water_hose", "weight": 3},
		{"id": "water_blast", "weight": 3},
		{"id": "thorns", "weight": 2},
		{"id": "vampire_slash", "weight": 2},
		{"id": "technique", "weight": 2},
		{"id": "blood_dagger", "weight": 3},
		{"id": "draw3", "weight": 2},
		{"id": "hasten", "weight": 2},
		{"id": "graft", "weight": 2},
		{"id": "net", "weight": 2},
		{"id": "energy_spring", "weight": 2},
		{"id": "swarm", "weight": 2, "min_year": 2},
		{"id": "thorns_armor", "weight": 2, "min_year": 4}
	],
	"high": [
		{"id": "high_plant", "weight": 4},
		{"id": "rice_seed", "weight": 2, "min_season": "autumn"},
		{"id": "maize_seed", "weight": 2, "min_year": 2, "min_season": "summer"},
		{"id": "potato_seed", "weight": 2, "min_year": 2, "min_season": "summer"},
		{"id": "wintersweet_seed", "weight": 2, "min_season": "winter"},
		{"id": "medium_plant", "weight": 2},
		{"id": "cotton_seed", "weight": 2, "min_season": "summer"},
		{"id": "flax_seed", "weight": 2, "min_year": 2, "min_season": "spring"},
		{"id": "soybean_seed", "weight": 2, "min_year": 2, "min_season": "spring"},
		{"id": "water_rain", "weight": 3},
		{"id": "tsunami", "weight": 3},
		{"id": "overflow", "weight": 3},
		{"id": "magic_shield", "weight": 2},
		{"id": "vampire_blast", "weight": 2},
		{"id": "sacrifice", "weight": 2},
		{"id": "power_crystal", "weight": 2},
		{"id": "trapper", "weight": 3},
		{"id": "energy_geyser", "weight": 2},
		{"id": "swarm", "weight": 2, "min_year": 2},
		{"id": "thorns_armor", "weight": 3, "min_year": 4}
	],
	"rare": [
		{"id": "win_plant", "weight": 4},
		{"id": "sugarcane_seed", "weight": 3, "min_season": "winter"},
		{"id": "saffron_seed", "weight": 3, "min_season": "winter"},
		{"id": "high_plant", "weight": 2},
		{"id": "wintersweet_seed", "weight": 2, "min_season": "winter"},
		{"id": "rice_seed", "weight": 2, "min_season": "autumn"},
		{"id": "maize_seed", "weight": 2, "min_year": 2, "min_season": "summer"},
		{"id": "potato_seed", "weight": 2, "min_year": 2, "min_season": "summer"},
		{"id": "medium_plant", "weight": 2},
		{"id": "cotton_seed", "weight": 2, "min_season": "summer"},
		{"id": "flax_seed", "weight": 2, "min_year": 2, "min_season": "spring"},
		{"id": "soybean_seed", "weight": 2, "min_year": 2, "min_season": "spring"},
		{"id": "tsunami", "weight": 3},
		{"id": "sacrifice", "weight": 3},
		{"id": "vampire_blast", "weight": 3},
		{"id": "magic_shield", "weight": 2},
		{"id": "water_rain", "weight": 2},
		{"id": "queen_sting", "weight": 3},
		{"id": "energy_geyser", "weight": 2},
		{"id": "thorns_armor", "weight": 2, "min_year": 4}
	]
}


func species(id):
	return SPECIES.get(id, null)


func scene_for(id):
	var sp = SPECIES.get(id, null)
	if sp == null:
		return null
	return load(sp["scene"])


# 图鉴用的成熟期照片
func photo_for(id):
	var sp = SPECIES.get(id, null)
	if sp == null:
		return null
	return load(sp["photo"])


func variants_for(id):
	var sp = SPECIES.get(id, null)
	if sp == null:
		return []
	return sp["variants"]


func variant_color(id, index):
	var sp = SPECIES.get(id, null)
	if sp == null:
		return Color.white
	var vs = sp["variants"]
	if index < 0 or index >= vs.size():
		return Color.white
	var c = vs[index]["color"]
	return Color(c[0], c[1], c[2])


# 变种的玩法特性。所有特性都在 GameData 里集中声明，
# 植物、收获与图鉴界面只负责读取。
func variant_perk(id, index):
	var sp = SPECIES.get(id, null)
	if sp == null:
		return null
	var vs = sp["variants"]
	if index < 0 or index >= vs.size():
		return null
	return vs[index].get("perk", null)


func mutation_chance(season, pity = 0):
	var base = MUTATION_CHANCE.get(season, 0.06)
	return min(1.0, base + MUTATION_PITY_STEP * pity)


func all_entry_ids():
	var out = []
	for sid in SPECIES_ORDER:
		out.append(sid)
		var sp = SPECIES[sid]
		for i in range(sp["variants"].size()):
			out.append(sid + "_v" + str(i))
	return out


# id 可以是 "tomato"，也可以是 "tomato_v0"
func entry(id):
	var sid = id
	var vi = -1
	var idx = id.find("_v")
	if idx > 0:
		sid = id.substr(0, idx)
		vi = int(id.substr(idx + 2))

	var sp = SPECIES.get(sid, null)
	if sp == null:
		return null

	var e = {
		"id": id,
		"species_id": sid,
		"variant_index": vi,
		"is_variant": vi >= 0,
		"name": sp["name"],
		"base_name": sp["name"],
		"scientific": sp["scientific"],
		"family": sp["family"],
		"origin": sp["origin"],
		"season": sp["season"],
		"season_name": sp["season_name"],
		"frames": sp["frames"],
		"health": sp["health"],
		"level": sp["level"],
		"lore": sp["lore"],
		"variant_desc": "",
		"perk_text": ""
	}

	if vi >= 0:
		var vs = sp["variants"]
		if vi < vs.size():
			e["name"] = vs[vi]["name"]
			e["variant_desc"] = vs[vi]["desc"]
			if vs[vi].has("scientific"):
				e["scientific"] = vs[vi]["scientific"]
			if vs[vi].has("perk"):
				e["perk_text"] = vs[vi]["perk"].get("text", "")

	return e


# 绝对季门：(年份-1)*4 + 季节序号。min_season 缺省按春（=该年一开始）。
const SEASON_GATE_INDEX = {"spring": 0, "summer": 1, "autumn": 2, "winter": 3}


func entry_gate(e):
	var y = int(e.get("min_year", 1))
	var s = SEASON_GATE_INDEX.get(String(e.get("min_season", "spring")), 0)
	return (y - 1) * 4 + s


func current_gate():
	return (Season.year - 1) * 4 + Season.current_index


# 指定季门上首次进池的种子卡（换季播报用）。
func seed_ids_at_gate(gate):
	var out = []
	for e in SEED_CARDS:
		if entry_gate(e) == gate:
			out.append(e["id"])
	return out


func _entry_available(e):
	var gate = entry_gate(e)
	if current_gate() >= gate:
		return true
	# 瓶碎回到第一年春后，历史上到过的季门仍然进池。
	# SaveGame 是最后一个 autoload，互指必须运行时取节点，否则编译期成环。
	var sv = get_node_or_null("/root/SaveGame")
	return sv != null and sv.enabled and int(sv.max_gate_reached) >= gate


# 当年（含历史最高年份）可种的种子卡 id，发牌保底的取牌范围。
func available_seed_card_ids():
	var out = []
	for e in SEED_CARDS:
		if _entry_available(e):
			out.append(e["id"])
	return out


func roll_basic_card_id():
	var available = []
	for e in BASIC_POOL:
		if _entry_available(e):
			available.append(e)
	if available.empty():
		return BASIC_POOL[0]["id"]

	# 还没拥有过的物种，种子权重放大 3 倍，避免整轮只反复抽到开局那几种。
	var weights = []
	var total = 0
	for e in available:
		var w = int(e["weight"])
		var sid = species_of_seed_card(e["id"])
		if sid != "" and not species_owned(sid):
			w *= 3
		weights.append(w)
		total += w

	var r = randi() % total
	for i in range(available.size()):
		r -= weights[i]
		if r < 0:
			return available[i]["id"]

	return available[0]["id"]


# 从某个池子里不重复地抽若干张
func roll_offer(pool_id, count):
	var pool = BOTTLE_POOLS.get(pool_id, BOTTLE_POOLS["basic"])
	var remaining = []
	for e in pool:
		if _entry_available(e):
			remaining.append(e)

	var out = []
	while out.size() < count and remaining.size() > 0:
		var total = 0
		for e in remaining:
			total += e["weight"]

		var r = randi() % total
		var idx = 0
		for i in range(remaining.size()):
			r -= remaining[i]["weight"]
			if r < 0:
				idx = i
				break

		out.append(remaining[idx]["id"])
		remaining.remove(idx)

	return out