class_name MapNode
extends Resource

enum Type {NOT_ASSIGNED, LEVEL, UPGRADE, HEAL, BOSS}

@export var type: Type
@export var row: int
@export var column: int
@export var position: Vector2
@export var next_nodes: Array[MapNode]
@export var selected:bool = false

func _to_string() -> String:
	return "%s (%s)" % [column, Type.keys()[type][0]]
