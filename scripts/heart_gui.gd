extends Panel

@onready var sprite = $Sprite2D

func update(full_heart: bool):
	if full_heart: sprite.frame = 0
	else: sprite.frame = 2
	
	
