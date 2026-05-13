extends Node2D

@export var starting_room : PackedScene
@export var room_database : RoomDatabase

@export var dungeon_music: AudioStream
@export var forest_music: AudioStream
@export var sky_music: AudioStream

# Boss music:
# Boss Intro Music plays once.
# Boss Loop Music starts immediately after the intro finishes and loops.
@export var boss_intro_music: AudioStream
@export var boss_loop_music: AudioStream

@export var dungeon_music_db := -15.0
@export var forest_music_db := -20.0
@export var sky_music_db := -15.0
@export var boss_music_db := -15.0

@onready var player = $Player
@onready var game_over = $CanvasLayer/GameOver
@onready var restart_button = $CanvasLayer/GameOver/HBoxContainer/Button
@onready var level_rewards_ui = $CanvasLayer/LevelReward
@onready var music: AudioStreamPlayer = $Music
@onready var heartContainer = $HeartUI/heartContainer

var current_room : Node2D
var current_exit : Area2D

var exit_used := false
var waiting_for_boss_loop := false


func _ready():
	run_manager.start_new_run()
	apply_starting_upgrades()
	save_data.clear_selected_starting_abilities()
	game_over.hide()
	level_rewards_ui.hide()
	heartContainer.setMaxHearts(player.max_health)

	# Music connection for boss intro -> boss loop.
	if music != null and not music.finished.is_connected(_on_music_finished):
		music.finished.connect(_on_music_finished)

	# UI connections
	if not level_rewards_ui.room_selected.is_connected(_on_room_selected):
		level_rewards_ui.room_selected.connect(_on_room_selected)
	if not level_rewards_ui.ability_selected.is_connected(_on_ability_reward_selected):
		level_rewards_ui.ability_selected.connect(_on_ability_reward_selected)

	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)

	load_room(starting_room)
	
	for c in get_tree().get_nodes_in_group("collectibles"):
		c.collected.connect(_on_collectible_collected)


func apply_starting_upgrades():
	for id in save_data.get_selected_starting_abilities():
		player.unlock_ability(id)


func play_music_for_room(room_scene: PackedScene):
	if room_scene == null:
		print("MUSIC ERROR: room_scene is null.")
		return

	if music == null:
		print("MUSIC ERROR: Music node was not found. Make sure Game has a child named Music.")
		return

	var path := room_scene.resource_path.to_lower()

	print("ROOM PATH: ", path)

	if "boss" in path:
		print("MUSIC TYPE DETECTED: boss")
		play_boss_music()
		return

	var next_track: AudioStream = dungeon_music
	var next_volume_db := dungeon_music_db
	var track_name := "dungeon"

	waiting_for_boss_loop = false

	if "forest" in path:
		next_track = forest_music
		next_volume_db = forest_music_db
		track_name = "forest"
	elif "sky" in path:
		next_track = sky_music
		next_volume_db = sky_music_db
		track_name = "sky"
	elif "dungeon" in path:
		next_track = dungeon_music
		next_volume_db = dungeon_music_db
		track_name = "dungeon"
	else:
		next_track = dungeon_music
		next_volume_db = dungeon_music_db
		track_name = "dungeon/default"

	print("MUSIC TYPE DETECTED: ", track_name)

	if next_track == null:
		print("MUSIC ERROR: No track assigned for ", track_name, ". Check the Game node Inspector.")
		return

	if music.stream == next_track and music.playing:
		music.volume_db = next_volume_db
		print("MUSIC: Already playing ", track_name, " track. Volume updated to ", next_volume_db, " dB.")
		return

	music.stop()
	music.stream = next_track
	music.volume_db = next_volume_db
	music.play()

	print("MUSIC: Now playing ", track_name, " track at ", next_volume_db, " dB.")


func play_boss_music() -> void:
	if music == null:
		print("MUSIC ERROR: Music node was not found.")
		return

	if boss_intro_music == null and boss_loop_music == null:
		print("MUSIC ERROR: No boss intro or boss loop music assigned.")
		return

	# If the boss loop is already playing, do not restart it.
	if music.stream == boss_loop_music and music.playing:
		music.volume_db = boss_music_db
		print("MUSIC: Already playing boss loop. Volume updated to ", boss_music_db, " dB.")
		return

	music.stop()
	music.volume_db = boss_music_db

	if boss_intro_music != null:
		waiting_for_boss_loop = true
		music.stream = boss_intro_music
		music.play()
		print("MUSIC: Now playing boss intro at ", boss_music_db, " dB.")
	else:
		waiting_for_boss_loop = false
		music.stream = boss_loop_music
		music.play()
		print("MUSIC: No boss intro assigned. Playing boss loop at ", boss_music_db, " dB.")


func _on_music_finished() -> void:
	if not waiting_for_boss_loop:
		return

	waiting_for_boss_loop = false

	if boss_loop_music == null:
		print("MUSIC ERROR: Boss intro finished, but Boss Loop Music is not assigned.")
		return

	music.stream = boss_loop_music
	music.volume_db = boss_music_db
	music.play()

	print("MUSIC: Boss intro finished. Now playing boss loop.")


func _on_ability_reward_selected(id: String):
	print("Ability rewarded: ", id)

	if id == "":
		return

	player.unlock_ability(id)


func _on_collectible_collected(id: String, value: int):
	if not save_data.has_collected(id):
		save_data.mark_collected(id)
		save_data.add_energy(value)


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

	# Play music AFTER unpausing so the AudioStreamPlayer is not blocked by pause.
	play_music_for_room(room_scene)

	# Safety Timer
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
	heartContainer.updateHealth(new_health)


# GAME OVER
func _on_player_died() -> void:
	game_over.show()
	restart_button.grab_focus()


# RESTART
func restart_game():
	game_over.hide()
	player.reset_stats()
	get_tree().change_scene_to_file("res://title_screen/title_screen.tscn")
