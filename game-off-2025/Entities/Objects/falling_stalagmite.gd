extends Node2D

## Falling stalagmite platform that triggers animation when player is nearby
## - Detects player within a specified distance
## - Triggers the stalagmite falling animation using AnimationPlayer
## - Only triggers once (doesn't reset)
## - AnimationPlayer can animate both the sprite AND collision shapes

@export var detection_distance: float = 100.0  ## Distance to detect player (pixels)
@export var one_time_trigger: bool = true  ## If true, only triggers once and doesn't reset
@export var animation_name: String = "fall"  ## Name of the animation to play

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

var has_triggered: bool = false

func _ready():
	# Set up the detection area
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)

	# Configure the detection shape based on the exported distance
	_update_detection_shape()

func _update_detection_shape():
	if detection_shape and detection_shape.shape is CircleShape2D:
		detection_shape.shape.radius = detection_distance

func _on_detection_area_body_entered(body: Node2D):
	# Check if it's the player and we haven't triggered yet (or can trigger multiple times)
	if body.is_in_group("Player") and (not has_triggered or not one_time_trigger):
		_trigger_fall()

func _on_detection_area_body_exited(body: Node2D):
	# Optional: Reset trigger if needed (when one_time_trigger is false)
	if not one_time_trigger and body.is_in_group("Player"):
		has_triggered = false

func _trigger_fall():
	if has_triggered and one_time_trigger:
		return

	has_triggered = true

	# Play the falling animation using AnimationPlayer
	if animation_player and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
