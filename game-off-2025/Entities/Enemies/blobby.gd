extends CharacterBody2D

## Blobby enemy that walks and jumps across platforms
## - Walks in configurable starting direction (left or right)
## - Turns around when hitting walls
## - Jumps off ledges when near platform edge
## - Jumps toward player when player is nearby
## - Dies when player stomps on top
## - Kills player on side collision

@export var walk_speed: float = 60.0
@export var gravity: float = 980.0
@export var edge_detection_distance: float = 12.0
@export var player_activation_range: float = 150.0
@export var player_detection_range: float = 100.0
@export var player_tracking_range: float = 50.0
@export var vertical_tracking_threshold: float = 40.0
@export var jump_velocity: float = -300.0
@export var jump_horizontal_boost: float = 200.0
@export var stomp_bounce_force: float = 150.0
@export var death_animation_duration: float = 2.0
@export var rotation_speed: float = 3.0
@export var fall_speed: float = 100.0
@export var squash_duration: float = 0.15
@export var squash_amount: Vector2 = Vector2(1.5, 0.4)
@export var jump_preparation_time: float = 0.4
@export var jump_cooldown_time: float = 0.5
@export_enum("Left:-1", "Right:1") var starting_direction: int = 1
@export var invincibility_duration: float = 0.8  # Brief invincibility after hitting player

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_raycast: RayCast2D = $FloorRayCast
@onready var stomp_detector: Area2D = $StompDetector
@onready var damage_detector: Area2D = $DamageDetector
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

enum State { WALKING, PREPARING_JUMP, JUMPING }

var direction: int = 1  # 1 for right, -1 for left
var is_alive: bool = true
var current_state: State = State.WALKING
var death_material: ShaderMaterial
var is_preparing_jump: bool = false
var jump_cooldown_timer: float = 0.0
var jump_direction: int = 1  # Direction locked in when jumping starts
var is_invincible: bool = false  # Brief invincibility after hitting player
var invincibility_timer: float = 0.0

# Audio
var squish_sound: AudioStream = preload("res://Assets/Audio/bug-splat.wav")

func _ready():
	# Set starting direction
	direction = starting_direction

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

	# Update jump cooldown timer
	if jump_cooldown_timer > 0:
		jump_cooldown_timer -= delta

	# Update invincibility timer
	if invincibility_timer > 0:
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			is_invincible = false

	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# When we land, return to walking state
		if current_state == State.JUMPING:
			current_state = State.WALKING
			# Start cooldown to prevent immediate re-jump
			jump_cooldown_timer = jump_cooldown_time

	match current_state:
		State.WALKING:
			_process_walking()
		State.PREPARING_JUMP:
			_process_preparing_jump()
		State.JUMPING:
			_process_jumping()

	# Update sprite (use jump_direction when preparing or jumping to prevent mid-air flipping)
	if animated_sprite:
		if current_state == State.JUMPING or current_state == State.PREPARING_JUMP:
			animated_sprite.flip_h = jump_direction > 0
		else:
			animated_sprite.flip_h = direction > 0

	# Move and check for wall collision
	move_and_slide()

	# Turn around if hit a wall (only during walking, not while jumping)
	if is_on_wall() and current_state == State.WALKING:
		_turn_around()

func _process_walking():
	"""Walking behavior: patrol and check for jumps"""
	# If airborne while in walking state, don't change horizontal velocity
	# This maintains momentum and prevents weird mid-air behavior
	if not is_on_floor():
		return

	# Check if player is within activation range
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance > player_activation_range:
			# Player is too far - stay idle
			velocity.x = 0
			if animated_sprite:
				animated_sprite.play("idle")
			return

	# Check if player is nearby and track them
	_track_nearby_player()

	# Don't check for jumps if we're already preparing one or on cooldown
	if is_preparing_jump or jump_cooldown_timer > 0:
		# Still walk while on cooldown
		velocity.x = direction * walk_speed
		if animated_sprite:
			animated_sprite.play("walk")
		return

	# Check for edge of platform
	if _should_jump_off_edge():
		_prepare_jump_off_ledge()
		return

	# Check if player is nearby and we should jump toward them
	if _should_jump_at_player():
		_prepare_jump_at_player()
		return

	# Normal walking
	velocity.x = direction * walk_speed

	if animated_sprite:
		animated_sprite.play("walk")

func _process_preparing_jump():
	"""Preparing to jump: halt movement and crouch"""
	# Stop horizontal movement
	velocity.x = 0

	# Play crouch animation
	if animated_sprite and animated_sprite.animation != "crouch":
		animated_sprite.play("crouch")

func _process_jumping():
	"""Jumping behavior: maintain horizontal momentum"""
	# Apply horizontal movement while jumping using locked jump direction
	velocity.x = jump_direction * jump_horizontal_boost

	if animated_sprite and animated_sprite.animation != "jump":
		animated_sprite.play("jump")

func _track_nearby_player():
	"""Always face the player when they're nearby AND on similar vertical level (only during walking)"""
	# Safety check: only track during walking state AND when on the floor
	# This prevents mid-air direction changes
	if current_state != State.WALKING or not is_on_floor():
		return

	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		return

	var distance = global_position.distance_to(player.global_position)
	if distance > player_tracking_range:
		return

	# Check if player is on a similar vertical level (same platform-ish)
	var vertical_distance = abs(player.global_position.y - global_position.y)
	if vertical_distance > vertical_tracking_threshold:
		# Player is on a different platform - don't track, just patrol
		return

	# Turn to face the player
	var to_player = player.global_position - global_position
	var new_direction = 1 if to_player.x > 0 else -1

	# Only update if direction actually changed
	if new_direction != direction:
		direction = new_direction
		# Update raycast position
		if floor_raycast:
			floor_raycast.position.x = edge_detection_distance * direction

func _should_jump_off_edge() -> bool:
	"""Check if there's no floor ahead (edge of platform)"""
	if floor_raycast:
		return not floor_raycast.is_colliding()
	return false

func _should_jump_at_player() -> bool:
	"""Check if player is nearby and blob should jump toward them"""
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		return false

	var distance = global_position.distance_to(player.global_position)
	if distance > player_detection_range:
		return false

	# Check if player is roughly in front of us
	var to_player = player.global_position - global_position
	var player_is_in_front = (to_player.x * direction) > 0  # Same sign as direction

	return player_is_in_front

func _prepare_jump_off_ledge():
	"""Prepare to jump off the edge - crouch first"""
	if is_preparing_jump:
		return

	is_preparing_jump = true
	current_state = State.PREPARING_JUMP

	# Lock jump direction NOW (before the await)
	jump_direction = direction

	# Wait for preparation time, then jump
	await get_tree().create_timer(jump_preparation_time).timeout

	# Check if still alive after delay
	if not is_alive:
		return

	_execute_jump()

func _prepare_jump_at_player():
	"""Prepare to jump at player - crouch and aim first"""
	if is_preparing_jump:
		return

	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		return

	is_preparing_jump = true
	current_state = State.PREPARING_JUMP

	# Adjust direction to face player immediately
	var to_player = player.global_position - global_position
	if to_player.x > 0:
		direction = 1
	else:
		direction = -1

	# Update raycast position
	if floor_raycast:
		floor_raycast.position.x = edge_detection_distance * direction

	# Lock jump direction NOW (after aiming, before the await)
	jump_direction = direction

	# Wait for preparation time, then jump
	await get_tree().create_timer(jump_preparation_time).timeout

	# Check if still alive after delay
	if not is_alive:
		return

	_execute_jump()

func _execute_jump():
	"""Actually perform the jump"""
	is_preparing_jump = false
	current_state = State.JUMPING
	velocity.y = jump_velocity

	# jump_direction was already locked in the prepare function

	if animated_sprite:
		animated_sprite.play("jump")

func _turn_around():
	"""Turn around and walk the other direction"""
	direction *= -1
	if floor_raycast:
		floor_raycast.position.x = edge_detection_distance * direction

func _on_stomp_detector_body_entered(body: Node2D):
	if not is_alive:
		return

	# If blobby is invincible, ignore stomps
	if is_invincible:
		return

	# Check if it's the player
	if body.is_in_group("Player"):
		# Get velocities to determine who's winning
		var player_velocity_y = 0.0
		if body is CharacterBody2D:
			player_velocity_y = body.velocity.y

		var blobby_velocity_y = velocity.y

		# Get vertical positions
		var player_center_y = body.global_position.y
		var blobby_center_y = global_position.y

		# Player only wins (stomps blobby) if player is clearly above AND falling onto blobby
		# This prevents blobby from dying when IT lands on the player
		var player_is_above = player_center_y < blobby_center_y
		var player_falling_onto_blobby = player_velocity_y > blobby_velocity_y + 50.0

		# Blobby wins if blobby is above and falling faster
		var blobby_is_above = blobby_center_y < player_center_y
		var blobby_falling_onto_player = blobby_velocity_y > player_velocity_y + 50.0
		var blobby_wins = blobby_is_above and blobby_falling_onto_player

		# Valid stomp: player must be above blobby AND falling onto it, AND blobby isn't winning
		if player_is_above and player_falling_onto_blobby and not blobby_wins:
			# Mark as dead immediately
			is_alive = false

			# Disable damage detector
			if damage_detector:
				damage_detector.set_deferred("monitoring", false)
				damage_detector.set_deferred("monitorable", false)

			if stomp_detector:
				stomp_detector.set_deferred("monitoring", false)
				stomp_detector.set_deferred("monitorable", false)

			# Stop physics
			set_physics_process(false)

			# Disable collision
			var main_collision = get_node_or_null("CollisionShape2D")
			if main_collision:
				main_collision.set_deferred("disabled", true)

			set_collision_layer_value(1, false)
			set_collision_layer_value(2, false)
			set_collision_mask_value(1, false)

			# Disable detector collision shapes
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

	# If blobby is invincible (just hit the player), ignore collisions
	if is_invincible:
		return

	# Check if it's the player
	if body.is_in_group("Player"):
		# Get velocities
		var player_velocity_y = 0.0
		if body is CharacterBody2D:
			player_velocity_y = body.velocity.y

		var blobby_velocity_y = velocity.y

		# Get vertical positions (centers)
		var player_center_y = body.global_position.y
		var blobby_center_y = global_position.y

		# Determine who is "winning" the vertical battle
		# Blobby kills player if:
		# - Blobby is above the player (blobby center is higher/smaller y)
		# - AND blobby is falling faster than player (or player is rising into blobby)
		var blobby_is_above = blobby_center_y < player_center_y
		var blobby_falling_onto_player = blobby_velocity_y > player_velocity_y + 50.0  # Blobby moving down relative to player

		# Player kills blobby if:
		# - Player is above blobby
		# - OR player is falling onto blobby from above
		var player_is_above = player_center_y < blobby_center_y
		var player_falling_onto_blobby = player_velocity_y > blobby_velocity_y + 50.0

		# Decision logic (player-friendly: ties go to player)
		var blobby_wins = blobby_is_above and blobby_falling_onto_player
		var player_wins = player_is_above or player_falling_onto_blobby or not blobby_wins

		if blobby_wins and not player_wins:
			# Grant blobby invincibility BEFORE hitting player to prevent race conditions
			# where stomp detector fires in the same frame
			_start_invincibility()
			# Bounce blobby upward to physically separate from player
			velocity.y = -200.0
			# Blobby landed on the player from above - damage the player
			_kill_player(body)
			return

		# Safety check
		if not is_alive:
			return

		# Otherwise, player wins - kill blobby
		is_alive = false

		# Disable both detectors
		if damage_detector:
			damage_detector.set_deferred("monitoring", false)
			damage_detector.set_deferred("monitorable", false)

		if stomp_detector:
			stomp_detector.set_deferred("monitoring", false)
			stomp_detector.set_deferred("monitorable", false)

		set_physics_process(false)

		var main_collision = get_node_or_null("CollisionShape2D")
		if main_collision:
			main_collision.set_deferred("disabled", true)

		set_collision_layer_value(1, false)
		set_collision_layer_value(2, false)
		set_collision_mask_value(1, false)

		# Disable detector collision shapes
		if damage_detector:
			var collision_shape = damage_detector.get_node_or_null("CollisionShape2D")
			if collision_shape:
				collision_shape.set_deferred("disabled", true)

		if stomp_detector:
			var collision_shape = stomp_detector.get_node_or_null("CollisionShape2D")
			if collision_shape:
				collision_shape.set_deferred("disabled", true)

		_die_from_stomp(body)

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

	# Rotate blobby
	tween.tween_property(animated_sprite, "rotation", TAU * rotation_speed, death_animation_duration)

	# Shrink blobby
	tween.tween_property(animated_sprite, "scale", Vector2(0.3, 0.3), death_animation_duration)

	# Make blobby fall
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
		# Pass blobby's position so player gets knocked back in the right direction
		death_manager.trigger_hazard_death(global_position)

func _start_invincibility():
	"""Grant blobby brief invincibility after hitting the player"""
	is_invincible = true
	invincibility_timer = invincibility_duration

	# Visual feedback: flash blobby to show invincibility
	if animated_sprite:
		_flash_invincibility()

func _flash_invincibility():
	"""Flash the sprite during invincibility"""
	if not animated_sprite or not is_alive:
		return

	var flash_interval = 0.1
	var flashes = int(invincibility_duration / (flash_interval * 2))

	for i in range(flashes):
		if not is_alive or not is_invincible:
			break
		animated_sprite.modulate.a = 0.4
		await get_tree().create_timer(flash_interval).timeout
		if not is_alive or not is_invincible:
			break
		animated_sprite.modulate.a = 1.0
		await get_tree().create_timer(flash_interval).timeout

	# Ensure sprite is fully visible at the end
	if animated_sprite and is_alive:
		animated_sprite.modulate.a = 1.0
