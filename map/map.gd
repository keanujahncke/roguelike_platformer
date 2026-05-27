extends CanvasLayer

signal map_node_selected(node: MapNode)

@export var node_scene: PackedScene = preload("res://map/map_room.tscn")
@export var room_database: RoomDatabase

@export var move_between_options_sfx: AudioStream
@export var choose_option_sfx: AudioStream

@export var move_sfx_volume_db: float = 0.0
@export var choose_sfx_volume_db: float = 0.0

@export var stick_scroll_speed := 450.0

@onready var lines_container = $ScrollContainer/MapContent/LinesContainer
@onready var rooms_container = $ScrollContainer/MapContent/RoomsContainer
@onready var scroll_container: ScrollContainer = $ScrollContainer

var map_data: Array[Array]
var room_buttons = {}

var move_sfx_player: AudioStreamPlayer
var choose_sfx_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_create_sfx_players()


func _process(delta: float) -> void:
	if not self.visible:
		return
		
	var input_axis := Input.get_axis("map_scroll_up", "map_scroll_down")
	
	if abs(input_axis) > 0.1:
		scroll_container.scroll_vertical += int(input_axis * stick_scroll_speed * delta)
		run_manager.map_scroll_position = scroll_container.scroll_vertical
		lines_container.queue_redraw()


func _create_sfx_players() -> void:
	move_sfx_player = AudioStreamPlayer.new()
	move_sfx_player.name = "MoveBetweenOptionsSFXPlayer"
	add_child(move_sfx_player)

	choose_sfx_player = AudioStreamPlayer.new()
	choose_sfx_player.name = "ChooseOptionSFXPlayer"
	add_child(choose_sfx_player)

	move_sfx_player.stream = move_between_options_sfx
	choose_sfx_player.stream = choose_option_sfx

	move_sfx_player.volume_db = move_sfx_volume_db
	choose_sfx_player.volume_db = choose_sfx_volume_db


func play_move_between_options_sfx() -> void:
	if move_sfx_player == null:
		return

	if move_sfx_player.stream == null:
		return

	move_sfx_player.volume_db = move_sfx_volume_db
	move_sfx_player.stop()
	move_sfx_player.play()


func play_choose_option_sfx() -> void:
	if choose_sfx_player == null:
		return

	if choose_sfx_player.stream == null:
		return

	choose_sfx_player.volume_db = choose_sfx_volume_db
	choose_sfx_player.stop()
	choose_sfx_player.play()


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
			btn.position = room.position - Vector2(16, 16)
			
			var is_available = false

			if run_manager.current_map_node == null:
				if room.row == 0:
					is_available = true
			else:
				for next in run_manager.current_map_node.next_rooms:
					if next.row == room.row and next.column == room.column:
						is_available = true
						break
			
			var is_completed = false

			for comp in run_manager.completed_nodes:
				if comp.row == room.row and comp.column == room.column:
					is_completed = true
					break

			btn.focus_mode = Control.FOCUS_ALL if is_available else Control.FOCUS_NONE
			
			var is_current = run_manager.current_map_node != null and run_manager.current_map_node.row == room.row and run_manager.current_map_node.column == room.column

			if is_current or is_completed:
				btn.modulate = Color.WHITE
			elif is_available:
				btn.modulate = Color(1, 1, 1, 1)
			else:
				btn.modulate = Color(0.3, 0.3, 0.3, 0.7)

			btn.setup(room, is_available, is_completed)

			if not btn.pressed.is_connected(_on_node_pressed):
				btn.pressed.connect(_on_node_pressed.bind(room))

			if not btn.focus_entered.is_connected(_on_map_button_focus_entered):
				btn.focus_entered.connect(_on_map_button_focus_entered)

			room_buttons[room] = btn


func _on_map_button_focus_entered() -> void:
	play_move_between_options_sfx()


func _on_node_pressed(room: MapNode) -> void:
	play_choose_option_sfx()

	if run_manager.current_map_node != null:
		run_manager.completed_nodes.append(run_manager.current_map_node)
	
	run_manager.current_map_node = room
	run_manager.map_scroll_position = scroll_container.scroll_vertical

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

	if not focusable.is_empty():
		focusable[0].grab_focus()
