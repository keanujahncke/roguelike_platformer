extends Node
class_name UISFXConnector

@export var move_between_options_sfx: AudioStream
@export var choose_option_sfx: AudioStream

@export var move_sfx_volume_db: float = 0.0
@export var choose_sfx_volume_db: float = 0.0

@export var auto_find_buttons_under_parent: bool = true
@export var manual_buttons: Array[Button] = []
@export var menu_roots: Array[NodePath] = []

@export var play_move_sfx_on_mouse_hover: bool = false
@export var play_move_sfx_on_keyboard_focus: bool = true
@export var play_choose_sfx_on_button_pressed: bool = true

var move_sfx_player: AudioStreamPlayer
var choose_sfx_player: AudioStreamPlayer

var connected_buttons: Array[Button] = []


func _ready() -> void:
	_create_audio_players()
	_connect_all_buttons()


func _create_audio_players() -> void:
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


func _connect_all_buttons() -> void:
	connected_buttons.clear()

	for button in manual_buttons:
		_connect_button(button)

	if auto_find_buttons_under_parent:
		if menu_roots.is_empty():
			var parent_node := get_parent()
			if parent_node != null:
				_find_buttons_recursive(parent_node)
		else:
			for root_path in menu_roots:
				var root_node := get_node_or_null(root_path)

				if root_node != null:
					_find_buttons_recursive(root_node)
				else:
					push_warning("UISFXConnector: Could not find menu root: " + str(root_path))


func _find_buttons_recursive(node: Node) -> void:
	if node is Button:
		_connect_button(node)

	for child in node.get_children():
		_find_buttons_recursive(child)


func _connect_button(button: Button) -> void:
	if button == null:
		return

	if connected_buttons.has(button):
		return

	connected_buttons.append(button)

	if play_move_sfx_on_mouse_hover:
		if not button.mouse_entered.is_connected(_on_button_mouse_entered):
			button.mouse_entered.connect(_on_button_mouse_entered)

	if play_move_sfx_on_keyboard_focus:
		if not button.focus_entered.is_connected(_on_button_focus_entered):
			button.focus_entered.connect(_on_button_focus_entered)

	if play_choose_sfx_on_button_pressed:
		if not button.pressed.is_connected(_on_button_pressed):
			button.pressed.connect(_on_button_pressed)


func _on_button_mouse_entered() -> void:
	play_move_between_options_sfx()


func _on_button_focus_entered() -> void:
	play_move_between_options_sfx()


func _on_button_pressed() -> void:
	play_choose_option_sfx()


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
