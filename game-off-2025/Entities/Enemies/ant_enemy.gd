extends CharacterBody2D

## Ant enemy that walks back and forth on platforms
## - Detects platform edges (via ray for now...) and turns around
## - Kills player on side collision
## - Dies when player stomps on top

@export var walk_speed: float = 50.0
@export var gravity: float = 980.0
@export var edge_detection_distance: float = 10.0
@export var stomp_bounce_force: float = 150.0
@export var death_animation_duration: float = 2.0
@export var rotation_speed: float = 3.0
@export var fall_speed: float = 100.0
@export var squash_duration: float = 0.15
@export var squash_amount: Vector2 = Vector2(1.5, 0.4)  # Wide and flat
@export var stomp_particle_scene: PackedScene = preload("res://Entities/Particles/stomp_impact.tscn")

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_raycast: RayCast2D = $FloorRayCast
@onready var stomp_detector: Area2D = $StompDetector
@onready var damage_detector: Area2D = $DamageDetector
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var direction: int = 1  # 1 for right, -1 for left
var is_alive: bool = true
var death_material: ShaderMaterial

# Audio
var squish_sound: AudioStream = preload("res://Assets/Audio/squish.mp3")

func _ready():
	# Connect stomp detection
	if stomp_detector:
		stomp_detector.body_entered.connect(_on_stomp_detector_body_entered)

	# Connect damage detection
	if damage_detector:
		damage_detector.body_entered.connect(_on_damage_detector_body_entered)

	# Set up floor detection raycast
	if floor_raycast:
		floor_raycast.position.x = edge_detection_distance * direction
		floor_raycast.target_position = Vector2(0, 20)
		floor_raycast.enabled = true

func _physics_process(delta: float):
	if not is_alive:
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Check for edge of platform or wall collision
	if is_on_floor() and _should_turn_around():
		_turn_around()

	# Move horizontally
	velocity.x = direction * walk_speed

	# Update sprite - always walking
	if animated_sprite:
		animated_sprite.flip_h = direction > 0
		animated_sprite.play("walk")

	# Move and check for wall collision
	move_and_slide()

	# Turn around if hit a wall
	if is_on_wall():
		_turn_around()

func _should_turn_around() -> bool:
	# Check if there's floor ahead using raycast
	if floor_raycast:
		return not floor_raycast.is_colliding()
	return false

func _turn_around():
	direction *= -1
	if floor_raycast:
		floor_raycast.position.x = edge_detection_distance * direction

func _on_stomp_detector_body_entered(body: Node2D):
	if not is_alive:
		return

	# Check if it's the player
	if body.is_in_group("Player"):
		# Can't use velocity (it's 0 when standing on platform)
		# Instead, check if player is positioned ABOVE the ant

		# Get player's center Y position
		var player_y = body.global_position.y
		var ant_center_y = global_position.y

		# Player must be significantly ABOVE ant's center to count as stomp
		# If at same level (walking into side), it's not a stomp
		var ABOVE_THRESHOLD = -3.0  # Player must be at least 3px above ant center
		var player_is_above = (player_y - ant_center_y) < ABOVE_THRESHOLD

		# Only stomp if player is clearly above the ant
		if player_is_above:
			# Mark as dead immediately
			is_alive = false

			# IMMEDIATELY disable damage detector to prevent it from triggering
			# This must happen before any physics interactions!
			if damage_detector:
				damage_detector.monitoring = false  # Disable immediately (not deferred!)
				damage_detector.monitorable = false

			if stomp_detector:
				stomp_detector.monitoring = false
				stomp_detector.monitorable = false

			# Stop physics
			set_physics_process(false)

			# Disable collision
			var main_collision = get_node_or_null("CollisionShape2D")
			if main_collision:
				main_collision.set_deferred("disabled", true)

			set_collision_layer_value(1, false)
			set_collision_layer_value(2, false)
			set_collision_mask_value(1, false)

			# Disable detector collision shapes (deferred for safety)
			if damage_detector:
				var collision_shape = damage_detector.get_node_or_null("CollisionShape2D")
				if collision_shape:
					collision_shape.set_deferred("disabled", true)

			if stomp_detector:
				var collision_shape = stomp_detector.get_node_or_null("CollisionShape2D")
				if collision_shape:
					collision_shape.set_deferred("disabled", true)

			_die_from_stomp(body)

func _on_damage_detector_body_entered(body: Node2D):
	if not is_alive:
		return

	# Check if it's the player
	if body.is_in_group("Player"):
		# Check if this is actually a stomp scenario - forgiving fallback
		var player_was_falling = false
		if body is CharacterBody2D:
			player_was_falling = body.velocity.y > 0  # Any downward movement (soft landings ok)

		var player_bottom_y = body.global_position.y
		if body.has_node("CollisionShape2D"):
			var player_collision = body.get_node("CollisionShape2D")
			if player_collision and player_collision.shape:
				var shape = player_collision.shape
				if shape is RectangleShape2D or shape is CapsuleShape2D:
					var shape_height = shape.size.y if shape is RectangleShape2D else shape.height
					player_bottom_y = body.global_position.y + (shape_height / 2.0)

		var ant_top_y = global_position.y - 6
		var STOMP_TOLERANCE = 6.0  # Tighter tolerance for ground enemy fallback
		var player_is_clearly_above = player_bottom_y <= ant_top_y + STOMP_TOLERANCE

		var is_stomp_scenario = player_was_falling and player_is_clearly_above

		# If it's a stomp, kill the ant instead of the player
		if is_stomp_scenario:
			is_alive = false

			# IMMEDIATELY disable both detectors to prevent further triggers
			if damage_detector:
				damage_detector.monitoring = false  # Immediate (not deferred!)
				damage_detector.monitorable = false

			if stomp_detector:
				stomp_detector.monitoring = false
				stomp_detector.monitorable = false

			set_physics_process(false)

			var main_collision = get_node_or_null("CollisionShape2D")
			if main_collision:
				main_collision.set_deferred("disabled", true)

			set_collision_layer_value(1, false)
			set_collision_layer_value(2, false)
			set_collision_mask_value(1, false)

			# Disable detector collision shapes (deferred for safety)
			if damage_detector:
				var collision_shape = damage_detector.get_node_or_null("CollisionShape2D")
				if collision_shape:
					collision_shape.set_deferred("disabled", true)

			if stomp_detector:
				var collision_shape = stomp_detector.get_node_or_null("CollisionShape2D")
				if collision_shape:
					collision_shape.set_deferred("disabled", true)

			_die_from_stomp(body)
			return

		# Safety check
		if not is_alive:
			return

		# Otherwise, kill the player
		_kill_player(body)

func _die_from_stomp(player: Node2D):
	is_alive = false

	# Trigger hit stop for satisfying feedback
	HitStop.activate(0.03)

	# Play squish sound
	if audio_player and squish_sound:
		audio_player.stream = squish_sound
		audio_player.play()

	# Give player a bounce
	if player is CharacterBody2D:
		player.velocity.y = -stomp_bounce_force

	# Disable physics
	set_physics_process(false)

	# Disable collision
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	# Disable damage detector
	if damage_detector:
		damage_detector.set_deferred("monitoring", false)
		damage_detector.set_deferred("monitorable", false)

	# Apply death shader
	_apply_death_shader()

	# Play squash effect, then death animation
	_play_squash_effect()


func _spawn_stomp_particles():
	"""Spawn particle effect at stomp location"""
	if not stomp_particle_scene:
		return

	var particles = stomp_particle_scene.instantiate()
	# Add to current scene (not as child of ant, so particles persist after ant dies)
	get_tree().current_scene.add_child(particles)
	# Position at the top of the ant (where the stomp happened)
	particles.global_position = global_position + Vector2(0, -8)
	# Start emitting
	particles.emitting = true

	# Auto-cleanup after particles finish
	if particles is CPUParticles2D or particles is GPUParticles2D:
		var cleanup_timer = get_tree().create_timer(particles.lifetime + 0.1)
		cleanup_timer.timeout.connect(particles.queue_free)

func _play_squash_effect():
	"""Quick squash effect before death animation"""
	if not animated_sprite:
		_play_death_animation()
		return

	# Squash down quickly, recover slower for more impact
	var squash_tween = create_tween()
	squash_tween.set_ease(Tween.EASE_OUT)
	squash_tween.set_trans(Tween.TRANS_BACK)

	# Instant squash down
	squash_tween.tween_property(animated_sprite, "scale", squash_amount, squash_duration * 0.3)
	# Slower bounce back
	squash_tween.tween_property(animated_sprite, "scale", Vector2.ONE, squash_duration * 0.7)

	# After squash completes, play death animation
	squash_tween.finished.connect(_play_death_animation)

func _apply_death_shader():
	if not animated_sprite:
		return

	# Load and create death shader material
	var death_shader = load("res://Shaders/death_shader.gdshader")
	death_material = ShaderMaterial.new()
	death_material.shader = death_shader
	death_material.set_shader_parameter("death_progress", 0.0)
	death_material.set_shader_parameter("distortion_strength", 0.5)

	# Apply the shader material
	animated_sprite.material = death_material

func _play_death_animation():
	if not animated_sprite:
		queue_free()
		return

	# Create animation tween
	var tween = create_tween()
	tween.set_parallel(true)

	# Fade death shader progress
	tween.tween_method(_update_death_shader, 0.0, 1.0, death_animation_duration)

	# Rotate the ant
	tween.tween_property(animated_sprite, "rotation", TAU * rotation_speed, death_animation_duration)

	# Shrink the ant
	tween.tween_property(animated_sprite, "scale", Vector2(0.3, 0.3), death_animation_duration)

	# Make ant fall
	tween.tween_property(self, "position:y", position.y + fall_speed, death_animation_duration)

	# Remove when animation completes
	tween.finished.connect(queue_free)

func _update_death_shader(progress: float):
	if death_material:
		death_material.set_shader_parameter("death_progress", progress)

func _kill_player(player: Node2D):
	# Find and trigger the player's death manager
	var death_manager = player.get_node_or_null("DeathManager")
	if death_manager and death_manager.has_method("trigger_hazard_death"):
		# Pass ant's position so player gets knocked back in the right direction
		death_manager.trigger_hazard_death(global_position)
