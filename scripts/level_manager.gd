extends Node2D

@export var starting_room : PackedScene
@export var room_database : RoomDatabase
@export var boss_room : RoomData

@export var dungeon_music: AudioStream
@export var forest_music: AudioStream
@export var sky_music: AudioStream

# Boss music:
@export var boss_intro_music: AudioStream
@export var boss_loop_music: AudioStream

@export var dungeon_music_db := -15.0
@export var forest_music_db := -20.0
@export var sky_music_db := -15.0
@export var boss_music_db := -15.0

# Boss music offsets:
# boss_intro_start_offset skips silence at the start of the boss intro file.
# Example: starts 1 seconds into the .wav.
@export var boss_intro_start_offset := 1
@export var boss_loop_start_offset := 0.0

@onready var player = $Player
@onready var game_over = $CanvasLayer/GameOver
@onready var restart_button = $CanvasLayer/GameOver/HBoxContainer/Button
@onready var level_rewards_ui = $CanvasLayer/LevelReward
@onready var music: AudioStreamPlayer = $Music
@onready var heartContainer = $HeartUI/heartContainer
@onready var map_ui = $CanvasLayer/Map 

var current_room : Node2D
var current_exit : Area2D

var exit_used := false
var waiting_for_boss_loop := false


func _ready():
	run_manager.start_new_run()
	
	if run_manager.map_data.is_empty():
		var gen = MapGenerator.new()
		run_manager.map_data = gen.generate_map()
		run_manager.current_map_node = null
		run_manager.completed_nodes.clear()
	
	apply_starting_upgrades()
	save_data.clear_selected_starting_abilities()
	game_over.hide()
	level_rewards_ui.hide()
	heartContainer.setMaxHearts(player.max_health)

	if music != null and not music.finished.is_connected(_on_music_finished):
		music.finished.connect(_on_music_finished)

	if not map_ui.map_node_selected.is_connected(_on_map_node_selected):
		map_ui.map_node_selected.connect(_on_map_node_selected)

	# Ensure we can return from the rewards screen to the map.
	if not level_rewards_ui.ability_selected.is_connected(_on_ability_reward_selected):
		level_rewards_ui.ability_selected.connect(_on_ability_reward_selected)
	
	# Connect the signal that tells us the upgrade choice is finished.
	if level_rewards_ui.has_signal("upgrade_completed"):
		if not level_rewards_ui.upgrade_completed.is_connected(_on_upgrade_finished):
			level_rewards_ui.upgrade_completed.connect(_on_upgrade_finished)

	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)

	get_tree().paused = true
	map_ui.open_map()


# --- MAP SELECTION LOGIC ---

func _on_map_node_selected(node: MapNode):
	match node.type:
		MapNode.Type.LEVEL:
			_handle_level_node(node)
		MapNode.Type.BOSS:
			_handle_boss_node(node)
		MapNode.Type.UPGRADE:
			_handle_upgrade_node()
		MapNode.Type.HEAL:
			_handle_heal_node()


func _handle_boss_node(node):
	# Directly load the single boss room scene.
	if boss_room != null:
		load_room(boss_room.scene)
	else:
		printerr("Boss room scene not assigned in Inspector!")


func _handle_level_node(_node: MapNode):
	# --- THE FIX: Hijack the first room selection if the tutorial isn't done ---
	if not save_data.has_completed_tutorial():
		print("[GAME] Tutorial active! Overriding map selection to force starting room.")
		
		# Flag it as completed so their next map choice behaves normally
		save_data.complete_tutorial()
		
		if starting_room != null:
			load_room(starting_room)
		else:
			printerr("Starting room scene not assigned in Inspector! Using database fallback.")
			_select_random_database_room()
		return

	# Otherwise, run your normal generation/filtering mechanics
	_select_random_database_room()


# Encapsulated your existing setup to keep the code organized and scannable
func _select_random_database_room():
	var current_abilities = run_manager.get_abilities()
	var all_rooms = room_database.rooms
	var ability_filtered: Array[RoomData] = []
	var final_valid_rooms: Array[RoomData] = []
	
	print("\n--- [ROOM SELECTION START] ---")
	print("Total rooms in Database: ", all_rooms.size())
	
	for rd in all_rooms:
		if _player_can_complete_room(rd, current_abilities):
			ability_filtered.append(rd)
		else:
			var r_name = rd.resource_path.get_file().get_basename()
			print("  [X] Removed (Missing Ability): ", r_name)

	for rd in ability_filtered:
		if not run_manager.visited_room_paths.has(rd.scene.resource_path):
			final_valid_rooms.append(rd)
		else:
			var r_name = rd.resource_path.get_file().get_basename()
			print("  [X] Removed (Already Visited): ", r_name)

	if not final_valid_rooms.is_empty():
		var chosen = final_valid_rooms.pick_random()
		run_manager.visited_room_paths.append(chosen.scene.resource_path)
		load_room(chosen.scene)
	else:
		print("!!! No unique valid rooms left. Picking fallback random.")
		var fallback = room_database.rooms.pick_random()
		load_room(fallback.scene)
	
	print("--- [ROOM SELECTION END] ---\n")


func _handle_upgrade_node():
	# is_upgrade = true skips the room selection phase.
	level_rewards_ui.open_ui(room_database, true)


func _handle_heal_node():
	# Restore 2 life points.
	player.health = min(player.health + 2, player.max_health)
	
	if player.has_signal("health_changed"):
		player.health_changed.emit(player.health)
	
	print("[GAME] Healed at Map Node. Health: ", player.health)
	
	# Short delay for visual feedback before returning to Map.
	await get_tree().create_timer(0.6).timeout
	map_ui.open_map()


func _on_upgrade_finished():
	map_ui.open_map()


func _on_exit_entered(body):
	if body.is_in_group("player") and not exit_used:
		exit_used = true
		get_tree().paused = true
		
		# Levels lead straight back to map.
		map_ui.open_map()


# Utility function moved from Map to LevelManager.
func _player_can_complete_room(room: RoomData, player_abilities: Array) -> bool:
	if room.required_abilities.is_empty():
		return true

	for requirement in room.required_abilities:
		if requirement is Array:
			var has_one_of_group = false
			
			for sub_id in requirement:
				if player_abilities.has(sub_id):
					has_one_of_group = true
					break
			
			if not has_one_of_group:
				return false
		else:
			if not player_abilities.has(requirement):
				return false
	
	return true


func _on_room_selected(_room_data : RoomData):
	# Fallback if a room choice somehow appears; return to map.
	map_ui.open_map()


# --- ROOM LOADING ---

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
			if not exit_node.body_entered.is_connected(_on_exit_entered):
				exit_node.body_entered.connect(_on_exit_entered)
	
	await get_tree().process_frame
	
	get_tree().paused = false
	
	play_music_for_room(room_scene)
	
	await get_tree().create_timer(0.5).timeout
	
	exit_used = false
	
	for c in get_tree().get_nodes_in_group("collectibles"):
		if not c.collected.is_connected(_on_collectible_collected):
			c.collected.connect(_on_collectible_collected)


# --- MUSIC ---

func play_music_for_room(room_scene: PackedScene):
	if room_scene == null:
		print("MUSIC ERROR: room_scene is null.")
		return
	
	if music == null:
		print("MUSIC ERROR: Music node was not found.")
		return
	
	var path := room_scene.resource_path.to_lower()
	
	if "boss" in path:
		play_boss_music()
		return
	
	waiting_for_boss_loop = false
	
	var next_track: AudioStream = dungeon_music
	var next_volume_db := dungeon_music_db
	var track_name := "dungeon"
	
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
	
	if next_track == null:
		print("MUSIC ERROR: No track assigned for ", track_name)
		return
	
	if music.stream == next_track and music.playing:
		music.volume_db = next_volume_db
		return
	
	music.stop()
	music.stream = next_track
	music.volume_db = next_volume_db
	music.play()
	
	print("MUSIC: Now playing ", track_name, " track at ", next_volume_db, " dB.")


func play_boss_music():
	if music == null:
		print("MUSIC ERROR: Music node was not found.")
		return
	
	if boss_intro_music == null and boss_loop_music == null:
		print("MUSIC ERROR: No boss intro or boss loop music assigned.")
		return
	
	# If the boss loop is already playing, do not restart it.
	if music.stream == boss_loop_music and music.playing:
		music.volume_db = boss_music_db
		return
	
	music.stop()
	music.volume_db = boss_music_db
	
	if boss_intro_music != null:
		music.stream = boss_intro_music
		music.play(boss_intro_start_offset)
		waiting_for_boss_loop = true
		print("MUSIC: Now playing boss intro at ", boss_music_db, " dB. Start offset: ", boss_intro_start_offset, " seconds.")
	else:
		music.stream = boss_loop_music
		music.play(boss_loop_start_offset)
		waiting_for_boss_loop = false
		print("MUSIC: No boss intro assigned. Playing boss loop at ", boss_music_db, " dB. Start offset: ", boss_loop_start_offset, " seconds.")


func _on_music_finished():
	if waiting_for_boss_loop and boss_loop_music:
		waiting_for_boss_loop = false
		music.stream = boss_loop_music
		music.volume_db = boss_music_db
		music.play(boss_loop_start_offset)
		print("MUSIC: Boss intro finished. Now playing boss loop. Start offset: ", boss_loop_start_offset, " seconds.")


# --- RESTART & UTILITY ---

func restart_game():
	run_manager.start_new_run()
	game_over.hide()
	player.reset_stats()
	get_tree().change_scene_to_file("res://title_screen/title_screen.tscn")


func apply_starting_upgrades():
	for id in save_data.get_selected_starting_abilities():
		run_manager.add_ability(id)
		player.unlock_ability(id)


func _on_ability_reward_selected(id: String):
	if id != "":
		player.unlock_ability(id)


func _on_player_health_changed(new_health: int):
	heartContainer.updateHealth(new_health)


func _on_player_died():
	game_over.show()
	restart_button.grab_focus()


func _on_collectible_collected(id: String, value: int):
	if not save_data.has_collected(id):
		save_data.mark_collected(id)
		save_data.add_energy(value)
		print("Collectible %s collected. Adding %s energy" % [id, value])
