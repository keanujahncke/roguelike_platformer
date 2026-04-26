extends Node

const BASE_PATH = "user://savegame_"
var current_slot : int = 0

func _ready():
	messages.save_requested.connect(save_game)

func get_file_path(slot: int) -> String:
	return BASE_PATH + str(slot) + ".json"

func save_slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(get_file_path(slot))

func save_game():
	var player = get_tree().get_first_node_in_group("player")
	if not player: return

	var unlocked_list = []
	if player.abilities_root:
		for ability in player.abilities_root.get_children():
			if "unlocked" in ability and ability.unlocked:
				unlocked_list.append(ability.name)

	var data = {
		"health": player.health,
		"max_health": player.max_health,
		"unlocked_abilities": unlocked_list,
		"current_room_path": player.current_room.scene_file_path if player.current_room else ""
	}

	var file = FileAccess.open(get_file_path(current_slot), FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	print("Saved to Slot: ", current_slot)

func load_game():
	var path = get_file_path(current_slot)
	if not FileAccess.file_exists(path):
		return null
	
	var file = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	return data
