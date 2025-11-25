extends Area2D
## Photo shard collectible that appears in cutscenes and levels
## A piece of a torn photograph that triggers story moments and level completion

signal photo_shard_collected

# Hovering/bobbing animation parameters
@export var hover_amplitude: float = 2.0
@export var hover_speed: float = 1.5
@export var glow_pulse_speed: float = 1.8

# Level configuration
@export var level_name: String = ""  # Set this to the level name (e.g., "level-1", "level-2")
@export_enum("Level Completion", "Cutscene Only") var shard_type: String = "Level Completion"  # Type of photo shard behavior
@export var force_show_for_testing: bool = false  # If true, always show even if already collected

var time_passed: float = 0.0
var initial_y: float = 0.0
var is_collected: bool = false
var base_glow_energy: float = 0.8

@onready var sprite: Sprite2D = $Sprite2D
@onready var light: PointLight2D = $PointLight2D if has_node("PointLight2D") else null

func _ready():
	# Store initial position for hovering effect
	initial_y = position.y

	# Connect to the body_entered signal for player interaction
	body_entered.connect(_on_body_entered)
	print("PhotoShard: _ready called, level_name = ", level_name)
	print("PhotoShard: Collision monitoring = ", monitoring)
	print("PhotoShard: CollisionShape2D disabled = ", $CollisionShape2D.disabled if has_node("CollisionShape2D") else "NO COLLISION SHAPE")

	# Store base glow energy
	if light:
		base_glow_energy = light.energy

	# Check if this shard has already been collected (unless force_show_for_testing is enabled)
	if not force_show_for_testing and not level_name.is_empty() and SaveManager.is_photo_shard_collected(level_name):
		# Already collected, hide and disable
		visible = false
		set_process(false)
		$CollisionShape2D.set_deferred("disabled", true)
		print("PhotoShard: Already collected for ", level_name, " - hiding")

	if force_show_for_testing:
		print("PhotoShard: force_show_for_testing is enabled - showing even if collected")

func _process(delta):
	# Create a gentle hovering/bobbing effect
	time_passed += delta
	position.y = initial_y + sin(time_passed * hover_speed) * hover_amplitude

	# Subtle glow pulse
	if light:
		var pulse = 1.0 + sin(time_passed * glow_pulse_speed) * 0.2
		light.energy = base_glow_energy * pulse

func _on_body_entered(body: Node2D):
	print("PhotoShard: body_entered triggered! Body: ", body.name, " Type: ", body.get_class())

	# Check if the body that entered is the player
	if is_collected:
		print("PhotoShard: Already collected, ignoring")
		return

	if body.name == "Player" or body is CharacterBody2D:
		print("PhotoShard: Player detected, starting collection!")
		await collect(body)
	else:
		print("PhotoShard: Not the player, ignoring")

func collect(player: Node2D):
	"""Collect the photo shard and trigger appropriate behavior based on shard_type"""
	if is_collected:
		return

	is_collected = true
	print("PhotoShard: Collected! Type: ", shard_type)

	# IMMEDIATELY disable collision so player can fall through
	$CollisionShape2D.set_deferred("disabled", true)

	# Emit signal
	photo_shard_collected.emit()

	# If this is a cutscene-only shard, just hide it and return
	if shard_type == "Cutscene Only":
		print("PhotoShard: Cutscene-only shard - just hiding")
		visible = false
		return

	# Otherwise, do the full level completion sequence
	print("PhotoShard: Level completion shard - starting sequence")

	# Set player to idle animation
	var anim_sprite: AnimatedSprite2D = null
	if player.has_node("AnimatedSprite2D"):
		anim_sprite = player.get_node("AnimatedSprite2D")
		if anim_sprite:
			anim_sprite.play("idle")
			print("PhotoShard: Set player to idle animation")

	# Let player fall to ground if in air - wait for them to land naturally
	if player is CharacterBody2D and not player.is_on_floor():
		print("PhotoShard: Player in air, waiting for landing...")

		var max_wait_time = 2.0  # Wait up to 2 seconds
		var time_waited = 0.0

		while not player.is_on_floor() and time_waited < max_wait_time:
			# Don't disable control yet - let player fall naturally
			player.velocity.x = 0  # Just stop horizontal movement
			await get_tree().process_frame
			time_waited += get_process_delta_time()

		if player.is_on_floor():
			print("PhotoShard: Player landed")
		else:
			print("PhotoShard: Timeout waiting for landing, proceeding anyway")

	# NOW disable player control (after landing or timeout)
	if player.has_method("disable_control"):
		player.disable_control()
		print("PhotoShard: Disabled player control")

	# Stop timer
	if TimerManager.current_timer_ui and TimerManager.current_timer_ui.has_method("stop_timer"):
		TimerManager.current_timer_ui.stop_timer()
		print("PhotoShard: Stopped timer")

	# Stop hunger depletion
	var hunger_manager = player.get_node_or_null("HungerManager")
	if hunger_manager and hunger_manager.has_method("set_depletion_active"):
		hunger_manager.set_depletion_active(false)
		print("PhotoShard: Stopped hunger depletion")

	# Wait a moment before dialogue
	print("PhotoShard: Waiting before dialogue...")
	await get_tree().create_timer(0.3).timeout

	# Show dialogue with audio
	print("PhotoShard: Starting dialogue...")
	var dialogue_line = DialogueManager.DialogueLine.new(
		"Huh, I found another photo scrap...",
		"",
		0.0,
		Callable(),
		"res://Assets/Audio/dialogue/27 i know what i need to do-1.wav"
	)
	DialogueManager.start_dialogue([dialogue_line])
	print("PhotoShard: Waiting for dialogue to finish...")
	await DialogueManager.dialogue_finished
	print("PhotoShard: Dialogue finished!")

	# Hide the shard immediately after dialogue
	visible = false
	print("PhotoShard: Hidden shard")

	# Mark as collected in save data
	if not level_name.is_empty():
		SaveManager.mark_photo_shard_collected(level_name)
		print("PhotoShard: Marked as collected in save data")

	# Auto-walk to cave entrance
	print("PhotoShard: Starting auto-walk to exit...")
	await walk_player_to_exit(player)
	print("PhotoShard: Finished walking to exit")

func walk_player_to_exit(player: Node2D):
	"""Automatically walk the player to the cave entrance"""
	# Find the cave entrance (it's in the "CaveEntrance" group)
	var cave_entrance = get_tree().get_first_node_in_group("CaveEntrance")
	if not cave_entrance:
		push_warning("PhotoShard: Could not find cave entrance!")
		return

	print("PhotoShard: Found cave entrance: ", cave_entrance.name)

	# Get player's animated sprite for animation
	var anim_sprite: AnimatedSprite2D = null
	if player.has_node("AnimatedSprite2D"):
		anim_sprite = player.get_node("AnimatedSprite2D")

	# Calculate walk direction
	var target_x = cave_entrance.global_position.x
	var start_x = player.global_position.x
	var distance = abs(target_x - start_x)
	var direction = sign(target_x - start_x)
	var walk_speed = 80.0

	print("PhotoShard: Player at ", start_x, ", Cave entrance at ", target_x)
	print("PhotoShard: Distance: ", distance, ", Direction: ", direction)

	if distance <= 10.0:
		print("PhotoShard: Player is already at cave entrance (distance: ", distance, ")")
		return

	# Start walk animation
	if anim_sprite:
		anim_sprite.play("walk")
		anim_sprite.flip_h = (direction < 0)

	# Walk to the entrance - use CharacterBody2D's velocity system
	if player is CharacterBody2D:
		var frames = 0
		while abs(player.global_position.x - target_x) > 10.0:
			# Set velocity and use move_and_slide
			player.velocity.x = direction * walk_speed
			player.velocity.y = 0  # Keep grounded
			player.move_and_slide()

			frames += 1
			if frames % 30 == 0:
				print("PhotoShard: Walking... pos: ", player.global_position.x, " target: ", target_x, " distance: ", abs(player.global_position.x - target_x))

			await get_tree().process_frame

		# Stop movement
		player.velocity = Vector2.ZERO
	else:
		# Fallback: direct position manipulation
		print("PhotoShard: Player is NOT CharacterBody2D, using fallback")
		while abs(player.global_position.x - target_x) > 10.0:
			player.global_position.x += direction * walk_speed * get_process_delta_time()
			await get_tree().process_frame

	# Stop animation
	if anim_sprite:
		anim_sprite.play("idle")

	print("PhotoShard: Player reached cave entrance")

func play_spawn_animation():
	"""Spawn animation - currently just starts bobbing"""
	pass
