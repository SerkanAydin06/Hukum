extends SceneTree

var ui_theme = preload("res://UI/HukumTheme.tres")
var count := 0

func _initialize():
	call_deferred("run")

func strip_scripts(node: Node):
	for child in node.get_children(): strip_scripts(child)
	node.set_script(null)

func run():
	if DisplayServer.get_name() == "headless":
		quit()
		return
	root.size = Vector2i(1920, 1080)
	var board = ColorRect.new()
	board.color = Color("24271f")
	board.size = Vector2(1920, 1080)
	board.theme = ui_theme
	root.add_child(board)
	for scene in ["AnaOyun", "LobiPaneli", "AnaMenu", "OyuncuSlotu"]:
		var instance = load("res://" + scene + ".tscn").instantiate()
		strip_scripts(instance)
		var nodes = instance.find_children("*", "Control", true, false)
		for node in nodes:
			var framed = node is NinePatchRect and node.texture != null and node.texture.resource_path.ends_with("window.svg")
			if not framed and not node is PanelContainer and not node is Panel: continue
			if str(node.name) == "Secim": continue
			var filters = OS.get_cmdline_user_args()
			if not filters.is_empty() and not str(node.name) in filters: continue
			var panel = node.duplicate(0)
			var path = str(node.get_path()) if node.is_inside_tree() else scene + "/" + str(node.name)
			board.add_child(panel)
			panel.visible = true
			panel.modulate = Color.WHITE
			panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			panel.size = Vector2(maxf(node.size.x, node.custom_minimum_size.x), maxf(node.size.y, node.custom_minimum_size.y))
			if panel.size.x < 100: panel.size.x = 240
			if panel.size.y < 60: panel.size.y = 100
			await process_frame
			await process_frame
			panel.position = ((Vector2(1920, 1080) - panel.size) / 2).floor()
			var title = Label.new()
			title.text = path + " — " + str(panel.size)
			title.position = Vector2(32, 12)
			board.add_child(title)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/hukum-ui-panel-%02d.png" % count)
			print("UI CATALOG %02d: %s %s" % [count, path, panel.size])
			count += 1
			panel.free()
			title.free()
		instance.free()
	print("HUKUM UI CATALOG: %d panels" % count)
	quit()
