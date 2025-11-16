extends Node

## CheckpointManager - Manages checkpoint spawn positions for the player
## Stores checkpoint position in memory only - cleared on level change

signal checkpoint_reached(checkpoint_position: Vector2)

# Static variables to persist checkpoint across scene reloads (but not level changes)
static var current_checkpoint_position: Vector2 = Vector2.ZERO
static var has_checkpoint: bool = false
static var checkpoint_level: String = ""  # Track which level the checkpoint is for

var player: CharacterBody2D
var level_start_position: Vector2 = Vector2.ZERO

func _ready():
	player = get_parent() as CharacterBody2D

	# Store the initial spawn position when level starts
	# Wait one frame to ensure player is properly positioned
	await get_tree().process_frame
	level_start_position = player.global_position

	# Check if we have a checkpoint for this level and respawn there
	var current_level = SceneManager.current_level if SceneManager else ""
	if has_checkpoint and checkpoint_level == current_level and current_checkpoint_position != Vector2.ZERO:
		# Respawn at checkpoint
		player.global_position = current_checkpoint_position
		player.velocity = Vector2.ZERO
		print("CheckpointManager: Respawning at checkpoint: ", current_checkpoint_position)

	# Connect to SceneManager to detect level changes
	if SceneManager:
		SceneManager.scene_changed.connect(_on_scene_changed)

	# Find all checkpoints in the scene and connect to them
	_connect_to_checkpoints()

func _connect_to_checkpoints():
	"""Find and connect to all checkpoint nodes in the scene"""
	# Wait a moment for scene to be fully loaded
	await get_tree().process_frame

	var current_level = SceneManager.current_level if SceneManager else ""
	var checkpoints = get_tree().get_nodes_in_group("checkpoint")
	for checkpoint in checkpoints:
		if checkpoint.has_signal("checkpoint_activated"):
			if not checkpoint.checkpoint_activated.is_connected(_on_checkpoint_activated):
				checkpoint.checkpoint_activated.connect(_on_checkpoint_activated)

		# If this checkpoint was previously activated in this level, re-activate it visually
		if has_checkpoint and checkpoint_level == current_level:
			if checkpoint.global_position.distance_to(current_checkpoint_position) < 5.0:
				# This is the active checkpoint - make it look activated
				if checkpoint.has_method("activate"):
					checkpoint.activated = true
					checkpoint._update_visual_state()

func _on_checkpoint_activated(checkpoint_position: Vector2):
	"""Called when player activates a checkpoint"""
	current_checkpoint_position = checkpoint_position
	has_checkpoint = true
	checkpoint_level = SceneManager.current_level if SceneManager else ""

	print("CheckpointManager: Checkpoint activated at ", checkpoint_position, " in level ", checkpoint_level)
	checkpoint_reached.emit(checkpoint_position)

func get_spawn_position() -> Vector2:
	"""Get the position where the player should spawn (checkpoint or level start)"""
	if has_checkpoint:
		return current_checkpoint_position
	else:
		return level_start_position

func reset_checkpoint():
	"""Clear the checkpoint (called on level change)"""
	has_checkpoint = false
	current_checkpoint_position = Vector2.ZERO
	checkpoint_level = ""
	print("CheckpointManager: Checkpoint cleared")

func _on_scene_changed(_scene_path: String):
	"""Reset checkpoint when changing to a different level"""
	# Only clear checkpoint if we're changing to a different level
	var new_level = SceneManager.current_level if SceneManager else ""
	if new_level != checkpoint_level:
		reset_checkpoint()

func respawn_player():
	"""Move player to spawn position (checkpoint or level start)"""
	if not player:
		return

	var spawn_pos = get_spawn_position()
	player.global_position = spawn_pos
	player.velocity = Vector2.ZERO

	print("CheckpointManager: Respawning player at ", spawn_pos)
