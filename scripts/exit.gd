extends Area2D

# We don't need a custom signal here if we use the built-in one
func _ready():
	add_to_group("exits")
	monitoring = true
	monitorable = true
