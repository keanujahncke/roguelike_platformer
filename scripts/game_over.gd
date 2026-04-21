extends Control

func _on_button_pressed() -> void:
	# Button pressed -> Game restarts
	var level_manager = get_tree().current_scene
	level_manager.restart_game()
