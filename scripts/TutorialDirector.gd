extends Node

@export var guide_path: NodePath
@export var dialogue_box_path: NodePath
@export var guide_spawn_point_path: NodePath
@export var guide_intro_stop_point_path: NodePath
@export var tutorial_triggers_parent_path: NodePath

# How long the player falls before the guide intro starts.
@export var intro_start_delay := 2.0

@onready var guide: CharacterBody2D = get_node(guide_path)
@onready var dialogue_box: Control = get_node(dialogue_box_path)
@onready var guide_spawn_point: Marker2D = get_node(guide_spawn_point_path)
@onready var guide_intro_stop_point: Marker2D = get_node(guide_intro_stop_point_path)
@onready var tutorial_triggers_parent: Node = get_node(tutorial_triggers_parent_path)

var player: Node2D = null
var intro_finished := false
var final_dialogue_finished := false


func _ready() -> void:
	await get_tree().process_frame

	player = get_tree().get_first_node_in_group("player") as Node2D

	if player == null:
		push_error("TutorialDirector could not find Player. Make sure the Player root node is in the group 'player'.")
		return

	# Makes the Guide and Player ignore each other's collision
	# without changing any collision layers/masks.
	if guide is PhysicsBody2D and player is PhysicsBody2D:
		guide.add_collision_exception_with(player)
		player.add_collision_exception_with(guide)

	# Put the guide at his spawn point immediately.
	guide.global_position = guide_spawn_point.global_position
	guide.stop_and_idle()

	_connect_triggers()

	# Lock player input immediately, but allow gravity so the player can fall into the room.
	_lock_player_with_gravity()

	if intro_start_delay > 0.0:
		await get_tree().create_timer(intro_start_delay).timeout

	await _start_intro_sequence()


func _connect_triggers() -> void:
	for child in tutorial_triggers_parent.get_children():
		if child.has_signal("tutorial_triggered"):
			child.tutorial_triggered.connect(_on_tutorial_triggered)


func _start_intro_sequence() -> void:
	# Once the guide intro begins, fully freeze the player.
	_lock_player()

	guide.global_position = guide_spawn_point.global_position
	guide.run_to_point(guide_intro_stop_point.global_position)

	await _wait_until_guide_reaches_intro_point()

	await _play_dialogue([
		"Hey, pal.",
		"You don’t look like you belong here.",
		"… I see. So you’re saying you fell from the sky after going through some sort of black hole?…",
		"Well, you’ll have to make your way out of this dungeon first if you want any chance at getting back home.",
		"Here, take this magic cape, it’ll help you with your journey...",
		"… What? You don’t know how to use it?!",
		"Let's head to the right, I'll show you a few neat tricks. Ha ha ha!"
	])

	intro_finished = true
	guide.follow(player)
	_unlock_player()


func _wait_until_guide_reaches_intro_point() -> void:
	while absf(guide.global_position.x - guide_intro_stop_point.global_position.x) > 10.0:
		await get_tree().process_frame


func _on_tutorial_triggered(trigger_id: String) -> void:
	if not intro_finished:
		return

	if final_dialogue_finished:
		return

	match trigger_id:
		"controls":
			await _play_checkpoint_dialogue([
				"For starters, try jumping onto this platform."
			])

		"jump":
			await _play_checkpoint_dialogue([
				"You got promise, kid. If you hold jump, you can jump even higher."
			])

		"momentum":
			await _play_checkpoint_dialogue([
				"Hold on a sec. There's a big gap here.",
				"If you build up some momentum before jumping, you can traverse a large gap like this."
			])

		"collectible":
			await _play_final_dialogue()

		_:
			push_warning("Unknown tutorial trigger id: " + trigger_id)


func _play_checkpoint_dialogue(lines: Array[String]) -> void:
	_lock_player()

	# Do not stop the guide here.
	# Let him continue replay-following while the dialogue is open,
	# so he catches up smoothly instead of teleporting after dialogue.
	await _play_dialogue(lines)

	guide.follow(player)
	_unlock_player()


func _play_final_dialogue() -> void:
	_lock_player()
	guide.stop_and_idle()

	await _play_dialogue([
		"Look up there. Do you see that large floppy disk?",
		"If you collect those on your journey you might gain some sort of hidden power...",
		"Oh! Also, if you keep using that cape you might come up with some cool techniques",
		"Okay... well... it's been good knowin' ya!",
		"You can head to the exit on the right when you're finished, or you can stick around and practice some more.",
		"Best of luck on getting home, pal."
	])

	final_dialogue_finished = true
	guide.stop_and_idle()
	_unlock_player()


func _play_dialogue(lines: Array[String]) -> void:
	dialogue_box.start_dialogue(lines)
	await dialogue_box.dialogue_finished


func _lock_player_with_gravity() -> void:
	if player == null:
		return

	if player.has_method("set_controls_locked"):
		player.set_controls_locked(true, true)
	else:
		push_error("Player does not have set_controls_locked().")


func _lock_player() -> void:
	if player == null:
		return

	if player.has_method("set_controls_locked"):
		player.set_controls_locked(true)
	else:
		push_error("Player does not have set_controls_locked().")


func _unlock_player() -> void:
	if player == null:
		return

	if player.has_method("set_controls_locked"):
		player.set_controls_locked(false)
	else:
		push_error("Player does not have set_controls_locked().")
