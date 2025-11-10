extends Control

signal continue_pressed
signal exit_pressed

@export var fade_in_duration: float = 0.3
@export var fade_out_duration: float = 0.2

var title_label: Label
var continue_button: Button
var exit_button: Button
var debug_toggle: CheckButton
var timer_toggle: CheckButton
var volume_slider: HSlider
var volume_value_label: Label
var current_button_index: int = 0
var is_paused: bool = false

func _ready():
	# Start invisible
	modulate.a = 0.0
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # Menu continues to process when game is paused

	# Get references to labels and buttons
	title_label = get_node("CenterContainer/VBoxContainer/TitleLabel")
	continue_button = get_node("CenterContainer/VBoxContainer/ContinueButton")
	exit_button = get_node("CenterContainer/VBoxContainer/ExitButton")
	debug_toggle = get_node("CenterContainer/VBoxContainer/DebugToggle")
	timer_toggle = get_node("CenterContainer/VBoxContainer/TimerToggle")
	volume_slider = get_node("CenterContainer/VBoxContainer/VolumeContainer/VolumeSlider")
	volume_value_label = get_node("CenterContainer/VBoxContainer/VolumeContainer/VolumeValueLabel")

	# Load settings from SaveManager
	debug_toggle.button_pressed = SaveManager.get_debug_mode()
	timer_toggle.button_pressed = SaveManager.get_show_timer()
	volume_slider.value = SaveManager.get_music_volume()
	_update_volume_label(SaveManager.get_music_volume())

	# Sync with managers
	DebugManager.debug_mode = SaveManager.get_debug_mode()

func _input(event):
	# Toggle pause menu when pause is pressed
	if Input.is_action_just_pressed("pause"):
		if is_paused:
			_on_continue_button_pressed()
		else:
			show_menu()
		get_viewport().set_input_as_handled()

	# Only handle other input when menu is visible
	if not visible or modulate.a < 0.9:
		return

	# Navigate between buttons with up/down or W/S
	if Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("down"):
		current_button_index = (current_button_index + 1) % 5
		_update_button_focus()
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("up"):
		current_button_index = (current_button_index - 1 + 5) % 5
		_update_button_focus()
		get_viewport().set_input_as_handled()

	# Handle left/right for volume slider
	elif Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("left"):
		if current_button_index == 4:  # Volume slider
			volume_slider.value = max(volume_slider.min_value, volume_slider.value - 5.0)
			get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("right"):
		if current_button_index == 4:  # Volume slider
			volume_slider.value = min(volume_slider.max_value, volume_slider.value + 5.0)
			get_viewport().set_input_as_handled()

	# Select button with space, enter, or controller A button
	elif Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
		_activate_current_button()
		get_viewport().set_input_as_handled()

func show_menu():
	visible = true
	is_paused = true
	current_button_index = 0

	debug_toggle.button_pressed = SaveManager.get_debug_mode()
	timer_toggle.button_pressed = SaveManager.get_show_timer()
	volume_slider.value = SaveManager.get_music_volume()
	
	# Pause the game
	get_tree().paused = true

	# Set initial button focus
	_update_button_focus()

	# Fade in the menu
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_in_duration)

func hide_menu():
	# Fade out the menu
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_out_duration)
	tween.finished.connect(func():
		visible = false
		is_paused = false
		get_tree().paused = false
	)

func _on_continue_button_pressed():
	continue_pressed.emit()
	hide_menu()

func _on_exit_button_pressed():
	exit_pressed.emit()
	# Unpause before quitting
	get_tree().paused = false
	# Quit the game
	get_tree().quit()

func _update_button_focus():
	if current_button_index == 0:
		continue_button.grab_focus()
	elif current_button_index == 1:
		exit_button.grab_focus()
	elif current_button_index == 2:
		debug_toggle.grab_focus()
	elif current_button_index == 3:
		timer_toggle.grab_focus()
	elif current_button_index == 4:
		volume_slider.grab_focus()

func _activate_current_button():
	if current_button_index == 0:
		_on_continue_button_pressed()
	elif current_button_index == 1:
		_on_exit_button_pressed()
	elif current_button_index == 2:
		# Toggle the debug checkbox
		debug_toggle.button_pressed = !debug_toggle.button_pressed
		_on_debug_toggle_toggled(debug_toggle.button_pressed)
	elif current_button_index == 3:
		# Toggle the timer checkbox
		timer_toggle.button_pressed = !timer_toggle.button_pressed
		_on_timer_toggle_toggled(timer_toggle.button_pressed)
	# No action needed for volume slider on activate

func _on_debug_toggle_toggled(toggled_on: bool):
	DebugManager.debug_mode = toggled_on
	SaveManager.set_debug_mode(toggled_on)
	if DebugManager.debug_mode:
		print("DEBUG MODE ENABLED - Player is invincible")
	else:
		print("DEBUG MODE DISABLED - Player can die normally")

func _on_volume_slider_value_changed(value: float):
	BackgroundMusic.set_volume(value)
	SaveManager.set_music_volume(value)
	_update_volume_label(value)

func _update_volume_label(db_value: float):
	# Convert dB to percentage (rough approximation)
	# -40 dB = 0%, 0 dB = 100%
	var percentage = int(((db_value + 40.0) / 40.0) * 100.0)
	volume_value_label.text = str(percentage) + "%"

func _on_timer_toggle_toggled(toggled_on: bool):
	SaveManager.set_show_timer(toggled_on)
	# Update timer visibility in the current level if it exists
	var timer_ui = get_tree().current_scene.find_child("TimerUI", true, false)
	if timer_ui:
		timer_ui.set_timer_visible(toggled_on)
