extends Node2D

@export var starting_room : PackedScene
@export var room_database : RoomDatabase

@onready var player = $Player
@onready var game_over = $CanvasLayer/GameOver
@onready var level_rewards_ui = $CanvasLayer/LevelReward

var current_room : Node2D
var current_exit : Area2D

var exit_used := false

@onready var heartsContainer = $CanvasLayer2/health_bar

func _ready():
	apply_starting_upgrades()
	save_data.clear_selected_starting_abilities()
	game_over.hide()
	level_rewards_ui.hide()
	heartsContainer.setMaxHearts(player.max_health)

	# UI connections
	if not level_rewards_ui.room_selected.is_connected(_on_room_selected):
		level_rewards_ui.room_selected.connect(_on_room_selected)
	if not level_rewards_ui.ability_selected.is_connected(_on_ability_reward_selected):
		level_rewards_ui.ability_selected.connect(_on_ability_reward_selected)
	
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	load_room(starting_room)

func apply_starting_upgrades():
	for id in save_data.get_selected_starting_abilities():
		player.unlock_ability(id)

# ABILITY PICKED -> actually unlock it
func _on_ability_reward_selected(id: String):
	print("Ability rewarded: ", id)

	if id == "":
		return

	player.unlock_ability(id)



func _on_room_selected(room_data : RoomData):
	load_room(room_data.scene) 

func load_room(room_scene : PackedScene):
	exit_used = true 
	get_tree().paused = true 
	
	if current_room:
		current_room.queue_free()

	current_room = room_scene.instantiate()
	add_child(current_room)
	player.current_room = current_room

	# Position player
	var spawn = current_room.get_node("Spawn")
	player.global_position = spawn.global_position
	player.velocity = Vector2.ZERO 

	var all_exits = get_tree().get_nodes_in_group("exits")
	for exit_node in all_exits:
		if exit_node is Area2D:
			# Ensure we don't double-connect if the room was re-loaded
			if not exit_node.body_entered.is_connected(_on_exit_entered):
				exit_node.body_entered.connect(_on_exit_entered)

	await get_tree().process_frame
	await get_tree().physics_frame
	
	get_tree().paused = false 
	
	# Safety Timer (Keep this at 0.5s to be safe)
	await get_tree().create_timer(0.5).timeout
	
	exit_used = false 
	print("SYSTEM READY: All Exits Armed.")

func _on_exit_entered(body):
	if body.is_in_group("player"):
		if exit_used:
			# This will catch if the player spawns on ANY of the exits
			print("Ignoring exit: Gate is still locked.")
			return
		
		# Once ANY exit is used, lock the gate so no others can fire
		exit_used = true 
		print("Valid Exit triggered! Opening UI...")
		level_rewards_ui.open_ui(room_database)

# RESPAWN
func respawn_player(player_node):
	var spawn = current_room.get_node("Spawn")
	player_node.global_position = spawn.global_position
	player_node.is_dead = false


func _on_player_health_changed(new_health: int):
	heartsContainer.updateHealth(new_health)

# GAME OVER
func _on_player_died() -> void:
	game_over.show()


# RESTART
func restart_game():
	game_over.hide()
	player.reset_stats()
	get_tree().change_scene_to_file("res://title_screen/title_screen.tscn")
	
	
