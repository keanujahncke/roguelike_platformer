extends Control

signal selected(data)

@onready var image = $TextureRect
@onready var button = $Button

var data : RoomData


func setup(room_data : RoomData):
	data = room_data
	image.texture = data.preview


func _ready():
	button.pressed.connect(_pressed)


func _pressed():
	selected.emit(data)
