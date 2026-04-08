extends Control

@export var choice_scene : PackedScene

@onready var container = $CenterContainer/VBoxContainer/ChoiceContainer/MarginContainer/HBoxContainer

signal room_selected(data)

func _ready():
	visible = false

func show_choices(choices):
	visible = true

	for c in container.get_children():
		c.queue_free()

	for room in choices:
		var choice = choice_scene.instantiate()
		container.add_child(choice)

		choice.setup(room)
		choice.selected.connect(_on_selected)


func _on_selected(data):
	visible = false
	room_selected.emit(data)
