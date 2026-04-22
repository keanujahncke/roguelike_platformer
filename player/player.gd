extends CharacterBody2D

signal died

var current_room: Node2D
var is_dead := false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var abilities_root = $Abilities

var abilities: Array = []

# MOVEMENT
@export var move_speed := 175.0
@export var acceleration := 1400.0
@export var friction := 1800.0

# JUMP
@export var jump_velocity := -300.0
@export var gravity := 1000.0
@export var fall_gravity := 1000.0
@export var jump_peak_gravity := 600.0

# FORGIVENESS
@export var coyote_time := 0.10
@export var jump_buffer_time := 0.20

var coyote_timer := 0.0
var jump_buffer_timer := 0.0

# STATE
var facing: int = 1
var was_running := false
var is_stopping := false
var run_time := 0.0
var is_doing_double_jump := false

@export var stop_min_run_time := 0.2

@export var max_health := 5
var health := 5



func _ready():
	anim.play("idle")

	for child in abilities_root.get_children():
		abilities.append(child)

		if child.has_method("setup"):
			child.setup(self)


func _physics_process(delta):
	if is_dead:
		return

	coyote_timer -= delta
	jump_buffer_timer -= delta

	var input_axis: float = Input.get_axis("move_left", "move_right")

	if input_axis != 0:
		facing = int(sign(input_axis))

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	if is_on_floor():
		coyote_timer = coyote_time

	# gravity
	if not is_on_floor() and not is_dash_active():
		if velocity.y < 0 and Input.is_action_pressed("jump"):
			velocity.y += jump_peak_gravity * delta
		else:
			velocity.y += (fall_gravity if velocity.y > 0 else gravity) * delta

	# jump
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0
		coyote_timer = 0

	# short hop
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

	# movement (NO slide / NO momentum interference)
	if not is_dash_active():
		if input_axis != 0:
			velocity.x = move_toward(
				velocity.x,
				input_axis * move_speed,
				acceleration * delta
			)
		else:
			velocity.x = move_toward(
				velocity.x,
				0.0,
				friction * delta
			)

	# abilities
	for ability in abilities:
		if ability.has_method("ability_process"):
			ability.ability_process(self, delta)

	move_and_slide()

	check_hazards()

	anim.flip_h = facing < 0

	update_animation(input_axis, delta)


func is_dash_active() -> bool:
	if has_node("Abilities/DashAbility"):
		return $Abilities/DashAbility.is_dashing
	return false


func update_animation(input_axis: float, delta: float):
	var is_running: bool = abs(velocity.x) > 1.0 and input_axis != 0.0

	if is_doing_double_jump:
		if anim.animation == "double_jump" and anim.is_playing():
			return
		else:
			is_doing_double_jump = false

	if is_running and is_on_floor():
		run_time += delta

	# dash priority
	if is_dash_active():
		play_anim("dash")
		return

	# wall slide priority
	if has_node("Abilities/WallJumpAbility"):
		if $Abilities/WallJumpAbility.is_wall_sliding:
			play_anim("wall_slide")
			return

	# glide priority
	if has_node("Abilities/GlideAbility"):
		if $Abilities/GlideAbility.is_gliding:
			play_anim("glide")
			return

	# air states
	if not is_on_floor():
		is_stopping = false

		if velocity.y < 0:
			play_anim("jump")
		else:
			play_anim("fall")

		was_running = is_running
		return

	# stop animation
	if (
		was_running
		and input_axis == 0.0
		and abs(velocity.x) > 1.0
		and not is_stopping
		and run_time >= stop_min_run_time
	):
		is_stopping = true
		anim.play("stop")
		was_running = false
		run_time = 0.0
		return

	if is_stopping:
		if not anim.is_playing() \
		or anim.frame >= anim.sprite_frames.get_frame_count("stop") - 1:
			is_stopping = false
			anim.play("idle")
		return

	if is_running:
		play_anim("run")
		was_running = true
	else:
		play_anim("idle")
		was_running = false
		run_time = 0.0


func play_anim(name: String):
	if anim.animation != name:
		anim.play(name)


func die_and_respawn():
	if is_dead:
		return

	is_dead = true
	died.emit()
	velocity = Vector2.ZERO


func check_hazards():
	if is_dead:
		return
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)

		if collision == null:
			continue

		var collider = collision.get_collider()

		if collider and collider.is_in_group("hazard"):
			take_damage(1)
			return
			
func take_damage(amount: int):
	health -= amount
	print("Hearts left: ", health)

	if health <= 0:
		is_dead = true
		died.emit() 
	else:
		var spawn = current_room.get_node("Spawn")
		global_position = spawn.global_position
		velocity = Vector2.ZERO

func reset_stats():
	is_dead = false
	health = max_health
	velocity = Vector2.ZERO
	set_physics_process(true)
	anim.play("idle")
	
	if abilities_root:
		for ability in abilities_root.get_children():
			if "unlocked" in ability:
				ability.unlocked = false
				
	print("STATS RESET: Player revived and abilities locked.")

func unlock_ability(name: String):
	match name:
		"dash":
			if has_node("Abilities/DashAbility"):
				$Abilities/DashAbility.unlocked = true

		"wall_jump":
			if has_node("Abilities/WallJumpAbility"):
				$Abilities/WallJumpAbility.unlocked = true

		"double_jump":
			if has_node("Abilities/DoubleJumpAbility"):
				$Abilities/DoubleJumpAbility.unlocked = true

		"glide":
			if has_node("Abilities/GlideAbility"):
				$Abilities/GlideAbility.unlocked = true

		"phase_dash":
			if has_node("Abilities/PhaseDashAbility"):
				$Abilities/PhaseDashAbility.unlocked = true

		"directional_dash":
			if has_node("Abilities/DirectionalDashAbility"):
				$Abilities/DirectionalDashAbility.unlocked = true
