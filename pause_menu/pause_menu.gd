extends CanvasLayer

@onready var pause_menu: Control = %PauseMenu

@onready var resume_game_button = %ResumeGameButton
@onready var main_menu_game_button = %MainMenuGameButton

@onready var pointer= $Pointer

func _ready() -> void:
	pause_menu.hide()
	pointer.visible = false
	get_tree().paused = false
	
	resume_game_button.pressed.connect(_on_resume_pressed)
	main_menu_game_button.pressed.connect(_on_main_menu_pressed)
	
func _process(_delta: float) -> void:
	var focused_node = get_viewport().gui_get_focus_owner()
	
	if focused_node != null and focused_node.is_visible_in_tree():
		pointer.visible = true
		var target_pos = focused_node.global_position
		var x_offset = -50 # Default distance
	
		if "slot" in focused_node.name.to_lower() or "slot" in focused_node.get_parent().name.to_lower():
			x_offset = -120 # Push it further left for the Slot menu
		elif focused_node is CheckBox:
			x_offset = -40

		var y_offset = focused_node.size.y / 2
		pointer.global_position = target_pos + Vector2(x_offset, y_offset)
		
		# Bobbing animation
		pointer.global_position.x += sin(Time.get_ticks_msec() * 0.01) * 5
	else:
		pointer.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"): # esc
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
	get_tree().paused = false 
	get_tree().change_scene_to_file("res://title_screen/title_screen.tscn")
