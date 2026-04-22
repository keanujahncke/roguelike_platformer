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

	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		jumps_left -= 1
		player.is_doing_double_jump = true
		player.play_anim("double_jump")

		# small hover before launch
		player.velocity.y = 0.2

		await player.get_tree().create_timer(0.08).timeout

		player.velocity.y = jump_velocity
