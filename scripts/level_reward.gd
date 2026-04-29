# level_reward.gd
extends CanvasLayer

signal ability_selected(id: String)
signal room_selected(room_data: RoomData)

@export_group("Templates")
@export var card_template: PackedScene

@export_group("Data Pool")
@export var available_abilities: Array[AbilityData] = []
@export var rooms_to_show: int = 2

@onready var reward_section = $CenterContainer/VBoxContainer/RewardSection
@onready var reward_container = $CenterContainer/VBoxContainer/RewardSection/HBoxContainer
# next_button is no longer needed for the flow, but you can keep the @onready if you don't want to delete the node yet

@onready var level_section = $CenterContainer/VBoxContainer/LevelSection
@onready var level_container = $CenterContainer/VBoxContainer/LevelSection/HBoxContainer

var stored_db: RoomDatabase
# selected_id is effectively local now, but keeping it as a class var is fine

func _ready():
	hide()
	process_mode = PROCESS_MODE_ALWAYS
	# Removed next_button connection

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
	var pool = available_abilities.duplicate()
	pool.shuffle()

	for res in pool.slice(0, 3):
		var card = card_template.instantiate()
		reward_container.add_child(card)
		card.setup(res)
		card.selected.connect(_on_ability_clicked)

	if reward_container.get_child_count() > 0:
		reward_container.get_child(0).button.grab_focus()

# --- REFACTORED CLICK LOGIC ---
func _on_ability_clicked(res: AbilityData):
	# 1. Save the fact that we saw/unlocked it
	save_data.unlock_seen_ability(res.id)
	save_data.add_energy(1)
	print("Max Energy increased! New Max: ", save_data.get_max_energy())
	
	# 2. Tell the Game manager to apply the ability
	ability_selected.emit(res.id)

	# 3. Transition UI immediately
	reward_section.hide()
	level_section.show()

	# 4. Show the levels
	_setup_levels()

func _setup_levels():
	_clear_container(level_container)
	var pool = stored_db.rooms.duplicate()
	pool.shuffle()

	for res in pool.slice(0, rooms_to_show):
		var card = card_template.instantiate()
		level_container.add_child(card)
		card.setup(res)
		card.selected.connect(_on_level_clicked)

	if level_container.get_child_count() > 0:
		level_container.get_child(0).button.grab_focus()

func _on_level_clicked(res: RoomData):
	room_selected.emit(res)
	hide()

func _clear_container(c):
	for child in c.get_children():
		child.queue_free()
