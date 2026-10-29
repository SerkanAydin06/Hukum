@tool
extends Control

var emblem: Texture2D

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func get_motif_rect() -> Rect2:
	var side = minf(300.0, minf(size.x - 48.0, size.y - 48.0))
	side = maxf(0.0, side)
	return Rect2((size - Vector2(side, side)) / 2.0, Vector2(side, side))

func _draw():
	if emblem == null or size.x < 170 or size.y < 130: return
	# One centered watermark, behind the content; no corner copies or ribbons.
	draw_texture_rect(emblem, get_motif_rect(), false, Color(1, 1, 1, 0.14))
