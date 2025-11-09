extends Control

signal play_again_pressed
signal next_level_pressed
signal level_select_pressed
signal exit_pressed

@export var fade_in_duration: float = 0.5
@export var fade_out_duration: float = 0.3

var title_label: Label
var subtitle_label: Label
var play_again_button: Button
var next_level_button: Button
var level_select_button: Button
var exit_button: Button
var current_button_index: int = 0
var is_success: bool = false
var button_count: int = 2

func _ready():
	# Start invisible
	modulate.a = 0.0
	visible = false

	# Get references to labels and buttons
	title_label = get_node("CenterContainer/VBoxContainer/TitleLabel")
	subtitle_label = get_node("CenterContainer/VBoxContainer/SubtitleLabel")
	play_again_button = get_node("CenterContainer/VBoxContainer/PlayAgainButton")
	next_level_button = get_node("CenterContainer/VBoxContainer/NextLevelButton")
	level_select_button = get_node("CenterContainer/VBoxContainer/LevelSelectButton")
	exit_button = get_node("CenterContainer/VBoxContainer/ExitButton")

func show_menu(death_reason: String = "starvation"):
	visible = true
	current_button_index = 0
	is_success = (death_reason == "success")

	# Death texts lmao
	match death_reason:
		"starvation":
			title_label.text = "YOU STARVED"
			subtitle_label.text = "The bat ran out of energy..."
		"fall":
			title_label.text = "YOU FELL"
			subtitle_label.text = "The bat plummeted into the void..."
		"success":
			title_label.text = "LEVEL COMPLETE!"
			title_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
			subtitle_label.text = "The bat found its way through the darkness!"
		_:
			title_label.text = "YOU DIED"
			subtitle_label.text = "The bat has perished..."

	# Show/hide buttons based on success or failure
	if is_success:
		play_again_button.visible = false
		next_level_button.visible = SceneManager.has_next_level()
		level_select_button.visible = true
		exit_button.visible = true

		if next_level_button.visible:
			button_count = 3
		else:
			button_count = 2
	else:
		play_again_button.visible = true
		next_level_button.visible = false
		level_select_button.visible = true
		exit_button.visible = true
		button_count = 3

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

	# Disable all cameras to prevent conflicts
	_disable_all_cameras()

	# Clear temporary firefly collection for this run (so they respawn)
	if SceneManager.current_level != "":
		FireflyCollectionManager.start_level_run(SceneManager.current_level)

	# Remove the canvas layer from root before reloading
	# (it won't be cleaned up automatically since it's attached to root, not the scene)
	var canvas_layer = get_parent()
	if canvas_layer:
		canvas_layer.queue_free()

	# Use call_deferred and reload_current_scene for more reliable scene reload
	get_tree().call_deferred("reload_current_scene")

func _on_next_level_button_pressed():
	next_level_pressed.emit()
	hide_menu()
	await get_tree().create_timer(fade_out_duration).timeout

	# Remove the canvas layer from root before changing scenes
	var canvas_layer = get_parent()
	if canvas_layer:
		canvas_layer.queue_free()

	# Use call_deferred to ensure the scene change happens after cleanup
	SceneManager.next_level.call_deferred()


func _on_level_select_button_pressed():
	level_select_pressed.emit()
	hide_menu()
	await get_tree().create_timer(fade_out_duration).timeout

	# Remove the canvas layer from root before changing scenes
	var canvas_layer = get_parent()
	if canvas_layer:
		canvas_layer.queue_free()

	# Use call_deferred to ensure the scene change happens after cleanup
	SceneManager.goto_level_select.call_deferred()


func _on_exit_button_pressed():
	exit_pressed.emit()
	# Return to main menu instead of quitting
	hide_menu()
	await get_tree().create_timer(fade_out_duration).timeout

	# Remove the canvas layer from root before changing scenes
	var canvas_layer = get_parent()
	if canvas_layer:
		canvas_layer.queue_free()

	# Use call_deferred to ensure the scene change happens after cleanup
	SceneManager.goto_main_menu.call_deferred()

func _input(event):
	# Only handle input when menu is visible
	if not visible or modulate.a < 0.9:
		return

	# Navigate between buttons with up/down or W/S
	if Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("down"):
		current_button_index = (current_button_index + 1) % button_count
		_update_button_focus()
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("up"):
		current_button_index = (current_button_index - 1 + button_count) % button_count
		_update_button_focus()
		get_viewport().set_input_as_handled()

	# Select button with space, enter, or controller A button
	elif Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
		_activate_current_button()
		get_viewport().set_input_as_handled()

func _update_button_focus():
	if is_success:
		# Success menu: Next Level (if available), Level Select, Exit
		if next_level_button.visible:
			match current_button_index:
				0: next_level_button.grab_focus()
				1: level_select_button.grab_focus()
				2: exit_button.grab_focus()
		else:
			# No next level available
			match current_button_index:
				0: level_select_button.grab_focus()
				1: exit_button.grab_focus()
	else:
		# Death menu: Play Again, Level Select, Exit
		match current_button_index:
			0: play_again_button.grab_focus()
			1: level_select_button.grab_focus()
			2: exit_button.grab_focus()


func _activate_current_button():
	if is_success:
		if next_level_button.visible:
			match current_button_index:
				0: _on_next_level_button_pressed()
				1: _on_level_select_button_pressed()
				2: _on_exit_button_pressed()
		else:
			match current_button_index:
				0: _on_level_select_button_pressed()
				1: _on_exit_button_pressed()
	else:
		match current_button_index:
			0: _on_play_again_button_pressed()
			1: _on_level_select_button_pressed()
			2: _on_exit_button_pressed()

func _disable_all_cameras():
	"""Disable all Camera2D nodes in the scene tree to prevent conflicts during scene transition"""
	for camera in get_tree().get_nodes_in_group("_camera2d"):
		if camera is Camera2D:
			camera.enabled = false
