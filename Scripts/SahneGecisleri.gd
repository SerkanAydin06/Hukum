extends CanvasLayer

@export_range(0.05, 1.0, 0.01) var fade_out_duration := 0.30
@export_range(0.05, 1.0, 0.01) var fade_in_duration := 0.38
@export var fade_color := Color(0.008, 0.012, 0.020, 1.0)

var _overlay: ColorRect
var _transition_in_progress := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	_overlay = ColorRect.new()
	_overlay.name = "FadeOverlay"
	_overlay.color = Color(
		fade_color.r,
		fade_color.g,
		fade_color.b,
		0.0
	)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func go_to(scene_path: String) -> void:
	if _transition_in_progress:
		return
	if scene_path.is_empty():
		push_error("SceneTransition: Scene path is empty.")
		return

	_transition_in_progress = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	await _fade_to(1.0, fade_out_duration)

	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error(
			"SceneTransition: Scene could not be opened: %s" % scene_path
		)
		await _fade_to(0.0, fade_in_duration)
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_transition_in_progress = false
		return

	# Let the new scene complete its first layout pass while the screen is black.
	await get_tree().process_frame
	await _fade_to(0.0, fade_in_duration)

	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_in_progress = false


func reload_current_scene() -> void:
	if _transition_in_progress:
		return

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return

	go_to(current_scene.scene_file_path)


func quit_game() -> void:
	if _transition_in_progress:
		return

	_transition_in_progress = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_to(1.0, fade_out_duration)
	get_tree().quit()


func _fade_to(target_alpha: float, duration: float) -> void:
	var fade := create_tween()
	fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade.set_trans(Tween.TRANS_QUAD)
	fade.set_ease(Tween.EASE_IN_OUT)
	fade.tween_property(
		_overlay,
		"color:a",
		clampf(target_alpha, 0.0, 1.0),
		duration
	)
	await fade.finished
