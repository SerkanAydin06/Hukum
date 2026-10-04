extends AnimatedSprite2D

@export_group("Animation")
@export var flight_animation: StringName = &"default"

@export_group("Screen Positions")
@export var start_x: float = -320.0
@export var end_x: float = 2240.0
@export var minimum_y: float = 150.0
@export var maximum_y: float = 350.0

@export_group("Flight Duration")
@export var minimum_flight_time: float = 25.0
@export var maximum_flight_time: float = 35.0

@export_group("Waiting")
@export var minimum_wait_time: float = 10.0
@export var maximum_wait_time: float = 25.0

var rng := RandomNumberGenerator.new()

var is_flying: bool = false
var wait_time_left: float = 0.0
var horizontal_speed: float = 0.0


func _ready() -> void:
	rng.randomize()

	visible = false
	animation = flight_animation
	play(flight_animation)

	# Oyun açıldığında hemen değil,
	# birkaç saniye sonra ilk sürü gelir.
	wait_time_left = rng.randf_range(2.0, 5.0)


func _process(delta: float) -> void:
	if is_flying:
		position.x += horizontal_speed * delta

		if position.x >= end_x:
			finish_flight()
	else:
		wait_time_left -= delta

		if wait_time_left <= 0.0:
			start_flight()


func start_flight() -> void:
	position.x = start_x
	position.y = rng.randf_range(
		minimum_y,
		maximum_y
	)

	var flight_duration := rng.randf_range(
		minimum_flight_time,
		maximum_flight_time
	)

	horizontal_speed = (
		(end_x - start_x)
		/ flight_duration
	)

	var frame_count := sprite_frames.get_frame_count(
		flight_animation
	)

	if frame_count > 0:
		frame = rng.randi_range(
			0,
			frame_count - 1
		)

	play(flight_animation)

	visible = true
	is_flying = true


func finish_flight() -> void:
	visible = false
	is_flying = false

	wait_time_left = rng.randf_range(
		minimum_wait_time,
		maximum_wait_time
	)
