extends AnimatableBody2D

@export var move_speed = 0.5

var move_direction = Vector2.LEFT

func _physics_process(delta):
	move_and_collide(move_direction * move_speed)

func _on_left_sensor_body_entered(body: Node2D) -> void:
	if body.is_in_group("ground"):
		move_direction = Vector2.RIGHT

func _on_right_sensor_body_entered(body: Node2D) -> void:
	if body.is_in_group("ground"):
		move_direction = Vector2.LEFT
