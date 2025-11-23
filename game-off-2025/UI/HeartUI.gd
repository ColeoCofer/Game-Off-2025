extends Node2D

# Reference to the AnimatedSprite2D
@onready var heart_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Configuration
var total_frames: int = 11  # Total frames in the hunger bar animation (0-10)

func _ready():
	# Stop the animation from playing automatically
	if heart_sprite:
		heart_sprite.stop()
		heart_sprite.animation = "hunger_bar"

	# Connect to HungerManager - find it dynamically
	var hunger_manager = get_tree().get_first_node_in_group("hunger_manager")
	if not hunger_manager:
		# Fallback: search for player's HungerManager (try both lowercase and capitalized)
		var player = get_tree().get_first_node_in_group("player")
		if not player:
			player = get_tree().get_first_node_in_group("Player")
		if player:
			hunger_manager = player.get_node_or_null("HungerManager")

	if hunger_manager:
		hunger_manager.hunger_changed.connect(_on_hunger_changed)
		# Initialize with current hunger
		_on_hunger_changed(hunger_manager.current_hunger, hunger_manager.max_hunger)
	else:
		push_error("HeartUI: Could not find HungerManager")

func _on_hunger_changed(current: float, maximum: float):
	if not heart_sprite:
		return

	# Calculate hunger percentage (0.0 to 1.0)
	var hunger_percentage = current / maximum

	# Map hunger percentage to frame number
	# Frame 0 -> full health (100%)
	# Frame 10 -> empty (0%)
	# Use total_frames multiplier so bar stays full longer
	var target_frame = int((1.0 - hunger_percentage) * total_frames)

	# Clamp to valid range
	target_frame = clamp(target_frame, 0, total_frames - 1)

	# Set the frame
	heart_sprite.frame = target_frame
