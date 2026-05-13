extends CharacterBody2D
class_name Boss

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export var idle_animation: String = "idle"
@export var fake_death_animation: String = "death"

# If true, player dies when the fake death animation finishes.
# If false, player dies after kill_delay seconds.
@export var kill_when_animation_finishes: bool = true

# Only used if kill_when_animation_finishes is false.
@export var kill_delay: float = 1.5

# Small pause after boss returns to idle before killing the player.
@export var idle_before_kill_delay: float = 0.25

var trap_sequence_running: bool = false


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


func fake_death_then_kill_player(player: Node) -> void:
	if trap_sequence_running:
		return

	trap_sequence_running = true

	if collision_shape != null:
		collision_shape.disabled = true

	if animated_sprite == null:
		await kill_player(player)
		return

	if animated_sprite.sprite_frames == null:
		await kill_player(player)
		return

	if not animated_sprite.sprite_frames.has_animation(fake_death_animation):
		push_warning("Boss: Fake death animation '" + fake_death_animation + "' does not exist.")
		await kill_player(player)
		return

	animated_sprite.sprite_frames.set_animation_loop(fake_death_animation, false)
	animated_sprite.frame = 0
	animated_sprite.play(fake_death_animation)

	if kill_when_animation_finishes:
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(kill_delay).timeout

	# Boss returns to idle after the fake death animation.
	if collision_shape != null:
		collision_shape.disabled = false

	play_idle_forced()

	# Optional tiny pause so the return-to-idle is readable.
	await get_tree().create_timer(idle_before_kill_delay).timeout

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
