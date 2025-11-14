extends Node

# SaveManager - Handles all persistent data for the game
# Stores settings, game progress, checkpoints, best times, etc.

# Idk if this is the best place? 
const SAVE_FILE_PATH = "user://save_data.json"

# Default save data structure
var save_data = {
	"settings": {
		"music_volume": -10.0,  # in dB
		"debug_mode": false,
		"show_timer": false  # Timer display toggle
	},
	"game_data": {
		"checkpoints": {},
		"best_times": {},
		"unlocked_levels": [],
		"total_playtime": 0.0,
		"fireflies_collected": {},  # {"level-1": [0, 1, 2], "level-2": [0]}
		"cutscenes_played": [],  # Track which cutscenes have been viewed
		"tutorials_shown": []  # Track which tutorials have been displayed
	}
}

func _ready():
	load_game()
	# Ensure tutorial and level 1 are always unlocked by default
	if not is_level_unlocked("tutorial"):
		unlock_level("tutorial")
	if not is_level_unlocked("level-1"):
		unlock_level("level-1")

# Save all data to file
func save_game():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data, "\t")
		file.store_string(json_string)
		file.close()
		print("Game saved successfully to: ", SAVE_FILE_PATH)
	else:
		push_error("Failed to save game data")

# Load all data from file
func load_game():
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("No save file found, using default data")
		save_game()  # Create initial save file
		return

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_string)

		if parse_result == OK:
			var loaded_data = json.data
			# Merge loaded data with defaults to handle new fields
			_merge_data(save_data, loaded_data)
			print("Game loaded successfully from: ", SAVE_FILE_PATH)
		else:
			push_error("Failed to parse save file")
	else:
		push_error("Failed to open save file")

# Recursively merge loaded data with defaults
func _merge_data(default_dict: Dictionary, loaded_dict: Dictionary):
	for key in loaded_dict:
		if key in default_dict:
			if typeof(loaded_dict[key]) == TYPE_DICTIONARY and typeof(default_dict[key]) == TYPE_DICTIONARY:
				_merge_data(default_dict[key], loaded_dict[key])
			else:
				default_dict[key] = loaded_dict[key]

# ============= SETTINGS FUNCTIONS =============

func set_music_volume(volume_db: float):
	save_data["settings"]["music_volume"] = volume_db
	save_game()

func get_music_volume() -> float:
	return save_data["settings"]["music_volume"]

func set_debug_mode(enabled: bool):
	save_data["settings"]["debug_mode"] = enabled
	save_game()

func get_debug_mode() -> bool:
	return save_data["settings"]["debug_mode"]

func set_show_timer(enabled: bool):
	save_data["settings"]["show_timer"] = enabled
	save_game()

func get_show_timer() -> bool:
	return save_data["settings"]["show_timer"]

# ============= GAME DATA FUNCTIONS =============

func save_checkpoint(level_name: String, checkpoint_data: Dictionary):
	save_data["game_data"]["checkpoints"][level_name] = checkpoint_data
	save_game()

func get_checkpoint(level_name: String) -> Dictionary:
	if level_name in save_data["game_data"]["checkpoints"]:
		return save_data["game_data"]["checkpoints"][level_name]
	return {}

func save_best_time(level_name: String, time: float):
	if level_name not in save_data["game_data"]["best_times"] or time < save_data["game_data"]["best_times"][level_name]:
		save_data["game_data"]["best_times"][level_name] = time
		save_game()

func get_best_time(level_name: String) -> float:
	if level_name in save_data["game_data"]["best_times"]:
		return save_data["game_data"]["best_times"][level_name]
	return 0.0

func unlock_level(level_name: String):
	if level_name not in save_data["game_data"]["unlocked_levels"]:
		save_data["game_data"]["unlocked_levels"].append(level_name)
		save_game()

func is_level_unlocked(level_name: String) -> bool:
	return level_name in save_data["game_data"]["unlocked_levels"]

func add_playtime(delta_time: float):
	save_data["game_data"]["total_playtime"] += delta_time
	# Don't save on every frame - call save_game() periodically instead

func get_total_playtime() -> float:
	return save_data["game_data"]["total_playtime"]

# ============= FIREFLY COLLECTION FUNCTIONS =============

func save_firefly(level_name: String, firefly_id: int):
	# Initialize array for this level if it doesn't exist
	if level_name not in save_data["game_data"]["fireflies_collected"]:
		save_data["game_data"]["fireflies_collected"][level_name] = []

	# Add firefly ID if not already collected
	var collected_fireflies = save_data["game_data"]["fireflies_collected"][level_name]
	if firefly_id not in collected_fireflies:
		collected_fireflies.append(firefly_id)
		save_game()

func is_firefly_collected(level_name: String, firefly_id: int) -> bool:
	if level_name not in save_data["game_data"]["fireflies_collected"]:
		return false
	return firefly_id in save_data["game_data"]["fireflies_collected"][level_name]

func get_collected_fireflies(level_name: String) -> Array:
	if level_name in save_data["game_data"]["fireflies_collected"]:
		return save_data["game_data"]["fireflies_collected"][level_name]
	return []

func get_firefly_count(level_name: String) -> int:
	return get_collected_fireflies(level_name).size()

func get_total_fireflies_collected() -> int:
	var total = 0
	for level in save_data["game_data"]["fireflies_collected"]:
		total += save_data["game_data"]["fireflies_collected"][level].size()
	return total

# ============= CUTSCENE TRACKING FUNCTIONS =============

func mark_cutscene_played(cutscene_id: String):
	"""Mark a cutscene as having been played"""
	if cutscene_id not in save_data["game_data"]["cutscenes_played"]:
		save_data["game_data"]["cutscenes_played"].append(cutscene_id)
		save_game()
		print("SaveManager: Marked cutscene '", cutscene_id, "' as played")

func has_cutscene_played(cutscene_id: String) -> bool:
	"""Check if a cutscene has already been played"""
	return cutscene_id in save_data["game_data"]["cutscenes_played"]

# ============= TUTORIAL TRACKING FUNCTIONS =============

func mark_tutorial_shown(tutorial_id: String):
	"""Mark a tutorial as having been shown"""
	if tutorial_id not in save_data["game_data"]["tutorials_shown"]:
		save_data["game_data"]["tutorials_shown"].append(tutorial_id)
		save_game()
		print("SaveManager: Marked tutorial '", tutorial_id, "' as shown")

func has_tutorial_shown(tutorial_id: String) -> bool:
	"""Check if a tutorial has already been shown"""
	return tutorial_id in save_data["game_data"]["tutorials_shown"]

# Clear all save data (for debugging or new game)
func reset_save_data():
	save_data = {
		"settings": {
			"music_volume": -10.0,
			"debug_mode": false,
			"show_timer": false
		},
		"game_data": {
			"checkpoints": {},
			"best_times": {},
			"unlocked_levels": [],
			"total_playtime": 0.0,
			"fireflies_collected": {},
			"cutscenes_played": [],
			"tutorials_shown": []
		}
	}
	save_game()
	print("Save data reset to defaults")
