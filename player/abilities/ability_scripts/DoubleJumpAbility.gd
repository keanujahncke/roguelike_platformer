extends Ability
class_name DoubleJumpAbility

@export var jump_velocity := -300.0
@export var max_air_jumps := 1
@export var jump_cooldown := 1.0

var cooldown_max := 0.0
var cooldown_left := 0.0

var jumps_left := 0
var double_jump_in_progress := false


func setup(_player):
	jumps_left = max_air_jumps
	cooldown_max = jump_cooldown
	cooldown_left = 0.0
	double_jump_in_progress = false


func ability_process(player, delta):
	if not unlocked:
		return

	# Count down cooldown.
	# When cooldown finishes, refill the double jump even if airborne.
	var was_on_cooldown: bool = cooldown_left > 0.0

	if cooldown_left > 0.0:
		cooldown_left = max(cooldown_left - delta, 0.0)

	if was_on_cooldown and cooldown_left <= 0.0:
		jumps_left = max_air_jumps
		player.is_doing_double_jump = false

	# Floor still gives an immediate full reset.
	if player.is_on_floor():
		jumps_left = max_air_jumps
		cooldown_left = 0.0
		player.is_doing_double_jump = false
		double_jump_in_progress = false
		return

	if double_jump_in_progress:
		return

	# Do NOT reset jumps_left on wall.
	# Do NOT block double jump just because the player is touching a wall.
	# This prevents wall spam while still allowing double jump near walls.
	if Input.is_action_just_pressed("jump") and jumps_left > 0 and cooldown_left <= 0.0:
		jumps_left -= 1
		cooldown_left = cooldown_max
		double_jump_in_progress = true
		player.is_doing_double_jump = true
		player.play_anim("double_jump")

		# Small hover before launch.
		player.velocity.y = 0.2

		await player.get_tree().create_timer(0.08).timeout

		if is_instance_valid(player):
			if player.double_jump_sfx:
				player.double_jump_sfx.play()

			player.velocity.y = jump_velocity

		double_jump_in_progress = false
