extends StaticBody2D

@onready var platform = $Sprite2D
@onready var timer = $Timer

var time = 1

func _ready() -> void:
	set_process(false)

func _process(delta):
	time += 1
	platform.position += Vector2(0, sin(time) * 2)

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		set_process(true)
		timer.start(0.5)

func _on_timer_timeout():
	queue_free()
