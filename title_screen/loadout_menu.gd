extends Control

@onready var title_label = $Label

@onready var double_jump_box = $ColumnLabels/Upgrades/DoubleJumpBox
@onready var wall_jump_box = $ColumnLabels/Upgrades/WallJumpBox
@onready var dash_box = $ColumnLabels/Upgrades/DashBox
@onready var glide_box = $ColumnLabels/Upgrades/GlideBox

@onready var start_run = $StartRun

var costs = {
	"DoubleJumpBox": 3,
	"WallJumpBox": 3,
	"DashBox": 3,
	"GlideBox": 3
}


func _ready():
	start_run.pressed.connect(_on_start_run_pressed)
	setup_boxes()
	update_energy_label()

func refresh():
	# 1. Update the checkboxes based on the NEW save data
	setup_boxes()
	
	# 2. Reset checkboxes so a previous slot's selection doesn't carry over
	double_jump_box.button_pressed = false
	wall_jump_box.button_pressed = false
	dash_box.button_pressed = false
	glide_box.button_pressed = false
	
	# 3. Update the energy UI text
	update_energy_label()

# ==================================================
# LOCK UNSEEN UPGRADES
# ==================================================

func setup_boxes():
	_setup_box(double_jump_box, "double_jump")
	_setup_box(wall_jump_box, "wall_jump")
	_setup_box(dash_box, "dash")
	_setup_box(glide_box, "glide")


func _setup_box(box: CheckBox, id: String):
	if save_data.has_seen_ability(id):
		box.disabled = false
		box.modulate = Color.WHITE
	else:
		box.disabled = true
		box.modulate = Color(0.5, 0.5, 0.5)


# ==================================================
# CHECKBOX SIGNAL
# ==================================================

func _on_box_toggled(_pressed: bool):
	var total = get_total_cost()

	if total > save_data.get_max_energy():
		var box = get_viewport().gui_get_focus_owner()

		if box is CheckBox:
			box.button_pressed = false

	update_energy_label()


# ==================================================
# ENERGY
# ==================================================

func get_total_cost() -> int:
	var total = 0

	for box_name in costs.keys():
		var box = get_node("ColumnLabels/Upgrades/" + box_name)

		if box.button_pressed:
			total += costs[box_name]

	return total


func update_energy_label():
	title_label.text = "Choose Starting Upgrades   Energy %d / %d" % [
		get_total_cost(),
		save_data.get_max_energy()
	]


# ==================================================
# START RUN
# ==================================================

func _on_start_run_pressed():
	var selected = []

	if double_jump_box.button_pressed:
		selected.append("double_jump")

	if wall_jump_box.button_pressed:
		selected.append("wall_jump")

	if dash_box.button_pressed:
		selected.append("dash")

	if glide_box.button_pressed:
		selected.append("glide")

	save_data.set_selected_starting_abilities(selected)

	save_data.save()
	call_deferred("_do_start_game")

func _do_start_game():
	if get_tree():
		get_tree().change_scene_to_file("res://scenes/game.tscn")
