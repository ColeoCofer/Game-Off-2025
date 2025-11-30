extends Node2D

## Bird spawner that spawns flying birds off-screen
## - Spawns birds from left or right side of screen
## - Birds fly across at player's Y position
## - Can be triggered manually or automatically on timer

@export var bird_scene: PackedScene = preload("res://Entities/Enemies/bird_flying.tscn")
@export var spawn_side: String = "random"  # "left", "right", or "random"
@export var spawn_offset_from_screen: float = 50.0  # How far off screen to spawn
@export var auto_spawn: bool = false  # Auto-spawn on timer
@export var spawn_interval_min: float = 3.0
@export var spawn_interval_max: float = 6.0
@export var activation_radius: float = 400.0  # Only spawn when player is within this distance
@export var bird_fly_speed: float = 110.0  # Speed of spawned birds

var spawn_timer: float = 0.0
var next_spawn_time: float = 0.0

func _ready():
	# Hide the spawner icon during gameplay (only visible in editor)
	var icon = get_node_or_null("Icon")
	if icon:
		icon.visible = false

	if auto_spawn:
		# Start the spawn timer
		next_spawn_time = randf_range(spawn_interval_min, spawn_interval_max)

func _process(delta: float):
	if not auto_spawn:
		return

	# Check if player is within activation radius
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		return

	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player > activation_radius:
		return  # Player too far away, don't spawn

	# Player is in range, increment spawn timer
	spawn_timer += delta
	if spawn_timer >= next_spawn_time:
		spawn_bird()
		spawn_timer = 0.0
		next_spawn_time = randf_range(spawn_interval_min, spawn_interval_max)

func spawn_bird():
	"""Spawn a bird flying across the screen"""
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		return

	# Determine which side to spawn from
	var side = spawn_side
	if side == "random":
		side = "left" if randf() < 0.5 else "right"

	# Get screen bounds
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return

	var viewport_rect = get_viewport_rect()
	var camera_pos = camera.get_screen_center_position()

	# Calculate spawn position
	var spawn_pos = Vector2.ZERO
	var direction = 1  # 1 = fly right, -1 = fly left

	if side == "left":
		# Spawn off the left side, fly right
		spawn_pos.x = camera_pos.x - (viewport_rect.size.x / 2.0) - spawn_offset_from_screen
		direction = 1
	else:  # "right"
		# Spawn off the right side, fly left
		spawn_pos.x = camera_pos.x + (viewport_rect.size.x / 2.0) + spawn_offset_from_screen
		direction = -1

	# Use player's current Y position
	spawn_pos.y = player.global_position.y

	# Instantiate and add bird
	var bird = bird_scene.instantiate()
	get_parent().add_child(bird)
	bird.global_position = spawn_pos

	# Set the bird's speed
	bird.fly_speed = bird_fly_speed

	# Setup the bird's flight direction
	if bird.has_method("setup_flight"):
		bird.setup_flight(direction)
