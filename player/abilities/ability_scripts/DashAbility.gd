extends Ability
class_name DashAbility

@export var dash_speed := 500.0
@export var dash_time := 0.10
@export var max_dashes := 1
@export var dash_cooldown := 0.5

# Collision layer used for solid terrain
@export var terrain_layer := 1

var cooldown_max := 0.0
var cooldown_left := 0.0
var dashes_left := 0
var is_dashing := false

func setup(_player):
	dashes_left = max_dashes
	cooldown_max = dash_cooldown
	cooldown_left = 0.0

func ability_process(player, delta):
	if not unlocked:
		return
		
	# Standard cooldown countdown
	if cooldown_left > 0.0:
		cooldown_left = max(cooldown_left - delta, 0.0)

	# Reset dashes on floor or wall (if wall jump is unlocked)
	if player.is_on_floor() or (player.is_on_wall() and has_wall_jump(player)):
		dashes_left = max_dashes

	# Trigger Dash
	if Input.is_action_just_pressed("dash") \
	and dashes_left > 0 \
	and not is_dashing \
	and cooldown_left <= 0.0:
		start_dash(player)

func start_dash(player):
	is_dashing = true
	dashes_left -= 1
	
	# Set up the UI cooldown bars immediately
	cooldown_max = dash_cooldown
	cooldown_left = dash_cooldown

	var dash_vec: Vector2 = get_dash_direction(player)

	# Safe fallback direction
	if dash_vec == Vector2.ZERO:
		dash_vec = Vector2(player.facing, 0)

	player.velocity = dash_vec.normalized() * dash_speed

	# Phase dash handling
	var phased := false
	if has_phase_dash(player):
		player.set_collision_mask_value(terrain_layer, false)
		phased = true

	await player.get_tree().create_timer(dash_time).timeout

	# Restore state
	if is_instance_valid(player):
		if phased:
			player.set_collision_mask_value(terrain_layer, true)
		is_dashing = false

func get_dash_direction(player) -> Vector2:
	if has_directional_dash(player):
		var x := Input.get_axis("move_left", "move_right")
		var y := Input.get_axis("move_up", "move_down")
		var dir := Vector2(x, y)
		if dir != Vector2.ZERO:
			return dir.normalized()

	return Vector2(player.facing, 0)

# Helper checks for sub-abilities
func has_directional_dash(player) -> bool:
	var node = player.get_node_or_null("Abilities/DirectionalDashAbility")
	return node != null and node.unlocked

func has_phase_dash(player) -> bool:
	var node = player.get_node_or_null("Abilities/PhaseDashAbility")
	return node != null and node.unlocked

func has_wall_jump(player) -> bool:
	var node = player.get_node_or_null("Abilities/WallJumpAbility")
	return node != null and node.unlocked
