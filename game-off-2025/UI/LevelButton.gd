extends Button

## LevelButton - Individual level button in the level select menu

signal level_selected(level_name: String)

var level_name: String = ""
var is_unlocked: bool = false

@onready var level_label: Label = $VBoxContainer/LevelLabel
@onready var time_label: Label = $VBoxContainer/TimeContainer/TimeLabel
@onready var best_label: Label = $VBoxContainer/TimeContainer/BestLabel
@onready var time_container: HBoxContainer = $VBoxContainer/TimeContainer
@onready var diamond_label: Label = $VBoxContainer/DiamondLabel


func setup(p_level_name: String, display_name: String, p_is_unlocked: bool, best_time: float) -> void:
	level_name = p_level_name
	is_unlocked = p_is_unlocked

	# Set level name
	level_label.text = display_name

	# Set lock status
	if is_unlocked:
		disabled = false
	else:
		disabled = true

	# Set best time if available (hide for tutorial)
	if level_name == "tutorial":
		time_container.visible = false
	elif best_time > 0.0:
		var minutes = int(best_time / 60.0)
		var seconds = int(best_time) % 60
		var milliseconds = int((best_time - int(best_time)) * 100)
		time_label.text = "%d:%02d.%02d" % [minutes, seconds, milliseconds]
		time_container.visible = true
	else:
		time_label.text = "--:--:--"
		time_container.visible = true

	# Set diamond collection status
	_update_diamond_display()

	# Update visual style
	if not is_unlocked:
		modulate = Color(0.5, 0.5, 0.5, 0.7)


func _ready() -> void:
	pressed.connect(_on_pressed)

	# Connect UI sound signals
	focus_entered.connect(UISounds.play_hover)
	mouse_entered.connect(UISounds.play_hover)
	pressed.connect(UISounds.play_click)


func _update_diamond_display() -> void:
	# Hide diamond label for tutorial level (no diamonds to collect)
	if level_name == "tutorial":
		diamond_label.visible = false
		return

	# Get diamond collection data from DiamondCollectionManager
	var collected_diamonds = DiamondCollectionManager.get_collected_diamonds(level_name)
	var collected_count = collected_diamonds.size()

	# Update label text to show "Diamonds X/3"
	diamond_label.text = "Diamonds %d/3" % collected_count
	diamond_label.visible = true


func _on_pressed() -> void:
	if is_unlocked:
		emit_signal("level_selected", level_name)
