extends Area2D

signal player_entered

func _on_body_entered(body):
	if body.is_in_group("player"):
		call_deferred("_emit_player_entered")

func _emit_player_entered():
	player_entered.emit()
