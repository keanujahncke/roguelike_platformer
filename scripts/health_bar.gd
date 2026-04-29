extends HBoxContainer

@onready var HealthBar = preload("res://scenes/health_bar.tscn")

var hearts: Array = []

func setMaxHearts(max_hp: int):
	
	for child in get_children():
		child.queue_free()
	hearts.clear()

	for i in range(max_hp):
		var heart = HealthBar.instantiate()
		add_child(heart)
		hearts.append(heart)

func updateHealth(current_hp: int):
	for i in range(hearts.size()):
		if i < current_hp:
			hearts[i].visible = true
		else:
			hearts[i].visible = false
