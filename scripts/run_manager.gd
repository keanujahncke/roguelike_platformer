extends Node

var current_run_abilities: Array = []

func start_new_run():
	current_run_abilities = save_data.get_selected_starting_abilities().duplicate()
	print("Run Started! Initial Abilities: ", current_run_abilities)

func add_ability(id: String):
	if not current_run_abilities.has(id):
		current_run_abilities.append(id)
		print("Run Ability Added: ", id)

func get_abilities() -> Array:
	return current_run_abilities
