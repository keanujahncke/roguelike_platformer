extends Area2D

@export var damage_amount: int = 9999
@export var trigger_once: bool = false

var triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if triggered and trigger_once:
		return

	if not is_player(body):
		return

	triggered = true

	if body.has_method("take_damage"):
		if "health" in body:
			body.take_damage(body.health)
		else:
			body.take_damage(damage_amount)
	else:
		push_warning("KillOnTouch: Player does not have take_damage(amount).")


func is_player(body: Node) -> bool:
	if body.is_in_group("player"):
		return true

	if body.name == "Player":
		return true

	return false
