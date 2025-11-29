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
var music_volume_slider: HSlider
var music_volume_value_label: Label
var sounds_volume_slider: HSlider
var sounds_volume_value_label: Label
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
	music_volume_slider = get_node("CenterContainer/VBoxContainer/MusicVolumeContainer/MusicVolumeSlider")
	music_volume_value_label = get_node("CenterContainer/VBoxContainer/MusicVolumeContainer/MusicVolumeValueLabel")
	sounds_volume_slider = get_node("CenterContainer/VBoxContainer/SoundsVolumeContainer/SoundsVolumeSlider")
	sounds_volume_value_label = get_node("CenterContainer/VBoxContainer/SoundsVolumeContainer/SoundsVolumeValueLabel")

	# Load settings from SaveManager
	debug_toggle.button_pressed = SaveManager.get_debug_mode()
	timer_toggle.button_pressed = SaveManager.get_show_timer()
	music_volume_slider.value = SaveManager.get_music_volume()
	sounds_volume_slider.value = SaveManager.get_sounds_volume()
	_update_music_volume_label(SaveManager.get_music_volume())
	_update_sounds_volume_label(SaveManager.get_sounds_volume())

	# Sync with managers
	DebugManager.debug_mode = SaveManager.get_debug_mode()

	# Connect UI sound signals
	_connect_ui_sounds()

func _input(event):
	# Toggle pause menu when pause is pressed
	if Input.is_action_just_pressed("pause"):
		# Don't allow pausing if not in a level
		if SceneManager.current_level == "":
			return

		# Don't allow pausing during cutscenes
		if CutsceneDirector and CutsceneDirector.is_active():
			return

		# Check if CutscenePlayer is active
		var cutscene_player = get_tree().get_first_node_in_group("cutscene_player")
		if cutscene_player and cutscene_player.has_method("is_cutscene_active") and cutscene_player.is_cutscene_active():
			return

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
		current_button_index = (current_button_index + 1) % 6
		_update_button_focus()
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("up"):
		current_button_index = (current_button_index - 1 + 6) % 6
		_update_button_focus()
		get_viewport().set_input_as_handled()

	# Handle left/right for volume sliders
	elif Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("left"):
		if current_button_index == 4:  # Music volume slider
			music_volume_slider.value = max(music_volume_slider.min_value, music_volume_slider.value - 5.0)
			get_viewport().set_input_as_handled()
		elif current_button_index == 5:  # Sounds volume slider
			sounds_volume_slider.value = max(sounds_volume_slider.min_value, sounds_volume_slider.value - 5.0)
			get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("right"):
		if current_button_index == 4:  # Music volume slider
			music_volume_slider.value = min(music_volume_slider.max_value, music_volume_slider.value + 5.0)
			get_viewport().set_input_as_handled()
		elif current_button_index == 5:  # Sounds volume slider
			sounds_volume_slider.value = min(sounds_volume_slider.max_value, sounds_volume_slider.value + 5.0)
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
	music_volume_slider.value = SaveManager.get_music_volume()
	sounds_volume_slider.value = SaveManager.get_sounds_volume()

	# Pause the game
	get_tree().paused = true

	# Force cursor visible for menu navigation
	InputModeManager.set_force_cursor_visible(true)

	# Set initial button focus
	_update_button_focus()

	# Fade in the menu
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_in_duration)

func hide_menu():
	# Restore normal cursor behavior (hide if using controller)
	InputModeManager.set_force_cursor_visible(false)

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
	# Restore normal cursor behavior
	InputModeManager.set_force_cursor_visible(false)
	# Hide the menu immediately to prevent input bleed-through
	visible = false
	is_paused = false
	modulate.a = 0.0
	# Unpause before going to main menu
	get_tree().paused = false
	# Go to main menu
	SceneManager.goto_main_menu()

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
		music_volume_slider.grab_focus()
	elif current_button_index == 5:
		sounds_volume_slider.grab_focus()

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

func _on_music_volume_slider_value_changed(value: float):
	BackgroundMusic.set_volume(value)
	SaveManager.set_music_volume(value)
	_update_music_volume_label(value)

func _on_sounds_volume_slider_value_changed(value: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sounds"), value)
	SaveManager.set_sounds_volume(value)
	_update_sounds_volume_label(value)

func _update_music_volume_label(db_value: float):
	# Convert dB to percentage (rough approximation)
	# -40 dB = 0%, 0 dB = 100%
	var percentage = int(((db_value + 40.0) / 40.0) * 100.0)
	music_volume_value_label.text = str(percentage) + "%"

func _update_sounds_volume_label(db_value: float):
	# Convert dB to percentage (rough approximation)
	# -40 dB = 0%, 0 dB = 100%
	var percentage = int(((db_value + 40.0) / 40.0) * 100.0)
	sounds_volume_value_label.text = str(percentage) + "%"

func _on_timer_toggle_toggled(toggled_on: bool):
	SaveManager.set_show_timer(toggled_on)
	# Update timer visibility in the current level if it exists
	var timer_ui = get_tree().current_scene.find_child("TimerUI", true, false)
	if timer_ui:
		timer_ui.set_timer_visible(toggled_on)


func _connect_ui_sounds() -> void:
	# Connect hover sounds (focus/mouse enter)
	continue_button.focus_entered.connect(UISounds.play_hover)
	continue_button.mouse_entered.connect(UISounds.play_hover)
	exit_button.focus_entered.connect(UISounds.play_hover)
	exit_button.mouse_entered.connect(UISounds.play_hover)
	debug_toggle.focus_entered.connect(UISounds.play_hover)
	debug_toggle.mouse_entered.connect(UISounds.play_hover)
	timer_toggle.focus_entered.connect(UISounds.play_hover)
	timer_toggle.mouse_entered.connect(UISounds.play_hover)
	music_volume_slider.focus_entered.connect(UISounds.play_hover)
	music_volume_slider.mouse_entered.connect(UISounds.play_hover)
	sounds_volume_slider.focus_entered.connect(UISounds.play_hover)
	sounds_volume_slider.mouse_entered.connect(UISounds.play_hover)

	# Connect click sounds (pressed/toggled)
	continue_button.pressed.connect(UISounds.play_click)
	exit_button.pressed.connect(UISounds.play_click)
	debug_toggle.toggled.connect(func(_on): UISounds.play_click())
	timer_toggle.toggled.connect(func(_on): UISounds.play_click())
