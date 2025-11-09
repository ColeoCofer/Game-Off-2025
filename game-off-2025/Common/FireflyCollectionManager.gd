extends Node

# FireflyCollectionManager - Handles firefly collection tracking and persistence
# Works with SaveManager to store collected fireflies
#
# Note that Fireflies are only permanently saved when the level is completed
# If the player dies, temporary collections are lost and fireflies respawn.

# Signal emitted when a firefly is collected
signal firefly_collected(level_name: String, firefly_id: int, total_collected: int, total_in_level: int)
signal all_fireflies_collected_in_level(level_name: String)

# Total fireflies per level (all levels have 3 fireflies)
const FIREFLIES_PER_LEVEL = 3

# Temporary collection tracking for current level run
var current_run_collected: Array = []
var current_run_level: String = ""

# Start a new level run - clears temporary collection
func start_level_run(level_name: String):
	current_run_level = level_name
	current_run_collected.clear()
	print("Started new level run: %s" % level_name)

# Collect/eat a firefly
func collect_firefly(level_name: String, firefly_id: int):
	# Check if already collected in current run
	if firefly_id in current_run_collected:
		print("Firefly %d already collected in this run!" % firefly_id)
		return

	# Add to temporary collection for current run
	current_run_collected.append(firefly_id)

	# Get total count (permanent + temporary)
	var permanent_count = SaveManager.get_firefly_count(level_name)
	var temp_count = current_run_collected.size()
	var total_collected = permanent_count + temp_count

	# Emit collection signal
	firefly_collected.emit(level_name, firefly_id, total_collected, FIREFLIES_PER_LEVEL)

	print("Firefly %d collected in %s! (Run: %d/?, Total: %d/%d)" % [firefly_id, level_name, temp_count, total_collected, FIREFLIES_PER_LEVEL])

# Commit temporary collected fireflies to permanent storage (called on level completion)
func commit_level_completion(level_name: String):
	if current_run_collected.is_empty():
		print("No new fireflies to save for %s" % level_name)
		return

	# Save all temporarily collected fireflies permanently
	for firefly_id in current_run_collected:
		SaveManager.save_firefly(level_name, firefly_id)

	var count = current_run_collected.size()
	print("Saved %d fireflies permanently for %s!" % [count, level_name])

	# Clear temporary collection
	current_run_collected.clear()

# Check if a specific firefly has been permanently collected
func is_firefly_collected(level_name: String, firefly_id: int) -> bool:
	return SaveManager.is_firefly_collected(level_name, firefly_id)

# Check if a firefly was collected in the current run (temporary)
func is_firefly_collected_this_run(firefly_id: int) -> bool:
	return firefly_id in current_run_collected

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
