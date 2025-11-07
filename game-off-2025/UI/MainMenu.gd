extends Control

## MainMenu - The main entry point for the game

@onready var start_button: Button = get_node("CenterContainer/VBoxContainer/StartButton")
@onready var settings_button: Button = get_node("CenterContainer/VBoxContainer/SettingsButton")
@onready var quit_button: Button = get_node("CenterContainer/VBoxContainer/QuitButton")
@onready var settings_panel: Control = get_node("SettingsPanel")
@onready var volume_slider: HSlider = get_node("SettingsPanel/CenterContainer/Panel/MarginContainer/VBoxContainer/VolumeSlider")
@onready var close_settings_button: Button = get_node("SettingsPanel/CenterContainer/Panel/MarginContainer/VBoxContainer/CloseButton")


func _ready() -> void:
	# Signals are already connected in the scene file

	# Set up focus navigation for settings panel
	volume_slider.focus_neighbor_bottom = volume_slider.get_path_to(close_settings_button)
	close_settings_button.focus_neighbor_top = close_settings_button.get_path_to(volume_slider)

	# Load settings
	_load_settings()

	# Focus the start button
	start_button.grab_focus()


func _load_settings() -> void:
	volume_slider.value = SaveManager.save_data["settings"]["music_volume"]


func _on_start_pressed() -> void:
	SceneManager.goto_level_select()


func _on_settings_pressed() -> void:
	settings_panel.visible = true
	volume_slider.grab_focus()


func _on_close_settings_pressed() -> void:
	settings_panel.visible = false
	settings_button.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_volume_changed(value: float) -> void:
	SaveManager.save_data["settings"]["music_volume"] = value
	SaveManager.save_game()
	BackgroundMusic.set_volume(value)


func _input(event: InputEvent) -> void:
	# Close settings with Escape key
	if settings_panel.visible and event.is_action_pressed("ui_cancel"):
		_on_close_settings_pressed()
		get_viewport().set_input_as_handled()
