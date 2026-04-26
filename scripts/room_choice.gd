extends Control

signal selected(data)

@onready var image = $TextureRect
@onready var button = $Button

var data # Holds either RoomData or AbilityData

func _ready():
	button.pressed.connect(_pressed)

func setup(incoming_data):
	data = incoming_data
	
	if data is AbilityData:
		image.texture = data.card_art
	elif data is RoomData:
		image.texture = data.preview

func _pressed():
	# Emit the whole resource back to the UI manager
	messages.save_requested.emit()
	selected.emit(data)
