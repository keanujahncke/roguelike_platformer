extends CharacterBody2D

enum GuideState {
	IDLE,
	RUNNING_TO_POINT,
	REPLAYING_PLAYER
}

@export var move_speed := 120.0
@export var gravity := 1000.0

# How far behind the player the guide should copy movement.
@export var replay_delay := 0.45

# Keep this at Vector2.ZERO for now.
@export var replay_visual_offset := Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var state: GuideState = GuideState.IDLE
var target_point: Vector2 = Vector2.ZERO
var player: Node2D = null

var position_history: Array[Dictionary] = []
var replay_time := 0.0
var last_replay_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	last_replay_position = global_position
	_play_idle()


func _physics_process(delta: float) -> void:
	match state:
		GuideState.IDLE:
			_idle_physics(delta)

		GuideState.RUNNING_TO_POINT:
			_run_to_target(delta)

		GuideState.REPLAYING_PLAYER:
			_replay_player_position(delta)


func run_to_point(point: Vector2) -> void:
	target_point = point
	state = GuideState.RUNNING_TO_POINT


func follow(target_player: Node2D) -> void:
	player = target_player
	state = GuideState.REPLAYING_PLAYER

	position_history.clear()
	replay_time = 0.0
	last_replay_position = global_position


func stop_and_idle() -> void:
	state = GuideState.IDLE
	velocity.x = 0.0
	position_history.clear()
	_play_idle()


func _idle_physics(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, move_speed)

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	_play_idle()
	move_and_slide()


func _run_to_target(delta: float) -> void:
	var direction: float = signf(target_point.x - global_position.x)
	var distance_x: float = absf(target_point.x - global_position.x)

	if distance_x <= 6.0:
		velocity.x = 0.0
		state = GuideState.IDLE
		_play_idle()
		return

	velocity.x = direction * move_speed

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	_flip_sprite(direction)
	_play_run()
	move_and_slide()


func _replay_player_position(delta: float) -> void:
	if player == null:
		stop_and_idle()
		return

	replay_time += delta

	position_history.append({
		"time": replay_time,
		"position": player.global_position
	})

	var target_replay_time: float = replay_time - replay_delay

	if target_replay_time <= 0.0:
		_play_idle()
		return

	var replay_position: Vector2 = global_position
	var found_position := false

	while position_history.size() > 2 and float(position_history[1]["time"]) < target_replay_time:
		position_history.pop_front()

	for i in range(position_history.size() - 1):
		var older: Dictionary = position_history[i]
		var newer: Dictionary = position_history[i + 1]

		var older_time: float = float(older["time"])
		var newer_time: float = float(newer["time"])

		if older_time <= target_replay_time and target_replay_time <= newer_time:
			var older_position: Vector2 = older["position"]
			var newer_position: Vector2 = newer["position"]

			var time_range: float = newer_time - older_time
			var t := 0.0

			if time_range > 0.0:
				t = (target_replay_time - older_time) / time_range

			replay_position = older_position.lerp(newer_position, t)
			found_position = true
			break

	if not found_position and position_history.size() > 0:
		replay_position = position_history[0]["position"]

	replay_position += replay_visual_offset

	var movement_delta: Vector2 = replay_position - last_replay_position

	global_position = replay_position

	if movement_delta.length() > 0.5:
		_flip_sprite(movement_delta.x)
		_play_run()
	else:
		_play_idle()

	last_replay_position = global_position


func _play_idle() -> void:
	if animated_sprite == null:
		return

	if animated_sprite.sprite_frames == null:
		return

	if animated_sprite.sprite_frames.has_animation("idle"):
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")


func _play_run() -> void:
	if animated_sprite == null:
		return

	if animated_sprite.sprite_frames == null:
		return

	if animated_sprite.sprite_frames.has_animation("run"):
		if animated_sprite.animation != "run":
			animated_sprite.play("run")


func _flip_sprite(direction: float) -> void:
	if animated_sprite == null:
		return

	if direction != 0.0:
		animated_sprite.flip_h = direction < 0.0
