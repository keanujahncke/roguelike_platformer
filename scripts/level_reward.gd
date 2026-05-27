extends CanvasLayer

signal ability_selected(id: String)
signal upgrade_completed

const HEAL_REWARD_ID := "heal_1"

@export_group("Templates")
@export var card_template: PackedScene

@export_group("Data Pool")
@export var available_abilities: Array[AbilityData] = []
@export var rewards_to_show: int = 2

@export_group("SFX")
@export var move_between_options_sfx: AudioStream
@export var choose_option_sfx: AudioStream
@export var move_sfx_volume_db: float = 0.0
@export var choose_sfx_volume_db: float = 0.0
@export var choose_sfx_delay_before_close: float = 0.12

@onready var reward_section = $CenterContainer/VBoxContainer/RewardSection
@onready var reward_container = $CenterContainer/VBoxContainer/RewardSection/HBoxContainer

var move_sfx_player: AudioStreamPlayer
var choose_sfx_player: AudioStreamPlayer
var reward_choice_locked := false


func _ready():
	hide()
	process_mode = PROCESS_MODE_ALWAYS
	_create_sfx_players()


func _create_sfx_players() -> void:
	move_sfx_player = AudioStreamPlayer.new()
	move_sfx_player.name = "MoveBetweenOptionsSFXPlayer"
	add_child(move_sfx_player)

	choose_sfx_player = AudioStreamPlayer.new()
	choose_sfx_player.name = "ChooseOptionSFXPlayer"
	add_child(choose_sfx_player)

	move_sfx_player.stream = move_between_options_sfx
	choose_sfx_player.stream = choose_option_sfx

	move_sfx_player.volume_db = move_sfx_volume_db
	choose_sfx_player.volume_db = choose_sfx_volume_db


func play_move_between_options_sfx() -> void:
	if move_sfx_player == null:
		return

	if move_sfx_player.stream == null:
		return

	move_sfx_player.volume_db = move_sfx_volume_db
	move_sfx_player.stop()
	move_sfx_player.play()


func play_choose_option_sfx() -> void:
	if choose_sfx_player == null:
		return

	if choose_sfx_player.stream == null:
		return

	choose_sfx_player.volume_db = choose_sfx_volume_db
	choose_sfx_player.stop()
	choose_sfx_player.play()


func open_ui(_is_upgrade: bool = false):
	if visible:
		return

	reward_choice_locked = false

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

	if heal_reward != null:
		reward_choices.append(heal_reward)

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

		if "button" in card:
			buttons.append(card.button)
			_connect_reward_button_sfx(card.button)
		elif card is Button:
			buttons.append(card)
			_connect_reward_button_sfx(card)

	_setup_button_focus(buttons)


func _connect_reward_button_sfx(btn: Button) -> void:
	if btn == null:
		return

	if not btn.focus_entered.is_connected(_on_reward_button_focused):
		btn.focus_entered.connect(_on_reward_button_focused)


func _on_reward_button_focused() -> void:
	play_move_between_options_sfx()


func _on_reward_clicked(res: AbilityData):
	if reward_choice_locked:
		return

	reward_choice_locked = true

	play_choose_option_sfx()

	if choose_sfx_delay_before_close > 0.0:
		await get_tree().create_timer(choose_sfx_delay_before_close).timeout

	if res.id == HEAL_REWARD_ID:
		_restore_one_life()
		ability_selected.emit("")
	else:
		run_manager.add_ability(res.id)
		save_data.unlock_seen_ability(res.id)
		ability_selected.emit(res.id)
	
	_close_ui()


func _close_ui():
	hide()
	get_tree().paused = false
	upgrade_completed.emit()


func _restore_one_life():
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

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
