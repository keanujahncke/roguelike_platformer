extends Node2D
class_name AreaManipulator

@export var ground_map: TileMapLayer
@export var chunk_moves: Array[ChunkMove] = []

@export var black_hole_indicator_scene: PackedScene

# Keep this OFF in the boss room inspector.
# BossIntroTrigger will turn this on later.
@export var use_attack_timer := false

# How long to wait before the first attack starts AFTER activate_attacks() is called.
@export var first_attack_delay := 2.0

# How long to wait after the full forward + reverse cycle finishes.
@export var attack_interval := 5.0

# How long after the boss terrain appears before reversing the move.
@export var reverse_delay := 5.0

# Keep this on only if you still want Enter to manually test.
@export var allow_manual_test_input := false
@export var test_input_action := "ui_accept"

# Time between source black hole finishing and destination black hole starting.
@export var reveal_delay := 0.4

# Time between destination reverse black hole finishing and source restore black hole starting.
@export var reverse_reveal_delay := 0.4

# 0.0 = tile change happens exactly at black hole peak.
# Positive = later than peak.
# Negative = earlier than peak.
@export var peak_timing_offset := 0.0

# If true, boss uses CM1, then CM2, then CM3, then repeats.
# If false, boss randomly picks one CM each cycle.
@export var use_chunk_moves_in_order := true

var attack_running := false
var attack_loop_running := false
var stored_source_tiles: Array[Dictionary] = []
var current_chunk_index := 0


func _ready() -> void:
	if ground_map == null:
		push_error("AreaManipulator: GroundMap is not assigned.")

	if black_hole_indicator_scene == null:
		push_warning("AreaManipulator: BlackHoleIndicator scene is not assigned.")

	hide_all_boss_terrain()

	# IMPORTANT:
	# Do not automatically start attacks unless Use Attack Timer is on.
	# For the boss intro system, keep Use Attack Timer OFF in the Inspector.
	if use_attack_timer:
		start_attack_loop()


func _process(_delta: float) -> void:
	if allow_manual_test_input and Input.is_action_just_pressed(test_input_action):
		print("AreaManipulator: manual test input pressed.")
		var move := get_next_chunk_move()
		if move != null:
			perform_full_black_hole_cycle(move)


func activate_attacks() -> void:
	if attack_loop_running:
		return
	
	use_attack_timer = true
	start_attack_loop()
	print("AreaManipulator attacks activated.")


func deactivate_attacks() -> void:
	use_attack_timer = false
	attack_loop_running = false
	attack_running = false
	hide_all_boss_terrain()
	print("AreaManipulator attacks deactivated.")


func hide_all_boss_terrain() -> void:
	for move in chunk_moves:
		if move != null:
			move.hide_boss_terrain()


func start_attack_loop() -> void:
	if attack_loop_running:
		return
	
	attack_loop_running = true
	
	await get_tree().create_timer(first_attack_delay).timeout

	while use_attack_timer:
		var move := get_next_chunk_move()

		if move != null:
			await perform_full_black_hole_cycle(move)
		else:
			print("AreaManipulator: No valid ChunkMoves assigned.")

		await get_tree().create_timer(attack_interval).timeout
	
	attack_loop_running = false


func get_next_chunk_move() -> ChunkMove:
	if chunk_moves.is_empty():
		push_warning("AreaManipulator: chunk_moves array is empty.")
		return null

	var valid_moves: Array[ChunkMove] = []

	for move in chunk_moves:
		if move != null:
			valid_moves.append(move)

	if valid_moves.is_empty():
		push_warning("AreaManipulator: No valid ChunkMove references found.")
		return null

	if use_chunk_moves_in_order:
		if current_chunk_index >= valid_moves.size():
			current_chunk_index = 0

		var selected_move := valid_moves[current_chunk_index]
		current_chunk_index += 1
		return selected_move

	return valid_moves.pick_random()


func perform_full_black_hole_cycle(move: ChunkMove) -> void:
	if attack_running:
		print("Attack already running.")
		return

	if move == null:
		push_error("AreaManipulator: ChunkMove is missing.")
		return

	attack_running = true

	await perform_forward_attack(move)

	await get_tree().create_timer(reverse_delay).timeout

	await perform_reverse_attack(move)

	attack_running = false


func perform_forward_attack(move: ChunkMove) -> void:
	if ground_map == null:
		push_error("AreaManipulator: GroundMap is missing.")
		return

	if move == null:
		push_error("AreaManipulator: ChunkMove is missing.")
		return

	if black_hole_indicator_scene == null:
		push_error("AreaManipulator: BlackHoleIndicator scene is missing.")
		return

	var source_rect_global: Rect2 = move.get_source_rect_global()
	var destination_rect_global: Rect2 = move.get_destination_rect_global()

	var source_cells: Array[Vector2i] = get_cells_in_global_rect(source_rect_global)

	if source_cells.is_empty():
		print("No source cells found inside the source rectangle for ", move.name)
		return

	store_source_tiles(source_cells)

	# -------------------------
	# SOURCE BLACK HOLE
	# -------------------------

	var source_black_hole: Node = spawn_black_hole_indicator(source_rect_global)
	var source_lifetime: float = get_black_hole_lifetime(source_black_hole)
	var source_peak_time: float = get_black_hole_peak_time(source_black_hole)

	await get_tree().create_timer(max(source_peak_time + peak_timing_offset, 0.0)).timeout

	if move.clear_source_after_move:
		remove_ground_tiles(source_cells)

	print("Forward: source tiles removed for ", move.name)

	var source_remaining_time: float = max(source_lifetime - source_peak_time - peak_timing_offset, 0.0)
	await get_tree().create_timer(source_remaining_time).timeout

	if source_black_hole != null and is_instance_valid(source_black_hole):
		source_black_hole.queue_free()

	# -------------------------
	# DELAY BEFORE DESTINATION
	# -------------------------

	await get_tree().create_timer(reveal_delay).timeout

	# -------------------------
	# DESTINATION BLACK HOLE
	# -------------------------

	var destination_black_hole: Node = spawn_black_hole_indicator(destination_rect_global)
	var destination_lifetime: float = get_black_hole_lifetime(destination_black_hole)
	var destination_peak_time: float = get_black_hole_peak_time(destination_black_hole)

	await get_tree().create_timer(max(destination_peak_time + peak_timing_offset, 0.0)).timeout

	move.reveal_boss_terrain()

	print("Forward: boss terrain revealed for ", move.name)

	var destination_remaining_time: float = max(destination_lifetime - destination_peak_time - peak_timing_offset, 0.0)
	await get_tree().create_timer(destination_remaining_time).timeout

	if destination_black_hole != null and is_instance_valid(destination_black_hole):
		destination_black_hole.queue_free()

	print("Forward attack complete for ", move.name)


func perform_reverse_attack(move: ChunkMove) -> void:
	if ground_map == null:
		push_error("AreaManipulator: GroundMap is missing.")
		return

	if move == null:
		push_error("AreaManipulator: ChunkMove is missing.")
		return

	if black_hole_indicator_scene == null:
		push_error("AreaManipulator: BlackHoleIndicator scene is missing.")
		return

	if stored_source_tiles.is_empty():
		print("No stored source tiles to restore for ", move.name)
		return

	var source_rect_global: Rect2 = move.get_source_rect_global()
	var destination_rect_global: Rect2 = move.get_destination_rect_global()

	# -------------------------
	# DESTINATION BLACK HOLE
	# -------------------------

	var destination_black_hole: Node = spawn_black_hole_indicator(destination_rect_global)
	var destination_lifetime: float = get_black_hole_lifetime(destination_black_hole)
	var destination_peak_time: float = get_black_hole_peak_time(destination_black_hole)

	await get_tree().create_timer(max(destination_peak_time + peak_timing_offset, 0.0)).timeout

	move.hide_boss_terrain()

	print("Reverse: boss terrain hidden for ", move.name)

	var destination_remaining_time: float = max(destination_lifetime - destination_peak_time - peak_timing_offset, 0.0)
	await get_tree().create_timer(destination_remaining_time).timeout

	if destination_black_hole != null and is_instance_valid(destination_black_hole):
		destination_black_hole.queue_free()

	# -------------------------
	# DELAY BEFORE SOURCE RESTORE
	# -------------------------

	await get_tree().create_timer(reverse_reveal_delay).timeout

	# -------------------------
	# SOURCE BLACK HOLE
	# -------------------------

	var source_black_hole: Node = spawn_black_hole_indicator(source_rect_global)
	var source_lifetime: float = get_black_hole_lifetime(source_black_hole)
	var source_peak_time: float = get_black_hole_peak_time(source_black_hole)

	await get_tree().create_timer(max(source_peak_time + peak_timing_offset, 0.0)).timeout

	restore_source_tiles()

	print("Reverse: source tiles restored for ", move.name)

	var source_remaining_time: float = max(source_lifetime - source_peak_time - peak_timing_offset, 0.0)
	await get_tree().create_timer(source_remaining_time).timeout

	if source_black_hole != null and is_instance_valid(source_black_hole):
		source_black_hole.queue_free()

	stored_source_tiles.clear()

	print("Reverse attack complete for ", move.name)


func store_source_tiles(source_cells: Array[Vector2i]) -> void:
	stored_source_tiles.clear()

	for cell in source_cells:
		var source_id: int = ground_map.get_cell_source_id(cell)

		if source_id == -1:
			continue

		var atlas_coords: Vector2i = ground_map.get_cell_atlas_coords(cell)
		var alternative_tile: int = ground_map.get_cell_alternative_tile(cell)

		stored_source_tiles.append({
			"cell": cell,
			"source_id": source_id,
			"atlas_coords": atlas_coords,
			"alternative_tile": alternative_tile
		})


func restore_source_tiles() -> void:
	for tile_data in stored_source_tiles:
		var cell: Vector2i = tile_data["cell"]
		var source_id: int = tile_data["source_id"]
		var atlas_coords: Vector2i = tile_data["atlas_coords"]
		var alternative_tile: int = tile_data["alternative_tile"]

		ground_map.set_cell(
			cell,
			source_id,
			atlas_coords,
			alternative_tile
		)


func spawn_black_hole_indicator(target_rect_global: Rect2) -> Node:
	var indicator: Node = black_hole_indicator_scene.instantiate()
	get_tree().current_scene.add_child(indicator)

	if indicator.has_method("setup_from_rect"):
		indicator.setup_from_rect(target_rect_global)
	else:
		indicator.global_position = target_rect_global.get_center()

	if indicator.has_method("play_from_start"):
		indicator.play_from_start()

	return indicator


func get_black_hole_lifetime(indicator: Node) -> float:
	if indicator == null:
		return 1.0

	if not is_instance_valid(indicator):
		return 1.0

	if indicator.has_method("get_animation_length"):
		return indicator.get_animation_length()

	return 1.0


func get_black_hole_peak_time(indicator: Node) -> float:
	if indicator == null:
		return 0.5

	if not is_instance_valid(indicator):
		return 0.5

	if indicator.has_method("get_peak_time"):
		return indicator.get_peak_time()

	return 0.5


func remove_ground_tiles(source_cells: Array[Vector2i]) -> void:
	for cell in source_cells:
		ground_map.set_cell(cell, -1)


func get_cells_in_global_rect(global_rect: Rect2) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []

	var local_top_left: Vector2 = ground_map.to_local(global_rect.position)
	var local_bottom_right: Vector2 = ground_map.to_local(global_rect.position + global_rect.size)

	var cell_a: Vector2i = ground_map.local_to_map(local_top_left)
	var cell_b: Vector2i = ground_map.local_to_map(local_bottom_right)

	var min_x: int = min(cell_a.x, cell_b.x)
	var max_x: int = max(cell_a.x, cell_b.x)
	var min_y: int = min(cell_a.y, cell_b.y)
	var max_y: int = max(cell_a.y, cell_b.y)

	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var cell := Vector2i(x, y)

			if ground_map.get_cell_source_id(cell) != -1:
				cells.append(cell)

	return cells
