extends Control

signal play_again_pressed
signal next_level_pressed
signal exit_pressed

@export var fade_in_duration: float = 0.5
@export var fade_out_duration: float = 0.3

var title_label: Label
var subtitle_label: Label
var play_again_button: Button
var next_level_button: Button
var exit_button: Button
var current_button_index: int = 0
var is_success: bool = false
var button_count: int = 2

# Stats UI elements
var stats_panel: PanelContainer
var time_label: Label
var deaths_label: Label
var diamonds_label: Label

# Levels that should NOT show stats (tutorial, endscene, etc.)
const SKIP_STATS_LEVELS = ["tutorial"]

func _ready():
	# Start invisible
	modulate.a = 0.0
	visible = false

	# Get references to labels and buttons
	title_label = get_node("CenterContainer/VBoxContainer/TitleLabel")
	subtitle_label = get_node("CenterContainer/VBoxContainer/SubtitleLabel")
	play_again_button = get_node("CenterContainer/VBoxContainer/PlayAgainButton")
	next_level_button = get_node("CenterContainer/VBoxContainer/NextLevelButton")
	exit_button = get_node("CenterContainer/VBoxContainer/ExitButton")

	# Get references to stats UI elements
	stats_panel = get_node("CenterContainer/VBoxContainer/StatsPanel")
	time_label = get_node("CenterContainer/VBoxContainer/StatsPanel/StatsContainer/TimeLabel")
	deaths_label = get_node("CenterContainer/VBoxContainer/StatsPanel/StatsContainer/DeathsLabel")
	diamonds_label = get_node("CenterContainer/VBoxContainer/StatsPanel/StatsContainer/DiamondsLabel")

	# Connect UI sound signals
	_connect_ui_sounds()

func show_menu(death_reason: String = "starvation"):
	visible = true
	current_button_index = 0
	is_success = (death_reason == "success")

	# Death texts lmao
	match death_reason:
		"starvation":
			title_label.text = "YOU STARVED"
			subtitle_label.text = "Sona ran out of energy..."
			subtitle_label.visible = true
		"fall":
			title_label.text = "YOU FELL"
			subtitle_label.text = "Sona plummeted into the void..."
			subtitle_label.visible = true
		"success":
			title_label.text = "LEVEL COMPLETE!"
			title_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
			subtitle_label.visible = false
		_:
			title_label.text = "YOU DIED"
			subtitle_label.text = "Sona has perished..."
			subtitle_label.visible = true

	# Show stats on level completion (but not for tutorial or endscene)
	_update_stats_display()

	# Show/hide buttons based on success or failure
	if is_success:
		play_again_button.visible = false
		next_level_button.visible = SceneManager.has_next_level()
		exit_button.visible = true

		if next_level_button.visible:
			button_count = 2  # Next Level, Main Menu
		else:
			button_count = 1  # Main Menu only
	else:
		play_again_button.visible = true
		next_level_button.visible = false
		exit_button.visible = true
		button_count = 2  # Play Again, Main Menu

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

	# Disable all cameras to prevent conflicts during scene transition
	_disable_all_cameras()

	# Disable all firefly collisions to prevent them from re-collecting during transition
	_disable_all_fireflies()

	# Clear temporary firefly collection for this run (so they respawn)
	# We do this AFTER disabling fireflies to prevent race condition
	var level_name = SceneManager.current_level

	# If SceneManager doesn't know the current level (e.g., opened directly in editor),
	# try to extract it from the scene file path
	if level_name == "":
		var scene_path = get_tree().current_scene.scene_file_path
		# Extract level name from path like "res://Levels/level-3.tscn"
		if scene_path.contains("level-"):
			var filename = scene_path.get_file().get_basename()  # Gets "level-3" from "level-3.tscn"
			level_name = filename

	if level_name != "":
		DiamondCollectionManager.start_level_run(level_name)

	# Store reference to current scene before cleanup
	var current_scene = get_tree().current_scene

	# Remove the canvas layer from root before reloading
	# (it won't be cleaned up automatically since it's attached to root, not the scene)
	var canvas_layer = get_parent()
	if canvas_layer:
		canvas_layer.queue_free()

	# Ensure current_scene is still valid before reloading
	if current_scene:
		get_tree().call_deferred("reload_current_scene")
	else:
		# Fallback: reload using SceneManager if current_scene is null
		if level_name != "":
			SceneManager.load_level.call_deferred(level_name)

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
		# Success menu: Next Level (if available), Main Menu
		if next_level_button.visible:
			match current_button_index:
				0: next_level_button.grab_focus()
				1: exit_button.grab_focus()
		else:
			# No next level available - only Main Menu
			exit_button.grab_focus()
	else:
		# Death menu: Play Again, Main Menu
		match current_button_index:
			0: play_again_button.grab_focus()
			1: exit_button.grab_focus()


func _activate_current_button():
	if is_success:
		if next_level_button.visible:
			match current_button_index:
				0: _on_next_level_button_pressed()
				1: _on_exit_button_pressed()
		else:
			_on_exit_button_pressed()
	else:
		match current_button_index:
			0: _on_play_again_button_pressed()
			1: _on_exit_button_pressed()

func _disable_all_cameras():
	"""Disable all Camera2D nodes in the scene tree to prevent conflicts during scene transition"""
	for camera in get_tree().get_nodes_in_group("_camera2d"):
		if camera is Camera2D:
			camera.enabled = false

func _disable_all_fireflies():
	"""Disable all firefly collision areas to prevent re-collection during scene transition"""
	# Find all Area2D nodes that look like fireflies and disable their collision detection
	for node in get_tree().current_scene.find_children("*", "Area2D", true, false):
		# Check if this looks like a firefly (has the firefly_id export var)
		if "firefly_id" in node:
			node.monitoring = false
			node.monitorable = false


func _update_stats_display():
	"""Show stats on level completion for actual levels (not tutorial or endscene)"""
	var current_level = SceneManager.current_level

	# Only show stats on success and for real levels
	var should_show_stats = is_success and current_level != "" and current_level not in SKIP_STATS_LEVELS

	stats_panel.visible = should_show_stats

	if should_show_stats:
		# Get completion time from TimerManager
		var completion_time = TimerManager.get_completion_time()
		time_label.text = "Time: " + _format_time(completion_time)

		# Get death count from SceneManager
		var death_count = SceneManager.get_death_count()
		deaths_label.text = "Deaths: " + str(death_count)

		# Get diamonds collected this run
		# The diamonds are committed to permanent storage when level completes,
		# so we need to get the count from what was just saved for this level
		var diamonds_collected = DiamondCollectionManager.get_diamond_count(current_level)
		diamonds_label.text = "Diamonds: " + str(diamonds_collected) + "/3"


func _format_time(time_seconds: float) -> String:
	"""Format time as MM:SS.mm"""
	var minutes = int(time_seconds) / 60
	var seconds = int(time_seconds) % 60
	var milliseconds = int((time_seconds - int(time_seconds)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]


func _connect_ui_sounds() -> void:
	# Connect hover sounds (focus/mouse enter)
	play_again_button.focus_entered.connect(UISounds.play_hover)
	play_again_button.mouse_entered.connect(UISounds.play_hover)
	next_level_button.focus_entered.connect(UISounds.play_hover)
	next_level_button.mouse_entered.connect(UISounds.play_hover)
	exit_button.focus_entered.connect(UISounds.play_hover)
	exit_button.mouse_entered.connect(UISounds.play_hover)

	# Connect click sounds (pressed)
	play_again_button.pressed.connect(UISounds.play_click)
	next_level_button.pressed.connect(UISounds.play_click)
	exit_button.pressed.connect(UISounds.play_click)
