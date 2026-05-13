extends Node2D

func _draw() -> void:
	var parent = get_parent().get_parent().get_parent() # This should be your Map node
	if not "map_data" in parent: return
	
	var line_color = Color(1, 1, 1, 0.4) 
	var width = 2.0
	
	for floor_layer in parent.map_data:
		for room in floor_layer:
			for next_room in room.next_rooms:
				# No offsets here! Use raw positions. 
				draw_line(room.position, next_room.position, line_color, width, true)
