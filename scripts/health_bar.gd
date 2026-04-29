extends HBoxContainer

@onready var HealthBar = preload("res://scenes/health_bar.tscn")

func setMaxHearts(max: int):
	for i in range(max):
		var heart = HealthBar.instantiate()
		add_child(heart)
