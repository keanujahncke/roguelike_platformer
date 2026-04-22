extends Button

signal selected(ability_id: String)

@onready var texture_display: TextureRect = $TextureRect
var ability_id: String = ""

func setup(data: AbilityData):
	ability_id = data.id
	texture_display.texture = data.card_art

func _on_pressed():
	selected.emit(ability_id)
