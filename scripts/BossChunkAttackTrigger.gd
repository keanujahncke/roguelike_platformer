extends Area2D
class_name BossChunkAttackTrigger

@export var area_manipulator: AreaManipulator

@export var trigger_once := true

# Optional delay after player passes through trigger before chunk attacks begin.
@export var delay_before_chunk_attacks := 0.0

var triggered := false


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if triggered and trigger_once:
		return

	if not is_player(body):
		return

	triggered = true

	print("BossChunkAttackTrigger: Player entered chunk attack trigger.")

	if delay_before_chunk_attacks > 0.0:
		await get_tree().create_timer(delay_before_chunk_attacks).timeout

	if area_manipulator != null:
		area_manipulator.activate_attacks()
	else:
		push_warning("BossChunkAttackTrigger: AreaManipulator is not assigned.")

	if trigger_once:
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)

	print("BossChunkAttackTrigger: Chunk attacks started.")


func is_player(body: Node) -> bool:
	if body == null:
		return false

	if body.is_in_group("player"):
		return true

	if body.name == "Player":
		return true

	return false
