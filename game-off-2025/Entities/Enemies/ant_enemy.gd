extends CharacterBody2D

## Ant enemy that walks back and forth on platforms
## - Detects platform edges and turns around
## - Kills player on side collision
## - Dies when player stomps on top

@export var walk_speed: float = 50.0
@export var gravity: float = 980.0
@export var edge_detection_distance: float = 10.0
@export var stomp_bounce_force: float = 150.0
@export var death_animation_duration: float = 2.0
@export var rotation_speed: float = 3.0
@export var fall_speed: float = 100.0

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

	# Check if it's the player and they're falling (stomping)
	if body.is_in_group("Player"):
		var player_velocity = body.velocity if body is CharacterBody2D else Vector2.ZERO

		# Only count as stomp if player is moving downward
		if player_velocity.y > 0:
			# Immediately disable damage detector to prevent it from triggering
			if damage_detector:
				damage_detector.monitoring = false
				damage_detector.monitorable = false
				# Also disable the collision shape
				var collision_shape = damage_detector.get_node_or_null("CollisionShape2D")
				if collision_shape:
					collision_shape.set_deferred("disabled", true)
			_die_from_stomp(body)

func _on_damage_detector_body_entered(body: Node2D):
	if not is_alive:
		return

	# Check if it's the player - side collision kills them
	if body.is_in_group("Player"):
		_kill_player(body)

func _die_from_stomp(player: Node2D):
	is_alive = false

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
		damage_detector.monitoring = false
		damage_detector.monitorable = false

	# Apply death shader (same as player)
	_apply_death_shader()

	# Play death animation
	_play_death_animation()

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
