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
	await portrait_clipping()
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


func portrait_clipping():
	# A bright solid portrait makes even a one-pixel leak outside the frame visible.
	var board = ColorRect.new()
	board.color = Color("183a2a")
	board.size = Vector2(1920, 1080)
	root.add_child(board)
	var image = Image.create(64, 96, false, Image.FORMAT_RGBA8)
	image.fill(Color.MAGENTA)
	var portrait_texture = ImageTexture.create_from_image(image)
	var portraits = []
	var sizes = [Vector2(80, 80), Vector2(128, 128), Vector2(200, 200), Vector2(240, 120)]
	for kind in range(2):
		for i in range(sizes.size()):
			var portrait = TextureRect.new() if kind == 0 else TextureButton.new()
			if portrait is TextureRect:
				portrait.texture = portrait_texture
			else:
				portrait.texture_normal = portrait_texture
				portrait.ignore_texture_size = true
			portrait.position = Vector2(80 + i * 400, 80 + kind * 400)
			portrait.size = Vector2(80, 80)
			var border = TextureRect.new()
			border.set_script(load("res://UI/PortraitBorder.gd"))
			border.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.add_child(border)
			board.add_child(portrait)
			border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			portrait.size = sizes[i] # Exercise resizing after the shader was installed.
			portraits.append(portrait)
			check(portrait.material is ShaderMaterial and portrait.material.shader.resource_path.ends_with("PortraitMask.gdshader"), "Portrait clips its own image")
			check(border.mouse_filter == Control.MOUSE_FILTER_IGNORE and border.material == null, "Frame remains visible and lets clicks through")
	await process_frame
	for portrait in portraits:
		var side = minf(portrait.size.x, portrait.size.y)
		check(portrait.material.get_shader_parameter("box_ratio").is_equal_approx(portrait.size / side), "Portrait mask follows container aspect and resize")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var shot = root.get_texture().get_image()
		shot.save_png("/tmp/hukum-portrait-clipping.png")
		for portrait in portraits:
			var side = minf(portrait.size.x, portrait.size.y)
			var origin = portrait.position + (portrait.size - Vector2(side, side)) / 2.0
			for uv in [Vector2(.02, .02), Vector2(.5, .02), Vector2(.98, .98), Vector2(.02, .98), Vector2(.98, .02)]:
				var pixel = shot.get_pixelv(Vector2i(origin + uv * side))
				check(pixel.is_equal_approx(board.color), "No portrait pixels outside the frame at " + str(portrait.size))
			var center = shot.get_pixelv(Vector2i(origin + Vector2(side, side) / 2.0))
			check(center.r > .95 and center.b > .95 and center.g < .05, "Portrait stays visible through the frame opening")
	board.free()
