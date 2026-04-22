extends Control

## Signal emitted when the player clicks a card
signal ability_selected(id: String)

@export var card_scene: PackedScene
## Drag your AbilityData .tres files into this array in the Inspector
@export var available_abilities: Array[AbilityData] = []

@onready var card_container = $CenterContainer/VBoxContainer/HBoxContainer

func _ready():
	# Ensure the menu starts hidden
	hide()

## Called by LevelManager when the player hits a room exit
func open_reward_menu():
	# 1. Filter out abilities the player already has (Optional but recommended)
	var valid_choices = _get_unlocked_pool()
	
	if valid_choices.is_empty():
		# If everything is already unlocked, skip to room selection
		ability_selected.emit("none")
		return

	# 2. Setup the UI
	_clear_cards()
	show()
	get_tree().paused = true
	
	# 3. Shuffle and pick up to 3 choices
	valid_choices.shuffle()
	var choices = valid_choices.slice(0, 3)
	
	# 4. Instantiate cards
	for data in choices:
		var card = card_scene.instantiate()
		card_container.add_child(card)
		
		# Pass the Resource to the card setup
		if card.has_method("setup"):
			card.setup(data)
		
		# Connect the card's internal signal to our handler
		card.selected.connect(_on_card_clicked)

	# 5. Grab focus for controller/keyboard support
	if card_container.get_child_count() > 0:
		card_container.get_child(0).grab_focus()


func _on_card_clicked(id: String):
	# Apply the upgrade to the player
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("unlock_ability"):
		player.unlock_ability(id)
	
	# Close the menu and resume time
	hide()
	get_tree().paused = false
	
	# Tell LevelManager we are done so it can show the Room Picker
	ability_selected.emit(id)


func _clear_cards():
	for child in card_container.get_children():
		child.queue_free()


## Helper to ensure we don't offer things the player already owns
func _get_unlocked_pool() -> Array[AbilityData]:
	var player = get_tree().get_first_node_in_group("player")
	if not player: 
		return available_abilities
		
	var pool: Array[AbilityData] = []
	for ability_data in available_abilities:
		# Assumes your ability nodes are named like "DashAbility"
		var node_name = ability_data.id.capitalize().replace(" ", "") + "Ability"
		var ability_node = player.get_node_or_null("Abilities/" + node_name)
		
		if ability_node and not ability_node.unlocked:
			pool.append(ability_data)
			
	return pool
