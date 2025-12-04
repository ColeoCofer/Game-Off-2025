extends Node

# GameModeManager - Handles game mode selection (Regular vs Simple)
# Regular: Classic mode with passive hunger drain
# Simple: No passive hunger drain, reduced energy capacity (~3 echolocation charges)

signal game_mode_changed(mode: GameMode)

enum GameMode {
	REGULAR,
	SIMPLE
}

# Current game mode
var current_mode: GameMode = GameMode.REGULAR  # Default to Simple for now (toggle later)

# Mode-specific configurations
const MODE_CONFIG = {
	GameMode.REGULAR: {
		"max_hunger": 100.0,
		"passive_drain": true,
		"depletion_rate": 3.5,
		"hunger_cost_percentage": 15.0  # ~6 charges at full
	},
	GameMode.SIMPLE: {
		"max_hunger": 100.0,  # Keep same max for UI consistency
		"passive_drain": false,
		"depletion_rate": 0.0,
		"hunger_cost_percentage": 30.0  # ~3 charges at full (100 / 30 ≈ 3.3 uses)
	}
}

func _ready():
	# Not saving/loading game mode for now - just use the default value
	print("GameModeManager: Using default game mode: ", get_mode_name())
	pass

func set_game_mode(mode: GameMode):
	if current_mode != mode:
		current_mode = mode
		game_mode_changed.emit(mode)
		print("GameModeManager: Game mode changed to ", get_mode_name())

func get_game_mode() -> GameMode:
	return current_mode

func get_mode_name() -> String:
	match current_mode:
		GameMode.REGULAR:
			return "Regular"
		GameMode.SIMPLE:
			return "Simple"
	return "Unknown"

func get_config() -> Dictionary:
	return MODE_CONFIG[current_mode]

func is_simple_mode() -> bool:
	return current_mode == GameMode.SIMPLE

func is_regular_mode() -> bool:
	return current_mode == GameMode.REGULAR

# Toggle between modes
func toggle_mode():
	if current_mode == GameMode.REGULAR:
		set_game_mode(GameMode.SIMPLE)
	else:
		set_game_mode(GameMode.REGULAR)

# Save/load functions commented out for testing - uncomment when ready to persist
#func _save_game_mode():
#	if SaveManager:
#		SaveManager.save_data["settings"]["game_mode"] = current_mode
#		SaveManager.save_game()
#
#func _load_game_mode():
#	if SaveManager and "game_mode" in SaveManager.save_data["settings"]:
#		current_mode = SaveManager.save_data["settings"]["game_mode"]
#		print("GameModeManager: Loaded game mode: ", get_mode_name())
