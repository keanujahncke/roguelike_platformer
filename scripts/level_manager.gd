extends Node2D

@export var starting_room : PackedScene
@export var room_database : RoomDatabase

@onready var player = $Player
@onready var game_over = $CanvasLayer/GameOver
@onready var level_rewards_ui = $CanvasLayer/LevelReward

var current_room : Node2D
var current_exit : Area2D

var exit_used := false


func _ready():
	game_over.hide()
	level_rewards_ui.hide()

	# UI connections
	level_rewards_ui.room_selected.connect(_on_room_selected)
	level_rewards_ui.ability_selected.connect(_on_ability_reward_selected)

	player.died.connect(_on_player_died)

	load_room(starting_room)


# ABILITY PICKED -> actually unlock it
func _on_ability_reward_selected(id: String):
	print("Ability rewarded: ", id)

	if id == "":
		return

	player.unlock_ability(id)


# ROOM PICKED
func _on_room_selected(room_data : RoomData):
	load_room(room_data.scene)


# LOAD ROOM
func load_room(room_scene : PackedScene):
	if current_room:
		current_room.queue_free()

	current_room = room_scene.instantiate()
	add_child(current_room)

	player.current_room = current_room

	# move player to spawn
	var spawn = current_room.get_node("Spawn")
	player.global_position = spawn.global_position

	# disconnect previous exit
	if current_exit:
		current_exit.player_entered.disconnect(
			Callable(self, "_on_exit_entered")
		)

	# connect new exit
	current_exit = current_room.get_node("Exit")
	current_exit.player_entered.connect(
		Callable(self, "_on_exit_entered")
	)

	exit_used = false


# EXIT -> open reward UI
func _on_exit_entered():
	if exit_used:
		return

	exit_used = true

	level_rewards_ui.open_ui(room_database)


# RESPAWN
func respawn_player(player_node):
	var spawn = current_room.get_node("Spawn")
	player_node.global_position = spawn.global_position
	player_node.is_dead = false


# GAME OVER
func _on_player_died() -> void:
	game_over.show()


# RESTART
func restart_game():
	game_over.hide()
	player.reset_stats()
	load_room(starting_room)
