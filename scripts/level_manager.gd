extends Node2D

@export var rooms : Array[PackedScene]
@export var choices_per_pick := 3

@onready var player = $Player

var current_room : Node2D
var current_choices : Array[PackedScene]


func _ready():
	pick_next_rooms()
	load_room(current_choices[0]) # temp auto-pick



# PICK ROOMS
func pick_next_rooms():

	current_choices.clear()

	var pool = rooms.duplicate()
	pool.shuffle()

	for i in min(choices_per_pick, pool.size()):
		current_choices.append(pool[i])

	# later you'll show UI here
	print("Choices:")
	for r in current_choices:
		print(r.resource_path)



# LOAD CHOSEN ROOM
func load_room(room_scene : PackedScene):

	# unload old
	if current_room:
		current_room.queue_free()

	# instantiate
	current_room = room_scene.instantiate()
	add_child(current_room)

	# move player
	var spawn = current_room.get_node("Spawn")
	player.global_position = spawn.global_position

	# connect exit
	var exit = current_room.get_node("Exit")
	exit.body_entered.connect(_on_exit_entered)



# EXIT TRIGGER
func _on_exit_entered(body):
	if body != player:
		return

	pick_next_rooms()

	# TEMP: auto pick first
	load_room(current_choices[0])
