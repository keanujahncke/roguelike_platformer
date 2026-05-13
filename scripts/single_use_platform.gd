extends StaticBody2D
@onready var platform = $Sprite2D
@onready var collision_shape = %CollisionShape2D
@onready var timer = $Timer

var is_broken = false
var origin_pos : Vector2 

func _ready() -> void:
	origin_pos = platform.position 
	set_process(false)

func _process(_delta):
	platform.position.x = origin_pos.x + randf_range(-2.0, 2.0)
	platform.position.y = origin_pos.y + randf_range(-2.0, 2.0)

func _on_area_2d_body_entered(body):
	if body.is_in_group("player") and not is_broken and timer.is_stopped():
		set_process(true)
		timer.start(0.5)

func _on_timer_timeout():
	if not is_broken:
		# --- PLATFORM BREAKS --- #
		is_broken = true
		set_process(false) 
		
		platform.position = origin_pos 
		
		platform.hide() 
		collision_shape.set_deferred("disabled", true)
		timer.start(5.0) 
	else:
		# --- PLATFORM RESPAWNS --- #
		is_broken = false
		platform.show()
		collision_shape.set_deferred("disabled", false)
		
		platform.position = origin_pos
		timer.stop()
