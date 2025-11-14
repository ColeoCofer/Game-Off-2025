extends Button

## LevelButton - Individual level button in the level select menu

signal level_selected(level_name: String)

var level_name: String = ""
var is_unlocked: bool = false

@onready var level_label: Label = $VBoxContainer/HBoxContainer/LevelLabel
@onready var status_label: Label = $VBoxContainer/HBoxContainer/StatusLabel
@onready var time_label: Label = $VBoxContainer/HBoxContainer/TimeLabel
@onready var firefly_container: HBoxContainer = $VBoxContainer/FireflyContainer
@onready var firefly_icon1: TextureRect = $VBoxContainer/FireflyContainer/FireflyIcon1
@onready var firefly_icon2: TextureRect = $VBoxContainer/FireflyContainer/FireflyIcon2
@onready var firefly_icon3: TextureRect = $VBoxContainer/FireflyContainer/FireflyIcon3


func setup(p_level_name: String, display_name: String, p_is_unlocked: bool, best_time: float) -> void:
	level_name = p_level_name
	is_unlocked = p_is_unlocked

	# Set level name
	level_label.text = display_name

	# Set lock status
	if is_unlocked:
		status_label.text = "✓"
		status_label.modulate = Color.GREEN
		disabled = false
	else:
		status_label.text = "🔒"
		status_label.modulate = Color.GRAY
		disabled = true

	# Set best time if available
	if best_time > 0.0:
		var minutes = int(best_time / 60.0)
		var seconds = int(best_time) % 60
		var milliseconds = int((best_time - int(best_time)) * 100)
		time_label.text = "%d:%02d.%02d" % [minutes, seconds, milliseconds]
	else:
		time_label.text = "--:--:--"

	# Set firefly collection status
	_update_firefly_display()

	# Update visual style
	if not is_unlocked:
		modulate = Color(0.5, 0.5, 0.5, 0.7)


func _ready() -> void:
	pressed.connect(_on_pressed)


func _update_firefly_display() -> void:
	# Hide firefly container for tutorial level (no fireflies to collect)
	if level_name == "tutorial":
		firefly_container.visible = false
		return

	# Get firefly collection data from FireflyCollectionManager
	var collected_fireflies = FireflyCollectionManager.get_collected_fireflies(level_name)

	# Update icon display - show firefly if collected, dark/hidden if not
	# Note: Firefly IDs in levels are 1, 2, 3 (not 0, 1, 2)
	var icons = [firefly_icon1, firefly_icon2, firefly_icon3]
	for i in range(icons.size()):
		var firefly_id = i + 1  # Map icon index (0,1,2) to firefly ID (1,2,3)
		if firefly_id in collected_fireflies:
			# Collected - show bright firefly image
			icons[i].modulate = Color(1.0, 1.0, 1.0, 1.0)  # Full brightness
			icons[i].visible = true
		else:
			# Not collected - very dark/barely visible
			icons[i].modulate = Color(0.2, 0.2, 0.2, 0.3)  # Much darker and more transparent
			icons[i].visible = true


func _on_pressed() -> void:
	if is_unlocked:
		emit_signal("level_selected", level_name)
