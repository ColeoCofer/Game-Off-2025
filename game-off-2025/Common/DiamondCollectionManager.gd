extends Node

# DiamondCollectionManager - Handles diamond collection tracking and persistence
# Works with SaveManager to store collected diamonds
#
# Note that Diamonds are only permanently saved when the level is completed
# If the player dies, temporary collections are lost and diamonds respawn.

# Signal emitted when a diamond is collected
signal diamond_collected(level_name: String, diamond_id: int, total_collected: int, total_in_level: int)
signal all_diamonds_collected_in_level(level_name: String)

# Total diamonds per level (all levels have 3 diamonds)
const DIAMONDS_PER_LEVEL = 3

# Temporary collection tracking for current level run
var current_run_collected: Array = []
var current_run_level: String = ""

# Start a new level run - clears temporary collection
func start_level_run(level_name: String):
	current_run_level = level_name
	print("CLEARING diamond collection for level: %s (was: %s)" % [level_name, current_run_collected])
	current_run_collected.clear()
	print("Started new level run: %s, collection now: %s" % [level_name, current_run_collected])

# Collect a diamond
func collect_diamond(level_name: String, diamond_id: int):
	# Check if already collected in current run
	if diamond_id in current_run_collected:
		print("Diamond %d already collected in this run!" % diamond_id)
		return

	# Add to temporary collection for current run
	current_run_collected.append(diamond_id)

	# Get total count (permanent + temporary)
	var permanent_count = SaveManager.get_diamond_count(level_name)
	var temp_count = current_run_collected.size()
	var total_collected = permanent_count + temp_count

	# Emit collection signal
	diamond_collected.emit(level_name, diamond_id, total_collected, DIAMONDS_PER_LEVEL)

	print("Diamond %d collected in %s! (Run: %d/?, Total: %d/%d)" % [diamond_id, level_name, temp_count, total_collected, DIAMONDS_PER_LEVEL])

# Commit temporary collected diamonds to permanent storage (called on level completion)
func commit_level_completion(level_name: String):
	if current_run_collected.is_empty():
		print("No new diamonds to save for %s" % level_name)
		return

	# Save all temporarily collected diamonds permanently
	for diamond_id in current_run_collected:
		SaveManager.save_diamond(level_name, diamond_id)

	var count = current_run_collected.size()
	print("Saved %d diamonds permanently for %s!" % [count, level_name])

	# Clear temporary collection
	current_run_collected.clear()

# Check if a specific diamond has been permanently collected
func is_diamond_collected(level_name: String, diamond_id: int) -> bool:
	return SaveManager.is_diamond_collected(level_name, diamond_id)

# Check if a diamond was collected in the current run (temporary)
func is_diamond_collected_this_run(diamond_id: int) -> bool:
	var result = diamond_id in current_run_collected
	print("Checking diamond %d in run collection %s: %s" % [diamond_id, current_run_collected, result])
	return result

# Get array of collected diamond IDs for a level
func get_collected_diamonds(level_name: String) -> Array:
	return SaveManager.get_collected_diamonds(level_name)

# Get count of collected diamonds in a level
func get_diamond_count(level_name: String) -> int:
	return SaveManager.get_diamond_count(level_name)

# Check if all diamonds in a level are collected
func are_all_diamonds_collected(level_name: String) -> bool:
	return get_diamond_count(level_name) == DIAMONDS_PER_LEVEL

# Get total diamonds collected across all levels
func get_total_diamonds_collected() -> int:
	return SaveManager.get_total_diamonds_collected()

# Get total possible diamonds in the game (number of levels * diamonds per level)
func get_total_diamonds_in_game() -> int:
	var level_count = SceneManager.get_all_levels().size()
	return level_count * DIAMONDS_PER_LEVEL

# Get completion percentage for diamonds
func get_completion_percentage() -> float:
	var total_possible = get_total_diamonds_in_game()
	if total_possible == 0:
		return 0.0
	var total_collected = get_total_diamonds_collected()
	return (float(total_collected) / float(total_possible)) * 100.0

# Check if all diamonds in the entire game are collected
func is_game_100_percent_complete() -> bool:
	return get_total_diamonds_collected() == get_total_diamonds_in_game()
