extends Area2D
## Cutscene trigger for starting in-level cutscene sequences
## Place in levels to trigger cutscenes when player enters the area

# Signals
signal cutscene_triggered(cutscene_id: String)

# Export variables
@export var cutscene_id: String = "default_cutscene"  ## Unique ID for this cutscene
@export var trigger_once: bool = true  ## Only trigger the first time
@export var auto_start: bool = false  ## Trigger immediately on level start
@export var disable_player_control: bool = true  ## Disable player movement during cutscene

# State
var has_triggered: bool = false

func _ready():
	# Set up collision detection for player (layer 3)
	collision_mask = 4  # Binary 100 = layer 3

	# Auto-start if configured
	if auto_start:
		await get_tree().create_timer(0.1).timeout  # Small delay for level setup
		_trigger_cutscene()

func _on_body_entered(body: Node2D) -> void:
	"""Called when something enters the trigger area"""
	# Check if it's the player (by group)
	if not body.is_in_group("Player"):
		return

	# Check if already triggered
	if has_triggered and trigger_once:
		return

	_trigger_cutscene()

func _trigger_cutscene() -> void:
	"""Trigger the cutscene"""
	has_triggered = true

	print("CutsceneTrigger: Triggering cutscene '%s'" % cutscene_id)
	cutscene_triggered.emit(cutscene_id)

	# Optionally disable this trigger
	if trigger_once:
		set_deferred("monitoring", false)

func reset() -> void:
	"""Reset the trigger so it can be activated again"""
	has_triggered = false
	monitoring = true
