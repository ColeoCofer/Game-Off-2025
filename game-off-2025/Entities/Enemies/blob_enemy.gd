extends StaticBody2D

# Enemy states
enum State { DORMANT, SHOOTING, VULNERABLE }

# Export variables
@export var max_health: int = 1  # Only takes 1 hit to kill
@export var aggro_radius: float = 300.0  # Start shooting when player this close
@export var shots_per_burst: int = 3
@export var shot_interval_min: float = 0.8
@export var shot_interval_max: float = 1.5
@export var vulnerable_duration: float = 2.0
@export var projectile_scene: PackedScene = preload("res://Entities/Enemies/blob_projectile.tscn")
@export var projectile_spawn_offset: Vector2 = Vector2(0, -10)
@export var stomp_bounce_force: float = -300.0

# Death animation settings
@export var death_animation_duration: float = 2.0
@export var rotation_speed: float = 3.0
@export var fall_speed: float = 100.0
@export var squash_duration: float = 0.4

# Internal state
var current_state: State = State.DORMANT
var current_health: int = 1
var shots_fired: int = 0
var shot_timer: float = 0.0
var vulnerable_timer: float = 0.0
var is_dead: bool = false

# References
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stomp_detector: Area2D = $StompDetector

# Death shader
var death_material: ShaderMaterial = null

func _ready():
	current_health = max_health

	# Connect stomp detector
	if stomp_detector:
		stomp_detector.body_entered.connect(_on_stomp_detector_body_entered)

	# Start in dormant state
	_enter_dormant_state()

func _process(delta: float):
	# Don't process anything if dead
	if is_dead:
		return

	# Check player proximity to activate/deactivate
	_check_player_proximity()

	# Process current state
	match current_state:
		State.DORMANT:
			_process_dormant(delta)
		State.SHOOTING:
			_process_shooting(delta)
		State.VULNERABLE:
			_process_vulnerable(delta)

func _check_player_proximity():
	# Find player
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		return

	# Check distance to player
	var distance = global_position.distance_to(player.global_position)
	var player_in_range = distance <= aggro_radius

	# State transitions based on proximity
	if player_in_range:
		# Player entered aggro range - start shooting if dormant
		if current_state == State.DORMANT:
			_enter_shooting_state()
	else:
		# Player left aggro range - go dormant if currently active
		if current_state == State.SHOOTING or current_state == State.VULNERABLE:
			_enter_dormant_state()

# ============================================================
# STATE MANAGEMENT
# ============================================================

func _enter_dormant_state():
	current_state = State.DORMANT
	if animated_sprite:
		animated_sprite.stop()

func _enter_shooting_state():
	current_state = State.SHOOTING
	shots_fired = 0
	shot_timer = 0.0

	if animated_sprite:
		animated_sprite.play("idle")

func _enter_vulnerable_state():
	current_state = State.VULNERABLE
	vulnerable_timer = 0.0

	if animated_sprite:
		animated_sprite.play("idle")

# ============================================================
# STATE PROCESSING
# ============================================================

func _process_dormant(delta: float):
	# Just wait - proximity detection in _check_player_proximity() handles activation
	pass

func _process_shooting(delta: float):
	shot_timer += delta

	# Shoot projectiles at random intervals
	if shots_fired < shots_per_burst:
		var next_shot_interval = randf_range(shot_interval_min, shot_interval_max)
		if shot_timer >= next_shot_interval:
			_fire_projectile()
			shots_fired += 1
			shot_timer = 0.0
	else:
		# Burst complete, enter vulnerable state
		_enter_vulnerable_state()

func _process_vulnerable(delta: float):
	vulnerable_timer += delta

	if vulnerable_timer >= vulnerable_duration:
		# Vulnerable period over, start shooting again
		_enter_shooting_state()

# ============================================================
# PROJECTILE SYSTEM
# ============================================================

func _fire_projectile():
	if not projectile_scene:
		return

	# Find player
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		return

	# Spawn projectile FIRST
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position + projectile_spawn_offset

	# Launch at player
	projectile.launch_at_target(player.global_position)

	# Play shoot animation (don't wait for it to finish)
	if animated_sprite:
		animated_sprite.play("shoot")
		# Schedule return to idle after animation
		_schedule_return_to_idle()

func _schedule_return_to_idle():
	# Wait for shoot animation to finish, then return to idle
	await animated_sprite.animation_finished
	if animated_sprite and current_state == State.SHOOTING:
		animated_sprite.play("idle")

# ============================================================
# STOMP DETECTION
# ============================================================

func _on_stomp_detector_body_entered(body: Node2D):
	# Check if it's the player
	if not (body.is_in_group("Player") or body is PlatformerController2D):
		return

	# Verify player is falling or just landed (velocity.y >= 0 instead of > 0)
	var player_falling = false
	if body is CharacterBody2D:
		player_falling = body.velocity.y >= -50  # Allow small upward velocity too (landing tolerance)

	if not player_falling:
		return

	# Check spatial position (player must be above)
	var player_bottom_y = body.global_position.y
	var blob_top_y = global_position.y - 8
	var player_is_above = player_bottom_y <= blob_top_y + 8

	if not player_is_above:
		return

	# Valid stomp detected - always kill blob (1 hit kill)
	_take_damage(body)

func _take_damage(player: Node2D):
	# Mark as dead to stop all state processing
	is_dead = true

	# Stop shooting immediately
	current_state = State.DORMANT

	# Hitstop effect
	HitStop.activate(0.03)

	# Bounce player
	if player is CharacterBody2D:
		player.velocity.y = stomp_bounce_force

	# Flash effect
	if animated_sprite:
		animated_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
		await get_tree().create_timer(0.1).timeout
		animated_sprite.modulate = Color.WHITE

	# Play squash effect then die
	_play_squash_effect()
	# Die immediately (1 hit kill)
	await get_tree().create_timer(squash_duration).timeout
	_die_from_stomp()

# ============================================================
# VISUAL EFFECTS
# ============================================================

func _play_squash_effect():
	if not animated_sprite:
		return

	var squash_tween = create_tween()
	squash_tween.set_ease(Tween.EASE_OUT)
	squash_tween.set_trans(Tween.TRANS_BACK)

	# Squash
	squash_tween.tween_property(animated_sprite, "scale", Vector2(1.5, 0.4), squash_duration * 0.3)
	# Bounce back
	squash_tween.tween_property(animated_sprite, "scale", Vector2.ONE, squash_duration * 0.7)

# ============================================================
# DEATH SYSTEM
# ============================================================

func _die_from_stomp():
	# Disable collision
	if stomp_detector:
		stomp_detector.set_deferred("monitoring", false)
		stomp_detector.set_deferred("monitorable", false)

	# Apply death shader
	_apply_death_shader()

	# Play death animation
	_play_death_animation()

func _apply_death_shader():
	var death_shader = load("res://Shaders/death_shader.gdshader")
	death_material = ShaderMaterial.new()
	death_material.shader = death_shader
	death_material.set_shader_parameter("death_progress", 0.0)
	death_material.set_shader_parameter("distortion_strength", 0.5)

	if animated_sprite:
		animated_sprite.material = death_material

func _play_death_animation():
	if not animated_sprite:
		queue_free()
		return

	var tween = create_tween()
	tween.set_parallel(true)

	# Fade death shader
	tween.tween_method(_update_death_shader, 0.0, 1.0, death_animation_duration)

	# For blob, spread out flat instead of shrinking
	# Rotate less than ant (just 1 rotation)
	tween.tween_property(animated_sprite, "rotation", TAU * 1.0, death_animation_duration)
	# Spread wide and flat
	tween.tween_property(animated_sprite, "scale", Vector2(2.0, 0.1), death_animation_duration)
	# Sink down a bit
	tween.tween_property(self, "position:y", position.y + fall_speed * 0.5, death_animation_duration)

	tween.finished.connect(queue_free)

func _update_death_shader(progress: float):
	if death_material:
		death_material.set_shader_parameter("death_progress", progress)
