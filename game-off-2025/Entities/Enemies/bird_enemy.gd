extends CharacterBody2D

## Bird enemy that perches and then swoops at the player
## - Starts perched (idle animation)
## - When player becomes visible, waits 0-1 seconds
## - Plays caw sound, then flies towards player
## - After 10 seconds of chasing, gives up and flies off screen
## - Kills player on collision (then leaves off screen)
## - Dies when player stomps on top (maybe do this differently than the ant... ?)

@export var fly_speed: float = 200.0
@export var gravity: float = 980.0
@export var detection_range: float = 200.0
@export var attack_delay_min: float = 0.0
@export var attack_delay_max: float = 1.0
@export var chase_timeout: float = 10.0
@export var retreat_speed: float = 150.0
@export var retreat_duration: float = 2.5
@export var stomp_bounce_force: float = 150.0
@export var death_animation_duration: float = 2.0
@export var rotation_speed: float = 3.0
@export var fall_speed: float = 100.0
@export var squash_duration: float = 0.15
@export var squash_amount: Vector2 = Vector2(1.5, 0.4)

enum State { PERCHED, PREPARING_ATTACK, FLYING, RETREATING, GIVING_UP }

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stomp_detector: Area2D = $StompDetector
@onready var damage_detector: Area2D = $DamageDetector
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var vision_raycast: RayCast2D = $VisionRayCast

var current_state: State = State.PERCHED
var is_alive: bool = true
var target_player: Node2D = null
var death_material: ShaderMaterial
var chase_timer: float = 0.0
var retreat_timer: float = 0.0

# Audio
var caw_sound: AudioStream = preload("res://Assets/Audio/caw.mp3")
var squish_sound: AudioStream = preload("res://Assets/Audio/bug-splat.wav")

func _ready():
	# Connect stomp detection
	if stomp_detector:
		stomp_detector.body_entered.connect(_on_stomp_detector_body_entered)

	# Connect damage detection
	if damage_detector:
		damage_detector.body_entered.connect(_on_damage_detector_body_entered)

	# Start perched
	_enter_perched_state()

func _physics_process(delta: float):
	if not is_alive:
		return

	match current_state:
		State.PERCHED:
			_process_perched(delta)
		State.FLYING:
			_process_flying(delta)
		State.RETREATING:
			_process_retreating(delta)
		State.GIVING_UP:
			_process_giving_up(delta)

func _process_perched(_delta: float):
	"""Check if player is visible while perched"""
	# Find player
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		return

	# Check if player is in range
	var distance = global_position.distance_to(player.global_position)
	if distance > detection_range:
		return

	# Check if player is visible (using raycast for line of sight)
	if vision_raycast:
		vision_raycast.target_position = to_local(player.global_position)
		vision_raycast.force_raycast_update()

		if vision_raycast.is_colliding():
			var collider = vision_raycast.get_collider()
			# If we hit the player, they're visible!
			if collider and collider.is_in_group("Player"):
				_start_attack(player)

func _process_flying(delta: float):
	"""Fly towards the player"""
	if not target_player:
		return

	# Check if player has died - if so, fly away
	var death_manager = target_player.get_node_or_null("DeathManager")
	if death_manager and death_manager.is_dead:
		_give_up()
		return

	# Track chase time
	chase_timer += delta

	# Check if chase timeout exceeded
	if chase_timer >= chase_timeout:
		_give_up()
		return

	# Calculate direction to player
	var direction = (target_player.global_position - global_position).normalized()

	# Set velocity towards player
	velocity = direction * fly_speed

	# Apply slight gravity so bird arcs downward
	velocity.y += gravity * delta * 0.3  # Reduced gravity for flying

	# Flip sprite based on direction
	if animated_sprite:
		animated_sprite.flip_h = direction.x < 0

	# Move
	move_and_slide()

func _enter_perched_state():
	"""Enter perched state - idle on a branch"""
	current_state = State.PERCHED
	velocity = Vector2.ZERO

	if animated_sprite:
		animated_sprite.play("idle")
		animated_sprite.flip_h = true  # Face left (where player comes from)

func _start_attack(player: Node2D):
	"""Begin attack sequence: delay -> caw -> fly"""
	current_state = State.PREPARING_ATTACK
	target_player = player

	# Random delay before attacking
	var delay = randf_range(attack_delay_min, attack_delay_max)
	await get_tree().create_timer(delay).timeout

	# Check if still alive after delay
	if not is_alive:
		return

	# Play caw sound
	if audio_player and caw_sound:
		audio_player.stream = caw_sound
		audio_player.play()

	# Wait for caw to finish (roughly 0.5 seconds)
	await get_tree().create_timer(0.3).timeout

	# Check if still alive
	if not is_alive:
		return

	# Start flying
	_enter_flying_state()

func _enter_flying_state():
	"""Start flying towards player"""
	current_state = State.FLYING
	chase_timer = 0.0  # Reset chase timer

	if animated_sprite:
		animated_sprite.play("flying")

func _start_retreat():
	"""Temporarily retreat after hitting a firefly shield"""
	current_state = State.RETREATING
	retreat_timer = 0.0

	# Temporarily disable collision detectors so bird doesn't spam hits while retreating
	if damage_detector:
		damage_detector.set_deferred("monitoring", false)
		damage_detector.set_deferred("monitorable", false)

	if stomp_detector:
		stomp_detector.set_deferred("monitoring", false)
		stomp_detector.set_deferred("monitorable", false)

func _process_retreating(delta: float):
	"""Fly away from player temporarily, then return to attack"""
	retreat_timer += delta

	# Check if retreat duration is over
	if retreat_timer >= retreat_duration:
		# Re-enable detectors
		if damage_detector:
			damage_detector.set_deferred("monitoring", true)
			damage_detector.set_deferred("monitorable", true)

		if stomp_detector:
			stomp_detector.set_deferred("monitoring", true)
			stomp_detector.set_deferred("monitorable", true)

		# Return to flying/chasing state
		_enter_flying_state()
		return

	# Fly away from player (upward and back)
	if target_player:
		# Calculate direction away from player
		var direction_from_player = (global_position - target_player.global_position).normalized()
		# Bias upward
		direction_from_player.y -= 0.5
		direction_from_player = direction_from_player.normalized()

		velocity = direction_from_player * retreat_speed
	else:
		# No player, just fly up
		velocity = Vector2(0, -1) * retreat_speed

	# Flip sprite based on direction
	if animated_sprite:
		animated_sprite.flip_h = velocity.x < 0

	move_and_slide()

func _give_up():
	"""Give up chasing and fly away"""
	current_state = State.GIVING_UP

	# Disable collision detectors so bird doesn't hurt player while fleeing
	if damage_detector:
		damage_detector.set_deferred("monitoring", false)
		damage_detector.set_deferred("monitorable", false)

	if stomp_detector:
		stomp_detector.set_deferred("monitoring", false)
		stomp_detector.set_deferred("monitorable", false)

func _process_giving_up(delta: float):
	"""Fly upward and off screen, then remove self"""
	# Fly upward and slightly in current direction
	var retreat_direction = Vector2(velocity.x * 0.3, -1.0).normalized()
	velocity = retreat_direction * retreat_speed

	# Move
	move_and_slide()

	# Check if off screen (bird has flown far enough up)
	var camera = get_viewport().get_camera_2d()
	if camera:
		var viewport_rect = get_viewport_rect()
		var camera_pos = camera.get_screen_center_position()
		var screen_top = camera_pos.y - (viewport_rect.size.y / 2.0) - 50  # Add margin

		# If bird is above screen, remove it
		if global_position.y < screen_top:
			queue_free()

func _on_stomp_detector_body_entered(body: Node2D):
	if not is_alive:
		return

	# Check if it's the player
	if body.is_in_group("Player"):
		# VERY forgiving velocity check: any downward movement OR very slow (gentle landing)
		var player_falling = false
		if body is CharacterBody2D:
			player_falling = body.velocity.y >= -10.0  # Even slight upward movement counts!

		# Get player's bottom position
		var player_bottom_y = body.global_position.y
		if body.has_node("CollisionShape2D"):
			var player_collision = body.get_node("CollisionShape2D")
			if player_collision and player_collision.shape:
				var shape = player_collision.shape
				if shape is RectangleShape2D or shape is CapsuleShape2D:
					var shape_height = shape.size.y if shape is RectangleShape2D else shape.height
					player_bottom_y = body.global_position.y + (shape_height / 2.0)

		# Bird's top position - MUCH more forgiving tolerance
		var bird_top_y = global_position.y - 6
		var STOMP_TOLERANCE = 12.0  # Very forgiving - increased from 8
		var player_is_above = player_bottom_y <= bird_top_y + STOMP_TOLERANCE

		# Valid stomp: player is falling AND above the bird (both very forgiving)
		if player_falling and player_is_above:
			# Mark as dead immediately
			is_alive = false

			# Stop physics
			set_physics_process(false)

			# Disable collision
			var main_collision = get_node_or_null("CollisionShape2D")
			if main_collision:
				main_collision.set_deferred("disabled", true)

			set_collision_layer_value(1, false)
			set_collision_layer_value(2, false)
			set_collision_mask_value(1, false)

			# Disable detectors
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

	# Check if it's the player
	if body.is_in_group("Player"):
		# Check if this is actually a stomp scenario - VERY forgiving fallback
		var player_was_falling = false
		if body is CharacterBody2D:
			player_was_falling = body.velocity.y >= -10.0  # Same as stomp detector - very forgiving

		var player_bottom_y = body.global_position.y
		if body.has_node("CollisionShape2D"):
			var player_collision = body.get_node("CollisionShape2D")
			if player_collision and player_collision.shape:
				var shape = player_collision.shape
				if shape is RectangleShape2D or shape is CapsuleShape2D:
					var shape_height = shape.size.y if shape is RectangleShape2D else shape.height
					player_bottom_y = body.global_position.y + (shape_height / 2.0)

		var bird_top_y = global_position.y - 6
		var STOMP_TOLERANCE = 10.0  # Very forgiving - increased from 6.0
		var player_is_clearly_above = player_bottom_y <= bird_top_y + STOMP_TOLERANCE

		var is_stomp_scenario = player_was_falling and player_is_clearly_above

		# If it's a stomp, kill the bird instead of the player
		if is_stomp_scenario:
			is_alive = false
			set_physics_process(false)

			var main_collision = get_node_or_null("CollisionShape2D")
			if main_collision:
				main_collision.set_deferred("disabled", true)

			set_collision_layer_value(1, false)
			set_collision_layer_value(2, false)
			set_collision_mask_value(1, false)

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
			return

		# Safety check
		if not is_alive:
			return

		# Otherwise, kill the player
		_kill_player(body)

func _die_from_stomp(player: Node2D):
	is_alive = false

	# Trigger hit stop
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

	var squash_tween = create_tween()
	squash_tween.set_ease(Tween.EASE_OUT)
	squash_tween.set_trans(Tween.TRANS_BACK)

	# Squash down quickly
	squash_tween.tween_property(animated_sprite, "scale", squash_amount, squash_duration * 0.3)
	# Bounce back
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

	# Rotate the bird
	tween.tween_property(animated_sprite, "rotation", TAU * rotation_speed, death_animation_duration)

	# Shrink the bird
	tween.tween_property(animated_sprite, "scale", Vector2(0.3, 0.3), death_animation_duration)

	# Make bird fall
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
		# Pass bird's position so player gets knocked back in the right direction
		death_manager.trigger_hazard_death(global_position)

		# If player actually died (wasn't protected by firefly), fly away
		if death_manager.is_dead:
			_give_up()
		else:
			# Player survived with firefly shield - retreat temporarily
			_start_retreat()
