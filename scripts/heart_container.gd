extends HBoxContainer

@onready var HeartGui = preload("res://scenes/heart_gui.tscn")

var hearts: Array = []

func setMaxHearts(max_hp: int):
	for child in get_children():
		child.queue_free()
	hearts.clear()

	for i in range(max_hp):
		var heart = HeartGui.instantiate()
		add_child(heart)
		hearts.append(heart)

func updateHealth(current_hp: int):
	var hearts = get_children()
	for i in range(current_hp):
		hearts[i].update(true)
		
	for i in range(current_hp, hearts.size()):
		hearts[i].update(false)
