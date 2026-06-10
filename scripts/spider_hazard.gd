@tool
extends Area2D

enum SpiderState {
	PAUSING,
	MOVING
}

enum SpiderFacing {
	NORMAL,
	UPSIDE_DOWN,
	LEFT_90,
	RIGHT_90
}

@export var speed := 180.0
@export var move_distance := 45.0
@export var pause_time := 0.6
@export var start_moving_left := true

@export var facing: SpiderFacing = SpiderFacing.NORMAL:
	set(value):
		facing = value
		call_deferred("_apply_facing")

var start_position: Vector2
var negative_position: Vector2
var positive_position: Vector2
var target_position: Vector2

var state: SpiderState = SpiderState.PAUSING
var pause_timer := 0.0
var moving_negative := true


func _ready():
	call_deferred("_apply_facing")

	if Engine.is_editor_hint():
		return

	start_position = global_position
	_calculate_movement_positions()

	moving_negative = start_moving_left
	target_position = negative_position if moving_negative else positive_position

	pause_timer = pause_time

	body_entered.connect(_on_body_entered)


func _physics_process(delta):
	if Engine.is_editor_hint():
		return

	match state:
		SpiderState.PAUSING:
			pause_timer -= delta

			if pause_timer <= 0.0:
				state = SpiderState.MOVING

		SpiderState.MOVING:
			global_position = global_position.move_toward(target_position, speed * delta)

			if global_position.distance_to(target_position) < 1.0:
				global_position = target_position

				moving_negative = not moving_negative
				target_position = negative_position if moving_negative else positive_position

				state = SpiderState.PAUSING
				pause_timer = pause_time


func _calculate_movement_positions():
	var axis := _get_movement_axis()

	negative_position = start_position - axis * move_distance
	positive_position = start_position + axis * move_distance


func _get_movement_axis() -> Vector2:
	match facing:
		SpiderFacing.NORMAL:
			return Vector2.RIGHT

		SpiderFacing.UPSIDE_DOWN:
			return Vector2.LEFT

		SpiderFacing.LEFT_90:
			return Vector2.UP

		SpiderFacing.RIGHT_90:
			return Vector2.DOWN

	return Vector2.RIGHT


func _apply_facing():
	if not is_inside_tree():
		return

	var sprite := get_node_or_null("Sprite2D") as Sprite2D

	if sprite == null:
		push_warning("Could not find Sprite2D child on SpiderHazard.")
		return

	match facing:
		SpiderFacing.NORMAL:
			sprite.rotation_degrees = 0

		SpiderFacing.UPSIDE_DOWN:
			sprite.rotation_degrees = 180

		SpiderFacing.LEFT_90:
			sprite.rotation_degrees = -90

		SpiderFacing.RIGHT_90:
			sprite.rotation_degrees = 90


func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
