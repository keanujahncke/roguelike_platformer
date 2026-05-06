extends Area2D

enum BirdState {
	PERCHING,
	FLYING_OUT,
	FLYING_BACK
}

@export var speed := 60.0
@export var fly_distance := 160.0
@export var perch_time := 1.5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var start_position: Vector2
var target_position: Vector2
var state: BirdState = BirdState.PERCHING
var perch_timer := 0.0


func _ready():
	start_position = global_position
	target_position = start_position + Vector2.LEFT * fly_distance

	set_facing_left(true)
	play_perch()

	body_entered.connect(_on_body_entered)


func _physics_process(delta):
	match state:
		BirdState.PERCHING:
			perch_timer -= delta

			if perch_timer <= 0:
				state = BirdState.FLYING_OUT
				set_facing_left(true)
				play_fly()

		BirdState.FLYING_OUT:
			global_position = global_position.move_toward(target_position, speed * delta)

			if global_position.distance_to(target_position) < 1.0:
				global_position = target_position
				state = BirdState.FLYING_BACK

				# Turn around midair to fly right.
				set_facing_left(false)
				play_fly()

		BirdState.FLYING_BACK:
			global_position = global_position.move_toward(start_position, speed * delta)

			if global_position.distance_to(start_position) < 1.0:
				global_position = start_position

				# Stop, turn back left, then perch.
				set_facing_left(true)
				state = BirdState.PERCHING
				play_perch()


func set_facing_left(facing_left: bool):
	# Flipped opposite version from earlier.
	sprite.flip_h = not facing_left


func play_perch():
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("perch"):
		sprite.play("perch")

	perch_timer = perch_time


func play_fly():
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("fly"):
		sprite.play("fly")


func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
