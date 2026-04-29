extends CanvasLayer

@onready var main_menu = %MainMenu
@onready var new_game_menu = %NewGameMenu
@onready var loadout_menu = %LoadoutMenu

@onready var new_game_button = %NewGameButton
@onready var quit_game_button: Button = %QuitGameButton

@onready var new_slot_00 = %NewSlot00
@onready var new_slot_01 = %NewSlot01
@onready var new_slot_02 = %NewSlot02

@onready var start_run_button = %StartRun


func _ready() -> void:
	new_game_button.pressed.connect(show_new_game_menu)
	quit_game_button.pressed.connect(_on_quit_pressed)

	new_slot_00.pressed.connect(_on_new_game_pressed.bind(0))
	new_slot_01.pressed.connect(_on_new_game_pressed.bind(1))
	new_slot_02.pressed.connect(_on_new_game_pressed.bind(2))

	#start_run_button.pressed.connect(_on_start_run_pressed)

	if save_data.current_slot != -1: 
		save_data.load_save()
		loadout_menu.refresh() 
		show_loadout_menu()
	else:
		show_main_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not main_menu.visible:
			show_main_menu()


# ==================================================
# MENU STATES
# ==================================================

func show_main_menu() -> void:
	main_menu.visible = true
	new_game_menu.visible = false
	loadout_menu.visible = false

	new_game_button.grab_focus()


func show_new_game_menu() -> void:
	main_menu.visible = false
	new_game_menu.visible = true
	loadout_menu.visible = false

	new_slot_01.grab_focus()


func show_loadout_menu() -> void:
	main_menu.visible = false
	new_game_menu.visible = false
	loadout_menu.visible = true

	start_run_button.grab_focus()


# ==================================================
# SLOT SELECT
# ==================================================

# Inside your CanvasLayer / Main Menu script

func _on_new_game_pressed(slot: int) -> void:
	print("--- SLOT SWAP INITIATED ---")
	save_data.current_slot = slot
	
	# Wait for a frame to ensure the variable update is processed
	await get_tree().process_frame
	
	var success = save_data.load_save()
	
	if success:
		loadout_menu.refresh() 
		
		show_loadout_menu()
	else:
		printerr("Failed to load slot ", slot)


# ==================================================
# START RUN
# ==================================================

func _on_start_run_pressed() -> void:
	save_data.save()
	start_game()


func start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


# ==================================================
# QUIT
# ==================================================

func _on_quit_pressed() -> void:
	save_data.save()
	get_tree().quit()
