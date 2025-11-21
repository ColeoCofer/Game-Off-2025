extends Node

## SceneManager - Handles scene transitions and level progression
## This singleton manages loading levels, menus, and scene transitions

signal scene_changed(scene_path: String)
signal level_completed(level_name: String, completion_time: float)

# Scene paths
const MAIN_MENU_PATH = "res://UI/MainMenu.tscn"
const LEVEL_SELECT_PATH = "res://UI/LevelSelectMenu.tscn"

# Level configuration
# name - used for saving to track levels, and the main key for looking up level data
# display_name - what players will see in the menus (not implemented yet...)
# path - path to the actual file
# order - order of levels that the player plays them in
var levels: Array[Dictionary] = [
	{"name": "tutorial", "display_name": "Tutorial", "path": "res://Levels/level-tutorial.tscn", "order": 0},
	{"name": "level-1", "display_name": "Level 1", "path": "res://Levels/level-1.tscn", "order": 1},
	{"name": "level-2", "display_name": "Level 2", "path": "res://Levels/level-2.tscn", "order": 2},
	{"name": "level-3", "display_name": "Level 3", "path": "res://Levels/level-3.tscn", "order": 3},
	{"name": "level-4", "display_name": "Level 4", "path": "res://Levels/level-4.tscn", "order": 4},
]

var current_level: String = ""
var current_level_start_time: float = 0.0
var is_transitioning: bool = false

# Fade transition nodes
var fade_layer: CanvasLayer
var fade_rect: ColorRect

func _ready() -> void:
	# Create fade transition overlay
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 100  # Render on top of everything
	add_child(fade_layer)

	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 0.0
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(fade_rect)

	# Connect to scene changes to detect level reloads
	get_tree().node_added.connect(_on_node_added)


func _process(delta: float) -> void:
	# Track level playtime if in a level
	if current_level != "" and current_level_start_time > 0.0:
		SaveManager.save_data["game_data"]["total_playtime"] += delta


## Load a specific level by name
func load_level(level_name: String) -> void:
	if is_transitioning:
		return

	var level_info = get_level_info(level_name)
	if level_info == null:
		push_error("Level not found: " + level_name)
		return

	current_level = level_name
	reset_level_timer()

	# Start a new diamond collection run (clears temporary collected diamonds)
	DiamondCollectionManager.start_level_run(level_name)

	await _change_scene(level_info["path"])


## Load the next level in sequence
func next_level() -> void:
	if current_level == "":
		return

	var current_info = get_level_info(current_level)
	if current_info == null:
		return

	var next_order = current_info["order"] + 1
	for level in levels:
		if level["order"] == next_order:
			load_level(level["name"])
			return

	# No more levels, return to level select
	goto_level_select()


## Reload the current level (useful for death/restart)
func reload_current_level() -> void:
	if current_level == "":
		return

	# Reload by calling load_level with current level
	# This ensures DiamondCollectionManager.start_level_run() is called to clear temp collections
	load_level(current_level)


## Go to the main menu
func goto_main_menu() -> void:
	if is_transitioning:
		return

	current_level = ""
	current_level_start_time = 0.0
	await _change_scene(MAIN_MENU_PATH)


## Go to the level select screen
func goto_level_select() -> void:
	if is_transitioning:
		return

	current_level = ""
	current_level_start_time = 0.0
	await _change_scene(LEVEL_SELECT_PATH)


## Called when a level is completed
func complete_level(level_name: String = "") -> void:
	if level_name == "":
		level_name = current_level

	if level_name == "":
		print("SceneManager: complete_level called but no level_name!")
		return

	# Calculate completion time
	var completion_time = (Time.get_ticks_msec() / 1000.0) - current_level_start_time

	print("SceneManager: Level completed - ", level_name)
	print("SceneManager: Completion time - ", completion_time)
	print("SceneManager: Start time was - ", current_level_start_time)

	# Save best time
	SaveManager.save_best_time(level_name, completion_time)
	print("SceneManager: Best time saved")

	# Save collected diamonds permanently (only if level completed without dying)
	DiamondCollectionManager.commit_level_completion(level_name)

	# Unlock next level
	var current_info = get_level_info(level_name)
	if current_info != null:
		var next_order = current_info["order"] + 1
		for level in levels:
			if level["order"] == next_order:
				SaveManager.unlock_level(level["name"])
				break

	emit_signal("level_completed", level_name, completion_time)


## Get level information by name
func get_level_info(level_name: String) -> Dictionary:
	for level in levels:
		if level["name"] == level_name:
			return level
	return {}


## Get all levels in order
func get_all_levels() -> Array[Dictionary]:
	return levels


## Check if there's a next level available
func has_next_level() -> bool:
	if current_level == "":
		return false

	var current_info = get_level_info(current_level)
	if current_info == null:
		return false

	var next_order = current_info["order"] + 1
	for level in levels:
		if level["order"] == next_order:
			return true
	return false


## Internal scene change with fade transition
func _change_scene(scene_path: String) -> void:
	if is_transitioning:
		return

	is_transitioning = true

	# Fade out
	await _fade_to_black()

	# Change scene
	get_tree().paused = false  # Unpause in case we were paused
	var result = get_tree().change_scene_to_file(scene_path)
	if result != OK:
		push_error("Failed to load scene: " + scene_path)
		is_transitioning = false
		return

	emit_signal("scene_changed", scene_path)

	# Fade in
	await _fade_from_black()

	is_transitioning = false


## Fade transition to black
func _fade_to_black() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.3)
	await tween.finished


## Fade transition from black
func _fade_from_black() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.3)
	await tween.finished


## Reset the level timer (called on level start/restart)
func reset_level_timer() -> void:
	current_level_start_time = Time.get_ticks_msec() / 1000.0


## Detect when a level scene is reloaded (after death/restart)
func _on_node_added(node: Node) -> void:
	# Check if this is the root of a level scene being loaded
	if current_level != "" and node == get_tree().current_scene:
		# Check if we're in a level by looking for the level path
		var level_info = get_level_info(current_level)
		if level_info != null:
			var scene_path = node.scene_file_path
			if scene_path == level_info["path"]:
				# Level was reloaded, reset the timer
				reset_level_timer()
				# Clear temporary diamond collection (player died/restarted)
				DiamondCollectionManager.start_level_run(current_level)
