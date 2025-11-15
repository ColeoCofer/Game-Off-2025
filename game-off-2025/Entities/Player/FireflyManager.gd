extends Node

## Manages firefly companion that acts as a shield
## When player has a firefly and takes damage, the firefly dies instead

signal firefly_collected
signal firefly_lost

var has_firefly: bool = false
var firefly_node: Node2D = null

@onready var player: CharacterBody2D = get_parent()

func _ready():
	# Hide firefly by default
	firefly_node = player.get_node_or_null("Firefly")
	print("FireflyManager ready - firefly_node found: ", firefly_node != null)
	if firefly_node:
		_set_firefly_visibility(false)

func collect_firefly():
	"""Called when player picks up a firefly"""
	print("collect_firefly called - has_firefly: ", has_firefly, " firefly_node: ", firefly_node != null)

	if has_firefly:
		print("Already have firefly, returning")
		return  # Already have one

	has_firefly = true

	# Show the firefly companion
	if firefly_node:
		print("Setting firefly visible")
		_set_firefly_visibility(true)
	else:
		print("ERROR: firefly_node is null!")

	firefly_collected.emit()

func _set_firefly_visibility(visible: bool):
	"""Helper to show/hide firefly and all its components"""
	print("_set_firefly_visibility called with visible=", visible)
	if not firefly_node:
		print("ERROR: firefly_node is null in _set_firefly_visibility")
		return

	firefly_node.visible = visible
	print("Set firefly_node.visible to ", visible)

	# Also make sure the sprite and light are visible/hidden
	var sprite = firefly_node.get_node_or_null("Sprite2D")
	var light = firefly_node.get_node_or_null("PointLight2D")
	var particles = firefly_node.get_node_or_null("TrailParticles")

	print("Found nodes - sprite: ", sprite != null, " light: ", light != null, " particles: ", particles != null)

	if sprite:
		sprite.visible = visible
		print("Set sprite.visible to ", visible)
	if light:
		light.visible = visible
		print("Set light.visible to ", visible)
	if particles:
		particles.visible = visible
		particles.emitting = visible
		print("Set particles.visible and emitting to ", visible)

func lose_firefly():
	"""Called when firefly shields player from damage"""
	if not has_firefly:
		return

	has_firefly = false

	# Play firefly death effect
	if firefly_node:
		_play_firefly_death_effect()

	firefly_lost.emit()

func _play_firefly_death_effect():
	"""Animated death effect for firefly"""
	if not firefly_node:
		return

	# Create a tween for the death animation
	var tween = create_tween()
	tween.set_parallel(true)

	# Flash bright then fade
	var sprite = firefly_node.get_node_or_null("Sprite2D")
	var light = firefly_node.get_node_or_null("PointLight2D")

	if sprite:
		# Flash bright
		tween.tween_property(sprite, "modulate:a", 1.5, 0.1)
		# Then fade out
		tween.tween_property(sprite, "modulate:a", 0.0, 0.4).set_delay(0.1)
		# Expand slightly
		tween.tween_property(sprite, "scale", Vector2(2.0, 2.0), 0.5)

	if light:
		# Burst of light
		tween.tween_property(light, "energy", 3.0, 0.1)
		# Then fade
		tween.tween_property(light, "energy", 0.0, 0.4).set_delay(0.1)

	# After animation, hide the firefly
	tween.finished.connect(func():
		if firefly_node:
			_set_firefly_visibility(false)
			# Reset properties
			if sprite:
				sprite.modulate.a = 1.0
				sprite.scale = Vector2.ONE
			if light:
				light.energy = 0.6
	)

func has_shield() -> bool:
	"""Check if player currently has firefly shield"""
	return has_firefly
