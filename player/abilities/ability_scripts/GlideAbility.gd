extends Ability
class_name GlideAbility

@export var glide_fall_speed := 70.0
@export var glide_gravity := 150.0

var is_gliding := false


func ability_process(player, delta):
	if not unlocked:
		is_gliding = false
		return

	is_gliding = false

	if player.is_on_floor():
		return

	if Input.is_action_pressed("glide") and player.velocity.y > 0:
		is_gliding = true

		player.velocity.y += glide_gravity * delta
		player.velocity.y = min(player.velocity.y, glide_fall_speed)
