extends Control

signal play_again_pressed
signal exit_pressed

@export var fade_in_duration: float = 0.5
@export var fade_out_duration: float = 0.3

var title_label: Label
var subtitle_label: Label

func _ready():
	# Start invisible
	modulate.a = 0.0
	visible = false

	# Get references to labels
	title_label = get_node("CenterContainer/VBoxContainer/TitleLabel")
	subtitle_label = get_node("CenterContainer/VBoxContainer/SubtitleLabel")

func show_menu(death_reason: String = "starvation"):
	visible = true

	# Set appropriate text based on death reason
	match death_reason:
		"starvation":
			title_label.text = "YOU STARVED"
			subtitle_label.text = "The bat ran out of energy..."
		"fall":
			title_label.text = "YOU FELL"
			subtitle_label.text = "The bat plummeted into the void..."
		_:
			title_label.text = "YOU DIED"
			subtitle_label.text = "The bat has perished..."

	# Fade in the menu
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_in_duration)

func hide_menu():
	# Fade out the menu
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_out_duration)
	tween.finished.connect(func(): visible = false)

func _on_play_again_button_pressed():
	play_again_pressed.emit()
	# Hide menu then reload
	hide_menu()
	await get_tree().create_timer(fade_out_duration).timeout
	get_tree().reload_current_scene()

func _on_exit_button_pressed():
	exit_pressed.emit()
	# Quit the game
	get_tree().quit()
