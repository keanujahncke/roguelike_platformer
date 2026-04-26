extends CanvasLayer

@onready var pause_menu: Control = %PauseMenu

@onready var resume_game_button = %ResumeGameButton
@onready var main_menu_game_button = %MainMenuGameButton

func _ready() -> void:
	pause_menu.hide()
	get_tree().paused = false
	
	resume_game_button.pressed.connect(_on_resume_pressed)
	main_menu_game_button.pressed.connect(_on_main_menu_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # esc
		if not pause_menu.visible:
			show_pause_menu()
		else:
			hide_pause_menu()

func show_pause_menu() -> void:
	get_tree().paused = true
	pause_menu.show() 
	resume_game_button.grab_focus()

func hide_pause_menu() -> void:
	get_tree().paused = false
	pause_menu.hide()

func _on_resume_pressed() -> void:
	hide_pause_menu()

func _on_main_menu_pressed() -> void:
	save_manager.save_game()
	get_tree().paused = false 
	get_tree().change_scene_to_file("res://title_screen/title_screen.tscn")
