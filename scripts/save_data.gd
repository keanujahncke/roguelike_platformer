extends Node

var current_slot := -1

const SAVE_FOLDER := "res://saves/"


func get_save_path() -> String:
	var path = SAVE_FOLDER + "save_slot_%d.json" % current_slot
	return path


var data = {
	"max_energy": 1,
	"seen_abilities": [],
	"selected_starting_abilities": []
}


func _ready():
	#load_save()
	if not DirAccess.dir_exists_absolute(SAVE_FOLDER):
		DirAccess.make_dir_recursive_absolute(SAVE_FOLDER)


# ==================================================
# SAVE / LOAD
# ==================================================

func save():
	var path = get_save_path()

	var file = FileAccess.open(path, FileAccess.WRITE)

	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("Saved Slot ", current_slot)


func load_save() -> bool:
	var path = get_save_path()
	if not FileAccess.file_exists(path):
		reset_save()
		return true

	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(text)
		
		if typeof(parsed) == TYPE_DICTIONARY:
			# DO NOT DO: data = parsed
			# DO THIS INSTEAD:
			data.clear()
			for key in parsed:
				data[key] = parsed[key]
			
			_apply_missing_defaults()
			print("Successfully refreshed data for Slot: ", current_slot)
			return true
	return false


func _apply_missing_defaults():
	if not data.has("max_energy"):
		data["max_energy"] = 1

	if not data.has("seen_abilities"):
		data["seen_abilities"] = []

	if not data.has("selected_starting_abilities"):
		data["selected_starting_abilities"] = []


func reset_save():
	data = {
		"max_energy": 1,
		"seen_abilities": [],
		"selected_starting_abilities": []
	}

	save()


# ==================================================
# META HELPERS
# ==================================================

func get_max_energy() -> int:
	return data["max_energy"]


func add_energy(amount: int):
	data["max_energy"] += amount
	save()


func get_seen_abilities() -> Array:
	return data["seen_abilities"]


func has_seen_ability(id: String) -> bool:
	return data["seen_abilities"].has(id)


func unlock_seen_ability(id: String):
	if not data["seen_abilities"].has(id):
		data["seen_abilities"].append(id)
		save()


func set_selected_starting_abilities(list: Array):
	data["selected_starting_abilities"] = list
	save()


func get_selected_starting_abilities() -> Array:
	return data["selected_starting_abilities"]


func clear_selected_starting_abilities():
	data["selected_starting_abilities"] = []
	save()
