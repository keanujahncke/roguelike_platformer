extends Ability
class_name WallJumpAbility

@export var wall_jump_x := 260.0
@export var wall_jump_y := -300.0
@export var wall_slide_speed := 60.0
@export var wall_jump_grace_time := 0.15
@export var wall_jump_cooldown := 0.5

var cooldown_max := 0.0
var cooldown_left := 0.0

var is_wall_sliding := false
var was_sliding_last_frame := false
var wall_jump_grace_timer := 0.0
var last_wall_normal := Vector2.ZERO

# Used so DoubleJumpAbility knows not to consume the same jump input.
var consumed_jump_this_frame := false


func setup(_player):
	cooldown_max = wall_jump_cooldown
	cooldown_left = 0.0


func ability_process(player, delta):
	consumed_jump_this_frame = false

	if not unlocked:
		return

	if cooldown_left > 0.0 and not is_wall_sliding:
		cooldown_left = max(cooldown_left - delta, 0.0)

	var touching_wall: bool = player.is_on_wall() and not player.is_on_floor()
	var jump_pressed: bool = Input.is_action_just_pressed("jump")

	# Refresh grace timer while touching a wall.
	if touching_wall:
		wall_jump_grace_timer = wall_jump_grace_time
		last_wall_normal = player.get_wall_normal()

		# Wall slide / hang.
		if player.velocity.y > 0.0 and Input.get_axis("move_left", "move_right") != 0.0:
			is_wall_sliding = true
			was_sliding_last_frame = true
			player.velocity.y = min(player.velocity.y, wall_slide_speed)

			# While actively sliding, keep this high so the player cannot
			# spam repeated wall jumps instantly while sticking to the wall.
			# The current slide jump is still allowed through was_sliding_last_frame.
			cooldown_max = 1.0
			cooldown_left = 1.0
		else:
			is_wall_sliding = false
	else:
		is_wall_sliding = false
		wall_jump_grace_timer = max(wall_jump_grace_timer - delta, 0.0)

	# Wall jump with grace window and cooldown check.
	# Important: this happens before clearing was_sliding_last_frame.
	var can_wall_jump: bool = (
		wall_jump_grace_timer > 0.0
		and not player.is_on_floor()
		and jump_pressed
		and last_wall_normal != Vector2.ZERO
		and (
			cooldown_left <= 0.0
			or was_sliding_last_frame
			or not touching_wall
		)
	)

	if can_wall_jump:
		consumed_jump_this_frame = true

		player.is_doing_double_jump = false

		player.velocity.y = wall_jump_y
		player.velocity.x = last_wall_normal.x * wall_jump_x

		wall_jump_grace_timer = 0.0
		last_wall_normal = Vector2.ZERO

		is_wall_sliding = false
		was_sliding_last_frame = false

		cooldown_max = wall_jump_cooldown
		cooldown_left = cooldown_max

		if player.jump_sfx:
			player.jump_sfx.play()

		return

	# The exact frame the player stops sliding down the wall without jumping.
	# This happens after the wall jump check so it does not kill grace jumps.
	if not is_wall_sliding and was_sliding_last_frame:
		cooldown_max = wall_jump_cooldown
		cooldown_left = cooldown_max
		was_sliding_last_frame = false
