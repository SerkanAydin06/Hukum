extends SceneTree

var failures := 0
var ui_theme = preload("res://UI/HukumTheme.tres")

class Swatch extends Control:
	var skin: StyleBox
	func _draw():
		draw_style_box(skin, Rect2(Vector2.ZERO, size))

func _initialize():
	call_deferred("run")

func check(ok: bool, message: String):
	if not ok:
		failures += 1
		push_error(message)

func run():
	# Scan authored controls as well as dynamic-menu defaults. Art selectors are
	# deliberately excluded: cards, flags, portraits, colors and terrain tiles.
	for scene in ["AnaMenu", "LobiPaneli", "AnaOyun", "KartUI", "OyuncuSlotu", "MedeniyetKart"]:
		var packed = load("res://" + scene + ".tscn")
		check(packed != null, "Scene loads: " + scene)
		var instance = packed.instantiate()
		var pending = [instance]
		while not pending.is_empty():
			var node = pending.pop_back()
			pending.append_array(node.get_children())
			if node is Button and not node is CheckButton:
				var type = str(node.theme_type_variation)
				if type.is_empty(): type = "Button"
				var skin = ui_theme.get_stylebox("normal", type)
				check(skin is StyleBoxTexture and skin.texture_margin_left == 20, "Nine-patch command: " + str(node.name))
		instance.free()
	if DisplayServer.get_name() != "headless":
		await rendered_scaling()
	print("HUKUM UI SCALING: %d failures" % failures)
	quit(1 if failures else 0)

func rendered_scaling():
	root.size = Vector2i(1920, 1080)
	var board = ColorRect.new()
	board.color = Color("10120f")
	board.size = Vector2(1920, 1080)
	board.theme = ui_theme
	root.add_child(board)
	var roles = ["Button", "HukumPrimary", "HukumDanger"]
	var states = ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]
	for row in range(3):
		for col in range(6):
			var swatch = Swatch.new()
			swatch.skin = ui_theme.get_stylebox(states[col], roles[row])
			swatch.position = Vector2(40 + col * 310, 70 + row * 110)
			swatch.size = Vector2(280, 64)
			board.add_child(swatch)
			var label = Label.new()
			label.text = str(roles[row]) + " · " + str(states[col])
			label.position = swatch.position + Vector2(0, 68)
			label.add_theme_font_size_override("font_size", 14)
			board.add_child(label)
	var sizes = [Vector2(120, 44), Vector2(260, 64), Vector2(720, 64), Vector2(640, 180)]
	var swatches = []
	for i in range(sizes.size()):
		var swatch = Swatch.new()
		swatch.skin = ui_theme.get_stylebox("normal", "Button")
		swatch.size = sizes[i]
		swatch.position = Vector2(60, 440 + i * 115)
		board.add_child(swatch)
		swatches.append(swatch)
		var text = Label.new()
		text.text = "%d × %d — SABİT KÖŞELER" % [sizes[i].x, sizes[i].y]
		text.position = swatch.position + Vector2(sizes[i].x + 25, 12)
		text.add_theme_font_size_override("font_size", 16)
		board.add_child(text)
	await process_frame
	await RenderingServer.frame_post_draw
	var shot = root.get_texture().get_image()
	shot.save_png("/tmp/hukum-ui-set.png")
	# Compare all four actual rendered corner patches across very different
	# widths AND heights: stretching the whole artwork would fail this check.
	for swatch in swatches.slice(1):
		var equal := true
		for corner in [Vector2.ZERO, Vector2(1, 0), Vector2(0, 1), Vector2.ONE]:
			var reference = swatches[0].position + (swatches[0].size - Vector2(20, 20)) * corner
			var candidate = swatch.position + (swatch.size - Vector2(20, 20)) * corner
			for y in range(20):
				for x in range(20):
					if shot.get_pixelv(Vector2i(reference) + Vector2i(x, y)) != shot.get_pixelv(Vector2i(candidate) + Vector2i(x, y)):
						equal = false
		check(equal, "Rendered corners stay identical at " + str(swatch.size))
