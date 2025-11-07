extends HBoxContainer

# Configuration
@export var bar_width: float = 150.0
@export var bar_height: float = 12.0
@export var bar_background_color: Color = Color(0.2, 0.2, 0.2, 0.8)
@export var bar_fill_color: Color = Color(0.239, 0.231, 0.149, 1.0)  # #3d3b26
@export var bar_ready_color: Color = Color(0.380, 0.408, 0.329, 1.0)  # #616854

# UI elements
var bar_background: ColorRect
var bar_fill: ColorRect

func _ready():
	# Background bar
	bar_background = ColorRect.new()
	bar_background.custom_minimum_size = Vector2(bar_width, bar_height)
	bar_background.size_flags_vertical = Control.SIZE_SHRINK_BEGIN  # Don't expand vertically
	bar_background.color = bar_background_color
	add_child(bar_background)

	# Create fill bar (as child of background for positioning)
	bar_fill = ColorRect.new()
	bar_fill.size = Vector2(bar_width, bar_height)  # Match exact size
	bar_fill.color = bar_ready_color  # Start ready
	bar_fill.position = Vector2.ZERO
	bar_background.add_child(bar_fill)

	# Connect to EcholocationManager - find it dynamically
	var echo_manager = get_tree().get_first_node_in_group("echolocation_manager")
	if not echo_manager:
		# Fallback: StaminaUI is a child of EcholocationManager, so get parent
		echo_manager = get_parent()

	if echo_manager and echo_manager.has_signal("cooldown_changed"):
		echo_manager.cooldown_changed.connect(_on_cooldown_changed)
	else:
		push_error("StaminaUI: Could not find EcholocationManager")

func _on_cooldown_changed(current: float, maximum: float):
	if current >= maximum:
		# Cooldown complete - show full bar with ready color
		bar_fill.size.x = bar_width
		bar_fill.color = bar_ready_color
	else:
		# Cooldown in progress - show progress
		var progress = current / maximum
		bar_fill.size.x = bar_width * progress
		bar_fill.color = bar_fill_color
