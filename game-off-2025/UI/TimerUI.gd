extends Control

## TimerUI - Displays the current level completion time in the top-right corner

@onready var time_label: Label = $TimeLabel

var is_running: bool = false
var current_time: float = 0.0


func _ready() -> void:
	# Check if timer should be visible based on settings
	visible = SaveManager.get_show_timer()

	# Position in top-right corner with some padding
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -150  # Adjust based on label width
	offset_top = 10
	offset_right = -10
	offset_bottom = 50


func _process(delta: float) -> void:
	if not is_running or not visible:
		return

	# Get time from SceneManager
	if SceneManager.current_level != "" and SceneManager.current_level_start_time > 0.0:
		current_time = (Time.get_ticks_msec() / 1000.0) - SceneManager.current_level_start_time
		_update_display()


func start_timer() -> void:
	is_running = true
	current_time = 0.0


func stop_timer() -> void:
	is_running = false


func reset_timer() -> void:
	current_time = 0.0
	_update_display()


func set_timer_visible(show: bool) -> void:
	visible = show


func _update_display() -> void:
	var minutes = int(current_time / 60.0)
	var seconds = int(current_time) % 60
	var milliseconds = int((current_time - int(current_time)) * 100)
	time_label.text = "%d:%02d.%02d" % [minutes, seconds, milliseconds]
