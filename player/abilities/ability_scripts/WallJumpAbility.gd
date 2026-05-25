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


func setup(_player):
	cooldown_max = wall_jump_cooldown
	cooldown_left = 0.0


func ability_process(player, delta):
	if not unlocked:
		return
		
	if cooldown_left > 0.0 and not is_wall_sliding:
		cooldown_left = max(cooldown_left - delta, 0.0)

	# Refresh grace timer while touching wall
	if player.is_on_wall() and not player.is_on_floor():
		wall_jump_grace_timer = wall_jump_grace_time
		last_wall_normal = player.get_wall_normal()

		# Wall slide / hang
		if player.velocity.y > 0 and Input.get_axis("move_left", "move_right") != 0:
			is_wall_sliding = true
			was_sliding_last_frame = true
			player.velocity.y = min(player.velocity.y, wall_slide_speed)
			
			cooldown_max = 1.0
			cooldown_left = 1.0
		else:
			is_wall_sliding = false
	else:
		is_wall_sliding = false
		wall_jump_grace_timer = max(wall_jump_grace_timer - delta, 0.0)

	# The exact frame the player stops sliding down the wall (without jumping)
	if not is_wall_sliding and was_sliding_last_frame:
		cooldown_max = wall_jump_cooldown
		cooldown_left = cooldown_max
		was_sliding_last_frame = false

	# Wall jump with grace window and cooldown check
	if wall_jump_grace_timer > 0.0 \
	and not player.is_on_floor() \
	and Input.is_action_just_pressed("jump") \
	and last_wall_normal != Vector2.ZERO \
	and (cooldown_left <= 0.0 or was_sliding_last_frame):

		player.is_doing_double_jump = false
		player.velocity.y = wall_jump_y
		player.velocity.x = last_wall_normal.x * wall_jump_x
		wall_jump_grace_timer = 0.0
		
		# Reset parameters and trigger the real countdown immediately upon jumping
		is_wall_sliding = false
		was_sliding_last_frame = false
		cooldown_max = wall_jump_cooldown
		cooldown_left = cooldown_max

		if player.jump_sfx:
			player.jump_sfx.play()
