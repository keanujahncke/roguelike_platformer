extends CharacterBody2D
class_name Boss

signal fake_death_finished

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export var idle_animation: String = "idle"
@export var fake_death_animation: String = "death"

# This animation plays once when the laser phase starts.
# After it finishes, the boss returns to idle while the laser phase continues.
@export var laser_attack_animation: String = "laser_attack"

# Delay between boss attack animation starting and lasers beginning to spawn.
@export var laser_phase_start_delay: float = 1.0

# NEW:
# Delay after the boss room loads before the laser phase loop begins.
@export var initial_laser_start_delay: float = 5.0

# Boss physical collision.
# Keep this true if you do NOT want the boss to block/touch the player physically.
@export var disable_boss_collision: bool = true

# Boss follow settings.
@export var follow_player: bool = true

# If true, the boss remembers its starting offset from the player AFTER the room loads.
# Example: if boss starts 200px above/right of player, it keeps that same relative position.
@export var use_starting_relative_offset: bool = false

# Used only if use_starting_relative_offset is false.
@export var manual_follow_offset: Vector2 = Vector2(180.0, -120.0)

# If true, the boss snaps perfectly to the relative position.
# If false, the boss smoothly floats toward that position.
@export var snap_to_follow_position: bool = false

# Lower = slower/more sluggish. Higher = faster/tighter follow.
@export var follow_smoothing_speed: float = 2.5

# If the boss is already close enough to the target position, he will not move.
# This helps stop tiny jittery movements.
@export var follow_deadzone: float = 8.0

# If true, boss sprite flips depending on whether player is left/right.
@export var face_player: bool = true

# Turn this on if the boss is facing the wrong direction.
@export var invert_face_player_direction: bool = false

# If true, the fake death sequence waits for the death animation to finish.
# If false, the fake death sequence waits for fake_death_delay seconds instead.
@export var wait_for_fake_death_animation_to_finish: bool = true

# Only used if wait_for_fake_death_animation_to_finish is false.
@export var fake_death_delay: float = 1.5

# Small pause after boss returns to idle before continuing the trap sequence.
@export var idle_after_fake_death_delay: float = 0.25


# --- LASER ATTACK SETTINGS ---

@export var boss_laser_scene: PackedScene
@export var laser_attack_enabled: bool = false

# Time between each laser during the active laser phase.
@export var laser_interval: float = 3.0

# How long the boss keeps firing lasers before taking a break.
# With laser_interval = 3.0 and laser_phase_duration = 12.0,
# the boss will fire about 4 lasers per phase.
@export var laser_phase_duration: float = 12.0

# How long the boss waits before starting the next laser phase.
@export var laser_phase_cooldown: float = 6.0

# Prevents too many lasers from existing at the same time.
@export var max_active_lasers: int = 2

# The boss chooses from this list of clear, readable angles.
@export var laser_angle_choices_degrees: Array[float] = [
	-75.0,
	-45.0,
	-20.0,
	0.0,
	20.0,
	45.0,
	75.0
]

# Use this to make the laser visually/collision-wise longer or wider.
# Example: Vector2(1, 2) makes it twice as long if your art/collision is vertical.
@export var laser_spawn_scale: Vector2 = Vector2(1.0, 2.0)


var trap_sequence_running: bool = false
var fake_death_is_finished: bool = false

var laser_loop_running: bool = false
var laser_start_delay_running: bool = false
var active_lasers: Array[Node] = []

var last_laser_angle_index: int = -1
var laser_attack_animation_token: int = 0

var player_ref: Node2D = null
var stored_follow_offset: Vector2 = Vector2.ZERO
var follow_setup_finished: bool = false


func _ready() -> void:
	randomize()
	
	setup_boss_collision()
	play_idle()
	
	# IMPORTANT:
	# When this boss room is loaded by LevelManager, the boss may enter the tree
	# before the real player has been moved to the boss room Spawn.
	# Waiting a frame lets LevelManager finish placing the player first.
	await get_tree().process_frame
	await get_tree().physics_frame
	
	setup_follow_offset()
	
	if laser_attack_enabled:
		start_laser_phase_loop_after_delay()


func _physics_process(delta: float) -> void:
	update_follow_player(delta)


func setup_boss_collision() -> void:
	if disable_boss_collision and collision_shape != null:
		collision_shape.disabled = true


func setup_follow_offset() -> void:
	player_ref = get_tree().get_first_node_in_group("player") as Node2D
	
	if player_ref == null:
		push_warning("Boss: Could not find player for follow setup. Make sure Player is in the 'player' group.")
		stored_follow_offset = manual_follow_offset
		follow_setup_finished = true
		return
	
	if use_starting_relative_offset:
		stored_follow_offset = global_position - player_ref.global_position
	else:
		stored_follow_offset = manual_follow_offset
	
	follow_setup_finished = true
	
	print("[BOSS FOLLOW] Player found: ", player_ref.name)
	print("[BOSS FOLLOW] Stored offset: ", stored_follow_offset)


func update_follow_player(delta: float) -> void:
	if not follow_player:
		return
	
	if not follow_setup_finished:
		return
	
	if player_ref == null or not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("player") as Node2D
		
		if player_ref == null:
			return
	
	var target_position := player_ref.global_position + stored_follow_offset
	var distance_to_target := global_position.distance_to(target_position)
	
	if snap_to_follow_position:
		global_position = target_position
	else:
		if distance_to_target > follow_deadzone:
			var t := 1.0 - exp(-follow_smoothing_speed * delta)
			global_position = global_position.lerp(target_position, t)
	
	update_facing_direction()


func update_facing_direction() -> void:
	if not face_player:
		return
	
	if animated_sprite == null:
		return
	
	if player_ref == null or not is_instance_valid(player_ref):
		return
	
	var should_flip := player_ref.global_position.x < global_position.x
	
	if invert_face_player_direction:
		should_flip = not should_flip
	
	animated_sprite.flip_h = should_flip


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


func play_laser_attack_then_return_to_idle() -> void:
	if trap_sequence_running:
		return

	if animated_sprite == null:
		push_error("Boss: AnimatedSprite2D not found.")
		return

	if animated_sprite.sprite_frames == null:
		push_error("Boss: AnimatedSprite2D has no SpriteFrames assigned.")
		return

	if not animated_sprite.sprite_frames.has_animation(laser_attack_animation):
		push_warning("Boss: Laser attack animation '" + laser_attack_animation + "' does not exist.")
		return

	laser_attack_animation_token += 1
	var my_token := laser_attack_animation_token

	animated_sprite.sprite_frames.set_animation_loop(laser_attack_animation, false)
	animated_sprite.stop()
	animated_sprite.frame = 0
	animated_sprite.play(laser_attack_animation)

	await animated_sprite.animation_finished

	if trap_sequence_running:
		return

	# Only return to idle if this is still the most recent laser attack animation.
	# This prevents older awaits from interrupting newer boss animations.
	if my_token != laser_attack_animation_token:
		return

	play_idle()


func set_laser_attack_enabled(enabled: bool) -> void:
	laser_attack_enabled = enabled
	
	if laser_attack_enabled:
		start_laser_phase_loop_after_delay()
	else:
		stop_all_laser_attacks(false)


func start_laser_phase_loop_after_delay() -> void:
	if laser_loop_running:
		return
	
	if laser_start_delay_running:
		return
	
	if boss_laser_scene == null:
		push_warning("Boss: boss_laser_scene is not assigned.")
		return
	
	laser_start_delay_running = true
	
	if initial_laser_start_delay > 0.0:
		await get_tree().create_timer(initial_laser_start_delay).timeout
	
	laser_start_delay_running = false
	
	if not laser_attack_enabled:
		return
	
	if trap_sequence_running:
		return
	
	start_laser_phase_loop()


func start_laser_phase_loop() -> void:
	if laser_loop_running:
		return
	
	if boss_laser_scene == null:
		push_warning("Boss: boss_laser_scene is not assigned.")
		return
	
	laser_loop_running = true
	
	while laser_attack_enabled and not trap_sequence_running:
		await run_laser_phase()
		
		if laser_attack_enabled and not trap_sequence_running:
			await get_tree().create_timer(laser_phase_cooldown).timeout
	
	laser_loop_running = false


func run_laser_phase() -> void:
	if not laser_attack_enabled or trap_sequence_running:
		return

	# 1. Boss attack animation starts first.
	# Do not await it. It returns to idle by itself when finished.
	play_laser_attack_then_return_to_idle()

	# 2. Small delay before lasers begin.
	if laser_phase_start_delay > 0.0:
		await get_tree().create_timer(laser_phase_start_delay).timeout

	if not laser_attack_enabled or trap_sequence_running:
		return

	# 3. Laser phase continues for the full laser_phase_duration.
	var phase_elapsed := 0.0
	
	while phase_elapsed < laser_phase_duration and laser_attack_enabled and not trap_sequence_running:
		clean_active_laser_list()
		
		if active_lasers.size() < max_active_lasers:
			spawn_laser_at_locked_player_position()
		
		await get_tree().create_timer(laser_interval).timeout
		phase_elapsed += laser_interval
	
	# 4. Laser phase ends here. Cooldown happens in start_laser_phase_loop().
	# Do not force idle here because the boss animation already returns to idle
	# naturally when laser_attack finishes.


func stop_laser_loop() -> void:
	stop_all_laser_attacks(false)


func stop_all_laser_attacks(force_idle: bool = true) -> void:
	laser_attack_enabled = false
	laser_start_delay_running = false
	waiting_cleanup_for_lasers()

	# Invalidate any laser attack animation await that might later try to return to idle.
	laser_attack_animation_token += 1

	for laser in active_lasers:
		_force_remove_laser(laser)

	active_lasers.clear()

	for laser in get_tree().get_nodes_in_group("boss_lasers"):
		_force_remove_laser(laser)

	if force_idle and not trap_sequence_running:
		play_idle()


func waiting_cleanup_for_lasers() -> void:
	clean_active_laser_list()


func _force_remove_laser(laser: Node) -> void:
	if laser == null:
		return

	if not is_instance_valid(laser):
		return

	if laser.is_queued_for_deletion():
		return

	if laser.has_method("force_stop_laser"):
		laser.force_stop_laser()
	else:
		laser.queue_free()


func clean_active_laser_list() -> void:
	var cleaned: Array[Node] = []
	
	for laser in active_lasers:
		if laser != null and is_instance_valid(laser) and not laser.is_queued_for_deletion():
			cleaned.append(laser)
	
	active_lasers = cleaned


func spawn_laser_at_locked_player_position() -> void:
	if not laser_attack_enabled or trap_sequence_running:
		return

	if boss_laser_scene == null:
		push_warning("Boss: boss_laser_scene is not assigned.")
		return
	
	var player := get_tree().get_first_node_in_group("player") as Node2D
	
	if player == null:
		push_warning("Boss: Could not find player for laser attack. Make sure Player is in the 'player' group.")
		return
	
	var laser_instance := boss_laser_scene.instantiate()
	
	if laser_instance == null:
		push_warning("Boss: Failed to instantiate boss_laser_scene.")
		return
	
	var laser_parent := get_parent()
	
	if laser_parent != null:
		laser_parent.add_child(laser_instance)
	else:
		get_tree().current_scene.add_child(laser_instance)
	
	active_lasers.append(laser_instance)
	
	var locked_target_position := player.global_position
	var chosen_rotation_degrees := get_random_laser_angle_degrees()
	var chosen_rotation_radians := deg_to_rad(chosen_rotation_degrees)
	
	if laser_instance.has_method("setup_laser"):
		laser_instance.setup_laser(
			locked_target_position,
			chosen_rotation_radians,
			laser_spawn_scale
		)
	else:
		push_warning("Boss: BossLaser scene root does not have setup_laser(). Make sure boss_laser.gd is attached to the root Area2D.")
		laser_instance.global_position = locked_target_position
		laser_instance.global_rotation = chosen_rotation_radians
		laser_instance.scale = laser_spawn_scale


func get_random_laser_angle_degrees() -> float:
	if laser_angle_choices_degrees.is_empty():
		return 0.0
	
	if laser_angle_choices_degrees.size() == 1:
		last_laser_angle_index = 0
		return laser_angle_choices_degrees[0]
	
	var random_index := randi_range(0, laser_angle_choices_degrees.size() - 1)
	
	# Avoid repeating the exact same angle twice in a row.
	while random_index == last_laser_angle_index:
		random_index = randi_range(0, laser_angle_choices_degrees.size() - 1)
	
	last_laser_angle_index = random_index
	return laser_angle_choices_degrees[random_index]


func fake_death_only() -> void:
	if trap_sequence_running:
		return

	trap_sequence_running = true
	fake_death_is_finished = false
	
	# Stop laser attacks immediately and remove any existing laser/indicator.
	stop_all_laser_attacks(false)

	# Boss should not have physical collision.
	if disable_boss_collision and collision_shape != null:
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

	# Do not re-enable boss collision here.
	if disable_boss_collision and collision_shape != null:
		collision_shape.disabled = true

	await get_tree().process_frame

	if player.has_method("take_damage"):
		if "health" in player:
			player.take_damage(player.health)
		else:
			player.take_damage(9999)
		return

	push_warning("Boss: Player does not have take_damage(amount).")
