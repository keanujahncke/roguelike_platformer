extends Node2D
class_name ChunkMove

@export var rotate_90_degrees := true
@export var clear_source_after_move := true

var source_area: Area2D
var source_shape: CollisionShape2D
var destination: Marker2D


func _ready():
	source_area = find_child_area()
	source_shape = find_child_collision_shape()
	destination = find_child_destination()

	if source_area == null:
		push_error(name + ": Missing SourceArea Area2D.")

	if source_shape == null:
		push_error(name + ": Missing CollisionShape2D.")

	if destination == null:
		push_error(name + ": Missing Destination Marker2D.")


func find_child_area() -> Area2D:
	for child in get_children():
		if child is Area2D:
			return child
	return null


func find_child_collision_shape() -> CollisionShape2D:
	if source_area == null:
		source_area = find_child_area()

	if source_area == null:
		return null

	for child in source_area.get_children():
		if child is CollisionShape2D:
			return child

	return null


func find_child_destination() -> Marker2D:
	for child in get_children():
		if child is Marker2D:
			return child
	return null


func get_source_rect_global() -> Rect2:
	if source_shape == null:
		source_shape = find_child_collision_shape()

	if source_shape == null:
		push_error(name + ": Source CollisionShape2D not found.")
		return Rect2()

	var rect_shape := source_shape.shape as RectangleShape2D

	if rect_shape == null:
		push_error(name + ": Source CollisionShape2D needs a RectangleShape2D.")
		return Rect2()

	var size := rect_shape.size * source_shape.global_scale
	var center := source_shape.global_position
	var top_left := center - size / 2.0

	return Rect2(top_left, size)


func get_destination_global_position() -> Vector2:
	if destination == null:
		destination = find_child_destination()

	if destination == null:
		push_error(name + ": Destination Marker2D not found.")
		return global_position

	return destination.global_position
