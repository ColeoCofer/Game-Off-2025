extends Node

## Manages firefly companions that act as shields
## When player has fireflies and takes damage, one firefly dies instead
## Limited to 1 firefly at once for balanced difficulty

signal firefly_collected
signal firefly_lost

const MAX_FIREFLIES = 1

var firefly_count: int = 0
var firefly_nodes: Array[Node2D] = []

@onready var player: CharacterBody2D = get_parent()

func _ready():
	# Find all firefly nodes (Firefly, Firefly2, Firefly3)
	# Note: We search for all 3 nodes even though MAX_FIREFLIES may be 1
	# This ensures all firefly nodes in the scene start hidden
	for i in range(3):  # Always check for all 3 possible firefly nodes
		var node_name = "Firefly" if i == 0 else "Firefly" + str(i + 1)
		var firefly = player.get_node_or_null(node_name)
		if firefly:
			firefly_nodes.append(firefly)
			# Immediately hide them (use call_deferred to ensure it happens after firefly's _ready)
			_set_firefly_visibility(firefly, false)
			# Also disable processing until activated
			firefly.set_process(false)

func collect_firefly():
	"""Called when player picks up a firefly"""
	# Always emit the signal so hunger restoration works
	# But only spawn a companion firefly if we don't already have one
	if firefly_count >= MAX_FIREFLIES:
		firefly_collected.emit()
		return  # Already have max, player gets hunger but no extra protection

	# Show the next firefly
	if firefly_count < firefly_nodes.size():
		var firefly = firefly_nodes[firefly_count]

		# Enable processing and visibility
		firefly.set_process(true)
		_set_firefly_visibility(firefly, true)

		# Set different starting angles for visual variety
		_set_firefly_orbit_offset(firefly, firefly_count)

		firefly_count += 1
		firefly_collected.emit()

func _set_firefly_visibility(firefly: Node2D, visible: bool):
	"""Helper to show/hide a specific firefly and all its components"""
	if not firefly:
		return

	firefly.visible = visible

	# Also make sure the sprite and light are visible/hidden
	var sprite = firefly.get_node_or_null("Sprite2D")
	var light = firefly.get_node_or_null("PointLight2D")
	var particles = firefly.get_node_or_null("TrailParticles")

	if sprite:
		sprite.visible = visible
	if light:
		light.visible = visible
	if particles:
		particles.visible = visible
		particles.emitting = visible

func _set_firefly_orbit_offset(firefly: Node2D, index: int):
	"""Set different orbit starting angles for each firefly"""
	# Spread fireflies evenly around the circle
	var angle_offset = (TAU / MAX_FIREFLIES) * index

	# Access the firefly script to set its initial orbit angle
	if firefly.has_method("set_orbit_angle"):
		firefly.set_orbit_angle(angle_offset)

func lose_firefly():
	"""Called when firefly shields player from damage - removes one firefly"""
	if firefly_count <= 0:
		return

	# Kill the last active firefly
	firefly_count -= 1
	var firefly = firefly_nodes[firefly_count]

	# Play firefly death effect
	if firefly:
		_play_firefly_death_effect(firefly)

	firefly_lost.emit()

func _play_firefly_death_effect(firefly: Node2D):
	"""Animated death effect for a specific firefly"""
	if not firefly:
		return

	# Create a tween for the death animation
	var tween = create_tween()
	tween.set_parallel(true)

	# Flash bright then fade
	var sprite = firefly.get_node_or_null("Sprite2D")
	var light = firefly.get_node_or_null("PointLight2D")

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
		if firefly:
			_set_firefly_visibility(firefly, false)
			# Disable processing until collected again
			firefly.set_process(false)
			# Reset properties
			if sprite:
				sprite.modulate.a = 1.0
				sprite.scale = Vector2.ONE
			if light:
				light.energy = 0.6
	)

func has_shield() -> bool:
	"""Check if player currently has any firefly shields"""
	return firefly_count > 0
