extends Node
## CutsceneDirector autoload singleton
## Manages in-level cutscene sequences, player control, and scripted animations

# Signals
signal cutscene_started(cutscene_id: String)
signal cutscene_finished(cutscene_id: String)
signal cutscene_step_completed(step_index: int)

# Cutscene action types
enum ActionType {
	DIALOGUE,           # Show dialogue
	WAIT,              # Wait for duration
	PLAYER_WALK,       # Make player walk to position
	PLAYER_STOP,       # Stop player movement
	PLAYER_ANIMATE,    # Play player animation
	SPAWN_OBJECT,      # Spawn an object
	PLAY_SOUND,        # Play sound effect
	FULLSCREEN_CUTSCENE, # Play fullscreen cutscene
	CUSTOM_FUNCTION    # Call custom function
}

# Cutscene action data structure
class CutsceneAction:
	var type: ActionType
	var data: Dictionary = {}

	func _init(p_type: ActionType, p_data: Dictionary = {}):
		type = p_type
		data = p_data

# State variables
var active_cutscene_id: String = ""
var is_cutscene_active: bool = false
var current_actions: Array = []
var current_action_index: int = -1
var player_ref: Node2D = null
var player_controller_ref: Node = null
var hunger_manager_ref: Node = null

# Registered cutscene sequences
var cutscene_sequences: Dictionary = {}

func _ready():
	# Try to find player reference
	_find_player()

func _find_player():
	"""Find the player in the scene tree"""
	await get_tree().process_frame

	# Clear old references (they may be stale from previous scene)
	player_ref = null
	player_controller_ref = null
	hunger_manager_ref = null

	player_ref = get_tree().get_first_node_in_group("Player")

	if player_ref:
		print("CutsceneDirector: Found player at position ", player_ref.global_position)

		# The player CharacterBody2D IS the controller (has PlatformerController2D class)
		if player_ref.has_method("disable_control"):
			player_controller_ref = player_ref
			print("CutsceneDirector: Player IS the controller")
		else:
			# Fallback: try to find controller in children
			for child in player_ref.get_children():
				if child.has_method("disable_control"):
					player_controller_ref = child
					print("CutsceneDirector: Found player controller: ", player_controller_ref.name)
					break

		# Find HungerManager (should be a child of player)
		for child in player_ref.get_children():
			if child.name == "HungerManager" or child.has_method("set_depletion_active"):
				hunger_manager_ref = child
				print("CutsceneDirector: Found HungerManager: ", child.name)
				break
	else:
		push_warning("CutsceneDirector: Could not find player in 'Player' group")

func register_cutscene(cutscene_id: String, actions: Array) -> void:
	"""Register a cutscene sequence with an ID"""
	cutscene_sequences[cutscene_id] = actions
	print("CutsceneDirector: Registered cutscene '%s' with %d actions" % [cutscene_id, actions.size()])

func play_cutscene(cutscene_id: String) -> void:
	"""Play a registered cutscene by ID"""
	if is_cutscene_active:
		push_warning("CutsceneDirector: Cannot start cutscene while one is active")
		return

	if not cutscene_sequences.has(cutscene_id):
		push_error("CutsceneDirector: Cutscene '%s' not registered" % cutscene_id)
		return

	_start_cutscene(cutscene_id, cutscene_sequences[cutscene_id])

func play_cutscene_direct(cutscene_id: String, actions: Array) -> void:
	"""Play a cutscene directly without registering"""
	if is_cutscene_active:
		push_warning("CutsceneDirector: Cannot start cutscene while one is active")
		return

	_start_cutscene(cutscene_id, actions)

func _start_cutscene(cutscene_id: String, actions: Array) -> void:
	"""Internal method to start a cutscene"""
	active_cutscene_id = cutscene_id
	is_cutscene_active = true
	current_actions = actions
	current_action_index = -1

	# Always re-find player to ensure reference is valid for current scene
	# (player instance changes between level loads)
	await _find_player()

	if not player_ref:
		push_error("CutsceneDirector: Cannot start cutscene - player not found!")
		_end_cutscene()
		return

	cutscene_started.emit(cutscene_id)
	print("CutsceneDirector: Starting cutscene '%s'" % cutscene_id)

	# Disable player control
	disable_player_control()

	# Execute actions sequentially
	await _execute_next_action()

func _execute_next_action() -> void:
	"""Execute the next action in the sequence"""
	current_action_index += 1

	if current_action_index >= current_actions.size():
		# All actions complete
		_end_cutscene()
		return

	var action: CutsceneAction = current_actions[current_action_index]
	cutscene_step_completed.emit(current_action_index)

	# Execute the action based on type
	match action.type:
		ActionType.DIALOGUE:
			await _action_dialogue(action.data)
		ActionType.WAIT:
			await _action_wait(action.data)
		ActionType.PLAYER_WALK:
			await _action_player_walk(action.data)
		ActionType.PLAYER_STOP:
			await _action_player_stop(action.data)
		ActionType.PLAYER_ANIMATE:
			await _action_player_animate(action.data)
		ActionType.SPAWN_OBJECT:
			await _action_spawn_object(action.data)
		ActionType.PLAY_SOUND:
			await _action_play_sound(action.data)
		ActionType.FULLSCREEN_CUTSCENE:
			await _action_fullscreen_cutscene(action.data)
		ActionType.CUSTOM_FUNCTION:
			await _action_custom_function(action.data)

	# Continue to next action
	if is_cutscene_active:
		await _execute_next_action()

# Action implementations
func _action_dialogue(data: Dictionary) -> void:
	"""Show dialogue"""
	var lines = data.get("lines", [])
	var audio_paths = data.get("audio_paths", [])
	if lines.is_empty():
		return

	# Check if we have audio paths - if so, create DialogueLines with audio
	if not audio_paths.is_empty():
		var dialogue_lines: Array[DialogueManager.DialogueLine] = []
		for i in range(lines.size()):
			var text = lines[i]
			var audio_path = ""
			if i < audio_paths.size():
				audio_path = audio_paths[i]
			dialogue_lines.append(DialogueManager.DialogueLine.new(text, "", 0.0, Callable(), audio_path))
		DialogueManager.start_dialogue(dialogue_lines)
	else:
		DialogueManager.start_simple_dialogue(lines)
	await DialogueManager.dialogue_finished

func _action_wait(data: Dictionary) -> void:
	"""Wait for a duration"""
	var duration = data.get("duration", 1.0)
	await get_tree().create_timer(duration).timeout

func _action_player_walk(data: Dictionary) -> void:
	"""Make player walk to a position"""
	var target_x = data.get("target_x", 0.0)
	var speed = data.get("speed", 50.0)

	if not player_ref:
		print("CutsceneDirector: ERROR - No player_ref in walk action")
		return

	print("CutsceneDirector: Starting walk action from ", player_ref.global_position.x, " to ", target_x)

	# Find the player's AnimatedSprite2D
	var anim_sprite: AnimatedSprite2D = null

	# Try common node names first
	if player_ref.has_node("AnimatedSprite2D"):
		anim_sprite = player_ref.get_node("AnimatedSprite2D")
		print("CutsceneDirector: Found AnimatedSprite2D by name")
	elif player_ref.has_node("PlayerSprite"):
		anim_sprite = player_ref.get_node("PlayerSprite")
		print("CutsceneDirector: Found PlayerSprite by name")
	else:
		# Fallback: search children
		print("CutsceneDirector: Searching for AnimatedSprite2D in children...")
		for child in player_ref.get_children():
			print("  - Child: ", child.name, " Type: ", child.get_class())
			if child is AnimatedSprite2D:
				anim_sprite = child
				print("CutsceneDirector: Found AnimatedSprite2D by type: ", child.name)
				break

	if not anim_sprite:
		push_warning("CutsceneDirector: Could not find AnimatedSprite2D for player walk animation")
		return

	# Simple walk-to-position implementation
	var start_x = player_ref.global_position.x
	var direction = sign(target_x - start_x)

	print("CutsceneDirector: Direction = ", direction, ", control_enabled = ", player_ref.control_enabled)
	print("CutsceneDirector: Current animation = ", anim_sprite.animation)
	print("CutsceneDirector: Available animations = ", anim_sprite.sprite_frames.get_animation_names())

	# Start walk animation
	anim_sprite.play("walk")
	anim_sprite.flip_h = (direction < 0)  # Flip sprite based on direction
	print("CutsceneDirector: Set animation to 'walk', flip_h = ", anim_sprite.flip_h)
	print("CutsceneDirector: Animation is now = ", anim_sprite.animation, ", is_playing = ", anim_sprite.is_playing())

	# Find the walking audio player
	var walking_audio: AudioStreamPlayer = null
	if player_ref.has_node("WalkingAudioPlayer"):
		walking_audio = player_ref.get_node("WalkingAudioPlayer")
		print("CutsceneDirector: Found WalkingAudioPlayer")

	# Walking sound timing
	var walking_sound_timer: float = 0.0
	var walking_sound_interval: float = 0.3  # Time between footsteps

	var frames = 0
	while abs(player_ref.global_position.x - target_x) > 2.0:
		if not is_cutscene_active:
			break

		player_ref.global_position.x += direction * speed * get_process_delta_time()
		frames += 1

		# Play walking sound at intervals
		if walking_audio:
			walking_sound_timer -= get_process_delta_time()
			if walking_sound_timer <= 0:
				walking_audio.play()
				walking_sound_timer = walking_sound_interval

		# Check animation every 30 frames
		if frames % 30 == 0:
			print("CutsceneDirector: Still walking... animation = ", anim_sprite.animation, ", pos = ", player_ref.global_position.x)

		await get_tree().process_frame

	# Stop walking sound
	if walking_audio and walking_audio.playing:
		walking_audio.stop()

	# Stop animation and return to idle
	anim_sprite.play("idle")
	print("CutsceneDirector: Walk complete, playing idle animation")

func _action_player_stop(data: Dictionary) -> void:
	"""Stop player movement"""
	# Player is already stopped since control is disabled
	await get_tree().process_frame

func _action_player_animate(data: Dictionary) -> void:
	"""Play a player animation"""
	var animation_name = data.get("animation", "idle")
	# TODO: Implement animation playing
	await get_tree().process_frame

func _action_spawn_object(data: Dictionary) -> void:
	"""Spawn an object in the scene"""
	var scene_path = data.get("scene_path", "")
	var position = data.get("position", Vector2.ZERO)
	var call_method = data.get("call_method", "")

	if scene_path.is_empty():
		return

	var scene = load(scene_path)
	if scene:
		var instance = scene.instantiate()
		instance.global_position = position
		get_tree().current_scene.add_child(instance)

		# Call method on spawned object if specified
		if not call_method.is_empty() and instance.has_method(call_method):
			instance.call(call_method)

	await get_tree().process_frame

func _action_play_sound(data: Dictionary) -> void:
	"""Play a sound effect"""
	var sound_path = data.get("sound_path", "")
	# TODO: Implement sound playing
	await get_tree().process_frame

func _action_fullscreen_cutscene(data: Dictionary) -> void:
	"""Play a fullscreen cutscene"""
	var frames = data.get("frames", [])

	if frames.is_empty():
		return

	# Find or create CutscenePlayer
	var cutscene_player = get_tree().get_first_node_in_group("cutscene_player")
	if not cutscene_player:
		var cutscene_player_scene = load("res://UI/CutscenePlayer/cutscene_player.tscn")
		if cutscene_player_scene:
			cutscene_player = cutscene_player_scene.instantiate()
			get_tree().root.add_child(cutscene_player)

	if cutscene_player and cutscene_player.has_method("play_cutscene"):
		cutscene_player.play_cutscene(frames)
		await cutscene_player.cutscene_finished

func _action_custom_function(data: Dictionary) -> void:
	"""Call a custom function"""
	var callable: Callable = data.get("function", Callable())
	if callable.is_valid():
		callable.call()
	await get_tree().process_frame

func _end_cutscene() -> void:
	"""End the current cutscene"""
	var cutscene_id = active_cutscene_id

	is_cutscene_active = false
	active_cutscene_id = ""
	current_actions.clear()
	current_action_index = -1

	# Re-enable player control
	enable_player_control()

	cutscene_finished.emit(cutscene_id)
	print("CutsceneDirector: Finished cutscene '%s'" % cutscene_id)

func disable_player_control() -> void:
	"""Disable player input and control"""
	if player_controller_ref and player_controller_ref.has_method("disable_control"):
		player_controller_ref.disable_control()
		print("CutsceneDirector: Disabled player control")
	elif player_controller_ref:
		# Fallback: disable physics processing
		player_controller_ref.set_physics_process(false)
		print("CutsceneDirector: Disabled player physics processing")

	# Pause hunger depletion during cutscene
	if hunger_manager_ref and hunger_manager_ref.has_method("set_depletion_active"):
		hunger_manager_ref.set_depletion_active(false)
		print("CutsceneDirector: Paused hunger depletion")

func enable_player_control() -> void:
	"""Re-enable player input and control"""
	if player_controller_ref and player_controller_ref.has_method("enable_control"):
		player_controller_ref.enable_control()
		print("CutsceneDirector: Enabled player control")
	elif player_controller_ref:
		# Fallback: enable physics processing
		player_controller_ref.set_physics_process(true)
		print("CutsceneDirector: Enabled player physics processing")

	# Resume hunger depletion after cutscene
	if hunger_manager_ref and hunger_manager_ref.has_method("set_depletion_active"):
		hunger_manager_ref.set_depletion_active(true)
		print("CutsceneDirector: Resumed hunger depletion")

func is_active() -> bool:
	"""Check if a cutscene is currently active"""
	return is_cutscene_active

# Helper functions to create actions
static func action_dialogue(lines: Array, audio_paths: Array = []) -> CutsceneAction:
	var data = {"lines": lines}
	if not audio_paths.is_empty():
		data["audio_paths"] = audio_paths
	return CutsceneAction.new(ActionType.DIALOGUE, data)

static func action_wait(duration: float) -> CutsceneAction:
	return CutsceneAction.new(ActionType.WAIT, {"duration": duration})

static func action_player_walk(target_x: float, speed: float = 50.0) -> CutsceneAction:
	return CutsceneAction.new(ActionType.PLAYER_WALK, {"target_x": target_x, "speed": speed})

static func action_spawn_object(scene_path: String, position: Vector2, call_method: String = "") -> CutsceneAction:
	var data = {"scene_path": scene_path, "position": position}
	if not call_method.is_empty():
		data["call_method"] = call_method
	return CutsceneAction.new(ActionType.SPAWN_OBJECT, data)

static func action_fullscreen_cutscene(frames: Array) -> CutsceneAction:
	return CutsceneAction.new(ActionType.FULLSCREEN_CUTSCENE, {"frames": frames})

static func action_custom(function: Callable) -> CutsceneAction:
	return CutsceneAction.new(ActionType.CUSTOM_FUNCTION, {"function": function})
