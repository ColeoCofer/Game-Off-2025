extends Node2D
class_name TutorialHint

## A tutorial hint that appears when the player approaches and disappears after being shown
##
## Usage:
## 1. Add this scene to your level
## 2. Set the hint_text in the inspector
## 3. Adjust trigger_radius for when the hint should appear
## 4. Position it where you want the text to display

@export var hint_text: String = "Tutorial Hint"
@export var trigger_radius: float = 100.0  ## How close player needs to be to trigger
@export var show_once: bool = true  ## If true, hint disappears permanently after being shown
@export var fade_in_duration: float = 0.3
@export var fade_out_duration: float = 0.3

@onready var label: Label = $CanvasLayer/Label
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var area: Area2D = $TriggerArea
@onready var collision_shape: CollisionShape2D = $TriggerArea/CollisionShape2D
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var player: CharacterBody2D = null
var has_been_shown: bool = false
var is_showing: bool = false
var fade_tween: Tween = null

func _ready():
	# Set up label with the hint text from inspector
	if label:
		label.text = hint_text
		label.modulate.a = 0.0  # Start invisible
		_update_label_position()
	else:
		push_error("TutorialHint: Label node not found!")

	# Set up trigger area radius
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = trigger_radius
	collision_shape.shape = circle_shape

	# Connect area signals
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _process(_delta):
	# Keep label positioned at hint's world position
	_update_label_position()

func _update_label_position():
	if label and is_inside_tree():
		# Get the camera to convert world position to screen position
		var camera = get_viewport().get_camera_2d()
		if camera:
			# Convert world position to screen coordinates
			var world_pos = global_position
			var screen_pos = world_pos - camera.get_screen_center_position() + get_viewport_rect().size / 2

			# Center the label on this position
			var label_size = label.size
			label.position = screen_pos - label_size / 2
		else:
			# Fallback if no camera (shouldn't happen in game)
			label.position = global_position

func _on_body_entered(body: Node2D):
	print("TutorialHint: Body entered - ", body.name, " Groups: ", body.get_groups())

	# Check if it's the player (case-insensitive check for "Player" group)
	var is_player = false
	for group in body.get_groups():
		if group.to_lower() == "player":
			is_player = true
			break

	if is_player or body.name == "Player":
		if show_once and has_been_shown:
			print("TutorialHint: Already shown, ignoring")
			return

		print("TutorialHint: Showing hint!")
		player = body
		show_hint()

func _on_body_exited(body: Node2D):
	if body == player:
		player = null
		hide_hint()

func show_hint():
	if is_showing:
		return

	is_showing = true
	has_been_shown = true

	print("TutorialHint: Showing hint with text: ", hint_text)
	print("TutorialHint: Label position: ", label.position if label else "NO LABEL")
	print("TutorialHint: Label modulate alpha before: ", label.modulate.a if label else "NO LABEL")

	# Play pop sound
	if audio_player and audio_player.stream:
		audio_player.play()

	# Fade in with tween
	if fade_tween:
		fade_tween.kill()

	fade_tween = create_tween()
	fade_tween.set_ease(Tween.EASE_OUT)
	fade_tween.set_trans(Tween.TRANS_BACK)
	fade_tween.tween_property(label, "modulate:a", 1.0, fade_in_duration)

	# Optional: Add a slight scale pop effect
	label.scale = Vector2(0.8, 0.8)
	fade_tween.parallel().tween_property(label, "scale", Vector2.ONE, fade_in_duration)

	print("TutorialHint: Tween started, target alpha: 1.0")

func hide_hint():
	if not is_showing:
		return

	is_showing = false

	# Fade out with tween
	if fade_tween:
		fade_tween.kill()

	fade_tween = create_tween()
	fade_tween.set_ease(Tween.EASE_IN)
	fade_tween.set_trans(Tween.TRANS_CUBIC)
	fade_tween.tween_property(label, "modulate:a", 0.0, fade_out_duration)

	# If show_once is true, hide the entire node after fading out
	if show_once:
		await fade_tween.finished
		visible = false
