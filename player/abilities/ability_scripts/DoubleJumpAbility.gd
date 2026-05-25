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

	var jump_pressed: bool = Input.is_action_just_pressed("jump")

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

	# Wall jump gets priority over double jump.
	# This prevents a wall jump from also consuming double jump cooldown.
	if jump_pressed and _wall_jump_should_take_priority(player):
		return

	if jump_pressed and jumps_left > 0 and cooldown_left <= 0.0:
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


func _wall_jump_should_take_priority(player) -> bool:
	if not player.has_node("Abilities/WallJumpAbility"):
		return false

	var wall_jump = player.get_node("Abilities/WallJumpAbility")

	if not wall_jump.unlocked:
		return false

	# If WallJumpAbility already used this same jump input this frame,
	# DoubleJumpAbility should not also consume it.
	if wall_jump.consumed_jump_this_frame:
		return true

	var touching_wall: bool = player.is_on_wall() and not player.is_on_floor()

	var wall_jump_available: bool = (
		wall_jump.wall_jump_grace_timer > 0.0
		and not player.is_on_floor()
		and wall_jump.last_wall_normal != Vector2.ZERO
		and (
			wall_jump.cooldown_left <= 0.0
			or wall_jump.was_sliding_last_frame
			or not touching_wall
		)
	)

	return wall_jump_available
