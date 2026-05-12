extends Node2D
class_name AreaManipulator

@export var ground_map: TileMapLayer
@export var boss_collision_map: TileMapLayer

@export var chunk_move: ChunkMove

@export var test_input_action := "ui_accept"

# This is the warning time before the real ground disappears.
# Later this will be how long the black hole warning animation stays active.
@export var warning_time := 0.8

# Delay before the new invisible collision appears at the destination.
@export var reappear_delay := 0.35

# Tile used for invisible boss collision.
# For now, use any solid ground tile from your TileSet.
@export var collision_tile_source_id: int = 0
@export var collision_tile_atlas_coords: Vector2i = Vector2i(2, 2)
@export var collision_tile_alternative_tile: int = 0

@export var destination_rotation_90 := true

# Turn this on while testing.
# Left-click a tile while running the scene to print tile info.
@export var print_clicked_tile_info := true

var attack_running := false


func _ready():
	if ground_map == null:
		push_error("AreaManipulator: GroundMap is not assigned.")

	if boss_collision_map == null:
		push_error("AreaManipulator: BossCollisionMap is not assigned.")

	if chunk_move == null:
		push_error("AreaManipulator: ChunkMove is not assigned.")


func _process(_delta):
	if Input.is_action_just_pressed(test_input_action):
		perform_void_chunk_attack(chunk_move)


func _input(event):
	if not print_clicked_tile_info:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if ground_map == null:
			print("GroundMap is not assigned, cannot check tile.")
			return

		var mouse_pos := get_global_mouse_position()
		var cell := global_position_to_cell(mouse_pos)

		print("----- CLICKED TILE INFO -----")
		print("Clicked cell: ", cell)
		print("Source ID: ", ground_map.get_cell_source_id(cell))
		print("Atlas coords: ", ground_map.get_cell_atlas_coords(cell))
		print("Alternative tile: ", ground_map.get_cell_alternative_tile(cell))
		print("-----------------------------")


func perform_void_chunk_attack(move: ChunkMove):
	if attack_running:
		return

	if ground_map == null:
		push_error("AreaManipulator: GroundMap is missing.")
		return

	if boss_collision_map == null:
		push_error("AreaManipulator: BossCollisionMap is missing.")
		return

	if move == null:
		push_error("AreaManipulator: ChunkMove is missing.")
		return

	attack_running = true

	var source_rect_global := move.get_source_rect_global()
	var source_cells := get_cells_in_global_rect(source_rect_global)

	if source_cells.is_empty():
		print("No source cells found inside the source rectangle.")
		attack_running = false
		return

	var bounds := get_cell_bounds(source_cells)
	var destination_cell := global_position_to_cell(move.get_destination_global_position())

	var shape_offsets: Array[Vector2i] = []

	for cell in source_cells:
		var offset := cell - bounds.position
		shape_offsets.append(offset)

	# Later: spawn black hole warning visual over the source area here.
	print("Black hole warning would appear now.")

	await get_tree().create_timer(warning_time).timeout

	# Remove original ground.
	remove_ground_tiles(source_cells)

	await get_tree().create_timer(reappear_delay).timeout

	# Later: spawn black hole/void platform visual at destination here.

	# Place invisible collision tiles at the destination.
	var placed_offsets := build_destination_offsets(shape_offsets, destination_rotation_90)
	place_boss_collision(destination_cell, placed_offsets)

	print("Void chunk attack complete.")
	print("Source tiles removed: ", source_cells.size())
	print("Invisible collision tiles placed: ", placed_offsets.size())

	attack_running = false


func remove_ground_tiles(source_cells: Array[Vector2i]):
	for cell in source_cells:
		ground_map.set_cell(cell, -1)


func place_boss_collision(destination_cell: Vector2i, offsets: Array[Vector2i]):
	for offset in offsets:
		var target_cell := destination_cell + offset

		boss_collision_map.set_cell(
			target_cell,
			collision_tile_source_id,
			collision_tile_atlas_coords,
			collision_tile_alternative_tile
		)


func build_destination_offsets(source_offsets: Array[Vector2i], rotate_90: bool) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	for offset in source_offsets:
		var placed_offset := offset

		if rotate_90:
			placed_offset = Vector2i(-offset.y, offset.x)

		result.append(placed_offset)

	# Normalize so the created shape starts at the destination marker.
	var min_offset := Vector2i(999999, 999999)

	for offset in result:
		min_offset.x = min(min_offset.x, offset.x)
		min_offset.y = min(min_offset.y, offset.y)

	for i in range(result.size()):
		result[i] = result[i] - min_offset

	return result


func get_cells_in_global_rect(global_rect: Rect2) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []

	var local_top_left := ground_map.to_local(global_rect.position)
	var local_bottom_right := ground_map.to_local(global_rect.position + global_rect.size)

	var cell_a := ground_map.local_to_map(local_top_left)
	var cell_b := ground_map.local_to_map(local_bottom_right)

	var min_x = min(cell_a.x, cell_b.x)
	var max_x = max(cell_a.x, cell_b.x)
	var min_y = min(cell_a.y, cell_b.y)
	var max_y = max(cell_a.y, cell_b.y)

	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var cell := Vector2i(x, y)

			if ground_map.get_cell_source_id(cell) != -1:
				cells.append(cell)

	return cells


func get_cell_bounds(cells: Array[Vector2i]) -> Rect2i:
	var min_x := cells[0].x
	var max_x := cells[0].x
	var min_y := cells[0].y
	var max_y := cells[0].y

	for cell in cells:
		min_x = min(min_x, cell.x)
		max_x = max(max_x, cell.x)
		min_y = min(min_y, cell.y)
		max_y = max(max_y, cell.y)

	var position := Vector2i(min_x, min_y)
	var size := Vector2i(max_x - min_x + 1, max_y - min_y + 1)

	return Rect2i(position, size)


func global_position_to_cell(global_pos: Vector2) -> Vector2i:
	var local_pos := ground_map.to_local(global_pos)
	return ground_map.local_to_map(local_pos)
