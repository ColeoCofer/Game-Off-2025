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

	# Hide the PhotoShard at the start - it will pop in later during the cutscene
	var shard = find_photo_shard()
	if shard:
		shard.visible = false
		print("Final cutscene: Hid PhotoShard at start")

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

	# Step 0: Set up camera to show more of the scene (move up to see cliff top)
	actions.append(CutsceneDirector.action_custom(setup_camera_for_scene))

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

	# Step 5: Show photo shard with pop animation after camera finishes panning
	actions.append(CutsceneDirector.action_custom(show_photo_shard_with_pop))
	actions.append(CutsceneDirector.action_wait(0.3))

	# Step 6: God rays shine down on the photo shard
	actions.append(CutsceneDirector.action_custom(show_god_rays_on_shard))
	actions.append(CutsceneDirector.action_wait(0.8))

	# Step 7: Dialogue "What's this?"
	actions.append(CutsceneDirector.action_dialogue(
		["What's this?"]
		# TODO: Add audio path when available
	))

	# Step 8: Sona walks over to the shard, pulls it out, says dialogue, then shard fades
	actions.append(CutsceneDirector.action_custom(walk_to_shard_hold_and_dialogue))

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


func setup_camera_for_scene():
	"""Set up camera to show more of the scene - move up to see the cliff top"""
	print("Setting up camera for scene...")

	if not camera:
		camera = player.get_node_or_null("Camera2D")

	if camera:
		# Move camera up to show more of the cliff
		var target_offset = Vector2(0, -40)  # Move up to see cliff top

		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(camera, "offset", target_offset, 0.5)
		await tween.finished

		print("Camera moved up to show cliff")
	else:
		push_warning("Could not find camera for setup")


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
	"""Pan camera left to show the photo shard and player, then lock it in place"""
	print("Panning camera to photo shard and locking...")

	if not camera:
		camera = player.get_node_or_null("Camera2D")

	if camera:
		# Get photo shard position
		var shard = find_photo_shard()
		if shard:
			# Pan left while keeping the vertical offset from setup
			# Current offset should be (0, -40) from setup_camera_for_scene
			var target_offset = Vector2(-95, -40)  # Pan left to show both walls, keep vertical offset

			var tween = create_tween()
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(camera, "offset", target_offset, 1.0)
			await tween.finished

			# Lock the camera by reparenting it to the scene root
			# This stops it from following the player
			var camera_global_pos = camera.global_position
			camera.get_parent().remove_child(camera)
			get_tree().current_scene.add_child(camera)
			camera.global_position = camera_global_pos

			print("Camera panned and locked in place")
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


func show_photo_shard_with_pop():
	"""Make the photo shard visible with a pop animation and sound"""
	print("Showing photo shard with pop...")

	# Find the PhotoShard node in the scene
	photo_shard_instance = find_photo_shard()

	if photo_shard_instance:
		# Disable the bobbing animation - it looks odd while in the ground
		photo_shard_instance.set_process(false)

		# Store original scale
		var original_scale = photo_shard_instance.scale

		# Start small/invisible
		photo_shard_instance.scale = Vector2.ZERO
		photo_shard_instance.visible = true

		# Play pop sound
		var pop_sound = AudioStreamPlayer.new()
		pop_sound.stream = load("res://Assets/Audio/UI/LightPop.wav")
		pop_sound.volume_db = -5.0
		get_tree().current_scene.add_child(pop_sound)
		pop_sound.play()
		pop_sound.finished.connect(func(): pop_sound.queue_free())

		# Pop animation: scale up larger than normal, then back to normal
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		# Scale up to 1.3x
		tween.tween_property(photo_shard_instance, "scale", original_scale * 1.3, 0.2)
		# Then back to normal
		tween.tween_property(photo_shard_instance, "scale", original_scale, 0.15)
		await tween.finished

		print("PhotoShard pop animation complete")
	else:
		push_error("Could not find PhotoShard in scene!")


func walk_to_shard_hold_and_dialogue():
	"""Make Sona walk over to the photo shard, pull it out, say dialogue, then fade shard"""
	print("Walking to photo shard...")

	if not photo_shard_instance:
		photo_shard_instance = find_photo_shard()

	if not photo_shard_instance or not player:
		push_warning("Could not find PhotoShard or player for walking")
		return

	# Get the shard's X position (walk to just left of it)
	var target_x = photo_shard_instance.global_position.x - 10

	# Find the player's AnimatedSprite2D
	var anim_sprite: AnimatedSprite2D = null
	if player.has_node("AnimatedSprite2D"):
		anim_sprite = player.get_node("AnimatedSprite2D")

	# Calculate direction
	var direction = sign(target_x - player.global_position.x)

	# Face the correct direction and start walk animation
	if anim_sprite:
		anim_sprite.flip_h = (direction < 0)
		anim_sprite.play("walk")

	# Walk to the shard
	var walk_speed = 50.0
	while abs(player.global_position.x - target_x) > 3.0:
		player.global_position.x += direction * walk_speed * get_process_delta_time()
		await get_tree().process_frame

	# Stop and face the shard
	if anim_sprite:
		anim_sprite.play("idle")
		anim_sprite.flip_h = false  # Face right toward shard

	print("Reached photo shard, now picking up...")

	# Brief pause before pickup
	await get_tree().create_timer(0.3).timeout

	# --- Pickup animation ---

	# Fade out god rays as player picks up shard
	if god_rays_instance and god_rays_instance.material:
		var rays_tween = create_tween()
		rays_tween.tween_method(
			func(val): god_rays_instance.material.set_shader_parameter("opacity", val),
			0.8, 0.0, 0.5
		)

	# Stop the shard's bobbing animation so it doesn't fight with our tween
	photo_shard_instance.set_process(false)

	# Animate shard moving to above player's head
	var target_pos = player.global_position + Vector2(0, -25)  # Above player's head

	var tween = photo_shard_instance.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	# Move to above player's head
	tween.tween_property(photo_shard_instance, "global_position", target_pos, 0.4)

	await tween.finished

	print("Sona is now holding the photo shard")

	# --- Show dialogue while holding shard ---
	DialogueManager.start_simple_dialogue(["Oh--that's the last one..."])
	await DialogueManager.dialogue_finished

	# --- Fade out the shard ---
	print("Fading out photo shard...")

	if photo_shard_instance:
		var fade_tween = photo_shard_instance.create_tween()
		fade_tween.tween_property(photo_shard_instance, "modulate:a", 0.0, 0.3)
		await fade_tween.finished

		photo_shard_instance.visible = false
		photo_shard_instance.modulate.a = 1.0
		photo_shard_instance = null

	# Clean up god rays
	if god_rays_instance:
		god_rays_instance.queue_free()
		god_rays_instance = null

	print("Photo shard sequence complete")


func create_final_cutscene_frames() -> Array:
	"""Create the fullscreen cutscene frames for the final photo sequence"""
	var frames = []

	# Create a temporary CutscenePlayer to access the create_frame method
	var CutscenePlayerScript = load("res://UI/CutscenePlayer/cutscene_player.gd")

	# Frame 1: sona-full-picture.png - "Mom..."
	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/sona-full-picture.png",
		[
			"Mom...",
			"I made it all this way and still cannot reach the top..."
		],
		0.0
		# TODO: Add audio paths when available
	))

	# Frame 3: sona-full-photo-above.png - despair and hope
	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/sona-full-photo-above.png",
		[
			"I let you down...",
			"I knew I couldn't do it without you here...",
			"...",
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
