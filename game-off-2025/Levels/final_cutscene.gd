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
var shard_light: PointLight2D = null

# Post-cutscene flight sequence
var correct_echo_position = Vector2(280, 520)  # Near cliff base on right side
var echo_trigger_radius = 60.0  # Generous radius for the trigger
var has_triggered_flight = false
var radial_glow_instance: ColorRect = null

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

	# Set up post-cutscene gameplay (player can now explore and trigger flight)
	await setup_post_cutscene_gameplay()

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
		["I can't make it up there after all..."],
		["res://Assets/Audio/dialogue/15 i can't make it up there after all-1.wav"]
	))

	# Step 4: Pan camera left to show the photo shard location
	actions.append(CutsceneDirector.action_custom(pan_camera_to_shard))

	# Step 5: God rays shine down on the ground first
	actions.append(CutsceneDirector.action_custom(show_god_rays_on_shard))
	actions.append(CutsceneDirector.action_wait(0.6))

	# Step 6: Photo shard pops out of the ground
	actions.append(CutsceneDirector.action_custom(show_photo_shard_with_pop))
	actions.append(CutsceneDirector.action_wait(0.5))

	# Step 7: Dialogue "What's this?"
	actions.append(CutsceneDirector.action_dialogue(
		["What's this?"],
		["res://Assets/Audio/dialogue/16 what's this.alp-1.wav"]
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
		["You were with me all along..."],
		["res://Assets/Audio/dialogue/25 you were with me all along-1.wav"]
	))

	actions.append(CutsceneDirector.action_wait(0.3))
	actions.append(CutsceneDirector.action_dialogue(
		["Thank you mom.", "I know what I need to do."],
		["res://Assets/Audio/dialogue/26 thank you mom-1.wav", "res://Assets/Audio/dialogue/27 i know what i need to do-1.wav"]
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

	# Size and position for a light beam shining down onto the shard
	var ray_width = 45.0  # Narrower beam
	var ray_height = 130.0  # Taller to extend higher
	god_rays_instance.size = Vector2(ray_width, ray_height)
	god_rays_instance.position = Vector2(
		shard.global_position.x - ray_width / 2,
		shard.global_position.y - ray_height  # Higher up
	)

	# Start invisible for fade-in
	god_rays_instance.modulate.a = 0.0

	# Create shader material using the simpler god_rays shader
	var shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://Shaders/god_rays.gdshader")

	# Configure for a glowy, cinematic light beam effect
	shader_material.set_shader_parameter("angle", 0.0)
	shader_material.set_shader_parameter("position", 0.0)  # Centered
	shader_material.set_shader_parameter("spread", 0.25)  # Less spread for narrower beam
	shader_material.set_shader_parameter("cutoff", 0.1)
	shader_material.set_shader_parameter("falloff", 0.3)  # Fade toward bottom
	shader_material.set_shader_parameter("edge_fade", 0.35)  # Softer edges to hide rectangle
	shader_material.set_shader_parameter("speed", 1.5)  # Faster for more movement/glistening
	shader_material.set_shader_parameter("ray1_density", 10.0)
	shader_material.set_shader_parameter("ray2_density", 25.0)
	shader_material.set_shader_parameter("ray2_intensity", 0.5)  # More secondary ray movement
	shader_material.set_shader_parameter("color", Color(1.0, 0.95, 0.8, 0.9))  # Brighter, more intense
	shader_material.set_shader_parameter("hdr", true)  # HDR for extra glow

	god_rays_instance.material = shader_material

	# Add to scene
	get_tree().current_scene.add_child(god_rays_instance)

	# Fade in the god rays
	var tween = create_tween()
	tween.tween_property(god_rays_instance, "modulate:a", 1.0, 1.0)
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

		# Add a glowing point light to the shard
		shard_light = PointLight2D.new()
		shard_light.name = "ShardGlow"
		shard_light.color = Color(1.0, 0.95, 0.8)  # Warm golden color
		shard_light.energy = 0.0  # Start at 0, will fade in
		shard_light.texture_scale = 0.15  # Size of the glow
		# Create a simple radial gradient texture for the light
		var gradient_texture = GradientTexture2D.new()
		gradient_texture.width = 128
		gradient_texture.height = 128
		gradient_texture.fill = GradientTexture2D.FILL_RADIAL
		gradient_texture.fill_from = Vector2(0.5, 0.5)
		gradient_texture.fill_to = Vector2(0.5, 0.0)
		var gradient = Gradient.new()
		gradient.colors = [Color.WHITE, Color.TRANSPARENT]
		gradient_texture.gradient = gradient
		shard_light.texture = gradient_texture
		photo_shard_instance.add_child(shard_light)

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
		tween.set_parallel(true)
		# Scale up to 1.3x
		tween.tween_property(photo_shard_instance, "scale", original_scale * 1.3, 0.2)
		# Fade in the light
		tween.tween_property(shard_light, "energy", 1.2, 0.3)
		await tween.finished

		# Then scale back to normal
		var tween2 = create_tween()
		tween2.set_ease(Tween.EASE_OUT)
		tween2.tween_property(photo_shard_instance, "scale", original_scale, 0.15)
		await tween2.finished

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
	var dialogue_lines: Array[DialogueManager.DialogueLine] = []
	dialogue_lines.append(DialogueManager.DialogueLine.new(
		"Oh--that's the last one...",
		"",
		0.0,
		Callable(),
		"res://Assets/Audio/dialogue/17 oh its the last one-1.wav"
	))
	DialogueManager.start_dialogue(dialogue_lines)
	await DialogueManager.dialogue_finished

	# --- Fade out the shard and its light ---
	print("Fading out photo shard...")

	if photo_shard_instance:
		var fade_tween = photo_shard_instance.create_tween()
		fade_tween.set_parallel(true)
		fade_tween.tween_property(photo_shard_instance, "modulate:a", 0.0, 0.3)
		# Also fade out the light energy
		if shard_light:
			fade_tween.tween_property(shard_light, "energy", 0.0, 0.3)
		await fade_tween.finished

		photo_shard_instance.visible = false
		photo_shard_instance.modulate.a = 1.0
		photo_shard_instance = null
		shard_light = null

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
		0.0,
		[
			"res://Assets/Audio/dialogue/18 mom-1.wav",
			"res://Assets/Audio/dialogue/19 i made it all this way-1.wav"
		]
	))

	# Frame 2: sona-full-photo-above.png - despair and hope
	# Use "|" to play multiple audio files sequentially for a single dialogue line
	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/sona-full-photo-above.png",
		[
			"I let you down...",
			"I knew I couldn't do it without you here...",
			"...",
			"Wait a minute...there's writing on the other side...",
		],
		0.0,
		[
			"res://Assets/Audio/dialogue/20 i let you down-1.wav",
			"res://Assets/Audio/dialogue/21 i knew i couldn't do it without you-1.wav|res://Assets/Audio/dialogue/22 without you here-1.wav",
			"",  # No audio for "..."
			"res://Assets/Audio/dialogue/23 wait a minute-1.wav|res://Assets/Audio/dialogue/24 theres writing on the other side-1.wav"
		]
	))

	# Frame 3: letter.png - no dialogue, just show the letter
	frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/letter.png",
		[
			""  # No dialogue - player reads the letter
		],
		0.0,
		[""]  # No audio
	))

	return frames


# =============================================================================
# POST-CUTSCENE GAMEPLAY - Flight Sequence
# =============================================================================

func setup_post_cutscene_gameplay():
	"""Set up the scene for post-cutscene exploration and flight trigger"""
	print("=== Setting up post-cutscene gameplay ===")

	# 1. Restore camera to follow the player
	if camera and camera.get_parent() != player:
		var cam_global_pos = camera.global_position
		camera.get_parent().remove_child(camera)
		player.add_child(camera)
		camera.position = Vector2.ZERO
		camera.offset = Vector2.ZERO
		print("Camera restored to player")

	# 2. Reset echolocation to normal fade behavior
	if echolocation_manager:
		echolocation_manager.echo_fade_duration = 3.5  # Reset to normal
		echolocation_manager.echo_pulses.clear()  # Clear permanent reveal
		# Set callback to control echolocation (only allow in correct spot)
		echolocation_manager.echolocation_check_callback = _check_echolocation_allowed
		print("Echolocation reset to normal, check callback set")

	# 3. Keep hunger full and disable depletion (Sona can't die in this level)
	var hunger_manager = player.get_node_or_null("HungerManager")
	if hunger_manager:
		hunger_manager.set_depletion_active(false)
		# Set hunger to max
		if hunger_manager.has_method("restore_hunger"):
			hunger_manager.restore_hunger(100.0)
		print("Hunger kept full, depletion disabled")

	# 4. Re-enable player control
	if player.has_method("enable_control"):
		player.enable_control()
		print("Player control re-enabled")

	print("Post-cutscene setup complete - player can now explore!")


func _check_echolocation_allowed(player_pos: Vector2) -> bool:
	"""Callback to check if echolocation should be allowed at this position.
	Returns true to allow echolocation, false to block it."""
	if has_triggered_flight:
		return false  # Already triggered, block further echolocation

	var distance = player_pos.distance_to(correct_echo_position)
	print("Echolocation attempt at ", player_pos, " - distance to trigger: ", distance)

	if distance <= echo_trigger_radius:
		# Correct spot! Allow echolocation and trigger the flight sequence
		has_triggered_flight = true
		print("Correct spot! Triggering flight sequence!")
		# Use call_deferred to trigger flight after echolocation completes
		call_deferred("trigger_flight_sequence")
		return true  # Allow echolocation
	else:
		# Wrong spot - show dialogue and block echolocation
		DialogueManager.start_simple_dialogue(["No, not here."])
		return false  # Block echolocation


func trigger_flight_sequence():
	"""The magical moment - Sona learns to fly!"""
	print("=== FLIGHT SEQUENCE BEGIN ===")

	# Make echolocation last longer during the flight sequence
	if echolocation_manager:
		echolocation_manager.echo_fade_duration = 15.0  # Long enough for entire flight + walk

	# Disable player control
	if player.has_method("disable_control"):
		player.disable_control()
		player.velocity = Vector2.ZERO

	# Get references
	var anim_sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D")
	var flap_audio = player.get_node_or_null("FlapAudioPlayer")

	# Create radial glow effect around Sona
	radial_glow_instance = create_radial_glow()

	# Brief pause before flight
	await get_tree().create_timer(0.5).timeout

	# Two-phase flight: straight up, then to the right
	var start_pos = player.global_position
	var top_pos = Vector2(start_pos.x, 423)  # Fly straight up to cliff height
	var landing_pos = Vector2(332, 423)  # Then fly right to cliff edge

	# Flight parameters - slower for cinematic effect
	var vertical_duration = 2.5  # Time to fly up
	var horizontal_duration = 1.5  # Time to fly right
	var flap_interval = 0.3

	# Start flap animation
	if anim_sprite:
		anim_sprite.play("flap")

	# Fade in the glow
	if radial_glow_instance and radial_glow_instance.material:
		var glow_tween = create_tween()
		glow_tween.tween_method(
			func(val): radial_glow_instance.material.set_shader_parameter("opacity", val),
			0.0, 1.0, 0.5
		)

	# Phase 1: Fly straight up
	var flight_tween = create_tween()
	flight_tween.set_ease(Tween.EASE_IN_OUT)
	flight_tween.set_trans(Tween.TRANS_CUBIC)
	flight_tween.tween_property(player, "global_position", top_pos, vertical_duration)

	# Play flap sounds during vertical flight
	var flap_timer = 0.0
	while flight_tween.is_running():
		flap_timer += get_process_delta_time()
		if flap_timer >= flap_interval:
			if flap_audio:
				flap_audio.play()
			if anim_sprite and not anim_sprite.is_playing():
				anim_sprite.play("flap")
			flap_timer = 0.0
		await get_tree().process_frame

	print("Sona reached cliff height, now flying right...")

	# Phase 2: Fly right to landing position
	var horizontal_tween = create_tween()
	horizontal_tween.set_ease(Tween.EASE_IN_OUT)
	horizontal_tween.set_trans(Tween.TRANS_CUBIC)
	horizontal_tween.tween_property(player, "global_position", landing_pos, horizontal_duration)

	# Continue flap sounds during horizontal flight
	flap_timer = 0.0
	while horizontal_tween.is_running():
		flap_timer += get_process_delta_time()
		if flap_timer >= flap_interval:
			if flap_audio:
				flap_audio.play()
			if anim_sprite and not anim_sprite.is_playing():
				anim_sprite.play("flap")
			flap_timer = 0.0
		await get_tree().process_frame

	print("Sona has landed on the cliff!")

	# Landing - switch to idle
	if anim_sprite:
		anim_sprite.play("idle")

	# Fade out the glow
	if radial_glow_instance:
		var fade_tween = create_tween()
		if radial_glow_instance.material:
			fade_tween.tween_method(
				func(val): radial_glow_instance.material.set_shader_parameter("opacity", val),
				1.0, 0.0, 0.5
			)
		await fade_tween.finished
		radial_glow_instance.queue_free()
		radial_glow_instance = null

	# Brief pause after landing
	await get_tree().create_timer(0.5).timeout

	# Walk into cave and continue to ending
	await walk_into_cave_and_end()


func create_radial_glow() -> ColorRect:
	"""Create the radial glow effect for the flight sequence"""
	var glow = ColorRect.new()
	glow.name = "RadialGlow"
	glow.size = Vector2(256, 256)  # Large so it surrounds Sona with room to spare
	glow.position = Vector2(-128, -128)  # Center on player

	var shader_mat = ShaderMaterial.new()
	shader_mat.shader = load("res://Shaders/radial_glow.gdshader")

	# Configure for a halo effect - dark center, light around edges
	shader_mat.set_shader_parameter("pixelation", Vector2(128.0, 128.0))  # Match new size
	shader_mat.set_shader_parameter("spread", 0.35)  # Longer rays
	shader_mat.set_shader_parameter("size", 0.1)  # Smaller visible area pushes light outward
	shader_mat.set_shader_parameter("speed", 0.8)
	shader_mat.set_shader_parameter("ray1_density", 6.0)
	shader_mat.set_shader_parameter("ray2_density", 5.0)
	shader_mat.set_shader_parameter("ray2_intensity", 0.3)
	shader_mat.set_shader_parameter("core_intensity", -0.5)  # NEGATIVE = halo effect (dark center)
	shader_mat.set_shader_parameter("hdr", false)
	shader_mat.set_shader_parameter("glow_color", Color(1.0, 0.95, 0.8, 0.5))  # Slightly more visible
	shader_mat.set_shader_parameter("opacity", 0.0)  # Start invisible

	glow.material = shader_mat
	player.add_child(glow)  # Add as child so it moves with player
	return glow


func walk_into_cave_and_end():
	"""Walk Sona into the cave entrance and fade to ending"""
	print("Walking into cave...")

	# IMPORTANT: Disable the CaveEntrance so it doesn't trigger level completion!
	var cave_entrance = get_tree().current_scene.find_child("CaveEntrance", true, false)
	if cave_entrance:
		# Set is_animating = true so it ignores player entry (check in _on_trigger_entered)
		cave_entrance.is_animating = true
		print("CaveEntrance is_animating set to true - will ignore player")

		# Also disconnect the signal to be extra safe
		var trigger_area = cave_entrance.get_node_or_null("TriggerArea")
		if trigger_area and trigger_area.body_entered.is_connected(cave_entrance._on_trigger_entered):
			trigger_area.body_entered.disconnect(cave_entrance._on_trigger_entered)
			print("CaveEntrance TriggerArea signal disconnected")

	var anim_sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D")

	# Face right and walk
	if anim_sprite:
		anim_sprite.flip_h = false
		anim_sprite.play("walk")

	# Walk right into the cave entrance (from cliff edge at 332 to cave at ~420)
	var target_x = 420.0
	var walk_tween = create_tween()
	walk_tween.tween_property(player, "global_position:x", target_x, 1.5)  # Slightly longer walk
	await walk_tween.finished

	# Stop animation
	if anim_sprite:
		anim_sprite.play("idle")

	print("Sona entered the cave - fading to black...")

	# Fade to black
	var fade_layer = CanvasLayer.new()
	fade_layer.layer = 100
	fade_layer.name = "FadeLayer"

	var fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.size = Vector2(1280, 720)  # Cover full screen
	fade_rect.modulate.a = 0.0
	fade_layer.add_child(fade_rect)
	get_tree().root.add_child(fade_layer)

	var fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "modulate:a", 1.0, 1.5)
	await fade_tween.finished

	# Brief pause in black
	await get_tree().create_timer(0.5).timeout

	# Show the ending sequence
	await show_ending_sequence(fade_layer)


func show_ending_sequence(fade_layer: CanvasLayer):
	"""Show the final cutscene images (gameboy ending)"""
	print("=== ENDING SEQUENCE ===")

	# Create cutscene frames for the ending
	var cutscene_frames = []
	var CutscenePlayerScript = load("res://UI/CutscenePlayer/cutscene_player.gd")

	# Frame 1: sona-gameboy-1.png
	cutscene_frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/sona-gameboy-1.png",
		[""],  # Empty for player to advance
		0.0,
		[""]
	))

	# Frame 2: sona-gameboy-2.png
	cutscene_frames.append(CutscenePlayerScript.create_frame(
		"res://Assets/Art/cut-scenes/sona-gameboy-2.png",
		[""],  # Empty for player to advance
		0.0,
		[""]
	))

	# Hide the fade layer so we can see the cutscene images
	if fade_layer and is_instance_valid(fade_layer):
		fade_layer.visible = false
		print("FadeLayer hidden for cutscene")

	# Get or create cutscene player
	var cutscene_player = get_tree().get_first_node_in_group("cutscene_player")
	var we_created_cutscene_player = false
	if not cutscene_player:
		var scene = load("res://UI/CutscenePlayer/cutscene_player.tscn")
		cutscene_player = scene.instantiate()
		get_tree().root.add_child(cutscene_player)
		we_created_cutscene_player = true

	# Play the ending cutscene
	cutscene_player.play_cutscene(cutscene_frames)
	await cutscene_player.cutscene_finished

	print("Ending cutscene complete!")

	# Wait a frame to let the cutscene_player finish its signal emission
	await get_tree().process_frame

	# Clean up cutscene player if we created it (use queue_free since we waited a frame)
	if we_created_cutscene_player and is_instance_valid(cutscene_player):
		cutscene_player.queue_free()
		print("CutscenePlayer queued for removal")

	# Clean up fade layer
	if fade_layer and is_instance_valid(fade_layer):
		fade_layer.queue_free()
		print("FadeLayer queued for removal")

	# Wait another frame for queue_free to process
	await get_tree().process_frame

	# Reset all global state before leaving the level
	cleanup_before_scene_change()

	# Wait for queue_free to process
	await get_tree().process_frame
	await get_tree().process_frame

	# TODO: Show final title screen (to be added by user)
	# TODO: Roll credits (to be added by user)

	# For now, return to main menu after a brief pause
	await get_tree().create_timer(1.0).timeout
	print("Returning to main menu...")
	SceneManager.goto_main_menu()


func cleanup_before_scene_change():
	"""Reset all global state that was modified during this cutscene"""
	print("Cleaning up before scene change...")

	# CRITICAL: Reset CutsceneDirector state (it's an autoload that persists!)
	CutsceneDirector.is_cutscene_active = false
	CutsceneDirector.active_cutscene_id = ""
	CutsceneDirector.current_actions.clear()
	CutsceneDirector.current_action_index = -1
	print("CutsceneDirector state reset")

	# Reset DialogueManager state (also an autoload)
	if DialogueManager.is_dialogue_active:
		DialogueManager.skip_dialogue()
	print("DialogueManager state reset")

	# Remove any FadeLayer we added to root (persists across scene changes!)
	var root = get_tree().root

	var fade_layer_node = root.get_node_or_null("FadeLayer")
	if fade_layer_node and is_instance_valid(fade_layer_node):
		fade_layer_node.queue_free()
		print("Queued FadeLayer for removal from root")

	# Clean up any cutscene players we added to root
	for child in root.get_children():
		if child.name == "FadeLayer" or child.name == "CutscenePlayer" or child.is_in_group("cutscene_player"):
			if is_instance_valid(child):
				child.queue_free()
				print("Queued lingering node for removal: ", child.name)

	# Reset EcholocationManager state
	if echolocation_manager:
		# Clear the callback we set
		echolocation_manager.echolocation_check_callback = Callable()
		# Reset fade duration to default
		echolocation_manager.echo_fade_duration = 3.5
		# Clear any active pulses
		echolocation_manager.echo_pulses.clear()
		print("EcholocationManager reset")

	# Re-enable player control if it was disabled
	if player and player.has_method("enable_control"):
		player.enable_control()

	# Re-enable hunger depletion (in case other levels need it)
	if player:
		var hunger_manager = player.get_node_or_null("HungerManager")
		if hunger_manager and hunger_manager.has_method("set_depletion_active"):
			hunger_manager.set_depletion_active(true)

	# Clean up radial glow if it still exists
	if radial_glow_instance:
		radial_glow_instance.queue_free()
		radial_glow_instance = null

	# Clean up god rays if they still exist
	if god_rays_instance:
		god_rays_instance.queue_free()
		god_rays_instance = null

	print("Cleanup complete")
