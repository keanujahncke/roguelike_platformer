extends Area2D

signal tutorial_triggered(trigger_id: String)

@export var trigger_id := ""
@export var trigger_once := true

var already_triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if already_triggered and trigger_once:
		return

	if not body.is_in_group("player"):
		return

	already_triggered = true
	tutorial_triggered.emit(trigger_id)
