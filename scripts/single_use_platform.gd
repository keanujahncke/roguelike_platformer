extends StaticBody2D
@onready var platform = $Sprite2D
@onready var collision_shape = %CollisionShape2D
@onready var timer = $Timer

var time = 0.0
var is_broken = false

func _ready() -> void:
	set_process(false)

func _process(delta):
	time += delta * 20 
	platform.position.y += sin(time) * 1.5

func _on_area_2d_body_entered(body):
	if body.is_in_group("player") and not is_broken:
		set_process(true)
		timer.start(0.5) # Time until platform breaks

func _on_timer_timeout():
	if not is_broken:
		# --- PLATFORM BREAKS --- #
		is_broken = true
		set_process(false)
		platform.hide() 
		collision_shape.set_deferred("disabled", true)
		
		timer.start(5.0) # Wait 5 to respawn platform
	else:
		# --- PLATFORM RESPAWNS --- #
		is_broken = false
		platform.show()
		collision_shape.set_deferred("disabled", false)
		platform.position = Vector2.ZERO
