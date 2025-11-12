extends Node
## Ending cutscene script for level-5
## Attach this to level-5 scene to trigger the ending sequence when player reaches the goal

# Debug options
@export var force_play_cutscene: bool = false  ## Enable this to always play cutscene (for testing)
@export var trigger_position_x: float = 0.0  ## X position where cutscene triggers (set in editor)

# References
var player: Node2D = null
var photo_shard_scene = preload("res://Entities/PhotoShard/photo_shard.tscn")
var photo_shard_instance = null
var cutscene_triggered: bool = false

func _ready():
	print("=== Ending Cutscene Setup ===")

	# Wait for scene to fully load
	await get_tree().create_timer(0.5).timeout

	# Find player
	player = get_tree().get_first_node_in_group("Player")
	if not player:
		push_error("Ending cutscene: Could not find player!")
		return

	print("Found player at position: ", player.global_position)

	# Register the ending cutscene
	register_ending_cutscene()

	# Connect to level complete signal if there's a level complete area
	var level_complete_area = get_tree().get_first_node_in_group("level_complete")
	if level_complete_area:
		if level_complete_area.has_signal("body_entered"):
			level_complete_area.body_entered.connect(_on_level_complete_area_entered)
			print("Connected to level complete area")

func _on_level_complete_area_entered(body: Node2D) -> void:
	"""Called when player enters the level complete area"""
	if cutscene_triggered:
		return

	if not body.is_in_group("Player"):
		return

	# Check if cutscene already played (unless force flag is set)
	if not force_play_cutscene and SaveManager.has_cutscene_played("ending_sequence"):
		print("Ending cutscene already played - allowing normal level completion")
		return

	cutscene_triggered = true
	print("Triggering ending cutscene!")

	# Play the ending sequence
	CutsceneDirector.play_cutscene("ending_sequence")

	# Wait for cutscene to finish
	await CutsceneDirector.cutscene_finished

	# Mark as played
	SaveManager.mark_cutscene_played("ending_sequence")

	# After cutscene, return to main menu or show credits
	await get_tree().create_timer(1.0).timeout
	SceneManager.goto_main_menu()

func register_ending_cutscene():
	"""Create and register the complete ending cutscene"""
	var actions = []

	# Get player's current position for calculations
	var start_x = player.global_position.x

	# Step 1: Player walks toward the dead end (tall cave wall)
	actions.append(CutsceneDirector.action_player_walk(start_x + 120.0, 60.0))

	# Step 2: Player stops and looks around
	actions.append(CutsceneDirector.action_wait(0.5))

	# Step 3: Dialogue - realization
	actions.append(CutsceneDirector.action_dialogue([
		"A dead end...",
		"I can't fly high enough to escape..."
	]))

	# Step 4: Wait, then photo shard appears
	actions.append(CutsceneDirector.action_wait(1.0))
	actions.append(CutsceneDirector.action_custom(spawn_photo_shard))

	# Step 5: Player notices shard
	actions.append(CutsceneDirector.action_wait(0.5))
	actions.append(CutsceneDirector.action_dialogue([
		"Another photo...?"
	]))

	# Step 6: Walk to photo shard
	actions.append(CutsceneDirector.action_player_walk(start_x + 160.0, 50.0))
	actions.append(CutsceneDirector.action_custom(pickup_photo_shard))

	# Step 7: Full-screen photo cutscene with emotional story
	var cutscene_frames = create_photo_cutscene_frames()
	actions.append(CutsceneDirector.action_fullscreen_cutscene(cutscene_frames))

	# Step 8: Return from cutscene
	actions.append(CutsceneDirector.action_custom(end_cutscene))

	# Register the sequence
	CutsceneDirector.register_cutscene("ending_sequence", actions)
	print("Ending cutscene registered!")

func spawn_photo_shard():
	"""Spawn the photo shard at the dead end"""
	if not player:
		return

	# Spawn photo shard slightly ahead of player and off to the side
	var spawn_pos = player.global_position + Vector2(40, -10)

	photo_shard_instance = photo_shard_scene.instantiate()
	photo_shard_instance.global_position = spawn_pos
	get_tree().current_scene.add_child(photo_shard_instance)

	# Play spawn animation
	if photo_shard_instance.has_method("play_spawn_animation"):
		photo_shard_instance.play_spawn_animation()

	print("Spawned photo shard at: ", spawn_pos)

func pickup_photo_shard():
	"""Player picks up the photo shard"""
	if photo_shard_instance and is_instance_valid(photo_shard_instance):
		# Play pickup animation
		if photo_shard_instance.has_method("play_pickup_animation"):
			photo_shard_instance.play_pickup_animation()
			await get_tree().create_timer(0.6).timeout

		# Remove the shard
		photo_shard_instance.queue_free()
		photo_shard_instance = null
		print("Picked up photo shard")

func create_photo_cutscene_frames() -> Array:
	"""Create the fullscreen cutscene frames for the ending photo sequence"""
	var frames = []

	# Load the CutscenePlayer script to access create_frame
	var CutscenePlayerScript = load("res://UI/CutscenePlayer/cutscene_player.gd")

	# Frame 1: Photo of family/memory
	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/looking-at-first-scrappng.png",
		[
			"This photo...it's the same as before...",
			"But there's something on the back..."
		]
	))

	# Frame 2: Turn photo over - reveal letter/writing
	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/sona-close-up-sad.png",
		[
			"It's...a letter?",
			"From my mother..."
		]
	))

	# Frame 3: Letter contents - emotional message
	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/sona-crying.png",
		[
			"'My dearest Sona,'",
			"'If you're reading this, I'm no longer with you.'",
			"'But know that you are stronger than you realize.'"
		]
	))

	# Frame 4: More letter - hope and encouragement
	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/sona-seeing-exit.png",
		[
			"'You don't need to fly to be free.'",
			"'Your voice, your courage—that is your way out.'",
			"'Trust yourself, and you will find another path.'"
		]
	))

	# Frame 5: Sona's realization
	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/sona-close-up-sad.png",
		[
			"Another way...",
			"Maybe I don't need to escape through the sky...",
			"Maybe I can find a different path..."
		]
	))

	# Frame 6: Fade to title or credits
	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/black.png",
		[
			"To be continued..."
		]
	))

	return frames

func end_cutscene():
	"""Called at the end of the cutscene sequence"""
	print("Ending cutscene complete")

	# Start background music (if different from level music)
	if BackgroundMusic:
		BackgroundMusic.play()
