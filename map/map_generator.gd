class_name MapGenerator
extends Node


const X_DIST := 160
const Y_DIST := 140
const PLACEMENT_RANDOMNESS := 35
const FLOORS := 10
const MAP_WIDTH := 5
const PATHS := 5
const LEVEL_NODE_WEIGHT := 10.0
const UPGRADE_NODE_WEIGHT := 4.0
const HEAL_NODE_WEIGHT := 4.0

var random_room_type_weights = {
	MapNode.Type.LEVEL: 0.0,
	MapNode.Type.HEAL: 0.0,
	MapNode.Type.UPGRADE: 0.0
}

var random_room_type_total_weight := 0
var map_data: Array[Array]

#func _ready() -> void:
	#generate_map()


func generate_map() -> Array[Array]:
	map_data = _generate_initial_grid()
	var starting_points := _get_random_starting_points()
	
	for j in starting_points:
		var current_j := j
		for i in FLOORS - 1:
			current_j = _setup_connection(i, current_j)
	
	_setup_boss_room()
	_setup_random_room_weights()
	_setup_room_types()
	
	#var i := 0
	#for floor in map_data:
		#print("floor %s" % i)
		#var used_rooms = floor.filter(
			#func(room: MapNode): return room.next_rooms.size() > 0
		#)
		#print(used_rooms)
		#i += 1
	
	return map_data
	

func _generate_initial_grid() -> Array[Array]:
	var result: Array[Array] = []
	var total_map_width := (MAP_WIDTH - 1) * X_DIST
	var start_x_padding := (1152 - total_map_width) / 2.0
	
	for i in FLOORS:
		var adjacent_rooms: Array[MapNode] = []
		
		for j in MAP_WIDTH:
			var current_room := MapNode.new()
			var offset := Vector2(randf(), randf() * PLACEMENT_RANDOMNESS)
			
			current_room.position = Vector2(start_x_padding + (j * X_DIST), i * -Y_DIST) + offset
			current_room.row = i
			current_room.column = j
			current_room.next_rooms = []
			
			if i == FLOORS - 1:
				current_room.position.y = (i + 1) * -Y_DIST
			
			adjacent_rooms.append(current_room)
			
		result.append(adjacent_rooms)
		
	return result

func _get_random_starting_points() -> Array[int]:
	var y_coordinates: Array[int]
	var unique_points: int = 0
	
	while unique_points < 2:
		unique_points = 0
		y_coordinates = []
		
		for i in PATHS:
			var starting_point := randi_range(0, MAP_WIDTH - 1)
			if not y_coordinates.has(starting_point):
				unique_points += 1
			
			y_coordinates.append(starting_point)
		
	return y_coordinates

func _setup_connection(i: int, j:int) -> int:
	var next_room: MapNode
	var current_room := map_data[i][j] as MapNode
	
	while not next_room or _would_cross_existing_path(i, j, next_room):
		var random_j := clampi(randi_range(j-1, j+1), 0, MAP_WIDTH - 1)
		next_room = map_data[i + 1][random_j]
	current_room.next_rooms.append(next_room)
	
	return next_room.column

func _would_cross_existing_path(i: int, j: int, room: MapNode) -> bool:
	var left_neighbor: MapNode
	var right_neighbor: MapNode
	
	if j > 0:
		left_neighbor = map_data[i][j - 1]
	if j < MAP_WIDTH - 1:
		right_neighbor = map_data[i][j + 1]
	
	if right_neighbor and room.column > j:
		for next_room: MapNode in right_neighbor.next_rooms:
			if next_room.column < room.column:
				return true
				
	if left_neighbor and room.column < j:
		for next_room: MapNode in left_neighbor.next_rooms:
			if next_room.column > room.column:
				return true
				
	return false

func _setup_boss_room() -> void:
	var middle := floori(MAP_WIDTH * 0.5)
	var boss_room := map_data[FLOORS - 1][middle] as MapNode
	
	boss_room.type = MapNode.Type.BOSS
	
	for j in MAP_WIDTH:
		var current_room = map_data[FLOORS - 2][j] as MapNode
		if current_room.next_rooms:
			current_room.next_rooms = [] as Array[MapNode]
			current_room.next_rooms.append(boss_room)

func _setup_random_room_weights() -> void:
	random_room_type_weights[MapNode.Type.LEVEL] = LEVEL_NODE_WEIGHT
	random_room_type_weights[MapNode.Type.HEAL] = LEVEL_NODE_WEIGHT + HEAL_NODE_WEIGHT
	random_room_type_weights[MapNode.Type.UPGRADE] = LEVEL_NODE_WEIGHT + HEAL_NODE_WEIGHT + UPGRADE_NODE_WEIGHT
	
	random_room_type_total_weight = random_room_type_weights[MapNode.Type.UPGRADE]

func _setup_room_types() -> void:
	
	for room: MapNode in map_data[0]:
		if room.next_rooms.size() > 0:
			room.type = MapNode.Type.LEVEL
	
	for room: MapNode in map_data[1]:
		if room.next_rooms.size() > 0:
			room.type = MapNode.Type.UPGRADE
	
	for room: MapNode in map_data[FLOORS / 2]:
		if room.next_rooms.size() > 0:
			room.type = MapNode.Type.UPGRADE
	
	for room: MapNode in map_data[FLOORS - 2]:
		if room.next_rooms.size() > 0:
			room.type = MapNode.Type.HEAL
	
	for current_floor in map_data:
		for room: MapNode in current_floor:
			for next_room: MapNode in room.next_rooms:
				if next_room.type == MapNode.Type.NOT_ASSIGNED:
					_set_room_randomly(next_room)


func _set_room_randomly(room_to_set: MapNode) -> void:
	var heal_below_2 := true
	var consecutive_heal := true
	var consecutive_upgrade := true
	var heal_on_13 := true
	
	
	var type_candidate: MapNode.Type
	
	while heal_below_2 or consecutive_heal or consecutive_upgrade or heal_on_13:
		type_candidate = _get_random_room_type_by_weight()
		
		var is_heal := type_candidate == MapNode.Type.HEAL
		var has_heal_parent := _room_has_parent_of_type(room_to_set, MapNode.Type.HEAL)
		var is_upgrade := type_candidate == MapNode.Type.UPGRADE
		var has_upgrade_parent := _room_has_parent_of_type(room_to_set, MapNode.Type.UPGRADE)
		
		heal_below_2 = is_heal and room_to_set.row < 3
		consecutive_heal = is_heal and has_heal_parent
		consecutive_upgrade = is_upgrade and has_upgrade_parent
		heal_on_13 = is_heal and room_to_set.row == 12
		
	room_to_set.type = type_candidate

func _room_has_parent_of_type(room: MapNode, type: MapNode.Type) -> bool:
	var parents: Array[MapNode] = []
	
	if room.column > 0 and room.row > 0:
		var parent_candidate := map_data[room.row - 1][room.column - 1] as MapNode
		if parent_candidate.next_rooms.has(room):
			parents.append(parent_candidate)
			
	
	if room.row > 0:
		var parent_candidate := map_data[room.row - 1][room.column] as MapNode
		if parent_candidate.next_rooms.has(room):
			parents.append(parent_candidate)
	
	if room.column < (MAP_WIDTH - 1) and room.row > 0:
		var parent_candidate := map_data[room.row - 1][room.column + 1] as MapNode
		if parent_candidate.next_rooms.has(room):
			parents.append(parent_candidate)
	
	for parent: MapNode in parents:
		if parent.type == type:
			return true
	
	return false

func _get_random_room_type_by_weight() -> MapNode.Type:
	var roll := randf_range(0.0, random_room_type_total_weight)
	
	for type: MapNode.Type in random_room_type_weights:
		if random_room_type_weights[type] > roll:
			return type
	
	return MapNode.Type.LEVEL
