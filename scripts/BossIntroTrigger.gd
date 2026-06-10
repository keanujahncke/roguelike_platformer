extends Area2D
class_name BossIntroTrigger

@export var boss: Boss

@export var trigger_once := true
@export var lock_player_during_intro := true

# How long the player stays locked before the throne intro animation resumes.
@export var delay_before_boss_gets_up := 3.0


# --- RESPAWN CHECKPOINT ---

# If true, reaching this trigger updates the room Spawn location.
@export var update_respawn_point_on_trigger: bool = true

# Assign this to a Marker2D in the throne room.
# Example: ThroneRespawnPoint
@export var respawn_point: Node2D

# Usually your room spawn node is named "Spawn".
@export var room_spawn_node_name: String = "Spawn"


var triggered := false


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not is_player(body):
		return

	await start_intro_for_player(body)


func start_intro_for_player(player: Node2D) -> void:
	if triggered and trigger_once:
		return

	if player == null:
		return

	triggered = true

	print("BossIntroTrigger: Boss intro started.")

	if update_respawn_point_on_trigger:
		set_room_respawn_point(player)

	if lock_player_during_intro:
		lock_player_with_gravity(player, true)

	if delay_before_boss_gets_up > 0.0:
		await get_tree().create_timer(delay_before_boss_gets_up).timeout

	if boss != null:
		await boss.play_intro_then_activate_boss_encounter()
	else:
		push_warning("BossIntroTrigger: Boss is not assigned.")

	if lock_player_during_intro:
		lock_player_with_gravity(player, false)

	if trigger_once:
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)

	print("BossIntroTrigger: Boss encounter started.")


func set_room_respawn_point(player: Node) -> void:
	if respawn_point == null:
		push_warning("BossIntroTrigger: Respawn Point is not assigned.")
		return

	if player == null:
		return

	var room: Node = null

	if "current_room" in player:
		room = player.current_room

	if room == null:
		room = get_parent()

	if room == null:
		push_warning("BossIntroTrigger: Could not find current room.")
		return

	if not room.has_node(room_spawn_node_name):
		push_warning("BossIntroTrigger: Room does not have a '" + room_spawn_node_name + "' node.")
		return

	var spawn_node := room.get_node(room_spawn_node_name) as Node2D

	if spawn_node == null:
		push_warning("BossIntroTrigger: Spawn node is not a Node2D.")
		return

	spawn_node.global_position = respawn_point.global_position

	print("BossIntroTrigger: Respawn point updated to throne room.")


func lock_player_with_gravity(player: Node, locked: bool) -> void:
	if player == null:
		return

	if player.has_method("set_controls_locked"):
		# Second argument = allow gravity while locked.
		player.set_controls_locked(locked, true)
	else:
		push_warning("BossIntroTrigger: Player does not have set_controls_locked(locked, allow_gravity).")


func is_player(body: Node) -> bool:
	if body == null:
		return false

	if body.is_in_group("player"):
		return true

	if body.name == "Player":
		return true

	return false
