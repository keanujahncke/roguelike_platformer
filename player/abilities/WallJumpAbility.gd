extends Ability
class_name WallJumpAbility

@export var wall_jump_x := 260.0
@export var wall_jump_y := -300.0
@export var wall_slide_speed := 60.0

var is_wall_sliding := false


func setup(_player):
	pass


func ability_process(player, _delta):
	if not unlocked:
		is_wall_sliding = false
		return

	is_wall_sliding = false

	# Wall slide / hang
	if player.is_on_wall() \
	and not player.is_on_floor() \
	and player.velocity.y > 0:

		is_wall_sliding = true
		player.velocity.y = min(player.velocity.y, wall_slide_speed)

	# Wall jump
	if player.is_on_wall() \
	and not player.is_on_floor() \
	and Input.is_action_just_pressed("jump"):

		player.velocity.y = wall_jump_y
		player.velocity.x = player.get_wall_normal().x * wall_jump_x
