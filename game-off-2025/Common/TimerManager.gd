extends Node

## TimerManager - Manages the in-game timer UI display
## This autoload singleton ensures the timer appears in all levels

var timer_ui_scene = preload("res://UI/TimerUI.tscn")
var current_timer_ui: Control = null


func _ready() -> void:
	# Connect to scene changes to add timer to new levels
	get_tree().node_added.connect(_on_node_added)
	SceneManager.level_completed.connect(_on_level_completed)


func _on_node_added(node: Node) -> void:
	# Check if this is a level scene root being added
	if node == get_tree().current_scene and node.scene_file_path.begins_with("res://Levels/"):
		# Wait one frame for the level to finish loading
		await get_tree().process_frame
		_add_timer_to_current_level()


func _add_timer_to_current_level() -> void:
	# Remove existing timer if present
	if current_timer_ui:
		current_timer_ui.queue_free()
		current_timer_ui = null

	# Verify current scene exists
	var current_scene = get_tree().current_scene
	if not current_scene:
		push_warning("TimerManager: current_scene is null, cannot add timer")
		return

	# Find the EcholocationManager (CanvasLayer) or any CanvasLayer in the level
	var canvas_layer = _find_ui_layer()
	if not canvas_layer:
		# If no canvas layer found, create one
		canvas_layer = CanvasLayer.new()
		canvas_layer.layer = 50  # Above game elements but below menus
		current_scene.add_child(canvas_layer)

	# Instance the timer UI
	current_timer_ui = timer_ui_scene.instantiate()
	canvas_layer.add_child(current_timer_ui)

	# Start the timer
	if current_timer_ui.has_method("start_timer"):
		current_timer_ui.start_timer()


func _find_ui_layer() -> CanvasLayer:
	# Try to find EcholocationManager first
	var echolocation_manager = get_tree().get_first_node_in_group("echolocation_manager")
	if echolocation_manager and echolocation_manager is CanvasLayer:
		return echolocation_manager

	# Fall back to any CanvasLayer in the scene
	var root = get_tree().current_scene
	if root:
		for child in root.get_children():
			if child is CanvasLayer:
				return child

	return null


func _on_level_completed(level_name: String, completion_time: float) -> void:
	# Stop the timer when level is completed
	if current_timer_ui and current_timer_ui.has_method("stop_timer"):
		current_timer_ui.stop_timer()

func stop_timer() -> void:
	# Stop the timer when level is completed
	if current_timer_ui and current_timer_ui.has_method("stop_timer"):
		current_timer_ui.stop_timer()
		
