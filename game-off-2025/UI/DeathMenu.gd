extends Control

signal play_again_pressed
signal exit_pressed

@export var fade_in_duration: float = 0.5
@export var fade_out_duration: float = 0.3

var title_label: Label
var subtitle_label: Label
var play_again_button: Button
var exit_button: Button
var current_button_index: int = 0

func _ready():
	# Start invisible
	modulate.a = 0.0
	visible = false

	# Get references to labels and buttons
	title_label = get_node("CenterContainer/VBoxContainer/TitleLabel")
	subtitle_label = get_node("CenterContainer/VBoxContainer/SubtitleLabel")
	play_again_button = get_node("CenterContainer/VBoxContainer/PlayAgainButton")
	exit_button = get_node("CenterContainer/VBoxContainer/ExitButton")

func show_menu(death_reason: String = "starvation"):
	visible = true
	current_button_index = 0

	# Death texts lmao
	match death_reason:
		"starvation":
			title_label.text = "YOU STARVED"
			subtitle_label.text = "The bat ran out of energy..."
		"fall":
			title_label.text = "YOU FELL"
			subtitle_label.text = "The bat plummeted into the void..."
		_:
			title_label.text = "YOU DIED"
			subtitle_label.text = "The bat has perished..."

	# Set initial button focus
	_update_button_focus()

	# Fade in the menu
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_in_duration)

func hide_menu():
	# Fade out the menu
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_out_duration)
	tween.finished.connect(func(): visible = false)

func _on_play_again_button_pressed():
	play_again_pressed.emit()
	# Hide menu then reload
	hide_menu()
	await get_tree().create_timer(fade_out_duration).timeout
	get_tree().reload_current_scene()

func _on_exit_button_pressed():
	exit_pressed.emit()
	# Quit the game
	get_tree().quit()

func _input(event):
	# Only handle input when menu is visible
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

func _update_button_focus():
	if current_button_index == 0:
		play_again_button.grab_focus()
	else:
		exit_button.grab_focus()

func _activate_current_button():
	if current_button_index == 0:
		_on_play_again_button_pressed()
	else:
		_on_exit_button_pressed()
