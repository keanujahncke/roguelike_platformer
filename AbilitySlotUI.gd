extends TextureRect

@export var ability_name: String = ""

@onready var progress_bar: TextureProgressBar = $TextureProgressBar


func _ready() -> void:
	if progress_bar:
		progress_bar.value = 0.0
	set_unlocked(false)


func set_unlocked(is_unlocked: bool) -> void:
	if is_unlocked:
		modulate = Color(1, 1, 1, 1) 
	else:
		modulate = Color(0.2, 0.2, 0.2, 0.8)


func update_cooldown(cooldown_left: float, cooldown_max: float) -> void:
	if not progress_bar:
		return
		
	if cooldown_max > 0.0 and cooldown_left > 0.0:
		progress_bar.value = (cooldown_left / cooldown_max) * 100.0
	else:
		progress_bar.value = 0.0
