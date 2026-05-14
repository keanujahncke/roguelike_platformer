extends Area2D
class_name BossLaser

@export var indicator_animation: String = "indicator"
@export var laser_animation: String = "laser"
@export var damage_amount: int = 1

# Extra warning time after the indicator animation finishes.
@export var extra_indicator_hold_time: float = 0.25

# Hurtbox timing during the laser animation.
# Damage starts this many seconds after the laser animation begins.
@export var hurtbox_start_delay: float = 0.3

# Damage ends this many seconds before the laser animation ends.
@export var hurtbox_end_early: float = 0.3

# Delay before the laser SFX plays after the laser animation starts.
@export var laser_sfx_delay: float = 0.15

# Backup values if animation duration cannot be calculated cleanly.
@export var fallback_indicator_time: float = 1.0
@export var fallback_laser_time: float = 1.9

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var laser_sfx: AudioStreamPlayer2D = $LaserSFX

var is_active: bool = false
var has_hit_player: bool = false
var sequence_started: bool = false
var current_phase: String = ""


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	disable_hurtbox()


func setup_laser(target_position: Vector2, laser_rotation: float, laser_scale: Vector2 = Vector2.ONE) -> void:
	global_position = target_position
	global_rotation = laser_rotation
	scale = laser_scale

	start_laser_sequence()


func start_laser_sequence() -> void:
	if sequence_started:
		return

	sequence_started = true
	current_phase = "indicator"
	is_active = false
	has_hit_player = false
	disable_hurtbox()

	if animated_sprite == null:
		push_warning("BossLaser: AnimatedSprite2D is missing.")
		queue_free()
		return

	if animated_sprite.sprite_frames == null:
		push_warning("BossLaser: AnimatedSprite2D has no SpriteFrames assigned.")
		queue_free()
		return

	if not animated_sprite.sprite_frames.has_animation(indicator_animation):
		push_warning("BossLaser: Missing indicator animation: " + indicator_animation)
		queue_free()
		return

	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)

	animated_sprite.stop()
	animated_sprite.frame = 0
	animated_sprite.play(indicator_animation)

	start_indicator_backup_timer()


func start_indicator_backup_timer() -> void:
	var duration := get_animation_duration(indicator_animation, fallback_indicator_time)

	await get_tree().create_timer(duration + 0.1).timeout

	if not is_instance_valid(self):
		return

	if current_phase == "indicator":
		begin_indicator_hold()


func _on_animation_finished() -> void:
	if current_phase == "indicator":
		begin_indicator_hold()
	elif current_phase == "laser":
		end_laser()


func begin_indicator_hold() -> void:
	if current_phase != "indicator":
		return

	current_phase = "indicator_hold"

	if extra_indicator_hold_time > 0.0:
		await get_tree().create_timer(extra_indicator_hold_time).timeout

	if not is_instance_valid(self):
		return

	if current_phase == "indicator_hold":
		start_actual_laser()


func start_actual_laser() -> void:
	if current_phase != "indicator_hold":
		return

	current_phase = "laser"
	is_active = false
	has_hit_player = false
	disable_hurtbox()

	if animated_sprite == null or animated_sprite.sprite_frames == null:
		end_laser()
		return

	if not animated_sprite.sprite_frames.has_animation(laser_animation):
		push_warning("BossLaser: Missing laser animation: " + laser_animation)
		end_laser()
		return

	animated_sprite.stop()
	animated_sprite.frame = 0
	animated_sprite.play(laser_animation)

	play_laser_sfx_after_delay()
	start_laser_hurtbox_window()


func play_laser_sfx_after_delay() -> void:
	if laser_sfx_delay > 0.0:
		await get_tree().create_timer(laser_sfx_delay).timeout

	if not is_instance_valid(self):
		return

	if current_phase != "laser":
		return

	play_laser_sfx()


func start_laser_hurtbox_window() -> void:
	var laser_duration := get_animation_duration(laser_animation, fallback_laser_time)

	var start_delay := hurtbox_start_delay
	var active_duration := laser_duration - hurtbox_start_delay - hurtbox_end_early

	# Safety: if the animation is too short for the chosen timing,
	# use the middle half of the animation as the damage window.
	if active_duration <= 0.0:
		start_delay = laser_duration * 0.25
		active_duration = laser_duration * 0.5

	await get_tree().create_timer(start_delay).timeout

	if not is_instance_valid(self):
		return

	if current_phase != "laser":
		return

	enable_hurtbox()
	check_overlapping_bodies_for_damage()

	await get_tree().create_timer(active_duration).timeout

	if not is_instance_valid(self):
		return

	if current_phase == "laser":
		disable_hurtbox()


func play_laser_sfx() -> void:
	if laser_sfx == null:
		return

	if laser_sfx.stream == null:
		return

	laser_sfx.stop()
	laser_sfx.play()


func enable_hurtbox() -> void:
	is_active = true

	if collision_shape != null:
		collision_shape.disabled = false


func disable_hurtbox() -> void:
	is_active = false

	if collision_shape != null:
		collision_shape.disabled = true


func end_laser() -> void:
	if current_phase == "done":
		return

	current_phase = "done"
	disable_hurtbox()
	queue_free()


func get_animation_duration(animation_name: String, fallback_time: float) -> float:
	if animated_sprite == null:
		return fallback_time

	if animated_sprite.sprite_frames == null:
		return fallback_time

	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return fallback_time

	var frame_count := animated_sprite.sprite_frames.get_frame_count(animation_name)
	var animation_speed := animated_sprite.sprite_frames.get_animation_speed(animation_name)

	if frame_count <= 0 or animation_speed <= 0.0:
		return fallback_time

	var total_frame_duration := 0.0

	for i in frame_count:
		total_frame_duration += animated_sprite.sprite_frames.get_frame_duration(animation_name, i)

	return total_frame_duration / animation_speed


func check_overlapping_bodies_for_damage() -> void:
	if not is_active:
		return

	for body in get_overlapping_bodies():
		try_damage_body(body)


func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return

	try_damage_body(body)


func try_damage_body(body: Node) -> void:
	if has_hit_player:
		return

	if body == null:
		return

	if not body.is_in_group("player") and body.name != "Player":
		return

	has_hit_player = true

	if body.has_method("take_damage"):
		body.take_damage(damage_amount)
	else:
		push_warning("BossLaser: Player does not have take_damage(amount).")
