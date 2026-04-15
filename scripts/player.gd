extends CharacterBody2D


signal died
var current_room : Node2D
var is_dead := false   # ✅ NEW


@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# MOVEMENT
@export var move_speed = 220.0
@export var acceleration = 1400.0
@export var friction = 1800.0

# JUMP
@export var jump_velocity = -300.0
@export var gravity = 1200.0
@export var fall_gravity = 2000.0
@export var jump_peak_gravity = 600.0

# WALL
@export var wall_slide_speed = 60.0
@export var wall_jump_x = 260.0
@export var wall_jump_y = -300.0
@export var wall_jump_forgiveness = 0.12

# DASH (horizontal only)
@export var dash_speed = 500.0
@export var dash_time = 0.10
@export var max_dashes = 1

var dashes_left
var is_dashing = false

# FORGIVENESS
@export var coyote_time = 0.1
@export var jump_buffer_time = 0.2

var coyote_timer = 0.0
var jump_buffer_timer = 0.0
var wall_jump_timer = 0.0

# STATE
var facing = 1
var wall_sliding = false
var was_running = false
var is_stopping = false
var run_time = 0.0

@export var stop_min_run_time = 0.2


func _ready():
	dashes_left = max_dashes
	anim.play("idle")


func _physics_process(delta):

	# timers
	coyote_timer -= delta
	jump_buffer_timer -= delta
	wall_jump_timer -= delta

	var input_axis = Input.get_axis("move_left", "move_right")

	if input_axis != 0:
		facing = sign(input_axis)

	# buffer jump
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	# coyote reset
	if is_on_floor():
		coyote_timer = coyote_time
		dashes_left = max_dashes

	# wall detection forgiveness
	if is_on_wall():
		wall_jump_timer = wall_jump_forgiveness
		dashes_left = max_dashes

	# wall slide
	wall_sliding = false
	if is_on_wall() and not is_on_floor() and velocity.y > 0:
		wall_sliding = true
		velocity.y = min(velocity.y, wall_slide_speed)

	# gravity (with jump peak forgiveness)
	if not is_on_floor() and not is_dashing:

		# halved gravity at jump peak
		if velocity.y < 0 and Input.is_action_pressed("jump"):
			velocity.y += jump_peak_gravity * delta
		else:
			velocity.y += (fall_gravity if velocity.y > 0 else gravity) * delta

	# jump
	if jump_buffer_timer > 0:

		# ground jump (coyote)
		if coyote_timer > 0:
			velocity.y = jump_velocity
			jump_buffer_timer = 0
			coyote_timer = 0

		# wall jump forgiveness
		elif wall_jump_timer > 0:
			velocity.y = wall_jump_y
			velocity.x = get_wall_normal().x * wall_jump_x
			jump_buffer_timer = 0
			wall_jump_timer = 0

	# variable jump
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

	# dash
	if Input.is_action_just_pressed("dash") and dashes_left > 0:
		start_dash()

	# movement
	if not is_dashing:
		if input_axis != 0:
			velocity.x = move_toward(
				velocity.x,
				input_axis * move_speed,
				acceleration * delta
			)
		else:
			velocity.x = move_toward(
				velocity.x,
				0,
				friction * delta
			)

	move_and_slide()
	check_hazards()

	# face sprite
	anim.flip_h = facing < 0

	# animation logic
	update_animation(input_axis, delta)


func update_animation(input_axis, delta):
	var is_running = abs(velocity.x) > 1 and input_axis != 0

	# Track how long player has been running
	if is_running and is_on_floor():
		run_time += delta

	# Air states take priority
	if not is_on_floor():
		is_stopping = false
		if velocity.y < 0:
			if anim.animation != "jump":
				anim.play("jump")
		else:
			if anim.animation != "fall":
				anim.play("fall")
		was_running = is_running
		return

	# Trigger stop only if player ran long enough
	if (
		was_running
		and input_axis == 0
		and abs(velocity.x) > 1
		and not is_stopping
		and run_time >= stop_min_run_time
	):
		is_stopping = true
		anim.play("stop")
		was_running = false
		run_time = 0.0
		return

	# Let stop finish before idle
	if is_stopping:
		if not anim.is_playing() or anim.frame >= anim.sprite_frames.get_frame_count("stop") - 1:
			is_stopping = false
			anim.play("idle")
		return

	# Normal ground states
	if is_running:
		if anim.animation != "run":
			anim.play("run")
		was_running = true
	else:
		if anim.animation != "idle":
			anim.play("idle")
		was_running = false
		run_time = 0.0


func start_dash():
	is_dashing = true
	dashes_left -= 1
	
	var dash_dir: int = facing
	
	if is_on_wall():
		dash_dir = get_wall_normal().x

	velocity.x = dash_dir * dash_speed
	velocity.y = 0
	
	await get_tree().create_timer(dash_time).timeout
	is_dashing = false

func die_and_respawn():
	if is_dead:
		return

	is_dead = true

	died.emit()
	velocity = Vector2.ZERO
	is_dashing = false

func check_hazards():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if not collision:
			continue

		var collider = collision.get_collider()

		if collider.is_in_group("hazard"):
			die_and_respawn()
			return
