# SaveManager Usage Examples
# This file shows how to use the SaveManager for various game data operations

extends Node

# Example 1: Save a checkpoint
func example_save_checkpoint():
	var checkpoint_data = {
		"position": Vector2(100, 200),
		"health": 75,
		"powerups": ["double_jump", "dash"]
	}
	SaveManager.save_checkpoint("level_1", checkpoint_data)

# Example 2: Load a checkpoint
func example_load_checkpoint():
	var checkpoint = SaveManager.get_checkpoint("level_1")
	if checkpoint.has("position"):
		print("Player position: ", checkpoint["position"])
		print("Player health: ", checkpoint["health"])
		print("Powerups: ", checkpoint["powerups"])

# Example 3: Save best time for a level
func example_save_best_time():
	var completion_time = 45.2  # seconds
	SaveManager.save_best_time("level_1", completion_time)

# Example 4: Get best time for a level
func example_get_best_time():
	var best_time = SaveManager.get_best_time("level_1")
	if best_time > 0:
		print("Best time: ", best_time, " seconds")
	else:
		print("No best time recorded yet")

# Example 5: Unlock a level
func example_unlock_level():
	SaveManager.unlock_level("level_2")

# Example 6: Check if level is unlocked
func example_check_level_unlocked():
	if SaveManager.is_level_unlocked("level_2"):
		print("Level 2 is unlocked!")
	else:
		print("Level 2 is locked")

# Example 7: Track playtime (call this in _process)
func _process(delta):
	SaveManager.add_playtime(delta)
	# Save playtime periodically (every 60 seconds)
	if int(SaveManager.get_total_playtime()) % 60 == 0:
		SaveManager.save_game()

# Example 8: Reset all save data (for debugging)
func example_reset_save():
	SaveManager.reset_save_data()
