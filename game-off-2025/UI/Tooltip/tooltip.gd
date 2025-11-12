extends Control
## Tooltip/Tutorial UI
## Shows brief tutorial messages with input prompts

signal tooltip_dismissed

# UI References
@onready var panel: Panel = $Panel
@onready var message_label: Label = $Panel/MarginContainer/VBoxContainer/MessageLabel
@onready var input_label: Label = $Panel/MarginContainer/VBoxContainer/InputLabel

# Configuration
@export var auto_dismiss_time: float = 0.0  ## Auto-dismiss after seconds (0 = manual dismiss only)
@export var fade_duration: float = 0.3

# State
var is_visible: bool = false
var auto_dismiss_timer: float = 0.0

func _ready():
	# Start hidden
	visible = false
	modulate.a = 0.0

func show_tooltip(message: String, input_hint: String = ""):
	"""Display a tooltip with message and optional input hint"""
	message_label.text = message

	if input_hint.is_empty():
		input_label.visible = false
	else:
		input_label.text = input_hint
		input_label.visible = true

	# Fade in
	visible = true
	is_visible = true

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)

	# Set up auto-dismiss timer if configured
	if auto_dismiss_time > 0:
		auto_dismiss_timer = auto_dismiss_time

	print("Tooltip: Showing message: ", message)

func hide_tooltip():
	"""Hide the tooltip with fade out"""
	if not is_visible:
		return

	is_visible = false

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(func(): visible = false)

	tooltip_dismissed.emit()
	print("Tooltip: Hidden")

func _process(delta):
	if not is_visible:
		return

	# Handle auto-dismiss timer
	if auto_dismiss_time > 0:
		auto_dismiss_timer -= delta
		if auto_dismiss_timer <= 0:
			hide_tooltip()

	# Manual dismiss with any action button
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
		hide_tooltip()
