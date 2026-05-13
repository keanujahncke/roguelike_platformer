extends Area2D
class_name BossFakeDeathTrigger

@export var boss: Boss
@export var sword_slash_scene: PackedScene
@export var slash_target: Node2D
@export var slash_offset: Vector2 = Vector2.ZERO

@export var disable_after_trigger: bool = true

var triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return

	if not is_player(body):
		return

	triggered = true

	lock_player_controls(body)

	spawn_sword_slash()

	if boss != null:
		await boss.fake_death_then_kill_player(body)
	else:
		push_warning("BossFakeDeathTrigger: Boss is not assigned.")

	if disable_after_trigger:
		# Keep the sword-in-stone visible, but stop the trigger from firing again.
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
