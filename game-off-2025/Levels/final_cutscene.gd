extends Node
## Final cutscene script for level-end
## Attach this to level-end scene to trigger the ending sequence

# Debug options
@export var force_play_cutscene: bool = false  ## Enable this to always play cutscene (for testing)

# References
var player: Node2D = null
var photo_shard_instance = null
var camera: Camera2D = null
var echolocation_manager = null
var god_rays_instance: ColorRect = null

func _ready():
	print("=== Final Cutscene Setup ===")

	# Check if this cutscene has already been played (unless force_play_cutscene is enabled)
	if not force_play_cutscene and SaveManager.has_cutscene_played("final_sequence"):
		print("Final cutscene already played - skipping")
		return

	# Stop the timer immediately (will restart after cutscene if needed)
	if TimerManager.current_timer_ui and TimerManager.current_timer_ui.has_method("stop_timer"):
		TimerManager.current_timer_ui.stop_timer()
		print("Final cutscene: Stopped timer")

	# Find player immediately (no wait)
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("Player")
	if not player:
		push_error("Final cutscene: Could not find player!")
		return

	print("Found player at position: ", player.global_position)

	# Get camera reference
	camera = player.get_node_or_null("Camera2D")
	if camera:
		print("Final cutscene: Found camera")

	# Find EcholocationManager
	echolocation_manager = get_tree().get_first_node_in_group("echolocation_manager")
	if echolocation_manager:
		print("Final cutscene: Found EcholocationManager")

	# Disable player control immediately and clear velocity
	if player.has_method("disable_control"):
		player.disable_control()
		player.velocity = Vector2.ZERO
		print("Final cutscene: Disabled player control and cleared velocity")

	# Stop hunger depletion during cutscene
	var hunger_manager = player.get_node_or_null("HungerManager")
	if hunger_manager and hunger_manager.has_method("set_depletion_active"):
		hunger_manager.set_depletion_active(false)
		print("Final cutscene: Stopped hunger depletion")

	# Register the final cutscene
	register_final_cutscene()

	# Wait before starting cutscene (player frozen, can see the level)
	await get_tree().create_timer(0.5).timeout

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

	# Play the final sequence (will re-disable control, but that's fine)
	CutsceneDirector.play_cutscene("final_sequence")

	# Wait for cutscene to finish
	await CutsceneDirector.cutscene_finished

	# Mark as played so it doesn't play again
	SaveManager.mark_cutscene_played("final_sequence")

func register_final_cutscene():
	"""Create and register the complete final cutscene"""
	var actions = []

	# Step 1: Trigger echolocation to reveal the scene
	actions.append(CutsceneDirector.action_custom(trigger_echolocation_reveal))
	actions.append(CutsceneDirector.action_wait(1.5))  # Wait for echolocation to expand

	# Step 2: Sona walks to the right toward the cave wall/cliff
	# Player starts at (156, 518) and walks to (291, 519) to see the cliff
	var target_x = 291.0  # Near the cliff so cave entrance is visible
	actions.append(CutsceneDirector.action_player_walk(target_x, 40.0))

	# Step 3: Sona stops and dialogue appears
	actions.append(CutsceneDirector.action_wait(0.5))
	actions.append(CutsceneDirector.action_dialogue(
		["I can't make it up there after all..."]
		# TODO: Add audio path when available
	))

	# Step 4: Pan camera left to show the photo shard location
	actions.append(CutsceneDirector.action_custom(pan_camera_to_shard))
	actions.append(CutsceneDirector.action_wait(1.0))

	# Step 5: God rays shine down on the photo shard, then make it visible
	actions.append(CutsceneDirector.action_custom(show_god_rays_on_shard))
	actions.append(CutsceneDirector.action_wait(1.0))
	actions.append(CutsceneDirector.action_custom(show_photo_shard))
	actions.append(CutsceneDirector.action_wait(0.5))

	# Step 6: Dialogue "What's this?"
	actions.append(CutsceneDirector.action_dialogue(
		["What's this?"]
		# TODO: Add audio path when available
	))

	# Step 7: Pick up the shard (animation: shard appears over her head briefly)
	actions.append(CutsceneDirector.action_custom(pickup_photo_shard))
	actions.append(CutsceneDirector.action_wait(0.8))

	# Step 8: Dialogue after picking up
	actions.append(CutsceneDirector.action_dialogue(
		["Oh--that's the last one..."]
		# TODO: Add audio path when available
	))

	# Step 9: Wait before fullscreen cutscene
	actions.append(CutsceneDirector.action_wait(0.5))

	# Step 10: Fullscreen cutscene with images
	var cutscene_frames = create_final_cutscene_frames()
	actions.append(CutsceneDirector.action_fullscreen_cutscene(cutscene_frames))

	# Step 11: Return to level and show final dialogue
	actions.append(CutsceneDirector.action_wait(0.5))
	actions.append(CutsceneDirector.action_dialogue(
		["You were with me all along..."]
		# TODO: Add audio path when available
	))

	actions.append(CutsceneDirector.action_wait(0.3))
	actions.append(CutsceneDirector.action_dialogue(
		["Thank you mom. I know what I need to do."]
		# TODO: Add audio path when available
	))

	# Register the complete sequence
	CutsceneDirector.register_cutscene("final_sequence", actions)
	print("Final cutscene registered with %d actions" % actions.size())


func trigger_echolocation_reveal():
	"""Trigger echolocation and prevent darkness from fading back in"""
	print("Triggering echolocation reveal...")

	if not echolocation_manager:
		echolocation_manager = get_tree().get_first_node_in_group("echolocation_manager")

	if echolocation_manager:
		# Create a permanent reveal pulse that doesn't fade
		# We'll add a pulse with very long fade duration
		var pulse = {
			"relative_offset": Vector2.ZERO,
			"intensity": 1.0,
			"radius": 0.0,
			"age": 0.0
		}
		echolocation_manager.echo_pulses.append(pulse)

		# Override the fade duration to be very long (essentially permanent)
		echolocation_manager.echo_fade_duration = 9999.0

		# Play the echo sound
		var echo_audio = player.get_node_or_null("EchoAudioPlayer")
		if echo_audio:
			echo_audio.play()

		print("Echolocation triggered with permanent reveal")
	else:
		push_warning("Could not find EcholocationManager for echolocation reveal")


func find_photo_shard() -> Node:
	"""Find the PhotoShard node in the scene tree (may be nested under TileMap)"""
	# First try direct child
	var shard = get_tree().current_scene.get_node_or_null("PhotoShard")
	if shard:
		return shard
	# Try under TileMap
	shard = get_tree().current_scene.get_node_or_null("TileMap/PhotoShard")
	if shard:
		return shard
	# Fallback: search entire tree
	return get_tree().current_scene.find_child("PhotoShard", true, false)


func pan_camera_to_shard():
	"""Pan camera left to show the photo shard and player in the same frame"""
	print("Panning camera to photo shard...")

	if not camera:
		camera = player.get_node_or_null("Camera2D")

	if camera:
		# Get photo shard position
		var shard = find_photo_shard()
		if shard:
			# Calculate a camera position that shows both player and shard
			# The shard is at ~(200, 515), player is at ~(350, 520)
			# We want to pan left to center between them
			var target_offset = Vector2(-80, 0)  # Pan camera left from player

			var tween = create_tween()
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(camera, "offset", target_offset, 1.0)
			await tween.finished
			print("Camera panned to show shard")
		else:
			push_warning("Could not find PhotoShard for camera pan")
	else:
		push_warning("Could not find camera for panning")


func show_god_rays_on_shard():
	"""Create god rays shining down on the photo shard"""
	print("Creating god rays on photo shard...")

	var shard = find_photo_shard()
	if not shard:
		push_warning("Could not find PhotoShard for god rays")
		return

	# Create a ColorRect for the god rays
	god_rays_instance = ColorRect.new()
	god_rays_instance.name = "GodRays"

	# Position and size the god rays above the shard
	god_rays_instance.size = Vector2(80, 120)
	god_rays_instance.position = shard.global_position + Vector2(-40, -120)  # Above and centered on shard

	# Create shader material
	var shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://Shaders/pixelated_god_rays.gdshader")

	# Configure shader parameters for a nice light beam effect
	shader_material.set_shader_parameter("angle", 0.0)  # Straight down
	shader_material.set_shader_parameter("position_offset", 0.5)
	shader_material.set_shader_parameter("spread", 0.3)
	shader_material.set_shader_parameter("cutoff", 0.2)
	shader_material.set_shader_parameter("falloff", 0.4)
	shader_material.set_shader_parameter("edge_fade", 0.2)
	shader_material.set_shader_parameter("speed", 0.5)
	shader_material.set_shader_parameter("ray1_density", 4.0)
	shader_material.set_shader_parameter("ray2_density", 15.0)
	shader_material.set_shader_parameter("ray2_intensity", 0.2)
	shader_material.set_shader_parameter("ray_color", Color(1.0, 0.95, 0.8, 0.7))
	shader_material.set_shader_parameter("pixelation", 16.0)
	shader_material.set_shader_parameter("quantize_colors", true)
	shader_material.set_shader_parameter("color_levels", 4)
	shader_material.set_shader_parameter("opacity", 0.0)  # Start invisible

	god_rays_instance.material = shader_material

	# Add to scene
	get_tree().current_scene.add_child(god_rays_instance)

	# Fade in the god rays
	var tween = create_tween()
	tween.tween_method(func(val): shader_material.set_shader_parameter("opacity", val), 0.0, 0.8, 1.0)
	await tween.finished

	print("God rays created and faded in")


func show_photo_shard():
	"""Make the photo shard visible and start bobbing animation"""
	print("Showing photo shard...")

	# Find the PhotoShard node in the scene
	photo_shard_instance = find_photo_shard()

	if photo_shard_instance:
		# Make it visible
		photo_shard_instance.visible = true
		print("PhotoShard made visible")

		# Start the bobbing animation if available
		if photo_shard_instance.has_method("play_spawn_animation"):
			photo_shard_instance.play_spawn_animation()
	else:
		push_error("Could not find PhotoShard in scene!")


func pickup_photo_shard():
	"""Play pickup animation - shard moves above player's head briefly then fades"""
	print("Picking up photo shard...")

	# Find the photo shard in the scene
	if not photo_shard_instance:
		photo_shard_instance = find_photo_shard()

	if photo_shard_instance and player:
		# Fade out god rays as player picks up shard
		if god_rays_instance and god_rays_instance.material:
			var rays_tween = create_tween()
			rays_tween.tween_method(
				func(val): god_rays_instance.material.set_shader_parameter("opacity", val),
				0.8, 0.0, 0.5
			)

		# Animate shard moving to above player's head
		var target_pos = player.global_position + Vector2(0, -25)  # Above player's head

		var tween = photo_shard_instance.create_tween()
		tween.set_parallel(true)

		# Move to above player's head
		tween.tween_property(photo_shard_instance, "global_position", target_pos, 0.4)

		await tween.finished

		# Wait a moment with shard above head
		await get_tree().create_timer(0.3).timeout

		# Fade out
		var fade_tween = photo_shard_instance.create_tween()
		fade_tween.tween_property(photo_shard_instance, "modulate:a", 0.0, 0.3)
		await fade_tween.finished

		# Hide the shard
		photo_shard_instance.visible = false
		photo_shard_instance.modulate.a = 1.0  # Reset modulate for potential reuse

		# Clean up god rays
		if god_rays_instance:
			god_rays_instance.queue_free()
			god_rays_instance = null

		photo_shard_instance = null
	else:
		push_warning("Could not find PhotoShard or player for pickup animation!")


func create_final_cutscene_frames() -> Array:
	"""Create the fullscreen cutscene frames for the final photo sequence"""
	var frames = []

	# Create a temporary CutscenePlayer to access the create_frame method
	var CutscenePlayerScript = load("res://UI/CutscenePlayer/cutscene_player.gd")

	# Frame 1: sona-full-picture.png - "Mom..."
	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/sona-full-picture.png",
		[
			"Mom..."
		],
		0.0
		# TODO: Add audio paths when available
	))

	# Frame 2: Still sona-full-picture.png - more dialogue
	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/sona-full-picture.png",
		[
			"I made it all this way and still cannot reach the top..."
		],
		0.0
	))

	# Frame 3: sona-full-photo-above.png - despair and hope
	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/sona-full-photo-above.png",
		[
			"I let you down..."
		],
		0.0
	))

	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/sona-full-photo-above.png",
		[
			"I knew I couldn't do it without you here..."
		],
		0.0
	))

	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/sona-full-photo-above.png",
		[
			"..."
		],
		0.0
	))

	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/sona-full-photo-above.png",
		[
			"Wait a minute...there's writing on the other side..."
		],
		0.0
	))

	# Frame 4: letter.png - no dialogue, just show the letter
	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/letter.png",
		[
			""  # No dialogue - player reads the letter
		],
		0.0  # Manual advance (player clicks to continue)
	))

	return frames
