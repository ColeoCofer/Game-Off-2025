extends Control

## MainMenu - The main entry point for the game

@onready var start_button: TextureButton = get_node("ButtonContainer/StartButtonContainer/StartButton")
@onready var settings_button: TextureButton = get_node("ButtonContainer/SettingsButtonContainer/SettingsButton")
@onready var quit_button: TextureButton = get_node("QuitButtonContainer/QuitButton")
@onready var selection_rect: Panel = get_node("SelectionRect")
@onready var settings_panel: Control = get_node("SettingsPanel")
@onready var music_volume_slider: HSlider = get_node("SettingsPanel/CenterContainer/Panel/MarginContainer/VBoxContainer/MusicVolumeSlider")
@onready var sounds_volume_slider: HSlider = get_node("SettingsPanel/CenterContainer/Panel/MarginContainer/VBoxContainer/SoundsVolumeSlider")
@onready var timer_toggle: CheckButton = get_node("SettingsPanel/CenterContainer/Panel/MarginContainer/VBoxContainer/TimerToggle")
@onready var close_settings_button: Button = get_node("SettingsPanel/CenterContainer/Panel/MarginContainer/VBoxContainer/CloseButton")

# Track whether we're using keyboard/controller or mouse
var using_keyboard_nav: bool = false


func _ready() -> void:
	# Signals are already connected in the scene file

	# Connect focus signals for main menu buttons
	start_button.focus_entered.connect(_on_button_focus_entered.bind(start_button))
	settings_button.focus_entered.connect(_on_button_focus_entered.bind(settings_button))
	quit_button.focus_entered.connect(_on_button_focus_entered.bind(quit_button))

	# Set up focus navigation for settings panel
	music_volume_slider.focus_neighbor_bottom = music_volume_slider.get_path_to(sounds_volume_slider)
	sounds_volume_slider.focus_neighbor_top = sounds_volume_slider.get_path_to(music_volume_slider)
	sounds_volume_slider.focus_neighbor_bottom = sounds_volume_slider.get_path_to(timer_toggle)
	timer_toggle.focus_neighbor_top = timer_toggle.get_path_to(sounds_volume_slider)
	timer_toggle.focus_neighbor_bottom = timer_toggle.get_path_to(close_settings_button)
	close_settings_button.focus_neighbor_top = close_settings_button.get_path_to(timer_toggle)

	# Load settings
	_load_settings()

	# Don't grab focus initially - wait for keyboard input
	# start_button.grab_focus()


func _load_settings() -> void:
	music_volume_slider.value = SaveManager.save_data["settings"]["music_volume"]
	sounds_volume_slider.value = SaveManager.save_data["settings"]["sounds_volume"]
	timer_toggle.button_pressed = SaveManager.get_show_timer()


func _on_button_focus_entered(button: Control) -> void:
	if using_keyboard_nav:
		selection_rect.visible = true
		# Position and size the selection rect to match the button
		var button_rect = button.get_global_rect()
		selection_rect.global_position = button_rect.position - Vector2(4, 4)
		selection_rect.size = button_rect.size + Vector2(8, 8)


func _on_start_pressed() -> void:
	SceneManager.goto_level_select()


func _on_settings_pressed() -> void:
	settings_panel.visible = true
	selection_rect.visible = false
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
			selection_rect.visible = false
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
