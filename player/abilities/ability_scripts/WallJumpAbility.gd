extends Ability
class_name WallJumpAbility

@export var wall_jump_x := 260.0
@export var wall_jump_y := -300.0
@export var wall_slide_speed := 60.0
@export var wall_jump_grace_time := 0.15

# UI Compatibility variables (No longer used for logic)
var cooldown_max := 0.0
var cooldown_left := 0.0

var is_wall_sliding := false
var wall_jump_grace_timer := 0.0
var last_wall_normal := Vector2.ZERO

# Kept so DoubleJumpAbility knows not to double-trigger on the same frame
var consumed_jump_this_frame := false

func setup(_player):
	cooldown_max = 0.0
	cooldown_left = 0.0

func ability_process(player, delta):
	consumed_jump_this_frame = false

	if not unlocked:
		is_wall_sliding = false
		wall_jump_grace_timer = 0.0
		last_wall_normal = Vector2.ZERO
		return

	# Refresh grace timer while touching wall
	if player.is_on_wall() and not player.is_on_floor():
		wall_jump_grace_timer = wall_jump_grace_time
		last_wall_normal = player.get_wall_normal()

		# Wall slide logic
		if player.velocity.y > 0 and Input.get_axis("move_left", "move_right") != 0:
			is_wall_sliding = true
			player.velocity.y = min(player.velocity.y, wall_slide_speed)
		else:
			is_wall_sliding = false
	else:
		is_wall_sliding = false
		wall_jump_grace_timer = max(wall_jump_grace_timer - delta, 0.0)

	# Wall jump execution
	if wall_jump_grace_timer > 0.0 \
	and not player.is_on_floor() \
	and Input.is_action_just_pressed("jump") \
	and last_wall_normal != Vector2.ZERO:

		consumed_jump_this_frame = true # Signals other abilities to ignore this input
		player.is_doing_double_jump = false
		
		player.velocity.y = wall_jump_y
		player.velocity.x = last_wall_normal.x * wall_jump_x
		
		wall_jump_grace_timer = 0.0
		last_wall_normal = Vector2.ZERO

		if player.jump_sfx:
			player.jump_sfx.play()
