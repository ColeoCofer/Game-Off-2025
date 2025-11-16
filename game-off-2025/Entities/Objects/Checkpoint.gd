extends Area2D

## Checkpoint - saves player spawn position when activated
## Only persists in memory - cleared on level restart/quit

signal checkpoint_activated(checkpoint_position: Vector2)

@export var activated: bool = false
@export var activation_particles_scene: PackedScene = null

var sprite: Sprite2D
var animated_sprite: AnimatedSprite2D
var particles: GPUParticles2D
var light: PointLight2D
var audio_player: AudioStreamPlayer

func _ready():
	# Get child nodes
	sprite = get_node_or_null("Sprite2D")
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	particles = get_node_or_null("GPUParticles2D")
	light = get_node_or_null("PointLight2D")
	audio_player = get_node_or_null("AudioStreamPlayer")

	# Connect to player entering the area
	body_entered.connect(_on_body_entered)

	# Set initial visual state
	_update_visual_state()

func _on_body_entered(body: Node2D):
	# Only activate once
	if activated:
		return

	# Check if it's the player
	if not body.is_in_group("Player"):
		return

	# Activate checkpoint
	activate()

func activate():
	"""Activate the checkpoint - changes visuals and notifies player"""
	if activated:
		return

	activated = true

	# Emit signal with checkpoint position
	checkpoint_activated.emit(global_position)

	# Update visual state
	_update_visual_state()

	# Play activation effects
	_play_activation_effects()

func _update_visual_state():
	"""Update visuals based on activated state"""
	# If using AnimatedSprite2D
	if animated_sprite:
		if activated:
			animated_sprite.play("lit")
		else:
			animated_sprite.play("unlit")

	# If using simple Sprite2D (modulate to show state)
	elif sprite:
		if activated:
			sprite.modulate = Color(1.5, 1.3, 1.0)  # Warm glow
		else:
			sprite.modulate = Color(0.5, 0.5, 0.5)  # Darker/unlit

	# Control light
	if light:
		light.enabled = activated

	# Control particles
	if particles:
		particles.emitting = activated

func _play_activation_effects():
	"""Play visual and audio effects when checkpoint activates"""
	# Play audio
	if audio_player:
		audio_player.play()

	# Emit one-shot particles if we have the scene
	if activation_particles_scene:
		var particle_instance = activation_particles_scene.instantiate()
		get_parent().add_child(particle_instance)
		particle_instance.global_position = global_position
		# Clean up after particles finish
		if particle_instance.has_signal("finished"):
			particle_instance.finished.connect(particle_instance.queue_free)

	# Brief hitstop for impact
	if HitStop:
		HitStop.activate(0.1)

	# Flash effect on sprite
	if sprite:
		_flash_sprite(sprite)
	elif animated_sprite:
		_flash_sprite(animated_sprite)

func _flash_sprite(sprite_node: Node2D):
	"""Create a flash effect on activation"""
	var original_modulate = sprite_node.modulate
	sprite_node.modulate = Color(3.0, 2.5, 1.5)  # Bright warm flash

	var tween = create_tween()
	tween.tween_property(sprite_node, "modulate", original_modulate, 0.3)

func reset():
	"""Reset checkpoint to inactive state (called when level restarts)"""
	activated = false
	_update_visual_state()
