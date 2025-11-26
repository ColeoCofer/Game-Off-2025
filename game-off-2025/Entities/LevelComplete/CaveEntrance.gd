extends Node2D

signal level_completed

## Configuration
@export var walk_duration: float = 1.5  # How long player walks toward entrance
@export var scale_duration: float = 1.2  # How long the scale/fade effect takes
@export var fade_to_black_duration: float = 0.8  # Screen fade duration
@export var min_player_scale: float = 0.25  # Final scale (simulates depth)
@export var depth_offset: float = 20.0  # How far "back" into the cave to walk (Y offset)

## Testing
@export var force_final_cutscene: bool = false  ## Force transition to level-end for testing (ignores save data check)

## Final level constants
const FINAL_LEVEL = "level-3"
const FINAL_CUTSCENE_ID = "game_complete"
const LEVEL_END_PATH = "res://Levels/level-end.tscn"

## Child nodes (automatically found)
var trigger_area: Area2D  # Area2D that detects player entry
var entrance_sprite: Sprite2D  # Your cave entrance art

var is_animating: bool = false
var player_ref: CharacterBody2D = null
var fade_canvas_layer: CanvasLayer = null

func _ready():
	# Find child nodes
	trigger_area = get_node_or_null("TriggerArea")
	entrance_sprite = get_node_or_null("EntranceSprite")

	if trigger_area:
		# Only connect if not already connected (might be connected in scene editor)
		if not trigger_area.body_entered.is_connected(_on_trigger_entered):
			trigger_area.body_entered.connect(_on_trigger_entered)
	else:
		push_error("CaveEntrance: TriggerArea child node not found!")

func _on_trigger_entered(body: Node2D):
	if body.is_in_group("Player") and not is_animating:
		print("Player entered cave entrance - starting sequence")
		is_animating = true
		player_ref = body

		# CRITICAL: Immediately stop hunger depletion and timer to prevent death during animation
		_stop_hunger_and_timer()

		_start_entrance_sequence()

func _stop_hunger_and_timer():
	"""Stop hunger depletion and timer as soon as player enters"""
	# Stop the timer immediately
	TimerManager.stop_timer()

	# Stop hunger depletion to prevent death during animation
	if player_ref:
		var hunger_manager = player_ref.get_node_or_null("HungerManager")
		if hunger_manager and hunger_manager.has_method("set_depletion_active"):
			hunger_manager.set_depletion_active(false)
			print("Cave entrance: Stopped hunger depletion")

			# Stop the heartbeat sound if it's playing
			if hunger_manager.has_method("stop_heartbeat"):
				hunger_manager.stop_heartbeat()
				print("Cave entrance: Stopped heartbeat sound")

		# Mark the death manager as if player is already "dead" to prevent any death triggers
		var death_manager = player_ref.get_node_or_null("DeathManager")
		if death_manager:
			death_manager.is_dead = true
			print("Cave entrance: Disabled death triggers")

func _start_entrance_sequence():
	"""Main entrance animation sequence"""
	if not player_ref:
		return

	# Disable player control
	player_ref.set_physics_process(false)

	# Get the animated sprite from the player
	var player_sprite = player_ref.get_node_or_null("AnimatedSprite2D")
	if not player_sprite:
		push_warning("Could not find player AnimatedSprite2D")
		_complete_transition()
		return

	# Calculate target position - center of trigger area (X only, keep player on ground)
	var target_position = Vector2(
		trigger_area.global_position.x,
		player_ref.global_position.y  # Keep player at their current Y position (on ground)
	)

	var start_position = player_ref.global_position

	# Store original values
	var original_scale = player_ref.scale
	var original_modulate = player_sprite.modulate

	# Phase 1: Walk player to entrance point
	var walk_tween = create_tween()
	walk_tween.set_parallel(false)

	# Move player to entrance
	walk_tween.tween_property(player_ref, "global_position", target_position, walk_duration)
	walk_tween.tween_callback(_start_depth_effect.bind(player_sprite, original_scale, original_modulate))

	await walk_tween.finished

func _start_depth_effect(player_sprite: AnimatedSprite2D, original_scale: Vector2, original_modulate: Color):
	"""Phase 2: Scale down and fade out to simulate walking into distance"""

	var depth_tween = create_tween()
	depth_tween.set_parallel(true)

	# Scale down (simulate walking into distance)
	depth_tween.tween_property(player_ref, "scale", original_scale * min_player_scale, scale_duration)

	# Fade out player
	var target_modulate = Color(original_modulate.r, original_modulate.g, original_modulate.b, 0.0)
	depth_tween.tween_property(player_sprite, "modulate", target_modulate, scale_duration)

	await depth_tween.finished

	# Phase 3: Fade screen to black and transition
	_fade_to_black_and_transition()

func _fade_to_black_and_transition():
	"""Phase 3: Create screen fade and trigger level completion"""

	# Create fade overlay
	var fade_overlay = ColorRect.new()
	fade_overlay.color = Color(0, 0, 0, 0)  # Start transparent
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Make it cover the entire screen
	fade_canvas_layer = CanvasLayer.new()
	fade_canvas_layer.layer = 200  # Very high layer to be on top of everything
	get_tree().root.add_child(fade_canvas_layer)
	fade_canvas_layer.add_child(fade_overlay)

	# Set to cover viewport
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.size = get_viewport().get_visible_rect().size

	# Fade to black
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), fade_to_black_duration)

	await fade_tween.finished

	# Trigger level completion
	_complete_transition()

func _complete_transition():
	"""Complete the level transition"""
	# Check if this is the final level and first time completing the game
	if _is_first_game_completion():
		_trigger_final_cutscene()
	else:
		# Show the completion menu
		_show_completion_menu()

	# Emit signal
	level_completed.emit()


func _is_first_game_completion() -> bool:
	"""Check if this is the first time completing the final level"""
	# Allow forcing for testing purposes
	if force_final_cutscene:
		print("CaveEntrance: force_final_cutscene is enabled, skipping normal checks")
		return true

	var current_level = SceneManager.current_level

	# If SceneManager doesn't know the level, try to extract from scene path
	if current_level == "":
		var scene_path = get_tree().current_scene.scene_file_path
		if scene_path.contains("level-"):
			current_level = scene_path.get_file().get_basename()

	# Check if we're on the final level and haven't seen the ending yet
	return current_level == FINAL_LEVEL and not SaveManager.has_cutscene_played(FINAL_CUTSCENE_ID)


func _trigger_final_cutscene():
	"""Transition to the final cutscene/ending sequence"""
	print("CaveEntrance: First time completing the game! Triggering final cutscene...")

	# Remove the fade overlay before transitioning
	if fade_canvas_layer:
		fade_canvas_layer.queue_free()
		fade_canvas_layer = null

	# Complete the level (save time, unlock next, etc.)
	SceneManager.complete_level()

	# Mark the final cutscene as played so it won't trigger again
	SaveManager.mark_cutscene_played(FINAL_CUTSCENE_ID)

	# Transition to the ending scene
	get_tree().change_scene_to_file(LEVEL_END_PATH)

func _show_completion_menu():
	"""Show the completion menu (reusing death menu)"""
	# Remove the fade overlay so menu is visible
	if fade_canvas_layer:
		fade_canvas_layer.queue_free()
		fade_canvas_layer = null

	# Notify SceneManager of level completion
	SceneManager.complete_level()

	# Find or create the death menu (we'll reuse it for completion)
	var death_menu = get_tree().get_first_node_in_group("DeathMenu")

	if not death_menu:
		# If menu doesn't exist in the scene, we need to add it
		var canvas_layer = get_tree().get_first_node_in_group("UI_Layer")
		if not canvas_layer:
			# Create a canvas layer if it doesn't exist
			canvas_layer = CanvasLayer.new()
			canvas_layer.add_to_group("UI_Layer")
			canvas_layer.layer = 100  # Make sure it's on top
			get_tree().root.add_child(canvas_layer)

		# Load and instance the death menu
		var death_menu_scene = load("res://UI/death_menu.tscn")
		death_menu = death_menu_scene.instantiate()
		death_menu.add_to_group("DeathMenu")
		canvas_layer.add_child(death_menu)

	if death_menu.has_method("show_menu"):
		death_menu.show_menu("success")
