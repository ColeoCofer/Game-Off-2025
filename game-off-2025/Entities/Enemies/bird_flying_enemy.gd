extends CharacterBody2D

## Flying bird enemy that swoops horizontally across the screen
## - Spawns off-screen to the left or right of player
## - Flies straight across while tracking player's Y position
## - Removes itself when it goes off the other side
## - Kills player on collision
## - Dies when player stomps on top

@export var fly_speed: float = 150.0
@export var vertical_tracking_speed: float = 35.0  # How fast the bird tracks player's Y position
@export var stomp_bounce_force: float = 220.0
@export var death_animation_duration: float = 2.0
@export var rotation_speed: float = 3.0
@export var fall_speed: float = 100.0
@export var squash_duration: float = 0.15
@export var squash_amount: Vector2 = Vector2(1.5, 0.4)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stomp_detector: Area2D = $StompDetector
@onready var damage_detector: Area2D = $DamageDetector
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var is_alive: bool = true
var fly_direction: int = 1  # 1 for right, -1 for left
var death_material: ShaderMaterial

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

	# Play caw sound when spawning
	if audio_player and caw_sound:
		audio_player.stream = caw_sound
		audio_player.play()

	# Start flying animation
	if animated_sprite:
		animated_sprite.play("flying")

func setup_flight(direction: int):
	"""Called by spawner to set flight direction. -1 = left, 1 = right"""
	fly_direction = direction

	# Flip sprite based on direction
	if animated_sprite:
		animated_sprite.flip_h = direction < 0

func _physics_process(_delta: float):
	if not is_alive:
		return

	# Fly horizontally
	velocity.x = fly_direction * fly_speed

	# Track player's Y position
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		var direction_to_player = sign(player.global_position.y - global_position.y)
		velocity.y = direction_to_player * vertical_tracking_speed
	else:
		velocity.y = 0  # No player found, fly straight

	move_and_slide()

	# Check if off screen and remove
	_check_if_offscreen()

func _check_if_offscreen():
	"""Remove bird if it's gone off screen"""
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return

	var viewport_rect = get_viewport_rect()
	var camera_pos = camera.get_screen_center_position()
	var screen_left = camera_pos.x - (viewport_rect.size.x / 2.0) - 50  # Add margin
	var screen_right = camera_pos.x + (viewport_rect.size.x / 2.0) + 50  # Add margin

	# If bird has flown off either side, remove it
	if global_position.x < screen_left or global_position.x > screen_right:
		queue_free()

func _on_stomp_detector_body_entered(body: Node2D):
	if not is_alive:
		return

	# Check if it's the player
	if body.is_in_group("Player"):
		# Player must be falling (velocity.y > 0)
		var player_falling = false
		if body is CharacterBody2D:
			player_falling = body.velocity.y > 0  # Moving downward

		# Get player's bottom position
		var player_bottom_y = body.global_position.y
		if body.has_node("CollisionShape2D"):
			var player_collision = body.get_node("CollisionShape2D")
			if player_collision and player_collision.shape:
				var shape = player_collision.shape
				if shape is RectangleShape2D or shape is CapsuleShape2D:
					var shape_height = shape.size.y if shape is RectangleShape2D else shape.height
					player_bottom_y = body.global_position.y + (shape_height / 2.0)

		# Bird's top position
		var bird_top_y = global_position.y - 6
		var player_is_above = player_bottom_y <= bird_top_y + 8

		# Valid stomp: player is falling AND above the bird
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
		# Check if this is actually a stomp scenario
		var player_was_falling = false
		if body is CharacterBody2D:
			player_was_falling = body.velocity.y > 20.0

		var player_bottom_y = body.global_position.y
		if body.has_node("CollisionShape2D"):
			var player_collision = body.get_node("CollisionShape2D")
			if player_collision and player_collision.shape:
				var shape = player_collision.shape
				if shape is RectangleShape2D or shape is CapsuleShape2D:
					var shape_height = shape.size.y if shape is RectangleShape2D else shape.height
					player_bottom_y = body.global_position.y + (shape_height / 2.0)

		var bird_top_y = global_position.y - 6
		var stomp_tolerance = 6.0
		var player_is_clearly_above = player_bottom_y <= bird_top_y + stomp_tolerance

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

		# Check if player actually died (might have firefly shield)
		var death_manager = body.get_node_or_null("DeathManager")
		if death_manager and death_manager.is_dead:
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
