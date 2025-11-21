extends Control

## LevelSelectMenu - Shows available levels with progression tbracking

@onready var level_grid: GridContainer = get_node("MarginContainer/VBoxContainer/CenterContainer/LevelGrid")
@onready var back_button: Button = get_node("MarginContainer/VBoxContainer/BackButton")

# Level button scene (we'll create this dynamically)
const LEVEL_BUTTON_SCENE = preload("res://UI/LevelButton.tscn")


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_populate_level_grid()

	# Focus first unlocked level
	await get_tree().process_frame
	_focus_first_unlocked()


func _populate_level_grid() -> void:
	# Clear existing buttons
	for child in level_grid.get_children():
		child.queue_free()

	# Get all levels from SceneManager sorted by order
	var all_levels = SceneManager.get_all_levels()
	all_levels.sort_custom(func(a, b): return a["order"] < b["order"])

	# Create level buttons in order
	for level_info in all_levels:
		var level_button = LEVEL_BUTTON_SCENE.instantiate()
		level_grid.add_child(level_button)

		# Button setup stuff
		level_button.setup(
			level_info["name"],
			level_info["display_name"],
			SaveManager.is_level_unlocked(level_info["name"]),
			SaveManager.get_best_time(level_info["name"])
		)

		# Connect the button
		level_button.level_selected.connect(_on_level_selected)


func _focus_first_unlocked() -> void:
	for child in level_grid.get_children():
		if child.is_unlocked:
			child.grab_focus()
			break


func _on_level_selected(level_name: String) -> void:
	SceneManager.load_level(level_name)


func _on_back_pressed() -> void:
	SceneManager.goto_main_menu()
