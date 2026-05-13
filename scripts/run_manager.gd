extends Node

var current_run_abilities: Array = []
var map_data: Array[Array] = [] # Stores generated floors [cite: 23]
var current_map_node: MapNode = null # Tracks player position [cite: 23]
var completed_nodes: Array[MapNode] = [] # Tracks progress [cite: 23]
var next_room_to_load: PackedScene = null # The room selected from map [cite: 24]

func start_new_run():
	current_run_abilities = save_data.get_selected_starting_abilities().duplicate() 
	map_data = [] 
	current_map_node = null
	completed_nodes = []
	next_room_to_load = null
	print("Run Started! Initial Abilities: ", current_run_abilities)

func add_ability(id: String):
	if not current_run_abilities.has(id):
		current_run_abilities.append(id)
		print("Run Ability Added: ", id)

func get_abilities() -> Array:
	return current_run_abilities
