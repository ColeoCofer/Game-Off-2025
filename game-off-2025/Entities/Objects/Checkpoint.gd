extends Area2D

## Checkpoint - saves player spawn position when activated
## Only persists in memory - cleared on level restart/quit

signal checkpoint_activated(checkpoint_position: Vector2)

@export var activated: bool = false
@export var activation_particles_scene: PackedScene = null
@export var z_index_offset: float = 0.0  ## Adjust this to fine-tune when player switches from front to back
@export var max_audio_distance: float = 200.0  ## Distance at which fire sound is inaudible
@export var min_audio_distance: float = 50.0   ## Distance at which fire sound is at full volume
@export var torch_volume_db: float = 0.0        ## Volume of the torch fire sound in decibels (-80 to 24)
@export var hunger_restore_amount: float = 50.0 ## Amount of hunger restored when checkpoint is first activated

var sprite: Sprite2D
var animated_sprite: AnimatedSprite2D
var particles: GPUParticles2D
var light: PointLight2D
var audio_player: AudioStreamPlayer  # For one-shot activation sound
var torch_audio_player: AudioStreamPlayer2D = null  # For looping torch fire sound
var player_ref: CharacterBody2D = null
var activation_area: Area2D = null

# Flicker variables
var base_light_energy: float = 1.5
var flicker_time: float = 0.0

func _ready():
	# Get child nodes
	sprite = get_node_or_null("Sprite2D")
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	particles = get_node_or_null("GPUParticles2D")
	light = get_node_or_null("PointLight2D")
	audio_player = get_node_or_null("AudioStreamPlayer")
	torch_audio_player = get_node_or_null("TorchAudioPlayer")
	activation_area = get_node_or_null("ActivationArea")

	# Setup activation whoosh sound on existing audio player
	if audio_player:
		audio_player.stream = load("res://Assets/Audio/fire/flames-light.wav")

	# Create torch audio player if it doesn't exist
	if not torch_audio_player:
		torch_audio_player = AudioStreamPlayer2D.new()
		torch_audio_player.name = "TorchAudioPlayer"
		torch_audio_player.bus = &"Sounds"

		# Load and configure the torch sound for looping
		var torch_stream = load("res://Assets/Audio/fire/flames-idle.wav")
		if torch_stream is AudioStreamMP3:
			torch_stream.loop = true
		torch_audio_player.stream = torch_stream

		torch_audio_player.volume_db = torch_volume_db
		torch_audio_player.autoplay = false
		torch_audio_player.max_distance = max_audio_distance
		torch_audio_player.attenuation = 2.0  # Exponential falloff
		add_child(torch_audio_player)

	# Connect to player entering/exiting the main area (for z-index management)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Connect to activation area if it exists (for checkpoint activation)
	if activation_area:
		activation_area.body_entered.connect(_on_activation_area_entered)

	# Connect to animation finished signal if using AnimatedSprite2D
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)

	# Set initial visual state
	_update_visual_state()

func _process(delta):
	# Update z-index based on player position relative to arch center
	if player_ref:
		_update_z_index_for_player()

	# Update light flickering when activated
	if activated and light and light.enabled:
		_update_light_flicker(delta)

	# Update torch audio volume based on player proximity
	if activated:
		_update_torch_audio()

func _update_z_index_for_player():
	"""Adjust z-index based on player position to create arch pass-through effect"""
	if not animated_sprite and not sprite:
		return

	# Use the sprite node's position for more accurate center calculation
	var sprite_node = animated_sprite if animated_sprite else sprite
	var checkpoint_center_x = sprite_node.global_position.x + z_index_offset
	var player_x = player_ref.global_position.x

	# Set arch to a fixed z-index
	sprite_node.z_index = 1

	if player_x < checkpoint_center_x:
		# Player is on the left side - render player on top of arch
		player_ref.z_index = 2
	else:
		# Player is on the right side - render player behind arch
		player_ref.z_index = 0

func _on_body_entered(body: Node2D):
	# Check if it's the player
	if body.is_in_group("Player"):
		# Store player reference for z-index management
		player_ref = body

		# If no separate activation area exists, activate on main area entry
		if not activation_area and not activated:
			activate(body)

func _on_activation_area_entered(body: Node2D):
	# Only activate checkpoint when player enters the narrow activation area
	if body.is_in_group("Player") and not activated:
		activate(body)

func _on_body_exited(body: Node2D):
	# Clear player reference when they leave
	if body == player_ref:
		# Reset player z-index to default
		player_ref.z_index = 0
		player_ref = null

func activate(player: Node2D = null):
	"""Activate the checkpoint - changes visuals, notifies player, and restores hunger"""
	if activated:
		return

	activated = true

	# Restore player's hunger when checkpoint is first activated
	if player and player is PlatformerController2D:
		var hunger_manager = player.get_node_or_null("HungerManager")
		if hunger_manager:
			hunger_manager.consume_food(hunger_restore_amount)

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
			# Play ignite animation (will transition to lit via signal)
			animated_sprite.play("ignite")
		else:
			# Play idle animation when not activated
			animated_sprite.play("idle")

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
	# Play one-shot whoosh sound
	if audio_player:
		audio_player.play()

	# Start looping torch fire sound (will be managed by _update_torch_audio)
	# The update function will handle volume based on player proximity

	# Emit one-shot particles if we have the scene
	if activation_particles_scene:
		var particle_instance = activation_particles_scene.instantiate()
		get_parent().add_child(particle_instance)
		particle_instance.global_position = global_position
		# Clean up after particles finish
		if particle_instance.has_signal("finished"):
			particle_instance.finished.connect(particle_instance.queue_free)

	# Brief hitstop for impact (idk maybe we don't need this...)
	#if HitStop:
		#HitStop.activate(0.1)

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

func _update_light_flicker(delta):
	"""Create a fire-like flickering/pulsing effect on the light"""
	flicker_time += delta

	# Combine multiple sine waves at different frequencies for realistic flicker
	var fast_flicker = sin(flicker_time * 15.0) * 0.15  # Fast subtle flicker
	var slow_pulse = sin(flicker_time * 2.5) * 0.2      # Slow breathing pulse
	var random_noise = (randf() - 0.5) * 0.1            # Random jitter

	# Combine the effects
	var flicker_amount = fast_flicker + slow_pulse + random_noise
	light.energy = base_light_energy + flicker_amount

func _update_torch_audio():
	"""Update torch fire sound volume based on player distance"""
	if not torch_audio_player:
		return

	# Find the player in the scene
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		# Stop playing if no player found
		if torch_audio_player.playing:
			torch_audio_player.stop()
		return

	# Calculate distance to player
	var distance = global_position.distance_to(player.global_position)

	# Start/stop playing based on distance
	if distance <= max_audio_distance:
		# Start looping if not already playing
		if not torch_audio_player.playing:
			torch_audio_player.play()

		# The AudioStreamPlayer2D handles volume falloff automatically based on distance
		# But we can stop it completely when too far for performance
	else:
		# Stop playing when too far away
		if torch_audio_player.playing:
			torch_audio_player.stop()

func _on_animation_finished():
	"""Handle animation finished signal - transition from ignite to lit"""
	if animated_sprite and activated and animated_sprite.animation == "ignite":
		# After ignite animation completes, play the lit animation on loop
		animated_sprite.play("lit")

func reset():
	"""Reset checkpoint to inactive state (called when level restarts)"""
	activated = false
	_update_visual_state()

	# Stop torch audio when resetting
	if torch_audio_player and torch_audio_player.playing:
		torch_audio_player.stop()
