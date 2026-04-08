extends Node2D

@export var starting_room : PackedScene
@export var room_database : RoomDatabase
@export var choices_per_pick := 3

@onready var player = $Player
@onready var picker = $CanvasLayer/RoomPicker

var current_room : Node2D
var current_choices : Array[RoomData]
var current_exit : Area2D

var exit_used := false

func _ready():
	picker.room_selected.connect(_on_room_selected)
	load_room(starting_room)


# PICK ROOMS
func pick_next_rooms():

	current_choices.clear()

	var pool = room_database.rooms.duplicate()

	for i in choices_per_pick:
		if pool.is_empty():
			break

		var index = randi() % pool.size()
		current_choices.append(pool[index])
		pool.remove_at(index)


func _on_room_selected(room_data : RoomData):
	load_room(room_data.scene)

# LOAD CHOSEN ROOM
func load_room(room_scene : PackedScene):
	if current_room:
		current_room.queue_free()

	current_room = room_scene.instantiate()
	add_child(current_room)

	# move player to spawn
	var spawn = current_room.get_node("Spawn")
	player.global_position = spawn.global_position

	# disconnect previous exit signal
	if current_exit:
		current_exit.player_entered.disconnect(Callable(self, "_on_exit_entered"))

	# set new exit
	current_exit = current_room.get_node("Exit")
	current_exit.player_entered.connect(Callable(self, "_on_exit_entered"))

	# reset single-trigger flag
	exit_used = false




func _on_exit_entered():
	if exit_used:
		return  # only trigger once per room

	exit_used = true
	pick_next_rooms()
	picker.show_choices(current_choices)
