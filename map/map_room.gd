extends TextureButton

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var associated_room: MapNode

func setup(room: MapNode, available: bool, completed: bool) -> void:
	associated_room = room
	match room.type:
		MapNode.Type.LEVEL: sprite.play("level")
		MapNode.Type.HEAL: sprite.play("heal")
		MapNode.Type.UPGRADE: sprite.play("upgrade")
		MapNode.Type.BOSS: sprite.play("boss")
	
	disabled = !available or completed
	
	if completed:
		modulate = Color(0.2, 1.0, 0.2) # Greenish for done
	elif !available:
		modulate = Color(0.3, 0.3, 0.3) # Dark for locked
	else:
		modulate = Color.WHITE

	if not focus_entered.is_connected(_on_focus_entered):
		focus_entered.connect(_on_focus_entered)
		focus_exited.connect(_on_focus_exited)

func _on_focus_entered() -> void:
	sprite.self_modulate = Color(1.5, 1.5, 1.5)
	var tween = create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5)
	set_meta("pulse_tween", tween)

func _on_focus_exited() -> void:
	sprite.self_modulate = Color(1, 1, 1)
	if has_meta("pulse_tween"):
		var tween = get_meta("pulse_tween") as Tween
		if tween: tween.kill()
	create_tween().tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
