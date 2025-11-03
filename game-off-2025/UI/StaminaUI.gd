extends HBoxContainer

# Configuration
@export var bar_width: float = 150.0
@export var bar_height: float = 12.0
@export var bar_background_color: Color = Color(0.2, 0.2, 0.2, 0.8)
@export var bar_fill_color: Color = Color(0.3, 0.8, 1.0, 1.0)  # Cyan/blue color (meh maybe change this)
@export var bar_ready_color: Color = Color(0.2, 1.0, 0.3, 1.0)  # Green when ready

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

	# Connect to EcholocationManager
	var echo_manager = get_node("/root/Level1/EcholocationManager")
	if echo_manager:
		echo_manager.cooldown_changed.connect(_on_cooldown_changed)

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
