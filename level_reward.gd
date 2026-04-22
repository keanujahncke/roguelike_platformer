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
@onready var next_button = $CenterContainer/VBoxContainer/RewardSection/NextButton

@onready var level_section = $CenterContainer/VBoxContainer/LevelSection
@onready var level_container = $CenterContainer/VBoxContainer/LevelSection/HBoxContainer

var stored_db: RoomDatabase
var selected_id: String = ""

func _ready():
	hide()
	process_mode = PROCESS_MODE_ALWAYS
	next_button.pressed.connect(_on_next_pressed)

func open_ui(db: RoomDatabase):
	stored_db = db
	selected_id = ""

	show()
	get_tree().paused = true

	reward_section.show()
	level_section.hide()
	next_button.hide()

	_setup_abilities()

func _setup_abilities():
	_clear_container(reward_container)

	var pool = available_abilities.duplicate()
	pool.shuffle()

	for res in pool.slice(0, 3):
		var card = card_template.instantiate()
		reward_container.add_child(card)

		card.setup(res)

		# IMPORTANT: pass the actual AbilityData resource
		card.selected.connect(_on_ability_clicked)

	if reward_container.get_child_count() > 0:
		reward_container.get_child(0).button.grab_focus()

func _on_ability_clicked(res: AbilityData):
	# use the resource id directly
	selected_id = res.id

	print("Selected ability:", selected_id)

	next_button.show()
	next_button.grab_focus()

func _on_next_pressed():
	# sends "dash", "wall_jump", etc.
	ability_selected.emit(selected_id)

	reward_section.hide()
	level_section.show()

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
	get_tree().paused = false

func _clear_container(c):
	for child in c.get_children():
		child.queue_free()
