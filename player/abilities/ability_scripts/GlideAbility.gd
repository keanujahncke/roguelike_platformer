extends Ability
class_name GlideAbility

@export var glide_fall_speed := 50.0
@export var glide_gravity := 100.0
@export var glide_cooldown := 1.0

var cooldown_max := 0.0
var cooldown_left := 0.0

var is_gliding := false
var was_gliding_last_frame := false

func setup(_player):
	cooldown_max = glide_cooldown
	cooldown_left = 0.0

func ability_process(player, delta):
	if not unlocked:
		is_gliding = false
		return
		
	if cooldown_left > 0.0 and not is_gliding:
		cooldown_left = max(cooldown_left - delta, 0.0)

	is_gliding = false

	if player.is_on_floor():
		if was_gliding_last_frame:
			cooldown_max = glide_cooldown
			cooldown_left = cooldown_max
			was_gliding_last_frame = false
		return

	if Input.is_action_pressed("glide") and player.velocity.y > 0 and (cooldown_left <= 0.0 or was_gliding_last_frame):
		is_gliding = true
		was_gliding_last_frame = true
		
		cooldown_max = 1.0
		cooldown_left = 1.0

		player.velocity.y += glide_gravity * delta
		player.velocity.y = min(player.velocity.y, glide_fall_speed)
		
	else:
		if was_gliding_last_frame:
			cooldown_max = glide_cooldown
			cooldown_left = cooldown_max
			was_gliding_last_frame = false
		
