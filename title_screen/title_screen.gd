extends CanvasLayer

@onready var main_menu = %MainMenu
@onready var new_game_menu = %NewGameMenu
@onready var load_game_menu = %LoadGameMenu

@onready var new_game_button = %NewGameButton
@onready var load_game_button = %LoadGameButton
@onready var quit_game_button: Button = %QuitGameButton

@onready var new_slot_01 = %NewSlot01
@onready var new_slot_02 = %NewSlot02
@onready var new_slot_03 = %NewSlot03

func _ready() -> void:
	new_game_button.pressed.connect(show_new_game_menu)
	quit_game_button.pressed.connect(_on_quit_pressed)

	
	new_slot_01.pressed.connect(_on_new_game_pressed.bind(0))
	new_slot_02.pressed.connect(_on_new_game_pressed.bind(1))
	new_slot_03.pressed.connect(_on_new_game_pressed.bind(2))
	
	show_main_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if main_menu.visible == false:
			show_main_menu()

func show_main_menu() -> void:
	main_menu.visible = true
	new_game_menu.visible = false
	new_game_button.grab_focus()

func show_new_game_menu() -> void:
	main_menu.visible = false
	new_game_menu.visible = true
	new_slot_01.grab_focus()


func _on_new_game_pressed(slot: int) -> void:
	save_manager.current_slot = slot
	save_manager.save_game() 
	start_game()

func _on_load_game_pressed(slot: int) -> void:
	save_manager.current_slot = slot
	start_game()
	
func _on_quit_pressed() -> void:
	save_manager.save_game()
	get_tree().quit()

func start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	
