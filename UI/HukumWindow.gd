@tool
extends PanelContainer

# Black fill comes from the shared theme; draw the original gold frame above it.
func _draw():
	if has_theme_stylebox("frame", "HukumWindow"):
		draw_style_box(get_theme_stylebox("frame", "HukumWindow"), Rect2(Vector2.ZERO, size))
