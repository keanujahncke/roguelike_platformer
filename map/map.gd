extends CanvasLayer

@export var node_scene: PackedScene
@export var room_database: RoomDatabase

# Updated references for the CanvasLayer hierarchy
@onready var lines_container = $ScrollContainer/MapContent/LinesContainer
@onready var rooms_container = $ScrollContainer/MapContent/RoomsContainer

# Find the reward UI which is now a sibling in the same CanvasLayer
@onready var level_rewards_ui = get_parent().get_node("LevelReward") 

var map_data: Array[Array]
var room_buttons = {}

func _ready() -> void:
	# Ensure the map is processed even when the game is paused
	process_mode = PROCESS_MODE_ALWAYS 
	
	if run_manager.map_data.is_empty():
		var gen = MapGenerator.new()
		run_manager.map_data = gen.generate_map() 
	
	map_data = run_manager.map_data
	_create_visuals()
	_setup_navigation()
	_grab_correct_focus()

func _create_visuals() -> void:
	# Clear old buttons to prevent stacking [cite: 4]
	for child in rooms_container.get_children():
		child.queue_free()
	room_buttons.clear()

	for floor_layer in map_data:
		for room in floor_layer:
			if room.next_rooms.is_empty() and room.type != MapNode.Type.BOSS:
				continue
				
			var btn = node_scene.instantiate()
			rooms_container.add_child(btn)
			btn.position = room.position - Vector2(16,16)
			
			var is_available = false
			if run_manager.current_map_node == null:
				if room.row == 0: is_available = true
			elif run_manager.current_map_node.next_rooms.has(room):
				is_available = true
			
			var is_completed = run_manager.completed_nodes.has(room)
			btn.setup(room, is_available, is_completed)
			btn.pressed.connect(_on_node_pressed.bind(room))
			room_buttons[room] = btn

func _on_node_pressed(room: MapNode) -> void:
	run_manager.current_map_node = room
	
	match room.type: 
		MapNode.Type.LEVEL, MapNode.Type.BOSS: 
			# 1. Filter the database using your existing logic
			var current_abilities = run_manager.get_abilities() 
			var valid_rooms: Array[RoomData] = []
			
			for room_data in room_database.rooms: 
				if level_rewards_ui._player_can_complete_room(room_data, current_abilities):
					valid_rooms.append(room_data)
			
			if not valid_rooms.is_empty():
				var chosen = valid_rooms.pick_random() 
				run_manager.next_room_to_load = chosen.scene 
				
				# 2. HIDE THE MAP
				self.hide() 
				
				# 3. CRITICAL: Unpause the tree so the new room can process
				get_tree().paused = false 
				
				# 4. Find the LevelManager and tell it to load
				var lm = get_tree().get_first_node_in_group("level_manager")
				if lm: 
					lm.load_room(chosen.scene)
				else:
					print("ERROR: Could not find LevelManager group!")


func _setup_navigation() -> void:
	for room in room_buttons:
		var btn = room_buttons[room]
		
		if not room.next_rooms.is_empty():
			# Get the first available next room in the path
			var target_node = room.next_rooms[0]
			
			if room_buttons.has(target_node):
				var target_btn = room_buttons[target_node]
				
				# Map the 'Top' neighbor to the next room in the path [cite: 5]
				btn.focus_neighbor_top = btn.get_path_to(target_btn)
				# Map the 'Bottom' neighbor back to this room [cite: 5]
				target_btn.focus_neighbor_bottom = target_btn.get_path_to(btn)
				

func _grab_correct_focus() -> void:
	# If the run just started, focus the first available room on floor 0
	if run_manager.current_map_node == null:
		for room in map_data[0]:
			if room_buttons.has(room):
				room_buttons[room].grab_focus()
				break
	else:
		# If we are in the middle of a run, focus the NEXT available room
		var current_btn = room_buttons[run_manager.current_map_node]
		if not run_manager.current_map_node.next_rooms.is_empty():
			var next_node = run_manager.current_map_node.next_rooms[0]
			room_buttons[next_node].grab_focus()
		else:
			# If at the boss, just keep focus on the boss node
			current_btn.grab_focus()
	
	# Force the lines to redraw now that focus might have changed things
	lines_container.queue_redraw()
