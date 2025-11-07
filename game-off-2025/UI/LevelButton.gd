extends Button

## LevelButton - Individual level button in the level select menu

signal level_selected(level_name: String)

var level_name: String = ""
var is_unlocked: bool = false

@onready var level_label: Label = $HBoxContainer/LevelLabel
@onready var status_label: Label = $HBoxContainer/StatusLabel
@onready var time_label: Label = $HBoxContainer/TimeLabel


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

	# Update visual style
	if not is_unlocked:
		modulate = Color(0.5, 0.5, 0.5, 0.7)


func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	if is_unlocked:
		emit_signal("level_selected", level_name)
