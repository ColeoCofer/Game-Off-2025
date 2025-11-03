extends Node2D

# Reference to the AnimatedSprite2D
@onready var heart_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Configuration
var total_frames: int = 18  # Total frames in the heart animation (0-17)

func _ready():
	# Stop the animation from playing automatically
	if heart_sprite:
		heart_sprite.stop()
		heart_sprite.animation = "heart"

	# Connect to HungerManager
	var hunger_manager = get_node("/root/Level1/Player/HungerManager")
	if hunger_manager:
		hunger_manager.hunger_changed.connect(_on_hunger_changed)
		# Initialize with current hunger
		_on_hunger_changed(hunger_manager.current_hunger, hunger_manager.max_hunger)

func _on_hunger_changed(current: float, maximum: float):
	if not heart_sprite:
		return

	# Calculate hunger percentage (0.0 to 1.0)
	var hunger_percentage = current / maximum

	# Map hunger percentage to frame number
	# fralme 17 -> full health
	# End on frame 0 -> RIP
	var target_frame = int(hunger_percentage * (total_frames - 1))

	# Clamp to valid range
	target_frame = clamp(target_frame, 0, total_frames - 1)

	# Set the frame
	heart_sprite.frame = target_frame
