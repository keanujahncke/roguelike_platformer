extends Node2D
class_name SwordSlashEffect

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var animation_name: String = "slash"


func _ready() -> void:
	if animated_sprite == null:
		queue_free()
		return

	if animated_sprite.sprite_frames == null:
		queue_free()
		return

	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.sprite_frames.set_animation_loop(animation_name, false)
		animated_sprite.frame = 0
		animated_sprite.play(animation_name)
	else:
		animated_sprite.frame = 0
		animated_sprite.play()

	await animated_sprite.animation_finished

	queue_free()
