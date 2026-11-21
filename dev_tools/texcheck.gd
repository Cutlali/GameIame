extends SceneTree
func _init():
	for p in ["res://decor/tree_big.png","res://seasons/summer/decor/tree_big.png","res://seasons/autumn/decor/tree_big.png","res://seasons/winter/decor/tree_big.png"]:
		var t = load(p)
		var img = t.get_data()
		img.lock()
		var w = img.get_width(); var h = img.get_height()
		var r=0.0; var g=0.0; var b=0.0; var n=0
		for y in range(h):
			for x in range(w):
				var c = img.get_pixel(x,y)
				if c.a > 0.4:
					r+=c.r; g+=c.g; b+=c.b; n+=1
		img.unlock()
		print(p, " ", w, "x", h, " mean ", Vector3(r/n,g/n,b/n))
	quit()
