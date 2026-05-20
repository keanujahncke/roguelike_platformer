extends CanvasLayer

# Signal now passes the entire MapNode resource
signal map_node_selected(node: MapNode)
# added this because of an error i got :P, fix if you want
@export var node_scene: PackedScene = preload("res://map/map_room.tscn")
@export var room_database: RoomDatabase

@onready var lines_container = $ScrollContainer/MapContent/LinesContainer
@onready var rooms_container = $ScrollContainer/MapContent/RoomsContainer

var map_data: Array[Array]
var room_buttons = {}

@export var stick_scroll_speed := 450.0  # Pixels per second
@onready var scroll_container: ScrollContainer = $ScrollContainer

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS 


func _process(delta: float) -> void:
	if not self.visible:
		return
		
	var input_axis := Input.get_axis("map_scroll_up", "map_scroll_down")
	
	if abs(input_axis) > 0.1:
		scroll_container.scroll_vertical += int(input_axis * stick_scroll_speed * delta)
		run_manager.map_scroll_position = scroll_container.scroll_vertical
		lines_container.queue_redraw()

func open_map():
	map_data = run_manager.map_data
	
	if run_manager.current_map_node != null:
		var found = false
		for layer in map_data:
			for room in layer:
				if room.row == run_manager.current_map_node.row and room.column == run_manager.current_map_node.column:
					run_manager.current_map_node = room
					found = true
					break
		if not found:
			run_manager.current_map_node = null
			run_manager.completed_nodes.clear()

	_create_visuals()
	_setup_navigation()
	self.show()
	
	await get_tree().process_frame
	var v_scroll = scroll_container.get_v_scroll_bar()
	
	if run_manager.map_scroll_position != -1:
		scroll_container.scroll_vertical = run_manager.map_scroll_position
	else:
		scroll_container.scroll_vertical = int(v_scroll.max_value)
		run_manager.map_scroll_position = scroll_container.scroll_vertical
	
	_grab_correct_focus()
	lines_container.queue_redraw()

func _create_visuals() -> void:
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
			else:
				for next in run_manager.current_map_node.next_rooms:
					if next.row == room.row and next.column == room.column:
						is_available = true
						break
			
			var is_completed = false
			for comp in run_manager.completed_nodes:
				if comp.row == room.row and comp.column == room.column:
					is_completed = true; break

			btn.focus_mode = Control.FOCUS_ALL if is_available else Control.FOCUS_NONE
			
			var is_current = run_manager.current_map_node != null and run_manager.current_map_node.row == room.row and run_manager.current_map_node.column == room.column
			if is_current or is_completed:
				btn.modulate = Color.WHITE
			elif is_available:
				btn.modulate = Color(1, 1, 1, 1)
			else:
				btn.modulate = Color(0.3, 0.3, 0.3, 0.7)

			btn.setup(room, is_available, is_completed)
			btn.pressed.connect(_on_node_pressed.bind(room))
			room_buttons[room] = btn

# REFACTORED: Now just handles the click and emits the node
func _on_node_pressed(room: MapNode) -> void:
	if run_manager.current_map_node != null:
		run_manager.completed_nodes.append(run_manager.current_map_node)
	
	run_manager.current_map_node = room
	run_manager.map_scroll_position = scroll_container.scroll_vertical
	# Pass the whole node to LevelManager
	map_node_selected.emit(room)
	self.hide()

func _setup_navigation() -> void:
	for room in room_buttons:
		var btn = room_buttons[room]
		for next in room.next_rooms:
			for target_room in room_buttons:
				if target_room.row == next.row and target_room.column == next.column:
					var target_btn = room_buttons[target_room]
					btn.focus_neighbor_top = btn.get_path_to(target_btn)
					target_btn.focus_neighbor_bottom = target_btn.get_path_to(btn)

func _grab_correct_focus() -> void:
	var focusable = room_buttons.values().filter(func(b): return b.focus_mode == Control.FOCUS_ALL)
	if not focusable.is_empty(): focusable[0].grab_focus()
