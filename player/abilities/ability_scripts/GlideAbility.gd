extends Ability
class_name GlideAbility

@export var glide_fall_speed := 50.0
@export var glide_gravity := 100.0

# UI Compatibility variables
var cooldown_max := 0.0
var cooldown_left := 0.0

var is_gliding := false

func setup(_player):
	cooldown_max = 0.0
	cooldown_left = 0.0

func ability_process(player, delta):
	if not unlocked:
		is_gliding = false
		return

	# Reset gliding state when on floor
	if player.is_on_floor():
		is_gliding = false
		return

	# Check for glide input while falling
	if Input.is_action_pressed("glide") and player.velocity.y > 0:
		is_gliding = true
		
		# Apply glide physics
		player.velocity.y += glide_gravity * delta
		player.velocity.y = min(player.velocity.y, glide_fall_speed)
	else:
		is_gliding = false
