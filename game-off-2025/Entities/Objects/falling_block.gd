extends AnimatableBody2D

## Falling block that shakes and falls when player stands on it
## - Detects when player stands on top of the block
## - Shakes for 500ms or so to warn the player
## - Falls straight down after the warning period (should allow them to jump off while falling)

@export var shake_duration: float = 0.5  ## Time in seconds before falling (while shaking)
@export var shake_intensity: float = 1.5  ## How much the block shakes (in pixels)
@export var fall_speed: float = 200.0  ## Speed at which the block falls
@export var destroy_after_fall: bool = true  ## Whether to remove the block after falling off screen

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $PlayerDetectionArea

var is_shaking: bool = false
var is_falling: bool = false
var has_triggered: bool = false
var shake_timer: float = 0.0
var original_position: Vector2
var player_on_block: bool = false

func _ready() -> void:
	original_position = sprite.position

	# Connect detection area signals
	if detection_area:
		detection_area.body_entered.connect(_on_player_entered)
		detection_area.body_exited.connect(_on_player_exited)
		print("FallingBlock: Detection area connected successfully")
	else:
		print("FallingBlock ERROR: No detection area found!")

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

		# After shake duration, start falling
		if shake_timer >= shake_duration:
			_start_falling()

	# Handle falling
	if is_falling:
		position.y += fall_speed * delta

		# Check if block has fallen far enough to be destroyed
		if destroy_after_fall and position.y > get_viewport_rect().size.y + 100:
			queue_free()

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

func _start_falling() -> void:
	print("FallingBlock: Starting to fall!")
	is_shaking = false
	is_falling = true

	# Reset sprite to original position (no more shaking)
	sprite.position = original_position

	# Disable collision so the block doesn't interfere while falling
	collision_shape.set_deferred("disabled", true)
	detection_area.set_deferred("monitoring", false)
