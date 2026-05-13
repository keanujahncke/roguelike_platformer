extends AnimatableBody2D

@export var move_distance: float = 128.0
@export var move_speed: float = 60.0

# Horizontal by default.
# x: 1, y: 0 = moves right first
# x: -1, y: 0 = moves left first
# x: 0, y: -1 = moves up first
# x: 0, y: 1 = moves down first
@export var move_direction: Vector2 = Vector2.RIGHT

@export var start_moving_forward: bool = true
@export var wait_time_at_ends: float = 0.25

var start_position: Vector2
var target_a: Vector2
var target_b: Vector2
var current_target: Vector2
var waiting: bool = false


func _ready() -> void:
	start_position = global_position

	if move_direction == Vector2.ZERO:
		move_direction = Vector2.RIGHT

	move_direction = move_direction.normalized()

	target_a = start_position
	target_b = start_position + move_direction * move_distance

	if start_moving_forward:
		current_target = target_b
	else:
		global_position = target_b
		current_target = target_a


func _physics_process(delta: float) -> void:
	if waiting:
		return

	global_position = global_position.move_toward(
		current_target,
		move_speed * delta
	)

	if global_position.distance_to(current_target) <= 0.5:
		global_position = current_target
		switch_target()


func switch_target() -> void:
	waiting = true

	await get_tree().create_timer(wait_time_at_ends).timeout

	if current_target == target_a:
		current_target = target_b
	else:
		current_target = target_a

	waiting = false
