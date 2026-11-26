extends SceneTree

# v1.8 声包接线检查：
# 1) SFX/Music 场景里每个播放器都拿到了有效音频流（ogg 全部导入成功）；
# 2) 新接口存在（rand_harvest / play_season_transition / set_mode）；
# 3) HandCard 出牌映射引用的卡对象都在注册表里；
# 4) 瓶碎/释放走的是新音而不是旧 mutation。

func _init():
	var problems = []
	var sfx = get_root().get_node("SFX")
	var music = get_root().get_node("Music")
	var gs = get_root().get_node("GS")

	var expect_players = {
		"Plant1": true, "Plant6": true,
		"Harvest1": true, "Harvest4": true, "HarvestVariant": true,
		"WaterBarrel": true, "WaterHose": true,
		"DrainLow": true, "DrainHigh": true,
		"AttackSingle": true, "AttackHeavy": true,
		"BottleHurt": true, "BottlePower": true, "BottleShatter": true,
		"SeasonSpring": true, "SeasonSummer": true,
		"SeasonAutumn": true, "SeasonWinter": true,
		"BugBite1": true, "BugBite2": true, "BugBite3": true, "BugBite4": true,
		"AttackWaterLow": true, "AttackWaterHigh": true,
		"AttackBloodLow": true, "AttackBloodHigh": true, "SwarmAttack": true,
		"WaterFree": true, "WaterCost1": true, "WaterRandom": true,
	}
	for n in sfx.get_children():
		if n is AudioStreamPlayer and n.stream == null:
			problems.append("SFX node with null stream: " + n.name)
		# Godot3 ogg/mp3 导入默认 loop=true，SFX._ready 必须把它们全关掉，
		# 否则一次点击无限重播（2026-11-25 试玩的"反复播放"根因）。
		elif n is AudioStreamPlayer and (n.stream is AudioStreamOGGVorbis
				or n.stream is AudioStreamMP3) and n.stream.loop:
			problems.append("stream still looping: " + n.name)
	for name in expect_players.keys():
		var p = sfx.get_node_or_null(name)
		if p == null:
			problems.append("missing SFX player: " + name)
		elif p.stream == null:
			problems.append("null stream: " + name)

	if sfx.get_child_count() != 55:
		problems.append("SFX children %d != 55" % sfx.get_child_count())

	if not sfx.has_method("rand_harvest"):
		problems.append("SFX.rand_harvest missing")
	if not sfx.has_method("rand_bug_bite"):
		problems.append("SFX.rand_bug_bite missing")
	if sfx.has_method("play_bug_spawn"):
		problems.append("SFX.play_bug_spawn should be removed")
	if not sfx.has_method("play_water_card"):
		problems.append("SFX.play_water_card missing")
	if not sfx.has_method("play_season_transition"):
		problems.append("SFX.play_season_transition missing")
	if not music.has_method("set_mode"):
		problems.append("Music.set_mode missing")

	for mn in ["GameMusic", "ShatterMusic", "EndingMusic"]:
		var mp = music.get_node_or_null(mn)
		if mp == null or mp.stream == null:
			problems.append("Music missing stream: " + mn)

	# 出牌映射依赖的卡对象
	for cid in ["whack", "kapow", "water_barrel", "water_hose",
			"vampire_fang", "vampire_slash", "vampire_blast"]:
		if gs.card_by_id(cid) == null:
			problems.append("registry missing card: " + cid)

	# YearEnd 槽位已换成"更换年份"（ogg 导入在编辑器里反复失败，最终用 wav 交付）
	var ye = sfx.get_node("YearEnd")
	if ye.stream == null or not str(ye.stream.resource_path).begins_with("res://sfx/year_change."):
		problems.append("YearEnd should stream year_change.*, got %s" % str(
			ye.stream.resource_path if ye.stream != null else "null"))
	# AttackHeavy 应该有低音调
	if abs(sfx.get_node("AttackHeavy").pitch_scale - 0.72) > 0.01:
		problems.append("AttackHeavy pitch not set")

	# 源码级检查：释放技能不再借用 mutation
	var f = File.new()
	if f.open("res://BottleManager.gd", File.READ) == OK:
		var src = f.get_as_text()
		if src.find("SFX.bottle_power.play_usual()") < 0:
			problems.append("release_power not using bottle_power")
		if src.find("SFX.mutation.play_usual()") >= 0:
			problems.append("release_power still borrowing mutation")
		f.close()

	if problems.empty():
		print("SFX CHECK OK")
	else:
		for p in problems:
			print("FAIL: " + p)
		print("SFX CHECK FAILED %d" % problems.size())
	quit()
