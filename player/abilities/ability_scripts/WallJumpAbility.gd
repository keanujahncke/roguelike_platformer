extends Ability
class_name WallJumpAbility

@export var wall_jump_x := 260.0
@export var wall_jump_y := -300.0
@export var wall_slide_speed := 60.0
@export var wall_jump_grace_time := 0.15

var is_wall_sliding := false
var wall_jump_grace_timer := 0.0
var last_wall_normal := Vector2.ZERO


func setup(_player):
	pass


func ability_process(player, delta):
	if not unlocked:
		is_wall_sliding = false
		wall_jump_grace_timer = 0.0
		last_wall_normal = Vector2.ZERO
		return

	is_wall_sliding = false

	# Refresh grace timer while touching wall
	if player.is_on_wall() and not player.is_on_floor():
		wall_jump_grace_timer = wall_jump_grace_time
		last_wall_normal = player.get_wall_normal()

		# Wall slide / hang
		if player.velocity.y > 0 and Input.get_axis("move_left", "move_right") != 0:
			is_wall_sliding = true
			player.velocity.y = min(player.velocity.y, wall_slide_speed)
		else:
			is_wall_sliding = false
	else:
		is_wall_sliding = false
		wall_jump_grace_timer = max(wall_jump_grace_timer - delta, 0.0)

	# Wall jump with grace window
	if wall_jump_grace_timer > 0.0 \
	and not player.is_on_floor() \
	and Input.is_action_just_pressed("jump") \
	and last_wall_normal != Vector2.ZERO:

		player.is_doing_double_jump = false
		player.velocity.y = wall_jump_y
		player.velocity.x = last_wall_normal.x * wall_jump_x
		wall_jump_grace_timer = 0.0
