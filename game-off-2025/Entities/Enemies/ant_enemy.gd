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

var direction: int = 1  # 1 for right, -1 for left
var is_alive: bool = true
var death_material: ShaderMaterial

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

	# Check if it's the player and they're above the ant
	if body.is_in_group("Player"):
		# Player must be above the ant's center
		var player_is_above = body.global_position.y < global_position.y - 5  # 5 pixel tolerance

		if player_is_above:
			# Immediately mark as dead FIRST to prevent any race conditions
			is_alive = false

			# Immediately disable BOTH detectors to prevent race conditions
			if damage_detector:
				damage_detector.set_deferred("monitoring", false)
				damage_detector.set_deferred("monitorable", false)
				var collision_shape = damage_detector.get_node_or_null("CollisionShape2D")
				if collision_shape:
					collision_shape.set_deferred("disabled", true)

			if stomp_detector:
				stomp_detector.set_deferred("monitoring", false)
				stomp_detector.set_deferred("monitorable", false)
				var collision_shape = stomp_detector.get_node_or_null("CollisionShape2D")
				if collision_shape:
					collision_shape.set_deferred("disabled", true)

			_die_from_stomp(body)

func _on_damage_detector_body_entered(body: Node2D):
	if not is_alive:
		return

	# Check if it's the player - side collision kills them
	if body.is_in_group("Player"):
		# Immediately disable BOTH detectors to prevent race conditions
		if damage_detector:
			damage_detector.set_deferred("monitoring", false)
			damage_detector.set_deferred("monitorable", false)
			var collision_shape = damage_detector.get_node_or_null("CollisionShape2D")
			if collision_shape:
				collision_shape.set_deferred("disabled", true)

		if stomp_detector:
			stomp_detector.set_deferred("monitoring", false)
			stomp_detector.set_deferred("monitorable", false)
			var collision_shape = stomp_detector.get_node_or_null("CollisionShape2D")
			if collision_shape:
				collision_shape.set_deferred("disabled", true)

		_kill_player(body)

func _die_from_stomp(player: Node2D):
	is_alive = false

	# Trigger hit stop for satisfying feedback
	HitStop.activate(0.03)

	# Good effect to have but doesn't look that good on the ant...
	# Spawn impact particles
	# _spawn_stomp_particles()  # Disabled - not adding much

	# Give player a bounce
	if player is CharacterBody2D:
		player.velocity.y = -stomp_bounce_force

	# Disable physics
	set_physics_process(false)

	# Disable collision
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	# Disable damage detector so we don't hurt player after death
	# (This is redundant with the immediate disable in _on_stomp_detector_body_entered,
	# but kept as a safety measure)
	if damage_detector:
		damage_detector.set_deferred("monitoring", false)
		damage_detector.set_deferred("monitorable", false)

	# Apply death shader (same as player)
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
		death_manager.trigger_hazard_death()
