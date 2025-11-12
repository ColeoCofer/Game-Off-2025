extends Node2D
## Photo shard collectible that appears in cutscenes
## A piece of a torn photograph that triggers story moments

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	# TODO: Load actual photo shard texture
	# For now, create a placeholder visual
	_create_placeholder_texture()

func _create_placeholder_texture():
	"""Create a simple placeholder texture until art is added"""
	# Create a simple colored rectangle as placeholder
	var placeholder = ColorRect.new()
	placeholder.size = Vector2(20, 30)
	placeholder.position = Vector2(-10, -15)
	placeholder.color = Color(0.9, 0.85, 0.7, 0.8)  # Yellowish paper color
	add_child(placeholder)

	# Add a border
	var border = ColorRect.new()
	border.size = Vector2(22, 32)
	border.position = Vector2(-11, -16)
	border.color = Color(0.4, 0.3, 0.2, 1.0)  # Dark brown border
	add_child(border)
	border.z_index = -1

func play_spawn_animation():
	"""Animate the shard appearing"""
	# Fade in and float down
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.5)
	tween.tween_property(self, "position:y", position.y + 10, 0.5)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

func play_pickup_animation():
	"""Animate the shard being picked up"""
	# Float up and fade out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 30, 0.5)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)

	await tween.finished
