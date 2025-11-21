extends Node2D

# Reference to the AnimatedSprite2D
@onready var echo_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Configuration
var total_frames: int = 7  # Total frames in the echo bar animation (0-6)

func _ready():
	# Stop the animation from playing automatically
	if echo_sprite:
		echo_sprite.stop()
		echo_sprite.animation = "echo_bar"

	# Connect to EcholocationManager - find it dynamically
	var echo_manager = get_tree().get_first_node_in_group("echolocation_manager")
	if not echo_manager:
		# Fallback: search for player's EcholocationManager
		var player = get_tree().get_first_node_in_group("player")
		if not player:
			player = get_tree().get_first_node_in_group("Player")
		if player:
			echo_manager = player.get_node_or_null("EcholocationManager")

	if echo_manager:
		echo_manager.cooldown_changed.connect(_on_cooldown_changed)
		# Initialize with current cooldown state if available
		if echo_manager.has_method("get_cooldown_progress"):
			var progress = echo_manager.get_cooldown_progress()
			_on_cooldown_changed(progress.x, progress.y)
	else:
		push_error("EchoBarUI: Could not find EcholocationManager")

func _on_cooldown_changed(current: float, maximum: float):
	if not echo_sprite:
		return

	# Calculate cooldown percentage (0.0 to 1.0)
	var cooldown_percentage = current / maximum

	# Map cooldown percentage to frame number
	# Frame 0 -> cooldown complete (full/ready, 100%)
	# Frame 6 -> cooldown just started (empty, 0%)
	# Use total_frames multiplier so bar stays full longer when ready
	var target_frame = int((1.0 - cooldown_percentage) * total_frames)

	# Clamp to valid range
	target_frame = clamp(target_frame, 0, total_frames - 1)

	# Set the frame
	echo_sprite.frame = target_frame
