extends Node

# FireflyCollectionManager - Handles firefly collection tracking and persistence
# Works with SaveManager to store collected fireflies

# Signal emitted when a firefly is collected
signal firefly_collected(level_name: String, firefly_id: int, total_collected: int, total_in_level: int)
signal all_fireflies_collected_in_level(level_name: String)

# Total fireflies per level (all levels have 3 fireflies)
const FIREFLIES_PER_LEVEL = 3

# Collect a firefly and save to persistent storage
func collect_firefly(level_name: String, firefly_id: int):
	# Check if already collected (shouldn't happen, but safety check)
	if SaveManager.is_firefly_collected(level_name, firefly_id):
		print("Firefly %d in %s already collected!" % [firefly_id, level_name])
		return

	# Save to persistent storage
	SaveManager.save_firefly(level_name, firefly_id)

	# Get updated count
	var total_collected = SaveManager.get_firefly_count(level_name)

	# Emit collection signal
	firefly_collected.emit(level_name, firefly_id, total_collected, FIREFLIES_PER_LEVEL)

	# Check if all fireflies in this level are collected
	if total_collected == FIREFLIES_PER_LEVEL:
		all_fireflies_collected_in_level.emit(level_name)
		print("All fireflies collected in %s! (%d/%d)" % [level_name, total_collected, FIREFLIES_PER_LEVEL])
	else:
		print("Firefly %d collected in %s! (%d/%d)" % [firefly_id, level_name, total_collected, FIREFLIES_PER_LEVEL])

# Check if a specific firefly has been collected
func is_firefly_collected(level_name: String, firefly_id: int) -> bool:
	return SaveManager.is_firefly_collected(level_name, firefly_id)

# Get array of collected firefly IDs for a level
func get_collected_fireflies(level_name: String) -> Array:
	return SaveManager.get_collected_fireflies(level_name)

# Get count of collected fireflies in a level
func get_firefly_count(level_name: String) -> int:
	return SaveManager.get_firefly_count(level_name)

# Check if all fireflies in a level are collected
func are_all_fireflies_collected(level_name: String) -> bool:
	return get_firefly_count(level_name) == FIREFLIES_PER_LEVEL

# Get total fireflies collected across all levels
func get_total_fireflies_collected() -> int:
	return SaveManager.get_total_fireflies_collected()

# Get total possible fireflies in the game (number of levels * fireflies per level)
func get_total_fireflies_in_game() -> int:
	var level_count = SceneManager.get_all_levels().size()
	return level_count * FIREFLIES_PER_LEVEL

# Get completion percentage for fireflies
func get_completion_percentage() -> float:
	var total_possible = get_total_fireflies_in_game()
	if total_possible == 0:
		return 0.0
	var total_collected = get_total_fireflies_collected()
	return (float(total_collected) / float(total_possible)) * 100.0

# Check if all fireflies in the entire game are collected
func is_game_100_percent_complete() -> bool:
	return get_total_fireflies_collected() == get_total_fireflies_in_game()
