extends Ability
class_name DoubleJumpAbility

@export var jump_velocity := -300.0
@export var max_air_jumps := 1

var jumps_left := 0


func setup(_player):
	jumps_left = max_air_jumps


func ability_process(player, _delta):
	if not unlocked:
		return

	# Reset on floor / wall
	if player.is_on_floor() or player.is_on_wall():
		jumps_left = max_air_jumps
		player.is_doing_double_jump = false
		return

	# Wall jump gets priority over double jump
	var wall_jump_available := false

	if player.has_node("Abilities/WallJumpAbility"):
		var wall_jump = player.get_node("Abilities/WallJumpAbility")
		wall_jump_available = wall_jump.unlocked and wall_jump.wall_jump_grace_timer > 0.0

	if wall_jump_available:
		return

	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		jumps_left -= 1
		player.is_doing_double_jump = true
		player.play_anim("double_jump")

		# small hover before launch
		player.velocity.y = 0.2

		await player.get_tree().create_timer(0.08).timeout
		
		player.double_jump_sfx.play()
		player.velocity.y = jump_velocity
