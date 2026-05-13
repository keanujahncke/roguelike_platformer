extends CanvasLayer

signal ability_selected(id: String)
signal upgrade_completed # Notifies LevelManager to return to map

const HEAL_REWARD_ID := "heal_1"

@export_group("Templates")
@export var card_template: PackedScene

@export_group("Data Pool")
@export var available_abilities: Array[AbilityData] = []
@export var rewards_to_show: int = 2

@onready var reward_section = $CenterContainer/VBoxContainer/RewardSection
@onready var reward_container = $CenterContainer/VBoxContainer/RewardSection/HBoxContainer

# Removed level_section and level_container references

func _ready():
	hide()
	process_mode = PROCESS_MODE_ALWAYS


func open_ui(_db: RoomDatabase = null, _is_upgrade: bool = false):
	# db and is_upgrade parameters kept for signature compatibility with LevelManager
	if visible:
		return

	show()
	get_tree().paused = true

	reward_section.show()
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

	# Always include restore life if it exists
	if heal_reward != null:
		reward_choices.append(heal_reward)

	# Fill slots with abilities the player does not have
	var remaining_slots := rewards_to_show - reward_choices.size()
	if remaining_slots > 0:
		for reward in ability_pool.slice(0, remaining_slots):
			reward_choices.append(reward)

	if reward_choices.is_empty():
		_close_ui.call_deferred()
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
		# Sync with run_manager for future room filtering
		run_manager.add_ability(res.id)
		ability_selected.emit(res.id)
	
	_close_ui()


func _close_ui():
	hide()
	get_tree().paused = false
	upgrade_completed.emit() # Signal manager to go back to map


func _restore_one_life():
	var player = get_tree().get_first_node_in_group("player")
	if player == null: return

	player.health = min(player.health + 1, player.max_health)
	if player.has_signal("health_changed"):
		player.health_changed.emit(player.health)


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


func _clear_container(c):
	for child in c.get_children():
		child.queue_free()
