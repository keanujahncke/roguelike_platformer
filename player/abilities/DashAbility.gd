extends Ability
class_name DashAbility

@export var dash_speed := 500.0
@export var dash_time := 0.10
@export var max_dashes := 1

# Collision layer used for solid terrain
@export var terrain_layer := 1

var dashes_left := 0
var is_dashing := false


func setup(_player):
	dashes_left = max_dashes


func ability_process(player, _delta):
	if not unlocked:
		return

	if player.is_on_floor():
		dashes_left = max_dashes
	elif player.is_on_wall() and has_wall_jump(player):
		dashes_left = max_dashes

	if Input.is_action_just_pressed("dash") \
	and dashes_left > 0 \
	and not is_dashing:
		start_dash(player)


func start_dash(player):
	is_dashing = true
	dashes_left -= 1

	var dash_vec: Vector2 = get_dash_direction(player)

	# Safe fallback direction
	if dash_vec == Vector2.ZERO:
		dash_vec = Vector2(player.velocity.x, 0)
		if dash_vec == Vector2.ZERO:
			dash_vec = Vector2(player.facing, 0)

	player.velocity = dash_vec.normalized() * dash_speed

	var phased := false

	# Phase dash handling (safer restore)
	if has_phase_dash(player):
		player.set_collision_mask_value(terrain_layer, false)
		phased = true

	await player.get_tree().create_timer(dash_time).timeout

	if phased and is_instance_valid(player):
		player.set_collision_mask_value(terrain_layer, true)

	is_dashing = false


func get_dash_direction(player) -> Vector2:
	# Directional dash (if unlocked)
	if has_directional_dash(player):
		var x := Input.get_axis("move_left", "move_right")
		var y := Input.get_axis("move_up", "move_down")

		var dir := Vector2(x, y)

		if dir != Vector2.ZERO:
			return dir.normalized()

	# Default horizontal dash
	return Vector2(player.facing, 0)


func has_directional_dash(player) -> bool:
	if player.has_node("Abilities/DirectionalDashAbility"):
		return player.get_node("Abilities/DirectionalDashAbility").unlocked
	return false


func has_phase_dash(player) -> bool:
	if player.has_node("Abilities/PhaseDashAbility"):
		return player.get_node("Abilities/PhaseDashAbility").unlocked
	return false

func has_wall_jump(player) -> bool:
	if player.has_node("Abilities/WallJumpAbility"):
		return player.get_node("Abilities/WallJumpAbility").unlocked
	return false
