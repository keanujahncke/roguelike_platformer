extends Control

signal dialogue_finished

@export var min_time_before_advance := 0.75
@export var normal_char_interval := 0.025
@export var dot_char_interval := 0.22
@export var punctuation_interval := 0.10

@onready var panel: Panel = $Panel
@onready var label: Label = $Panel/Label

var lines: Array[String] = []
var current_line_index := 0
var active := false

var line_timer := 0.0

var current_full_line := ""
var current_visible_text := ""
var current_char_index := 0
var typing := false
var char_timer := 0.0


func _ready() -> void:
	hide()


func _process(delta: float) -> void:
	if not active:
		return

	line_timer += delta

	if typing:
		_update_typewriter(delta)


func start_dialogue(new_lines: Array[String]) -> void:
	lines = new_lines
	current_line_index = 0
	active = true
	show()
	_show_current_line()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		get_viewport().set_input_as_handled()

		if line_timer < min_time_before_advance:
			return

		if typing:
			_finish_typing_current_line()
		else:
			_advance_dialogue()


func _show_current_line() -> void:
	if current_line_index >= lines.size():
		_end_dialogue()
		return

	current_full_line = lines[current_line_index]

	# Convert the single ellipsis character into three periods
	# so it can appear dot-by-dot.
	current_full_line = current_full_line.replace("…", "...")

	current_visible_text = ""
	current_char_index = 0
	typing = true
	char_timer = 0.0
	line_timer = 0.0

	label.text = ""


func _update_typewriter(delta: float) -> void:
	char_timer -= delta

	while char_timer <= 0.0 and typing:
		if current_char_index >= current_full_line.length():
			typing = false
			label.text = current_full_line
			return

		var next_char := current_full_line[current_char_index]

		current_visible_text += next_char
		label.text = current_visible_text
		current_char_index += 1

		char_timer += _get_delay_for_character(next_char)


func _get_delay_for_character(character: String) -> float:
	if character == ".":
		return dot_char_interval

	if character == "," or character == "!" or character == "?" or character == ":" or character == ";":
		return punctuation_interval

	return normal_char_interval


func _finish_typing_current_line() -> void:
	typing = false
	current_visible_text = current_full_line
	current_char_index = current_full_line.length()
	label.text = current_full_line


func _advance_dialogue() -> void:
	current_line_index += 1

	if current_line_index >= lines.size():
		_end_dialogue()
	else:
		_show_current_line()


func _end_dialogue() -> void:
	active = false
	typing = false
	hide()
	dialogue_finished.emit()
