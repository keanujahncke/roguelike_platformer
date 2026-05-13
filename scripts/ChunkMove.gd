extends Node2D
class_name ChunkMove

@export var boss_terrain_layer: TileMapLayer
@export var clear_source_after_move := true

var source_area: Area2D
var source_shape: CollisionShape2D

var destination_area: Area2D
var destination_shape: CollisionShape2D


func _ready():
	source_area = find_area_by_name_part("Source")
	source_shape = find_collision_shape_in_area(source_area)

	destination_area = find_area_by_name_part("Destination")
	destination_shape = find_collision_shape_in_area(destination_area)

	if source_area == null:
		push_error(name + ": Missing SourceArea Area2D.")

	if source_shape == null:
		push_error(name + ": Missing source CollisionShape2D.")

	if destination_area == null:
		push_error(name + ": Missing DestinationArea Area2D.")

	if destination_shape == null:
		push_error(name + ": Missing destination CollisionShape2D.")

	hide_boss_terrain()


func find_area_by_name_part(name_part: String) -> Area2D:
	for child in get_children():
		if child is Area2D and child.name.contains(name_part):
			return child
	return null


func find_collision_shape_in_area(area: Area2D) -> CollisionShape2D:
	if area == null:
		return null

	for child in area.get_children():
		if child is CollisionShape2D:
			return child

	return null


func get_source_rect_global() -> Rect2:
	return get_rect_from_shape(source_shape, "source")


func get_destination_rect_global() -> Rect2:
	return get_rect_from_shape(destination_shape, "destination")


func get_rect_from_shape(shape_node: CollisionShape2D, label: String) -> Rect2:
	if shape_node == null:
		push_error(name + ": Missing " + label + " CollisionShape2D.")
		return Rect2()

	var rect_shape := shape_node.shape as RectangleShape2D

	if rect_shape == null:
		push_error(name + ": " + label + " CollisionShape2D needs a RectangleShape2D.")
		return Rect2()

	var size := rect_shape.size * shape_node.global_scale
	var center := shape_node.global_position
	var top_left := center - size / 2.0

	return Rect2(top_left, size)


func reveal_boss_terrain():
	if boss_terrain_layer == null:
		push_error(name + ": Boss terrain layer is not assigned.")
		return

	boss_terrain_layer.visible = true
	boss_terrain_layer.enabled = true
	boss_terrain_layer.collision_enabled = true


func hide_boss_terrain():
	if boss_terrain_layer == null:
		return

	boss_terrain_layer.visible = false
	boss_terrain_layer.enabled = false
	boss_terrain_layer.collision_enabled = false
