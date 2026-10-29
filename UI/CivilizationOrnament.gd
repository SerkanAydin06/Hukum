@tool
extends Control

var emblem: Texture2D
var accent := Color.GOLD
var pattern := 0

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw():
	if size.x < 170 or size.y < 130: return
	var side = minf(250.0, minf(size.y - 48.0, size.x * 0.36))
	if emblem:
		draw_texture_rect(emblem, Rect2(Vector2(size.x - side - 28, size.y - side - 24), Vector2(side, side)), false, Color(1, 1, 1, 0.14))
		if size.x > 900:
			draw_texture_rect(emblem, Rect2((size - Vector2(side, side)) / 2, Vector2(side, side)), false, Color(1, 1, 1, 0.07))
	var ink = Color(accent, 0.28)
	# Small repeated motifs stay on the inside border, behind all text/cards.
	for x in range(36, int(size.x) - 36, 42):
		var p = Vector2(x, size.y - 14)
		match pattern:
			0: # Ottoman tulip / paired arabesque leaves
				draw_polyline(PackedVector2Array([p + Vector2(-9, 0), p + Vector2(-4, -4), p + Vector2(0, 1), p + Vector2(4, -4), p + Vector2(9, 0)]), ink, 1.0, true)
			1: # Venetian waves
				draw_arc(p + Vector2(0, 1), 8, PI, TAU, 12, ink, 1.0, true)
			2: # Byzantine meander
				draw_polyline(PackedVector2Array([p + Vector2(-10, 0), p + Vector2(-10, -5), p + Vector2(5, -5), p + Vector2(5, 2), p + Vector2(-3, 2), p + Vector2(-3, -1)]), ink, 1.0, true)
			3: # Egyptian lotus fan
				for dx in [-8, 0, 8]: draw_line(p, p + Vector2(dx, -6), ink, 1.0, true)
			4: # Steppe braid / arrowheads
				draw_polyline(PackedVector2Array([p + Vector2(-9, 0), p + Vector2(0, -5), p + Vector2(9, 0), p + Vector2(0, 3), p + Vector2(-9, 0)]), ink, 1.0, true)
			5: # Norse interlaced diamonds
				draw_polyline(PackedVector2Array([p + Vector2(-10, 0), p + Vector2(-3, -4), p + Vector2(5, 2), p + Vector2(12, -3)]), ink, 1.0, true)
				draw_polyline(PackedVector2Array([p + Vector2(-10, -3), p + Vector2(-3, 2), p + Vector2(5, -4), p + Vector2(12, 0)]), ink, 1.0, true)
