extends Node
## TutorialManager autoload singleton
## Manages tutorial tooltips and tracks which ones have been shown

signal tutorial_shown(tutorial_id: String)
signal tutorial_dismissed(tutorial_id: String)

# Debug options
@export var force_show_tutorials: bool = false  ## Enable to always show tutorials (for testing)

# References
var tooltip_scene = preload("res://UI/Tooltip/tooltip.tscn")
var tooltip_instance: Control = null
var canvas_layer: CanvasLayer = null

# State
var active_tutorial_id: String = ""
var shown_tutorials: Array = []  # Track which tutorials have been shown this session

func _ready():
	# Create canvas layer for tooltip UI
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # Above most UI
	add_child(canvas_layer)

	# Connect to game events for automatic tutorials
	_setup_tutorial_triggers()

	print("TutorialManager: Ready")

func _setup_tutorial_triggers():
	"""Set up automatic tutorial triggers based on game events"""

	# Tutorial after first butterfly/firefly collection
	# We need to connect to the player's HungerManager since butterflies restore hunger
	# This will be done once the player is loaded in the scene
	await get_tree().create_timer(1.0).timeout
	_connect_to_player_hunger()

func show_tutorial(tutorial_id: String, message: String, input_hint: String = "[Press SPACE]", auto_dismiss: float = 0.0):
	"""Show a tutorial tooltip

	Args:
		tutorial_id: Unique identifier for this tutorial
		message: The tutorial message to display
		input_hint: Optional input hint text (default: "[Press SPACE]")
		auto_dismiss: Auto-dismiss after seconds (0 = manual only)
	"""

	# Check if this tutorial has already been shown this session (unless force flag is set)
	if not force_show_tutorials and tutorial_id in shown_tutorials:
		print("TutorialManager: Tutorial '", tutorial_id, "' already shown this session")
		return

	# Check if tooltip is already showing
	if tooltip_instance and is_instance_valid(tooltip_instance):
		print("TutorialManager: Tooltip already active, dismissing current one first")
		hide_tutorial()
		await get_tree().create_timer(0.5).timeout

	# Create tooltip instance
	tooltip_instance = tooltip_scene.instantiate()
	tooltip_instance.auto_dismiss_time = auto_dismiss
	canvas_layer.add_child(tooltip_instance)

	# Connect to dismissed signal
	tooltip_instance.tooltip_dismissed.connect(_on_tooltip_dismissed)

	# Show the tooltip
	active_tutorial_id = tutorial_id
	tooltip_instance.show_tooltip(message, input_hint)

	# Mark as shown
	shown_tutorials.append(tutorial_id)
	tutorial_shown.emit(tutorial_id)

	print("TutorialManager: Showing tutorial '", tutorial_id, "'")

func show_tutorial_once(tutorial_id: String, message: String, input_hint: String = "[Press SPACE]", auto_dismiss: float = 0.0):
	"""Show a tutorial tooltip only if it hasn't been shown before (persists across game sessions)

	Args:
		tutorial_id: Unique identifier for this tutorial
		message: The tutorial message to display
		input_hint: Optional input hint text
		auto_dismiss: Auto-dismiss after seconds (0 = manual only)
	"""

	# Check if tutorial has been shown in a previous session (unless force flag is set)
	if not force_show_tutorials and SaveManager.has_tutorial_shown(tutorial_id):
		print("TutorialManager: Tutorial '", tutorial_id, "' already shown previously (saved)")
		return

	# Show the tutorial
	show_tutorial(tutorial_id, message, input_hint, auto_dismiss)

	# Save that we've shown this tutorial
	SaveManager.mark_tutorial_shown(tutorial_id)

func hide_tutorial():
	"""Manually hide the current tooltip"""
	if tooltip_instance and is_instance_valid(tooltip_instance):
		tooltip_instance.hide_tooltip()

func _on_tooltip_dismissed():
	"""Called when tooltip is dismissed"""
	tutorial_dismissed.emit(active_tutorial_id)
	active_tutorial_id = ""

	# Clean up tooltip instance after a delay
	if tooltip_instance and is_instance_valid(tooltip_instance):
		await get_tree().create_timer(0.5).timeout
		if tooltip_instance and is_instance_valid(tooltip_instance):
			tooltip_instance.queue_free()
			tooltip_instance = null

func reset_session_tutorials():
	"""Reset the list of tutorials shown this session (for testing)"""
	shown_tutorials.clear()
	print("TutorialManager: Session tutorials reset")

func is_tutorial_active() -> bool:
	"""Check if a tutorial tooltip is currently showing"""
	return tooltip_instance != null and is_instance_valid(tooltip_instance) and tooltip_instance.is_visible

# ============= TUTORIAL EVENT CALLBACKS =============

func _connect_to_player_hunger():
	"""Connect to player's HungerManager to detect first food consumption"""
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		print("TutorialManager: Could not find player for tutorial triggers")
		return

	var hunger_manager = player.get_node_or_null("HungerManager")
	if not hunger_manager:
		print("TutorialManager: Could not find HungerManager")
		return

	if hunger_manager.has_signal("food_consumed"):
		hunger_manager.food_consumed.connect(_on_first_food_consumed)
		print("TutorialManager: Connected to HungerManager food_consumed signal")

func _on_first_food_consumed(_amount: float):
	"""Called when player consumes food (butterfly) - shows echolocation tutorial on first consumption"""

	# Wait a moment after collection before showing tutorial
	await get_tree().create_timer(1.0).timeout

	# Show the echolocation tutorial (only once ever)
	show_tutorial_once(
		"echolocation_tip",
		"Use echolocation to reveal your surroundings!",
		"[Press E to echolocate]",
		5.0  # Auto-dismiss after 5 seconds
	)
