extends CanvasLayer

# References
@onready var darkness_overlay: ColorRect = $DarknessOverlay
@onready var player: CharacterBody2D = get_parent().get_node("Player")
@onready var camera: Camera2D = player.get_node("Camera2D")
@onready var echo_audio: AudioStreamPlayer = player.get_node("EchoAudioPlayer")
@onready var hunger_manager: Node = player.get_node("HungerManager")

# Echo animation sprite (created programmatically to render above darkness)
var echo_animation_sprite: AnimatedSprite2D

# Low hunger vignette overlay (created programmatically)
var vignette_overlay: ColorRect
var vignette_material: ShaderMaterial

# Vision settings
@export var vision_radius: float = 75.
@export var vision_fade_distance: float = 40.0  # How gradually the vision fades (higher = more gradual)
@export var darkness_intensity: float = 0.95

# Echolocation settings
@export var echo_reveal_distance: float = 800.0
@export var echo_fade_duration: float = 3.5  # seconds
@export var echo_expansion_speed: float = 1200.0  # pixels per second (how fast the wave expands)
@export var hunger_cost_percentage: float = 15.0  # Percentage of max hunger consumed per echo
@export var cooldown_duration: float = 0.3  # Cooldown between echolocation uses (seconds)

# Wave visual settings
@export var wave_thickness: float = 20.0  # How thick each wave ring is (thinner = more distinct rings)
@export var wave_brightness: float = 2.1  # How visible/bright the wave rings appear (0-1)
@export var wave_offset: float = 30.0  # How far ahead of the reveal the wave appears
@export var wave_ring_count: int = 5  # Number of concentric sound wave rings
@export var wave_ring_spacing: float = 35.0  # Spacing between each ring in pixels

# Vision mask style
@export var use_dithering: bool = false:  # Toggle between dithering (pixelated edge) and smooth fade
	set(value):
		use_dithering = value
		if shader_material:
			shader_material.set_shader_parameter("use_dithering", use_dithering)

# Echo ring animation (sprite-based visual effect)
@export var enable_echo_animation: bool = false  # Toggle for echo ring sprite animation

# Echolocation pulses (relative offset from player, intensity, and expansion radius)
var echo_pulses: Array = []  # Array of {relative_offset: Vector2, intensity: float, radius: float, age: float}

# Cooldown timer
var cooldown_remaining: float = 0.0

# Optional callback to check if echolocation should be allowed
# Set this from external scripts to control echolocation (e.g., final cutscene)
# Callback receives player position and should return true to allow, false to block
var echolocation_check_callback: Callable = Callable()

# Shader material
var shader_material: ShaderMaterial

# Low hunger vignette settings
@export var vignette_hunger_threshold: float = 20.0  # Show vignette below this hunger value
@export var vignette_max_intensity: float = 0.5  # Maximum vignette intensity
var vignette_pulse_time: float = 0.0  # Tracks pulse animation

func _ready():
	# Apply game mode settings for echolocation cost
	_apply_game_mode_settings()

	# Ensure darkness overlay is visible (in case it was disabled during level editing)
	darkness_overlay.visible = true

	# Create echo animation sprite (renders above darkness overlay in this CanvasLayer)
	if enable_echo_animation:
		_setup_echo_animation()

	# Create shader material
	shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://Shaders/vision_shader.gdshader")

	# Apply to darkness overlay
	darkness_overlay.material = shader_material

	# Set initial shader parameters
	shader_material.set_shader_parameter("vision_radius", vision_radius)
	shader_material.set_shader_parameter("vision_fade_distance", vision_fade_distance)
	shader_material.set_shader_parameter("darkness_intensity", darkness_intensity)
	shader_material.set_shader_parameter("echo_reveal_distance", echo_reveal_distance)
	shader_material.set_shader_parameter("wave_thickness", wave_thickness)
	shader_material.set_shader_parameter("wave_brightness", wave_brightness)
	shader_material.set_shader_parameter("wave_offset", wave_offset)
	shader_material.set_shader_parameter("wave_ring_count", wave_ring_count)
	shader_material.set_shader_parameter("wave_ring_spacing", wave_ring_spacing)
	shader_material.set_shader_parameter("use_dithering", use_dithering)

	# Initialize echo arrays
	update_echo_shader_params()

	# Create low hunger vignette overlay
	# _setup_vignette_overlay()  # DISABLED - user didn't like the effect

func _apply_game_mode_settings():
	"""Apply settings based on current game mode"""
	if GameModeManager:
		var config = GameModeManager.get_config()
		hunger_cost_percentage = config.hunger_cost_percentage
		print("EcholocationManager: Applied game mode settings - hunger_cost: ", hunger_cost_percentage, "%")

func _process(delta: float):
	# Update cooldown timer
	if cooldown_remaining > 0:
		cooldown_remaining -= delta

	# Update player position in shader
	var player_screen_pos = get_screen_position(player.global_position)
	shader_material.set_shader_parameter("player_position", player_screen_pos)

	# Update echo animation position to follow player (in screen space)
	if echo_animation_sprite and echo_animation_sprite.visible:
		echo_animation_sprite.position = player_screen_pos

	# Handle echolocation input
	if Input.is_action_just_pressed("echolocate") and can_use_echolocation():
		# Check external callback if set (allows external control of echolocation)
		if echolocation_check_callback.is_valid():
			if not echolocation_check_callback.call(player.global_position):
				return  # Callback blocked echolocation
		trigger_echolocation()

	# Update echolocation pulses (fade over time)
	update_echo_pulses(delta)

	# Update shader with current echo positions
	update_echo_shader_params()

	# Update low hunger vignette effect
	# _update_vignette(delta)  # DISABLED - user didn't like the effect

func can_use_echolocation() -> bool:
	# Cannot use echolocation during cutscenes
	if CutsceneDirector.is_cutscene_active:
		return false

	# Check cooldown
	if cooldown_remaining > 0:
		return false

	# Check if player has enough hunger to use echolocation
	if hunger_manager:
		var hunger_cost = hunger_manager.max_hunger * (hunger_cost_percentage / 100.0)
		return hunger_manager.current_hunger > hunger_cost

	return false

func trigger_echolocation():
	# Reset cooldown
	cooldown_remaining = cooldown_duration

	# Apply hunger cost
	if hunger_manager:
		var hunger_cost = hunger_manager.max_hunger * (hunger_cost_percentage / 100.0)
		hunger_manager.take_damage(hunger_cost)

	# Play echo sound
	if echo_audio:
		echo_audio.play()

	# Play echo ring animation centered on player (in screen space)
	if echo_animation_sprite:
		echo_animation_sprite.position = get_screen_position(player.global_position)
		echo_animation_sprite.visible = true
		echo_animation_sprite.frame = 0
		echo_animation_sprite.play("echo")

	# Create new echolocation pulse at player position
	# Store as relative offset (0,0) so it follows the player
	var pulse = {
		"relative_offset": Vector2.ZERO,  # Offset from player position
		"intensity": 1.0,
		"radius": 0.0,  # Starts at 0 and expands
		"age": 0.0  # Track how long the pulse has existed
	}
	echo_pulses.append(pulse)

	# Emit signal for enemies to detect echolocation
	echolocation_triggered.emit(player.global_position)

func update_echo_pulses(delta: float):
	# Update pulses: expand radius and fade over time
	for i in range(echo_pulses.size() - 1, -1, -1):
		# Increment age
		echo_pulses[i].age += delta

		# Expand the radius
		echo_pulses[i].radius += echo_expansion_speed * delta

		# Fade out intensity over time
		echo_pulses[i].intensity -= delta / echo_fade_duration

		# Remove fully faded pulses
		if echo_pulses[i].intensity <= 0.0:
			echo_pulses.remove_at(i)

func update_echo_shader_params():
	# Prepare arrays for shader (up to 10 pulses)
	var positions: Array = []
	var intensities: Array = []
	var radii: Array = []

	for i in range(10):
		if i < echo_pulses.size():
			# Calculate world position by adding relative offset to current player position
			var world_pos = player.global_position + echo_pulses[i].relative_offset
			var screen_pos = get_screen_position(world_pos)
			positions.append(screen_pos)
			intensities.append(echo_pulses[i].intensity)
			radii.append(echo_pulses[i].radius)
		else:
			positions.append(Vector2.ZERO)
			intensities.append(0.0)
			radii.append(0.0)

	# Update shader parameters
	shader_material.set_shader_parameter("echo_positions", positions)
	shader_material.set_shader_parameter("echo_intensities", intensities)
	shader_material.set_shader_parameter("echo_radii", radii)

func get_screen_position(world_pos: Vector2) -> Vector2:
	# Convert world position to screen position accounting for camera
	var viewport_size = get_viewport().get_visible_rect().size
	var camera_pos = camera.get_screen_center_position()
	var zoom = camera.zoom

	# Calculate offset from camera center
	var offset = (world_pos - camera_pos) * zoom

	# Convert to screen coordinates (center of screen + offset)
	var screen_pos = viewport_size / 2.0 + offset

	return screen_pos

# Signal for enemy detection (emitted when player uses echolocation)
signal echolocation_triggered(player_position: Vector2)

func _on_echo_animation_finished():
	# Hide the echo animation sprite when it finishes playing
	if echo_animation_sprite:
		echo_animation_sprite.visible = false

func _setup_echo_animation():
	"""Creates the echo ring animation sprite that plays when echolocation is triggered"""
	# Load the echo spritesheet texture
	var echo_texture = load("res://Assets/Art/Echo.png")
	if not echo_texture:
		push_warning("EcholocationManager: Could not load Echo.png")
		return

	# Create SpriteFrames with 6 frames (128x128 each from 768x128 spritesheet)
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("echo")
	sprite_frames.set_animation_loop("echo", false)
	sprite_frames.set_animation_speed("echo", 28.0)

	# Create atlas textures for each frame
	for i in range(9):
		var atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = echo_texture
		atlas_texture.region = Rect2(i * 256, 0, 256, 256)
		sprite_frames.add_frame("echo", atlas_texture)

	# Create the AnimatedSprite2D
	echo_animation_sprite = AnimatedSprite2D.new()
	echo_animation_sprite.sprite_frames = sprite_frames
	echo_animation_sprite.animation = "echo"
	echo_animation_sprite.visible = false
	echo_animation_sprite.z_index = 100  # Render above darkness overlay
	echo_animation_sprite.scale = Vector2(1.5, 1.5)  # Scale up the animation

	# Connect animation finished signal
	echo_animation_sprite.animation_finished.connect(_on_echo_animation_finished)

	# Add as child of this CanvasLayer (renders in screen space above darkness)
	add_child(echo_animation_sprite)

func _setup_vignette_overlay():
	"""Creates the red vignette overlay for low hunger warning"""
	# Create ColorRect that fills the entire screen
	vignette_overlay = ColorRect.new()
	vignette_overlay.name = "VignetteOverlay"

	# Set to fill entire viewport
	vignette_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block input

	# Create shader material
	vignette_material = ShaderMaterial.new()
	vignette_material.shader = load("res://Shaders/low_hunger_vignette.gdshader")

	# Set initial parameters
	vignette_material.set_shader_parameter("intensity", 0.0)
	vignette_material.set_shader_parameter("pulse", 0.0)
	vignette_material.set_shader_parameter("vignette_radius", 0.4)
	vignette_material.set_shader_parameter("vignette_softness", 0.5)

	# Apply shader to overlay
	vignette_overlay.material = vignette_material

	# Add as child (renders on top of darkness overlay)
	add_child(vignette_overlay)

func _update_vignette(delta: float):
	"""Updates the vignette effect based on current hunger level"""
	if not hunger_manager or not vignette_material:
		return

	var current_hunger = hunger_manager.current_hunger

	# Calculate vignette intensity based on hunger level
	var intensity = 0.0
	if current_hunger <= vignette_hunger_threshold:
		# Fade in vignette as hunger decreases
		# At threshold (20): intensity = 0
		# At 0 hunger: intensity = vignette_max_intensity
		intensity = (1.0 - (current_hunger / vignette_hunger_threshold)) * vignette_max_intensity

	# Update pulse animation (synced with heartbeat - about 1 beat per second)
	vignette_pulse_time += delta * 2.5  # 2.5 Hz pulse rate for more dramatic effect
	var pulse_value = (sin(vignette_pulse_time) + 1.0) / 2.0  # Oscillates 0 to 1

	# Only pulse when intensity is active
	if intensity > 0.0:
		vignette_material.set_shader_parameter("pulse", pulse_value)
	else:
		vignette_material.set_shader_parameter("pulse", 0.0)

	# Update intensity
	vignette_material.set_shader_parameter("intensity", intensity)
