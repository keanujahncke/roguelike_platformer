extends Ability
class_name DoubleJumpAbility

@export var jump_velocity := -300.0
@export var max_air_jumps := 1

# We keep these so the UI script doesn't throw errors, 
# but we no longer use them for logic.
var cooldown_max := 0.0
var cooldown_left := 0.0

var jumps_left := 0

func setup(_player):
	jumps_left = max_air_jumps
	cooldown_max = 0.0
	cooldown_left = 0.0

func ability_process(player, _delta):
	if not unlocked:
		return

	# Reset jumps when touching surfaces
	if player.is_on_floor() or player.is_on_wall():
		jumps_left = max_air_jumps
		player.is_doing_double_jump = false
		return

	# Wall jump priority check
	var wall_jump_available := false
	if player.has_node("Abilities/WallJumpAbility"):
		var wall_jump = player.get_node("Abilities/WallJumpAbility")
		# We check if wall jump is unlocked and within its grace period
		wall_jump_available = wall_jump.unlocked and wall_jump.wall_jump_grace_timer > 0.0

	if wall_jump_available:
		return

	# Execute Double Jump
	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		jumps_left -= 1
		player.is_doing_double_jump = true
		player.play_anim("double_jump")

		# Small hover before launch
		player.velocity.y = 0.2

		await player.get_tree().create_timer(0.08).timeout
		
		if is_instance_valid(player):
			if player.double_jump_sfx:
				player.double_jump_sfx.play()
			player.velocity.y = jump_velocity
