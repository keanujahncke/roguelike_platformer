extends CanvasLayer

@onready var main_menu = %MainMenu
@onready var new_game_menu = %NewGameMenu
@onready var loadout_menu = %LoadoutMenu

@onready var new_game_button = %NewGameButton
@onready var quit_game_button = %QuitGameButton

@onready var slot_00_load = %slot_00_load
@onready var slot_00_delete = %slot_00_delete


@onready var slot_01_load = %slot_01_load
@onready var slot_01_delete = %slot_01_delete

@onready var slot_02_load = %slot_02_load
@onready var slot_02_delete = %slot_02_delete

@onready var start_run_button = %StartRun
@onready var pointer = %Pointer



func _ready() -> void:
	# Hides Pointer
	pointer.visible = false
	
	new_game_button.pressed.connect(show_new_game_menu)
	quit_game_button.pressed.connect(_on_quit_pressed)

	# LOAD buttons
	slot_00_load.pressed.connect(_on_new_game_pressed.bind(0))
	slot_01_load.pressed.connect(_on_new_game_pressed.bind(1))
	slot_02_load.pressed.connect(_on_new_game_pressed.bind(2))

	# DELETE buttons
	slot_00_delete.pressed.connect(_on_delete_pressed.bind(0))
	slot_01_delete.pressed.connect(_on_delete_pressed.bind(1))
	slot_02_delete.pressed.connect(_on_delete_pressed.bind(2))

	start_run_button.pressed.connect(_on_start_run_pressed)

	if save_data.current_slot != -1: 
		save_data.load_save()
		loadout_menu.refresh() 
		show_loadout_menu()
	else:
		show_main_menu()
		
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

	slot_00_load.grab_focus()


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


func _on_delete_pressed(slot: int) -> void:
	print("Deleting slot ", slot)
	save_data.clear_slot(slot)


# ==================================================
# START RUN
# ==================================================

func _on_start_run_pressed() -> void:
	save_data.save()
	start_game()


func start_game() -> void:
	print("[MENU] Starting Run. Clearing old session data to force map regeneration...")
	
	# CRITICAL: Wipe the Singleton data so the next scene builds a fresh map
	run_manager.map_data = [] 
	run_manager.current_map_node = null
	run_manager.completed_nodes.clear()
	
	# Change to the game scene
	get_tree().change_scene_to_file("res://scenes/game.tscn")


# ==================================================
# QUIT
# ==================================================

func _on_quit_pressed() -> void:
	save_data.save()
	get_tree().quit()
