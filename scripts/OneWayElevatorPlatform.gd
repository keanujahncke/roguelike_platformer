extends AnimatableBody2D
class_name OneWayElevatorPlatform

@export var move_distance: float = 240.0
@export var move_speed: float = 80.0

# For upward movement, keep this as Vector2.UP.
@export var move_direction: Vector2 = Vector2.UP

# If true, elevator starts only when player touches TriggerArea.
# If false, elevator starts immediately when room loads.
@export var wait_for_player_trigger: bool = true

# Delay after player touches the elevator before it starts moving.
@export var start_delay: float = 0.25

# If true, the platform never comes back down.
@export var stay_at_top: bool = true

# If true, the player can only trigger it once.
@export var trigger_once: bool = true


# --- PLAYER LOCK / POSITIONING ---

# If true, player gets pulled to PlayerCenter before elevator rises.
@export var force_player_to_center: bool = true

# Assign this to a Marker2D placed where the player should stand.
# If left empty, the script will try to find a child named PlayerCenter.
@export var player_center_marker: Node2D

# Extra offset from PlayerCenter.
@export var player_center_offset: Vector2 = Vector2.ZERO

# How long it takes to slide the player into the center.
@export var center_player_duration: float = 0.35

# -1 = face left
#  1 = face right
#  0 = do not force facing
@export var forced_player_facing_direction: int = -1

# If true, player remains locked until elevator reaches the top.
@export var lock_player_until_top: bool = true


# --- BOSS INTRO HANDOFF ---

# Assign your BossIntroTrigger here if the elevator should start the boss intro
# when it reaches the top.
@export var boss_intro_trigger: BossIntroTrigger

# If true, the elevator starts the boss intro once it reaches the top.
# The boss intro trigger will handle unlocking the player afterward.
@export var start_boss_intro_when_reaching_top: bool = false


var start_position: Vector2
var target_position: Vector2

var moving: bool = false
var finished: bool = false
var triggered: bool = false

var locked_player: Node2D = null

@onready var trigger_area: Area2D = $TriggerArea


func _ready() -> void:
	start_position = global_position

	if move_direction == Vector2.ZERO:
		move_direction = Vector2.UP

	move_direction = move_direction.normalized()
	target_position = start_position + move_direction * move_distance

	if player_center_marker == null and has_node("PlayerCenter"):
		player_center_marker = $PlayerCenter

	if trigger_area != null:
		if not trigger_area.body_entered.is_connected(_on_trigger_area_body_entered):
			trigger_area.body_entered.connect(_on_trigger_area_body_entered)
	else:
		push_warning("OneWayElevatorPlatform: Missing TriggerArea child.")

	if not wait_for_player_trigger:
		start_elevator(null)


func _physics_process(delta: float) -> void:
	if not moving:
		return

	global_position = global_position.move_toward(
		target_position,
		move_speed * delta
	)

	if global_position.distance_to(target_position) <= 0.5:
		global_position = target_position
		moving = false
		finished = true

		await handle_reached_top()

		if stay_at_top:
			set_physics_process(false)

		print("Elevator reached top.")


func _on_trigger_area_body_entered(body: Node2D) -> void:
	if finished:
		return

	if triggered and trigger_once:
		return

	if not is_player(body):
		return

	triggered = true
	start_elevator(body)


func start_elevator(player: Node2D) -> void:
	if moving:
		return

	if finished:
		return

	if player != null:
		locked_player = player

		if lock_player_until_top:
			lock_player_with_gravity(locked_player, true)

		if force_player_to_center:
			await move_player_to_platform_center(locked_player)

		force_player_facing(locked_player)

	if start_delay > 0.0:
		await get_tree().create_timer(start_delay).timeout

	if finished:
		return

	moving = true
	print("Elevator started.")


func handle_reached_top() -> void:
	if start_boss_intro_when_reaching_top and boss_intro_trigger != null and locked_player != null:
		if is_instance_valid(locked_player):
			# Do not unlock here. BossIntroTrigger will unlock after the boss intro.
			await boss_intro_trigger.start_intro_for_player(locked_player)
			locked_player = null
			return

	unlock_player()


func move_player_to_platform_center(player: Node2D) -> void:
	if player == null:
		return

	var center_position: Vector2 = get_player_center_position()
	var target_x: float = center_position.x
	var start_x: float = player.global_position.x

	if center_player_duration <= 0.0:
		player.global_position.x = target_x
		return

	var elapsed: float = 0.0

	while elapsed < center_player_duration:
		if player == null or not is_instance_valid(player):
			return

		var frame_delta: float = get_process_delta_time()
		elapsed += frame_delta

		var t: float = clampf(elapsed / center_player_duration, 0.0, 1.0)

		player.global_position.x = lerp(start_x, target_x, t)

		await get_tree().process_frame

	if player != null and is_instance_valid(player):
		player.global_position.x = target_x


func get_player_center_position() -> Vector2:
	if player_center_marker != null:
		return player_center_marker.global_position + player_center_offset

	# Fallback only.
	# If this pulls the player wrong, add/assign PlayerCenter.
	return global_position + player_center_offset


func force_player_facing(player: Node) -> void:
	if player == null:
		return

	if forced_player_facing_direction == 0:
		return

	var direction: int = 1

	if forced_player_facing_direction < 0:
		direction = -1

	if "facing" in player:
		player.facing = direction

	if player.has_node("AnimatedSprite2D"):
		var sprite: AnimatedSprite2D = player.get_node("AnimatedSprite2D") as AnimatedSprite2D

		if sprite != null:
			sprite.flip_h = direction < 0


func lock_player_with_gravity(player: Node, locked: bool) -> void:
	if player == null:
		return

	if player.has_method("set_controls_locked"):
		# Second argument = allow gravity while locked.
		player.set_controls_locked(locked, true)
	else:
		push_warning("OneWayElevatorPlatform: Player does not have set_controls_locked(locked, allow_gravity).")


func unlock_player() -> void:
	if locked_player == null:
		return

	if not is_instance_valid(locked_player):
		locked_player = null
		return

	if lock_player_until_top:
		lock_player_with_gravity(locked_player, false)

	locked_player = null


func is_player(body: Node) -> bool:
	if body == null:
		return false

	if body.is_in_group("player"):
		return true

	if body.name == "Player":
		return true

	return false
