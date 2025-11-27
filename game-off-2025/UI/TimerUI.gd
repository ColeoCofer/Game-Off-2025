extends Control

## TimerUI - Displays the current level completion time in the top-right corner

@onready var time_label: Label = $TimeLabel

var is_running: bool = false
var current_time: float = 0.0
var total_pause_time: float = 0.0
var pause_start_time: float = 0.0
var is_paused: bool = false
var cutscene_start_time: float = 0.0
var is_in_cutscene: bool = false
var was_visible_before_cutscene: bool = false


func _ready() -> void:
	# Add to group for easy cleanup
	add_to_group("timer_ui")

	# Check if timer should be visible based on settings
	visible = SaveManager.get_show_timer()

	# Position in top-right corner with some padding
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -150  # Adjust based on label width
	offset_top = 10
	offset_right = -10
	offset_bottom = 50

	# Set process mode to always run even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Connect to CutsceneDirector signals to pause timer during cutscenes
	if CutsceneDirector:
		CutsceneDirector.cutscene_started.connect(_on_cutscene_started)
		CutsceneDirector.cutscene_finished.connect(_on_cutscene_finished)


func _process(delta: float) -> void:
	# Check for pause state changes
	_check_pause_state()

	if not is_running or not visible:
		return

	# Don't update display while paused or in cutscene
	if get_tree().paused or is_in_cutscene:
		return

	# Get time from SceneManager
	if SceneManager.current_level != "" and SceneManager.current_level_start_time > 0.0:
		# Calculate current time minus total pause time
		var raw_time = (Time.get_ticks_msec() / 1000.0) - SceneManager.current_level_start_time
		current_time = raw_time - total_pause_time
		_update_display()


func _check_pause_state() -> void:
	var is_game_paused = get_tree().paused

	if is_game_paused and not is_paused:
		# Game just paused - record pause start time
		is_paused = true
		pause_start_time = Time.get_ticks_msec() / 1000.0
	elif not is_game_paused and is_paused:
		# Game just unpaused - add to total pause time
		is_paused = false
		var pause_duration = (Time.get_ticks_msec() / 1000.0) - pause_start_time
		total_pause_time += pause_duration


func start_timer() -> void:
	is_running = true
	current_time = 0.0
	total_pause_time = 0.0
	pause_start_time = 0.0
	is_paused = false


func stop_timer() -> void:
	is_running = false

func get_current_time() -> float:
	"""Get the current timer value"""
	return current_time


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


func _on_cutscene_started(cutscene_id: String) -> void:
	"""Called when a cutscene starts - pause the timer and hide it"""
	if not is_in_cutscene:
		is_in_cutscene = true
		cutscene_start_time = Time.get_ticks_msec() / 1000.0

		# Remember if timer was visible before cutscene
		was_visible_before_cutscene = visible

		# Hide timer during cutscene
		visible = false


func _on_cutscene_finished(cutscene_id: String) -> void:
	"""Called when a cutscene ends - resume the timer and show it if it was visible before"""
	if is_in_cutscene:
		is_in_cutscene = false
		var cutscene_duration = (Time.get_ticks_msec() / 1000.0) - cutscene_start_time
		total_pause_time += cutscene_duration

		# Restore visibility only if it was visible before cutscene
		visible = was_visible_before_cutscene
