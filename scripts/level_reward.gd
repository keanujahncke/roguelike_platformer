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
	var pool = available_abilities.duplicate()
	pool.shuffle()

	for res in pool.slice(0, 2):
		var card = card_template.instantiate()
		reward_container.add_child(card)
		card.setup(res)
		card.selected.connect(_on_ability_clicked)

	if reward_container.get_child_count() > 0:
		reward_container.get_child(0).button.grab_focus()

# --- REFACTORED CLICK LOGIC ---
func _on_ability_clicked(res: AbilityData):
	save_data.unlock_seen_ability(res.id)
	save_data.add_energy(1)
	print("Max Energy increased! New Max: ", save_data.get_max_energy())
	
	run_manager.add_ability(res.id)
	ability_selected.emit(res.id)
	
	reward_section.hide()
	level_section.show()
	
	_setup_levels()

func _setup_levels():
	
	_clear_container(level_container)
	
	var current_abilities = run_manager.get_abilities()
	var valid_rooms: Array[RoomData] = []
	
	for room in stored_db.rooms:
		if _player_can_complete_room(room, current_abilities):
			valid_rooms.append(room)
			
	valid_rooms.shuffle()
	
	for res in valid_rooms.slice(0, rooms_to_show):
		var card = card_template.instantiate()
		level_container.add_child(card)
		card.setup(res)
		card.selected.connect(_on_level_clicked)

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

func _clear_container(c):
	for child in c.get_children():
		child.queue_free()
