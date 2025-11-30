extends AnimatableBody2D

## Falling block that shakes and falls when player stands on it
## - Detects when player stands on top of the block
## - Shakes for 500ms or so to warn the player
## - Falls straight down after the warning period (should allow them to jump off while falling)

@export var shake_duration: float = 0.5  ## Time in seconds before falling (while shaking)
@export var shake_intensity: float = 1.5  ## How much the block shakes (in pixels)
@export var fall_speed: float = 200.0  ## Speed at which the block falls
@export var solid_fall_duration: float = 1.5  ## Time in seconds the block stays solid while falling
@export var respawn_time: float = 15.0  ## Time in seconds before the block respawns after falling

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var landing_detection_area: Area2D = $LandingDetectionArea
@onready var jump_detection_area: Area2D = $JumpDetectionArea
@onready var falling_rock_sound: AudioStreamPlayer = $FallingRockSound

var is_shaking: bool = false
var is_falling: bool = false
var has_triggered: bool = false
var is_respawning: bool = false
var shake_timer: float = 0.0
var fall_timer: float = 0.0
var collision_disabled: bool = false
var original_position: Vector2
var original_global_position: Vector2
var player_on_block: bool = false
var sound_duration: float = 0.0
var sound_start_volume: float = 0.0
var fade_start_time: float = 0.0

func _ready() -> void:
	original_position = sprite.position
	original_global_position = global_position

	# Connect landing detection area signals (for triggering shake)
	if landing_detection_area:
		landing_detection_area.body_entered.connect(_on_player_entered)
		landing_detection_area.body_exited.connect(_on_player_exited)
		print("FallingBlock: Landing detection area connected successfully")
	else:
		print("FallingBlock ERROR: No landing detection area found!")

	print("FallingBlock ready at: ", global_position)

func _physics_process(delta: float) -> void:
	# Check if player is on the block and we haven't triggered yet
	if player_on_block and not has_triggered and not is_shaking and not is_falling:
		_start_shaking()

	# Handle shaking animation
	if is_shaking:
		shake_timer += delta

		# Random shake offset
		var shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		sprite.position = original_position + shake_offset

		# Fade out the sound as it plays
		_update_sound_fade()

		# After shake duration, start falling
		if shake_timer >= shake_duration:
			_start_falling()

	# Handle falling
	if is_falling:
		fall_timer += delta

		# Set constant_linear_velocity so CharacterBody2D knows the platform is moving
		# This allows get_platform_velocity() to return the correct value
		constant_linear_velocity = Vector2(0, fall_speed)
		# Actually move the block
		position.y += fall_speed * delta

		# Continue fading out the sound while falling
		_update_sound_fade()

		# Disable collision after solid_fall_duration
		if not collision_disabled and fall_timer >= solid_fall_duration:
			collision_disabled = true
			collision_shape.set_deferred("disabled", true)
			print("FallingBlock: Collision disabled, player will fall through now")

		# Check if block has fallen far enough to start respawn timer
		if position.y > get_viewport_rect().size.y + 100:
			_start_respawn()

func _on_player_entered(body: Node2D) -> void:
	print("FallingBlock: Body entered - Name: ", body.name, " | Type: ", body.get_class(), " | Groups: ", body.get_groups())
	if body.is_in_group("Player") or body.name == "Player":
		print("FallingBlock: PLAYER DETECTED!")
		player_on_block = true

func _on_player_exited(body: Node2D) -> void:
	print("FallingBlock: Body exited - ", body.name)
	if body.is_in_group("Player") or body.name == "Player":
		player_on_block = false

func _start_shaking() -> void:
	print("FallingBlock: Starting to shake!")
	has_triggered = true
	is_shaking = true
	shake_timer = 0.0

	# Play the falling rock sound
	if falling_rock_sound and falling_rock_sound.stream:
		falling_rock_sound.play()
		sound_start_volume = falling_rock_sound.volume_db
		sound_duration = falling_rock_sound.stream.get_length()
		# Start fading when 60% through the sound
		fade_start_time = sound_duration * 0.6
		print("FallingBlock: Playing sound, duration: ", sound_duration)

func _start_falling() -> void:
	print("FallingBlock: Starting to fall!")
	is_shaking = false
	is_falling = true
	fall_timer = 0.0

	# Reset sprite to original position (no more shaking)
	sprite.position = original_position

	# Keep detection area active so we know when player leaves the block
	# This helps with jump detection

func _start_respawn() -> void:
	print("FallingBlock: Starting respawn sequence...")
	is_falling = false
	is_respawning = true

	# Hide and disable everything
	visible = false
	collision_shape.set_deferred("disabled", true)
	landing_detection_area.set_deferred("monitoring", false)
	jump_detection_area.set_deferred("monitoring", false)

	# Wait for respawn time, then reset
	await get_tree().create_timer(respawn_time).timeout
	_respawn()

func _update_sound_fade() -> void:
	if not falling_rock_sound or not falling_rock_sound.playing:
		return

	var playback_position = falling_rock_sound.get_playback_position()

	# Start fading out after fade_start_time
	if playback_position >= fade_start_time:
		var fade_duration = sound_duration - fade_start_time
		var fade_progress = (playback_position - fade_start_time) / fade_duration

		# Interpolate from start volume to -80 db (near silence)
		var target_volume = lerp(sound_start_volume, -80.0, fade_progress)
		falling_rock_sound.volume_db = target_volume

func _respawn() -> void:
	print("FallingBlock: Respawning!")

	# Stop any playing sound
	if falling_rock_sound and falling_rock_sound.playing:
		falling_rock_sound.stop()

	# Reset position
	global_position = original_global_position
	sprite.position = original_position

	# Reset all state variables
	is_shaking = false
	is_falling = false
	is_respawning = false
	has_triggered = false
	collision_disabled = false
	player_on_block = false
	shake_timer = 0.0
	fall_timer = 0.0
	constant_linear_velocity = Vector2.ZERO

	# Re-enable everything
	visible = true
	collision_shape.disabled = false
	landing_detection_area.monitoring = true
	jump_detection_area.monitoring = true
