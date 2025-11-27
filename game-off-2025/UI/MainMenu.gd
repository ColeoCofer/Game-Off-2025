extends Control

## MainMenu - The main entry point for the game

@onready var start_button: Button = get_node("ButtonContainer/StartButtonContainer/StartButton")
@onready var settings_button: Button = get_node("ButtonContainer/SettingsButtonContainer/SettingsButton")
@onready var quit_button: Button = get_node("QuitButtonContainer/QuitButton")
@onready var settings_panel: Control = get_node("SettingsPanel")
@onready var music_volume_slider: HSlider = get_node("SettingsPanel/CenterContainer/Panel/MarginContainer/VBoxContainer/MusicVolumeSlider")
@onready var sounds_volume_slider: HSlider = get_node("SettingsPanel/CenterContainer/Panel/MarginContainer/VBoxContainer/SoundsVolumeSlider")
@onready var timer_toggle: CheckButton = get_node("SettingsPanel/CenterContainer/Panel/MarginContainer/VBoxContainer/TimerToggle")
@onready var close_settings_button: Button = get_node("SettingsPanel/CenterContainer/Panel/MarginContainer/VBoxContainer/CloseButton")

# Track whether we're using keyboard/controller or mouse
var using_keyboard_nav: bool = false


func _ready() -> void:
	# Signals are already connected in the scene file

	# Set up focus navigation for settings panel
	music_volume_slider.focus_neighbor_bottom = music_volume_slider.get_path_to(sounds_volume_slider)
	sounds_volume_slider.focus_neighbor_top = sounds_volume_slider.get_path_to(music_volume_slider)
	sounds_volume_slider.focus_neighbor_bottom = sounds_volume_slider.get_path_to(timer_toggle)
	timer_toggle.focus_neighbor_top = timer_toggle.get_path_to(sounds_volume_slider)
	timer_toggle.focus_neighbor_bottom = timer_toggle.get_path_to(close_settings_button)
	close_settings_button.focus_neighbor_top = close_settings_button.get_path_to(timer_toggle)

	# Load settings
	_load_settings()

	# Ensure main music is playing (resumes after special songs like final cutscene)
	BackgroundMusic.resume_main_music()

	# Don't grab focus initially - wait for keyboard input
	# start_button.grab_focus()


func _load_settings() -> void:
	music_volume_slider.value = SaveManager.save_data["settings"]["music_volume"]
	sounds_volume_slider.value = SaveManager.save_data["settings"]["sounds_volume"]
	timer_toggle.button_pressed = SaveManager.get_show_timer()


func _on_start_pressed() -> void:
	SceneManager.goto_level_select()


func _on_settings_pressed() -> void:
	settings_panel.visible = true
	music_volume_slider.grab_focus()


func _on_close_settings_pressed() -> void:
	settings_panel.visible = false
	settings_button.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_music_volume_changed(value: float) -> void:
	SaveManager.save_data["settings"]["music_volume"] = value
	SaveManager.save_game()
	BackgroundMusic.set_volume(value)

func _on_sounds_volume_changed(value: float) -> void:
	SaveManager.save_data["settings"]["sounds_volume"] = value
	SaveManager.save_game()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sounds"), value)


func _on_timer_toggle_toggled(toggled_on: bool) -> void:
	SaveManager.set_show_timer(toggled_on)


func _input(event: InputEvent) -> void:
	# Detect mouse movement and disable keyboard navigation
	if event is InputEventMouseMotion:
		if using_keyboard_nav:
			using_keyboard_nav = false
			# Release focus from all buttons
			if get_viewport().gui_get_focus_owner():
				get_viewport().gui_get_focus_owner().release_focus()

	# Detect keyboard/controller input and enable navigation
	elif event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if not using_keyboard_nav and (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion):
			using_keyboard_nav = true
			# Grab focus on appropriate button based on which panel is visible
			if settings_panel.visible:
				if not get_viewport().gui_get_focus_owner():
					music_volume_slider.grab_focus()
			else:
				if not get_viewport().gui_get_focus_owner():
					start_button.grab_focus()

	# Close settings with Escape key
	if settings_panel.visible and event.is_action_pressed("ui_cancel"):

		_on_close_settings_pressed()
		get_viewport().set_input_as_handled()
