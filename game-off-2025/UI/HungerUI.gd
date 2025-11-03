extends HBoxContainer

# Configuration
@export var bar_width: float = 150.0
@export var bar_height: float = 12.0
@export var bar_background_color: Color = Color(0.2, 0.2, 0.2, 0.8)
@export var bar_full_color: Color = Color(0.2, 1.0, 0.3, 1.0)  # Green when full
@export var bar_warning_color: Color = Color(1.0, 0.8, 0.0, 1.0)  # Yellow when getting low
@export var bar_critical_color: Color = Color(1.0, 0.2, 0.2, 1.0)  # Red when very low
@export var warning_threshold: float = 0.5  # Below 50% shows warning color
@export var critical_threshold: float = 0.25  # Below 25% shows critical color

# UI elements
var bar_background: ColorRect
var bar_fill: ColorRect

func _ready():
	# Background bar
	bar_background = ColorRect.new()
	bar_background.custom_minimum_size = Vector2(bar_width, bar_height)
	bar_background.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bar_background.color = bar_background_color
	add_child(bar_background)

	# Create fill bar (as child of background for positioning)
	bar_fill = ColorRect.new()
	bar_fill.size = Vector2(bar_width, bar_height)
	bar_fill.color = bar_full_color
	bar_fill.position = Vector2.ZERO
	bar_background.add_child(bar_fill)

	# Connect to HungerManager
	var hunger_manager = get_node("/root/Level1/Player/HungerManager")
	if hunger_manager:
		hunger_manager.hunger_changed.connect(_on_hunger_changed)

func _on_hunger_changed(current: float, maximum: float):
	var progress = current / maximum
	bar_fill.size.x = bar_width * progress

	# Change color based on hunger level
	if progress <= critical_threshold:
		bar_fill.color = bar_critical_color
	elif progress <= warning_threshold:
		bar_fill.color = bar_warning_color
	else:
		bar_fill.color = bar_full_color
