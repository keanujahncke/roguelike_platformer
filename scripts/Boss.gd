extends CharacterBody2D
class_name Boss

signal fake_death_finished

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export var idle_animation: String = "idle"
@export var fake_death_animation: String = "death"

# If true, the fake death sequence waits for the death animation to finish.
# If false, the fake death sequence waits for fake_death_delay seconds instead.
@export var wait_for_fake_death_animation_to_finish: bool = true

# Only used if wait_for_fake_death_animation_to_finish is false.
@export var fake_death_delay: float = 1.5

# Small pause after boss returns to idle before continuing the trap sequence.
@export var idle_after_fake_death_delay: float = 0.25

var trap_sequence_running: bool = false
var fake_death_is_finished: bool = false


func _ready() -> void:
	play_idle()


func play_idle() -> void:
	if trap_sequence_running:
		return

	play_idle_forced()


func play_idle_forced() -> void:
	if animated_sprite == null:
		push_error("Boss: AnimatedSprite2D not found.")
		return

	if animated_sprite.sprite_frames == null:
		push_error("Boss: AnimatedSprite2D has no SpriteFrames assigned.")
		return

	if animated_sprite.sprite_frames.has_animation(idle_animation):
		animated_sprite.sprite_frames.set_animation_loop(idle_animation, true)
		animated_sprite.play(idle_animation)
	else:
		push_warning("Boss: Idle animation '" + idle_animation + "' does not exist.")


func fake_death_only() -> void:
	if trap_sequence_running:
		return

	trap_sequence_running = true
	fake_death_is_finished = false

	if collision_shape != null:
		collision_shape.disabled = true

	if animated_sprite == null:
		push_warning("Boss: AnimatedSprite2D not found.")
		_finish_fake_death()
		return

	if animated_sprite.sprite_frames == null:
		push_warning("Boss: AnimatedSprite2D has no SpriteFrames assigned.")
		_finish_fake_death()
		return

	if not animated_sprite.sprite_frames.has_animation(fake_death_animation):
		push_warning("Boss: Fake death animation '" + fake_death_animation + "' does not exist.")
		_finish_fake_death()
		return

	animated_sprite.sprite_frames.set_animation_loop(fake_death_animation, false)
	animated_sprite.frame = 0
	animated_sprite.play(fake_death_animation)

	if wait_for_fake_death_animation_to_finish:
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(fake_death_delay).timeout

	if collision_shape != null:
		collision_shape.disabled = false

	play_idle_forced()

	if idle_after_fake_death_delay > 0.0:
		await get_tree().create_timer(idle_after_fake_death_delay).timeout

	_finish_fake_death()


func _finish_fake_death() -> void:
	fake_death_is_finished = true
	fake_death_finished.emit()


func fake_death_then_kill_player(player: Node) -> void:
	await fake_death_only()
	await kill_player(player)


func kill_player(player: Node) -> void:
	if player == null:
		return

	if collision_shape != null:
		collision_shape.disabled = false

	await get_tree().process_frame

	if player.has_method("take_damage"):
		if "health" in player:
			player.take_damage(player.health)
		else:
			player.take_damage(9999)
		return

	push_warning("Boss: Player does not have take_damage(amount).")
