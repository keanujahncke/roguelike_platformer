extends Area2D

signal collected

@export var id: String = ""
@export var value: int = 1

func _ready():
	body_entered.connect(_on_body_entered)
	if save_data.has_collected(id):
		queue_free()

func _process(delta):
	position.y += sin(Time.get_ticks_msec() / 200.0) * 0.2

func _on_body_entered(body):
	if body.is_in_group("player"):
		collect()

func collect():
	emit_signal("collected", id, value)
	queue_free()
