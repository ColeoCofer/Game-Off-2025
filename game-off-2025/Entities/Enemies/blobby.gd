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
@export var player_detection_range: float = 100.0
@export var player_tracking_range: float = 50.0
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

# Audio
var squish_sound: AudioStream = preload("res://Assets/Audio/squish.mp3")

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
	if is_on_floor() and _should_jump_off_edge():
		_prepare_jump_off_ledge()
		return

	# Check if player is nearby and we should jump toward them
	if is_on_floor() and _should_jump_at_player():
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
	"""Always face the player when they're nearby (only during walking)"""
	# Safety check: only track during walking state
	if current_state != State.WALKING:
		return

	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		return

	var distance = global_position.distance_to(player.global_position)
	if distance > player_tracking_range:
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

	# Check if it's the player
	if body.is_in_group("Player"):
		# Forgiving velocity check: any downward movement counts as falling
		var player_falling = false
		if body is CharacterBody2D:
			player_falling = body.velocity.y > 0

		# Get player's bottom position
		var player_bottom_y = body.global_position.y
		if body.has_node("CollisionShape2D"):
			var player_collision = body.get_node("CollisionShape2D")
			if player_collision and player_collision.shape:
				var shape = player_collision.shape
				if shape is RectangleShape2D or shape is CapsuleShape2D:
					var shape_height = shape.size.y if shape is RectangleShape2D else shape.height
					player_bottom_y = body.global_position.y + (shape_height / 2.0)

		# Blobby's top position
		var blobby_top_y = global_position.y - 6
		var STOMP_TOLERANCE = 10.0  # Very forgiving for blob enemy
		var player_is_above = player_bottom_y <= blobby_top_y + STOMP_TOLERANCE

		# Valid stomp: player must be falling AND above
		if player_falling and player_is_above:
			# Mark as dead immediately
			is_alive = false

			# IMMEDIATELY disable damage detector
			if damage_detector:
				damage_detector.monitoring = false
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

	# Check if it's the player
	if body.is_in_group("Player"):
		# Check if this is actually a stomp scenario - forgiving fallback
		var player_was_falling = false
		if body is CharacterBody2D:
			player_was_falling = body.velocity.y > 0

		var player_bottom_y = body.global_position.y
		if body.has_node("CollisionShape2D"):
			var player_collision = body.get_node("CollisionShape2D")
			if player_collision and player_collision.shape:
				var shape = player_collision.shape
				if shape is RectangleShape2D or shape is CapsuleShape2D:
					var shape_height = shape.size.y if shape is RectangleShape2D else shape.height
					player_bottom_y = body.global_position.y + (shape_height / 2.0)

		var blobby_top_y = global_position.y - 6
		var STOMP_TOLERANCE = 10.0  # Forgiving fallback for blob enemy
		var player_is_clearly_above = player_bottom_y <= blobby_top_y + STOMP_TOLERANCE

		var is_stomp_scenario = player_was_falling and player_is_clearly_above

		# If it's a stomp, kill blobby instead of the player
		if is_stomp_scenario:
			is_alive = false

			# IMMEDIATELY disable both detectors
			if damage_detector:
				damage_detector.monitoring = false
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
