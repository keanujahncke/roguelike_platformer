extends Area2D
class_name BossFakeDeathTrigger

@export var boss: Boss
@export var sword_slash_scene: PackedScene
@export var slash_target: Node2D
@export var slash_offset: Vector2 = Vector2.ZERO

@export var boss_camera_target: Marker2D

# Optional. If assigned, camera pans back to this marker before reattaching.
# If not assigned, camera pans back to the exact original camera position from before the pan.
@export var camera_return_target: Marker2D

@export var pan_to_boss_time: float = 1.25
@export var hold_on_boss_before_slash_time: float = 0.15
@export var pan_back_to_original_time: float = 1.0
@export var hold_before_player_death_time: float = 0.15

@export var disable_after_trigger: bool = true

var triggered: bool = false

var detached_camera: Camera2D = null
var camera_old_parent: Node = null
var camera_old_local_position: Vector2 = Vector2.ZERO
var camera_old_global_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return

	if not is_player(body):
		return

	triggered = true

	lock_player_controls(body)

	# 1. Camera pans down to boss FIRST.
	await pan_camera_to_boss(body)

	if hold_on_boss_before_slash_time > 0.0:
		await get_tree().create_timer(hold_on_boss_before_slash_time).timeout

	# 2. Sword slash and boss death animation start at the same time.
	spawn_sword_slash()
	start_boss_fake_death_immediately()

	# 3. Wait for boss death animation to fully finish.
	if boss != null and not boss.fake_death_is_finished:
		await boss.fake_death_finished

	# 4. Pan back to where the camera originally was.
	await pan_camera_back_to_original_position(body)

	# 5. Reattach camera to the player.
	reattach_camera_to_original_parent()

	if hold_before_player_death_time > 0.0:
		await get_tree().create_timer(hold_before_player_death_time).timeout

	# 6. Only now does the player death / life loss happen.
	if boss != null:
		await boss.kill_player(body)
	else:
		push_warning("BossFakeDeathTrigger: Boss is not assigned, so player was not killed.")

	if disable_after_trigger:
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)


func is_player(body: Node) -> bool:
	if body.is_in_group("player"):
		return true

	if body.name == "Player":
		return true

	return false


func lock_player_controls(player: Node) -> void:
	if player.has_method("set_controls_locked"):
		player.set_controls_locked(true)
	else:
		push_warning("BossFakeDeathTrigger: Player does not have set_controls_locked(locked).")


func spawn_sword_slash() -> void:
	if sword_slash_scene == null:
		push_warning("BossFakeDeathTrigger: Sword slash scene is not assigned.")
		return

	var slash: Node2D = sword_slash_scene.instantiate()
	get_tree().current_scene.add_child(slash)

	if slash_target != null:
		slash.global_position = slash_target.global_position + slash_offset
	elif boss != null:
		slash.global_position = boss.global_position + slash_offset
	else:
		slash.global_position = global_position + slash_offset


func start_boss_fake_death_immediately() -> void:
	if boss == null:
		push_warning("BossFakeDeathTrigger: Boss is not assigned.")
		return

	# Do not await this here.
	# This starts the boss death animation at the same time as the sword slash.
	boss.fake_death_only()


func pan_camera_to_boss(player: Node2D) -> void:
	if boss_camera_target == null:
		push_warning("BossFakeDeathTrigger: Boss camera target is not assigned.")
		return

	var camera := get_viewport().get_camera_2d()

	if camera == null:
		push_warning("BossFakeDeathTrigger: Could not find active Camera2D.")
		return

	detached_camera = camera
	camera_old_parent = camera.get_parent()
	camera_old_local_position = camera.position
	camera_old_global_position = camera.global_position

	if camera_old_parent == null:
		push_warning("BossFakeDeathTrigger: Camera has no parent.")
		return

	# Detach camera from player so it can move independently.
	camera_old_parent.remove_child(camera)
	get_tree().current_scene.add_child(camera)

	camera.global_position = camera_old_global_position
	camera.make_current()

	var tween := create_tween()
	tween.tween_property(camera, "global_position", boss_camera_target.global_position, pan_to_boss_time)

	await tween.finished


func pan_camera_back_to_original_position(player: Node2D) -> void:
	if detached_camera == null:
		push_warning("BossFakeDeathTrigger: No detached camera to pan back.")
		return

	var camera := detached_camera
	var return_position := get_camera_return_position(player)

	var tween := create_tween()
	tween.tween_property(camera, "global_position", return_position, pan_back_to_original_time)

	await tween.finished


func get_camera_return_position(player: Node2D) -> Vector2:
	if camera_return_target != null:
		return camera_return_target.global_position

	return camera_old_global_position


func reattach_camera_to_original_parent() -> void:
	if detached_camera == null:
		return

	if camera_old_parent == null:
		push_warning("BossFakeDeathTrigger: Camera old parent is null, cannot reattach.")
		return

	var camera := detached_camera

	if camera.get_parent() != null:
		camera.get_parent().remove_child(camera)

	camera_old_parent.add_child(camera)
	camera.position = camera_old_local_position
	camera.make_current()

	detached_camera = null
	camera_old_parent = null
	camera_old_local_position = Vector2.ZERO
	camera_old_global_position = Vector2.ZERO
