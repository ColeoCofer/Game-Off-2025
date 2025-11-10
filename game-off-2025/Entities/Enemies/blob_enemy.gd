extends CharacterBody2D

# Enemy states
enum State { DORMANT, SHOOTING, VULNERABLE, INVINCIBLE }

# Export variables
@export var max_health: int = 3
@export var wake_radius: float = 200.0 # How far away can it be woken up
@export var shots_per_burst: int = 3 # 3 shots before a short break
@export var shot_interval_min: float = 0.8
@export var shot_interval_max: float = 1.5
@export var vulnerable_duration: float = 2.0
@export var invincibility_duration: float = 0.5 # So the player can't just reck it 
@export var flash_speed: float = 0.1 # Blob get's hit flash
@export var projectile_scene: PackedScene = preload("res://Entities/Enemies/blob_projectile.tscn")
@export var projectile_spawn_offset: Vector2 = Vector2(0, -10)
@export var stomp_bounce_force: float = -150.0

# Death animation settings
@export var death_animation_duration: float = 2.0
@export var rotation_speed: float = 3.0
@export var fall_speed: float = 100.0
@export var squash_duration: float = 0.4

# Internal state
var current_state: State = State.DORMANT
var current_health: int = 3
var is_invincible: bool = false
var shots_fired: int = 0
var shot_timer: float = 0.0
var vulnerable_timer: float = 0.0
var invincibility_timer: float = 0.0
var is_flashing: bool = false

# Immovable position
var spawn_position: Vector2

# References
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stomp_detector: Area2D = $StompDetector
@onready var echolocation_manager: Node = null

# Death shader
var death_material: ShaderMaterial = null

func _ready():
	current_health = max_health

	# Store spawn position so blob stays immovable
	spawn_position = global_position

	# Connect to echolocation manager
	_connect_to_echolocation()

	# Connect stomp detector
	if stomp_detector:
		stomp_detector.body_entered.connect(_on_stomp_detector_body_entered)

	# Start in dormant state
	_enter_dormant_state()

func _physics_process(delta: float):
	# Keep blob completely immovable
	velocity = Vector2.ZERO

	# CharacterBody2D needs move_and_slide() to properly handle collisions
	move_and_slide()

	# Reset position to prevent being pushed
	global_position = spawn_position

	match current_state:
		State.DORMANT:
			_process_dormant(delta)
		State.SHOOTING:
			_process_shooting(delta)
		State.VULNERABLE:
			_process_vulnerable(delta)
		State.INVINCIBLE:
			_process_invincible(delta)

func _connect_to_echolocation():
	# Find the echolocation manager in the scene tree (it's in the echolocation_manager group)
	echolocation_manager = get_tree().get_first_node_in_group("echolocation_manager")
	if echolocation_manager:
		echolocation_manager.echolocation_triggered.connect(_on_echolocation_triggered)
		print("Blob connected to echolocation manager")
	else:
		print("Warning: Blob could not find echolocation manager")

func _on_echolocation_triggered(player_position: Vector2):
	# Only react if dormant
	if current_state != State.DORMANT:
		return

	# Check if player is within wake radius
	var distance = global_position.distance_to(player_position)
	print("Blob: Echolocation detected! Distance: ", distance, " / ", wake_radius)
	if distance <= wake_radius:
		print("Blob: Waking up!")
		_wake_up()
	else:
		print("Blob: Too far away to wake up")

func _wake_up():
	print("Blob waking up!")
	_enter_shooting_state()

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

func _enter_invincible_state():
	current_state = State.INVINCIBLE
	is_invincible = true
	invincibility_timer = 0.0

	# Start flash effect
	_start_flash()

# ============================================================
# STATE PROCESSING
# ============================================================

func _process_dormant(delta: float):
	# Wait for echolocation signal
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

func _process_invincible(delta: float):
	invincibility_timer += delta

	if invincibility_timer >= invincibility_duration:
		# Invincibility over
		is_invincible = false
		_stop_flash()

		# Return to shooting state immediately
		_enter_shooting_state()

# ============================================================
# PROJECTILE SYSTEM
# ============================================================

func _fire_projectile():
	if not projectile_scene:
		print("Blob: No projectile scene loaded!")
		return

	# Find player
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		print("Blob: No player found!")
		return

	# Spawn projectile FIRST
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position + projectile_spawn_offset

	print("Blob: Spawned projectile at ", projectile.global_position)

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

	# Verify player is falling
	var player_falling = false
	if body is CharacterBody2D:
		player_falling = body.velocity.y > 0

	if not player_falling:
		return

	# Check spatial position (player must be above)
	var player_bottom_y = body.global_position.y
	var blob_top_y = global_position.y - 8
	var player_is_above = player_bottom_y <= blob_top_y + 8

	if not player_is_above:
		return

	# Valid stomp detected - check state
	if current_state == State.SHOOTING:
		# Dangerous to stomp during shooting - damage player
		_damage_player(body)
	elif current_state == State.VULNERABLE and not is_invincible:
		# Safe to stomp during vulnerable window
		_take_damage(body)

func _damage_player(player: Node2D):
	# Stomping on blob during shooting phase kills the player
	var death_manager = player.get_node_or_null("DeathManager")
	if death_manager and death_manager.has_method("trigger_enemy_death"):
		death_manager.trigger_enemy_death()

	# Still bounce the player (death animation plays after)
	if player is CharacterBody2D:
		player.velocity.y = stomp_bounce_force

func _take_damage(player: Node2D):
	if is_invincible:
		return

	# Reduce health
	current_health -= 1

	# Hitstop effect
	HitStop.activate(0.03)

	# Bounce player
	if player is CharacterBody2D:
		player.velocity.y = stomp_bounce_force

	# Check if dead
	if current_health <= 0:
		_die_from_stomp()
	else:
		# Play hurt reaction
		_play_squash_effect()
		_enter_invincible_state()

# ============================================================
# VISUAL EFFECTS
# ============================================================

func _start_flash():
	is_flashing = true
	_flash_loop()

func _stop_flash():
	is_flashing = false
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE

func _flash_loop():
	if not is_flashing or not animated_sprite:
		return

	# Flash white
	animated_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
	await get_tree().create_timer(flash_speed).timeout

	if not is_flashing or not animated_sprite:
		return

	# Flash normal
	animated_sprite.modulate = Color.WHITE
	await get_tree().create_timer(flash_speed).timeout

	# Continue loop
	if is_flashing:
		_flash_loop()

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
