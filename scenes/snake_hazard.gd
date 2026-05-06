extends Area2D

@export var speed := 50.0
@export var move_distance := 120.0

var start_position: Vector2
var down_position: Vector2
var moving_down := true


func _ready():
	start_position = global_position
	down_position = start_position + Vector2.DOWN * move_distance

	body_entered.connect(_on_body_entered)


func _physics_process(delta):
	if moving_down:
		global_position = global_position.move_toward(down_position, speed * delta)

		if global_position.distance_to(down_position) < 1.0:
			global_position = down_position
			moving_down = false
	else:
		global_position = global_position.move_toward(start_position, speed * delta)

		if global_position.distance_to(start_position) < 1.0:
			global_position = start_position
			moving_down = true


func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
