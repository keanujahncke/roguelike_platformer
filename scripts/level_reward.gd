# level_reward.gd
extends CanvasLayer

signal ability_selected(id: String)
signal room_selected(room_data: RoomData)

const HEAL_REWARD_ID := "heal_1"

@export_group("Templates")
@export var card_template: PackedScene

@export_group("Data Pool")
@export var available_abilities: Array[AbilityData] = []
@export var rewards_to_show: int = 2
@export var rooms_to_show: int = 2

@onready var reward_section = $CenterContainer/VBoxContainer/RewardSection
@onready var reward_container = $CenterContainer/VBoxContainer/RewardSection/HBoxContainer

@onready var level_section = $CenterContainer/VBoxContainer/LevelSection
@onready var level_container = $CenterContainer/VBoxContainer/LevelSection/HBoxContainer

var stored_db: RoomDatabase


func _ready():
	hide()
	process_mode = PROCESS_MODE_ALWAYS


func open_ui(db: RoomDatabase):
	if visible:
		return

	stored_db = db
	show()
	get_tree().paused = true

	reward_section.show()
	level_section.hide()

	_setup_abilities()


func _setup_abilities():
	_clear_container(reward_container)

	var current_abilities = run_manager.get_abilities()

	var heal_reward: AbilityData = null
	var ability_pool: Array[AbilityData] = []

	for reward in available_abilities:
		if reward.id == HEAL_REWARD_ID:
			heal_reward = reward
		elif not current_abilities.has(reward.id):
			ability_pool.append(reward)

	ability_pool.shuffle()

	var reward_choices: Array[AbilityData] = []

	# Always include restore life if it exists in available_abilities.
	if heal_reward != null:
		reward_choices.append(heal_reward)

	# Fill the rest of the choices with normal abilities the player does not have.
	var remaining_slots := rewards_to_show - reward_choices.size()
	if remaining_slots > 0:
		for reward in ability_pool.slice(0, remaining_slots):
			reward_choices.append(reward)

	# If no normal abilities are left AND no heal reward exists, skip to room selection.
	if reward_choices.is_empty():
		print("No rewards left. Skipping directly to room selection.")
		reward_section.hide()
		level_section.show()
		_setup_levels()
		return

	var buttons = []

	for res in reward_choices:
		var card = card_template.instantiate()
		reward_container.add_child(card)
		card.setup(res)
		card.selected.connect(_on_reward_clicked)

		buttons.append(card.button)

	_setup_button_focus(buttons)


func _on_reward_clicked(res: AbilityData):
	if res.id == HEAL_REWARD_ID:
		_restore_one_life()
		ability_selected.emit("")
	else:
		save_data.unlock_seen_ability(res.id)
		save_data.add_energy(1)
		print("Max Energy increased! New Max: ", save_data.get_max_energy())

		run_manager.add_ability(res.id)
		ability_selected.emit(res.id)

	reward_section.hide()
	level_section.show()

	_setup_levels()


func _restore_one_life():
	var player = get_tree().get_first_node_in_group("player")

	if player == null:
		print("Heal reward failed: player not found.")
		return

	player.health = min(player.health + 1, player.max_health)

	if player.has_signal("health_changed"):
		player.health_changed.emit(player.health)

	print("Restored 1 life. Current health: ", player.health)


func _setup_levels():
	_clear_container(level_container)

	var current_abilities = run_manager.get_abilities()
	var valid_rooms: Array[RoomData] = []

	for room in stored_db.rooms:
		if _player_can_complete_room(room, current_abilities):
			valid_rooms.append(room)

	valid_rooms.shuffle()

	var buttons = []

	for res in valid_rooms.slice(0, rooms_to_show):
		var card = card_template.instantiate()
		level_container.add_child(card)
		card.setup(res)
		card.selected.connect(_on_level_clicked)

		buttons.append(card.button)

	_setup_button_focus(buttons)


func _setup_button_focus(buttons: Array):
	for i in range(buttons.size()):
		var btn = buttons[i]

		if i > 0:
			btn.focus_neighbor_left = buttons[i - 1].get_path()
		if i < buttons.size() - 1:
			btn.focus_neighbor_right = buttons[i + 1].get_path()

	if buttons.size() > 1:
		buttons[0].focus_neighbor_left = buttons[-1].get_path()
		buttons[-1].focus_neighbor_right = buttons[0].get_path()

	if buttons.size() > 0:
		buttons[0].grab_focus()


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


func _on_level_clicked(res: RoomData):
	room_selected.emit(res)
	hide()
	get_tree().paused = false


func _clear_container(c):
	for child in c.get_children():
		child.queue_free()
