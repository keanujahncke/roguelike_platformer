extends Area2D

enum SpiderState {
	PAUSING,
	MOVING
}

@export var speed := 180.0
@export var move_distance := 45.0
@export var pause_time := 0.6
@export var start_moving_left := true

var start_position: Vector2
var left_position: Vector2
var right_position: Vector2
var target_position: Vector2

var state: SpiderState = SpiderState.PAUSING
var pause_timer := 0.0
var moving_left := true


func _ready():
	start_position = global_position
	left_position = start_position + Vector2.LEFT * move_distance
	right_position = start_position + Vector2.RIGHT * move_distance

	moving_left = start_moving_left
	target_position = left_position if moving_left else right_position

	pause_timer = pause_time

	body_entered.connect(_on_body_entered)


func _physics_process(delta):
	match state:
		SpiderState.PAUSING:
			pause_timer -= delta

			if pause_timer <= 0.0:
				state = SpiderState.MOVING

		SpiderState.MOVING:
			global_position = global_position.move_toward(target_position, speed * delta)

			if global_position.distance_to(target_position) < 1.0:
				global_position = target_position

				moving_left = not moving_left
				target_position = left_position if moving_left else right_position

				state = SpiderState.PAUSING
				pause_timer = pause_time


func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
