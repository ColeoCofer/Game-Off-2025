extends Control

signal continue_pressed
signal exit_pressed

@export var fade_in_duration: float = 0.3
@export var fade_out_duration: float = 0.2

var title_label: Label
var continue_button: Button
var exit_button: Button
var debug_toggle: CheckButton
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

	# Set debug toggle state from DebugManager
	debug_toggle.button_pressed = DebugManager.debug_mode

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
		current_button_index = (current_button_index + 1) % 2
		_update_button_focus()
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("up"):
		current_button_index = (current_button_index - 1) % 2
		_update_button_focus()
		get_viewport().set_input_as_handled()

	# Select button with space, enter, or controller A button
	elif Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
		_activate_current_button()
		get_viewport().set_input_as_handled()

func show_menu():
	visible = true
	is_paused = true
	current_button_index = 0

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
	else:
		exit_button.grab_focus()

func _activate_current_button():
	if current_button_index == 0:
		_on_continue_button_pressed()
	else:
		_on_exit_button_pressed()

func _on_debug_toggle_toggled(toggled_on: bool):
	DebugManager.debug_mode = toggled_on
	if DebugManager.debug_mode:
		print("DEBUG MODE ENABLED - Player is invincible")
	else:
		print("DEBUG MODE DISABLED - Player can die normally")
