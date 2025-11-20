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
@onready var hitbox_area: Area2D = $HitboxArea
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var direction: int = 1  # 1 for right, -1 for left
var is_alive: bool = true
var death_material: ShaderMaterial

# Audio
var squish_sound: AudioStream = preload("res://Assets/Audio/squish.mp3")

func _ready():
	# Add to mob group for player collision detection
	add_to_group("mob")

	# Connect hitbox detection
	if hitbox_area:
		hitbox_area.body_entered.connect(_on_hitbox_body_entered)
		print("DEBUG ANT: Hitbox connected! Area monitoring: ", hitbox_area.monitoring, " monitorable: ", hitbox_area.monitorable)
	else:
		print("DEBUG ANT: ERROR - No hitbox_area found!")

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

func _on_hitbox_body_entered(body: Node2D):
	"""Single hitbox detection - checks if stomp or side hit"""
	print("DEBUG ANT: Hitbox triggered by: ", body.name)

	if not is_alive:
		print("DEBUG ANT: Ant already dead, ignoring")
		return

	if not body.is_in_group("Player"):
		print("DEBUG ANT: Body is not player, ignoring")
		return

	print("DEBUG ANT: Player detected! Checking collision type...")

	# Calculate player and enemy positions
	var player_center_y = body.global_position.y
	var enemy_center_y = global_position.y
	var height_difference = enemy_center_y - player_center_y

	# Player must be significantly above (at least 3 pixels) to count as stomp
	# This prevents step-up micro-movements from triggering false stomps
	var MIN_STOMP_HEIGHT = 3.0
	var player_is_above = height_difference >= MIN_STOMP_HEIGHT
	print("DEBUG ANT: Player center: ", player_center_y, " Enemy center: ", enemy_center_y, " Height diff: ", height_difference, " Player is above? ", player_is_above)

	# Stomp if player is significantly above enemy
	if player_is_above:
		print("DEBUG ANT: STOMP detected - killing ant")
		squash(body)
	else:
		print("DEBUG ANT: SIDE HIT detected - killing player")
		hit_player(body)

## Called by player when they stomp on the ant from above
func squash(player: Node2D):
	if not is_alive:
		return

	# Mark as dead and stop physics immediately
	is_alive = false
	set_physics_process(false)

	# Disable collision immediately
	var main_collision = get_node_or_null("CollisionShape2D")
	if main_collision:
		main_collision.set_deferred("disabled", true)

	set_collision_layer_value(1, false)
	set_collision_layer_value(2, false)
	set_collision_mask_value(1, false)

	# Disable hitbox to prevent further collisions
	if hitbox_area:
		hitbox_area.set_deferred("monitoring", false)
		hitbox_area.set_deferred("monitorable", false)

	# Trigger hit stop for satisfying feedback
	HitStop.activate(0.03)

	# Play squish sound
	if audio_player and squish_sound:
		audio_player.stream = squish_sound
		audio_player.play()

	# Give player a bounce
	if player is CharacterBody2D:
		player.velocity.y = -stomp_bounce_force

	# Apply death shader
	_apply_death_shader()

	# Play squash effect, then death animation
	_play_squash_effect()

## Called by player when they hit the ant from the side/bottom
func hit_player(player: Node2D):
	if not is_alive:
		return

	_kill_player(player)


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
