extends Node
## Opening cutscene script for level-1
## Attach this to level-1 scene to trigger the opening sequence

# Debug options
@export var force_play_cutscene: bool = false  ## Enable this to always play cutscene (for testing)

# References
var player: Node2D = null
var photo_shard_instance = null

func _ready():
	print("=== Opening Cutscene Setup ===")

	# Check if this cutscene has already been played (unless force_play_cutscene is enabled)
	if not force_play_cutscene and SaveManager.has_cutscene_played("opening_sequence"):
		print("Opening cutscene already played - skipping")
		return

	# Stop the timer immediately (will restart after cutscene)
	if TimerManager.current_timer_ui and TimerManager.current_timer_ui.has_method("stop_timer"):
		TimerManager.current_timer_ui.stop_timer()
		print("Opening cutscene: Stopped timer")

	# Find player immediately (no wait)
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("Player")
	if not player:
		push_error("Opening cutscene: Could not find player!")
		return

	print("Found player at position: ", player.global_position)

	# Disable player control immediately and clear velocity
	if player.has_method("disable_control"):
		player.disable_control()
		player.velocity = Vector2.ZERO
		print("Opening cutscene: Disabled player control and cleared velocity")

	# Register the opening cutscene
	register_opening_cutscene()

	# Wait before starting cutscene (player frozen, can see the level)
	await get_tree().create_timer(1.0).timeout

	# Clear velocity again and ensure player is facing right for the cutscene
	player.velocity = Vector2.ZERO

	# Find the AnimatedSprite2D to ensure proper facing direction
	var anim_sprite: AnimatedSprite2D = null
	if player.has_node("AnimatedSprite2D"):
		anim_sprite = player.get_node("AnimatedSprite2D")
	else:
		for child in player.get_children():
			if child is AnimatedSprite2D:
				anim_sprite = child
				break

	if anim_sprite:
		anim_sprite.flip_h = false  # Face right for the cutscene

	# Play the opening sequence (will re-disable control, but that's fine)
	CutsceneDirector.play_cutscene("opening_sequence")

	# Wait for cutscene to finish
	await CutsceneDirector.cutscene_finished

	# Reset the level start time so timer starts from 0
	SceneManager.reset_level_timer(false)
	print("Opening cutscene: Reset level timer")

	# Restart the timer now that cutscene is complete
	if TimerManager.current_timer_ui and TimerManager.current_timer_ui.has_method("start_timer"):
		TimerManager.current_timer_ui.start_timer()
		print("Opening cutscene: Restarted timer")

	# Mark as played so it doesn't play again
	SaveManager.mark_cutscene_played("opening_sequence")

func register_opening_cutscene():
	"""Create and register the complete opening cutscene"""
	var actions = []

	# Get player's starting position
	var start_x = player.global_position.x

	# Step 1: Sona walks slowly across cave floor
	var walk_distance_1 = 80.0
	actions.append(CutsceneDirector.action_player_walk(start_x + walk_distance_1, 40.0))

	# Step 2: Sona stops and dialogue appears
	actions.append(CutsceneDirector.action_wait(0.3))
	actions.append(CutsceneDirector.action_dialogue(
		["I should turn around..."],
		["res://Assets/Audio/dialogue/1 i should turn around-1.wav"]
	))

	# Step 3: Pause
	actions.append(CutsceneDirector.action_wait(1.0))

	# Step 4: Sona takes a few steps forward
	var walk_distance_2 = 50.0
	actions.append(CutsceneDirector.action_player_walk(start_x + walk_distance_1 + walk_distance_2, 40.0))

	# Step 5: Photo shard appears at edge of screen
	actions.append(CutsceneDirector.action_custom(show_photo_shard))
	actions.append(CutsceneDirector.action_wait(0.5))

	# Step 6: Dialogue "Huh...?"
	actions.append(CutsceneDirector.action_dialogue(
		["Huh...?"],
		["res://Assets/Audio/dialogue/2 huh-1.wav"]
	))

	# Step 7: Sona walks over to the shard
	var shard_x = start_x + walk_distance_1 + walk_distance_2 + 25.0 # Must keep adding them
	actions.append(CutsceneDirector.action_player_walk(shard_x, 50.0))

	# Step 8: Pick up the shard
	actions.append(CutsceneDirector.action_custom(pickup_photo_shard))
	actions.append(CutsceneDirector.action_wait(0.5))

	# Step 9: Fullscreen cutscene with images
	var cutscene_frames = create_photo_cutscene_frames()
	actions.append(CutsceneDirector.action_fullscreen_cutscene(cutscene_frames))

	# Step 10: Transition to title screen
	actions.append(CutsceneDirector.action_custom(go_to_title_screen))

	# Register the complete sequence
	CutsceneDirector.register_cutscene("opening_sequence", actions)
	print("Opening cutscene registered with %d actions" % actions.size())


func show_photo_shard():
	"""Make the photo shard visible and start bobbing animation"""
	print("Showing photo shard...")

	# Find the PhotoShard node in the scene
	photo_shard_instance = get_tree().current_scene.get_node_or_null("PhotoShard")

	if photo_shard_instance:
		# Make it visible
		photo_shard_instance.visible = true
		print("PhotoShard made visible")

		# Play pop sound
		var pop_sound = AudioStreamPlayer.new()
		pop_sound.stream = load("res://Assets/Audio/UI/LightPop.wav")
		pop_sound.volume_db = -5.0
		get_tree().current_scene.add_child(pop_sound)
		pop_sound.play()
		pop_sound.finished.connect(func(): pop_sound.queue_free())

		# Start the bobbing animation if available
		if photo_shard_instance.has_method("play_spawn_animation"):
			photo_shard_instance.play_spawn_animation()
	else:
		push_error("Could not find PhotoShard in scene!")

func pickup_photo_shard():
	"""Play pickup animation and remove the shard"""
	print("Picking up photo shard...")

	# Find the photo shard in the scene
	if not photo_shard_instance:
		photo_shard_instance = get_tree().current_scene.get_node_or_null("PhotoShard")

	if photo_shard_instance:
		# Trigger the collection which plays the pickup animation
		if photo_shard_instance.has_method("collect"):
			photo_shard_instance.collect(player)
			await get_tree().create_timer(0.6).timeout  # Wait for fade_out_duration
		else:
			# Fallback: just remove it
			photo_shard_instance.queue_free()

		photo_shard_instance = null

func create_photo_cutscene_frames() -> Array:
	"""Create the fullscreen cutscene frames for the photo sequence"""
	var frames = []

	# Create a temporary CutscenePlayer to access the create_frame method
	var CutscenePlayerScript = load("res://UI/CutscenePlayer/cutscene_player.gd")

	# Audio files 3 and 4 combined for "This photo...it looks familiar..."
	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/looking-at-first-scrappng.png",
		[
			"This photo...it looks familiar..."
		],
		0.0,
		["res://Assets/Audio/dialogue/3 this photo-1.wav"]
	))

	# Audio files 5 and 7 for "I think it's of me and my mom...right before..."
	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/sona-close-up-sad.png",
		[
			"I think it's of me and my mom...",
			"...right before..."
		],
		0.0,
		[
			"res://Assets/Audio/dialogue/5 its of me and my mom-1.wav",
			"res://Assets/Audio/dialogue/7 mom bat scream-1.wav"
		]
	))

	# Audio files 8 and 9 combined for "It kills me to be so alone..."
	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/sona-crying.png",
		[
			"It kills me to be so alone...",
		],
		0.0,
		["res://Assets/Audio/dialogue/8 it kills me-1.wav"]
	))

	# Two dialogue lines with separate audio files
	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/sona-seeing-exit.png",
		[
			"There could be others out there...",
			"But I lost my only family before I learned to fly..."
		],
		0.0,
		[
			"res://Assets/Audio/dialogue/10 there could be others out there-1.wav",
			"res://Assets/Audio/dialogue/11 but i lost my only family-1.wav"
		]
	))

	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/black.png",
		[
			"Maybe there's another way..."
		],
		0.0,
		["res://Assets/Audio/dialogue/13 maybe theres another way-1.wav"]
	))

	# Frame 4: Fade to black (we'll use a black image or the title image)
	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/sona-title.png",
		[
			"" # TODO: Need to add a sleep statement here for n-seconds
		]
	))

	return frames

func go_to_title_screen():
	"""Fade to black and end cutscene, returning to gameplay"""
	print("Ending opening cutscene, returning to gameplay...")

	# Music continues playing - no need to restart it
	# The cutscene will end naturally and return control to player
	# No need to load main menu - player continues in level-1
