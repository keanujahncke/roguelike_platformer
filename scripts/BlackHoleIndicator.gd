extends Node2D
class_name BlackHoleIndicator

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var animation_name: String = "black_hole"

# Higher = faster black hole animation.
# 1.0 = normal speed
# 2.0 = twice as fast
# 3.0 = three times as fast
@export var animation_speed_scale: float = 2.0

@export var padding: Vector2 = Vector2(0, 0)

@export var stretch_to_rect: bool = true
@export var preserve_aspect_ratio: bool = false
@export var size_multiplier: Vector2 = Vector2(1.25, 1.25)

# Your black hole peaks around frame 14.
# Tile removal/reveal happens around this frame.
@export var scale_reference_frame: int = 14


func _ready() -> void:
	play_from_start()


func setup_from_rect(global_rect: Rect2) -> void:
	global_position = global_rect.get_center()

	if animated_sprite == null:
		return

	if not stretch_to_rect:
		return

	var reference_size: Vector2 = get_reference_sprite_size()

	if reference_size.x <= 0 or reference_size.y <= 0:
		return

	var target_size: Vector2 = global_rect.size + padding

	if preserve_aspect_ratio:
		var scale_factor: float = max(
			target_size.x / reference_size.x,
			target_size.y / reference_size.y
		)

		animated_sprite.scale = Vector2(scale_factor, scale_factor) * size_multiplier
	else:
		animated_sprite.scale = Vector2(
			target_size.x / reference_size.x,
			target_size.y / reference_size.y
		) * size_multiplier


func play_from_start() -> void:
	if animated_sprite == null:
		return

	animated_sprite.speed_scale = animation_speed_scale

	if animated_sprite.sprite_frames != null:
		if animated_sprite.sprite_frames.has_animation(animation_name):
			animated_sprite.animation = animation_name
			animated_sprite.sprite_frames.set_animation_loop(animation_name, false)

	animated_sprite.frame = 0
	animated_sprite.play(animation_name)


func get_animation_length() -> float:
	if animated_sprite == null:
		return 1.0

	if animated_sprite.sprite_frames == null:
		return 1.0

	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return 1.0

	var frame_count: int = animated_sprite.sprite_frames.get_frame_count(animation_name)
	var fps: float = animated_sprite.sprite_frames.get_animation_speed(animation_name)

	if frame_count <= 0 or fps <= 0:
		return 1.0

	var total_duration_units: float = 0.0

	for i: int in range(frame_count):
		var frame_duration: float = animated_sprite.sprite_frames.get_frame_duration(animation_name, i)
		total_duration_units += frame_duration

	var speed: float = max(float(animation_speed_scale), 0.01)

	return total_duration_units / fps / speed


func get_peak_time() -> float:
	if animated_sprite == null:
		return 0.5

	if animated_sprite.sprite_frames == null:
		return 0.5

	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return 0.5

	var fps: float = animated_sprite.sprite_frames.get_animation_speed(animation_name)

	if fps <= 0:
		return 0.5

	var frame_count: int = animated_sprite.sprite_frames.get_frame_count(animation_name)
	var peak_frame: int = clampi(scale_reference_frame, 0, frame_count - 1)

	var total_duration_units: float = 0.0

	for i: int in range(peak_frame):
		var frame_duration: float = animated_sprite.sprite_frames.get_frame_duration(animation_name, i)
		total_duration_units += frame_duration

	var speed: float = max(float(animation_speed_scale), 0.01)

	return total_duration_units / fps / speed


func get_reference_sprite_size() -> Vector2:
	if animated_sprite == null:
		return Vector2.ZERO

	if animated_sprite.sprite_frames == null:
		return Vector2.ZERO

	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return Vector2.ZERO

	var frame_count: int = animated_sprite.sprite_frames.get_frame_count(animation_name)

	if frame_count <= 0:
		return Vector2.ZERO

	var frame_index: int = clampi(scale_reference_frame, 0, frame_count - 1)
	var tex: Texture2D = animated_sprite.sprite_frames.get_frame_texture(animation_name, frame_index)

	if tex == null:
		return Vector2.ZERO

	return tex.get_size()
