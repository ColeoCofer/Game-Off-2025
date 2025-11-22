extends CanvasLayer

# References
@onready var darkness_overlay: ColorRect = $DarknessOverlay
@onready var player: CharacterBody2D = get_parent().get_node("Player")
@onready var camera: Camera2D = player.get_node("Camera2D")
@onready var echo_audio: AudioStreamPlayer = player.get_node("EchoAudioPlayer")
@onready var hunger_manager: Node = player.get_node("HungerManager")

# Vision settings
@export var vision_radius: float = 75.
@export var vision_fade_distance: float = 40.0  # How gradually the vision fades (higher = more gradual)
@export var darkness_intensity: float = 0.95

# Echolocation settings
@export var echo_reveal_distance: float = 800.0
@export var echo_fade_duration: float = 3.5  # seconds
@export var echo_expansion_speed: float = 1200.0  # pixels per second (how fast the wave expands)
@export var hunger_cost_percentage: float = 15.0  # Percentage of max hunger consumed per echo

# Wave visual settings
@export var wave_thickness: float = 60.0  # How thick the visible wave ring is
@export var wave_brightness: float = 0.4  # How visible/bright the wave ring appears (0-1)
@export var wave_offset: float = 40.0  # How far ahead of the reveal the wave appears

# Echolocation pulses (relative offset from player, intensity, and expansion radius)
var echo_pulses: Array = []  # Array of {relative_offset: Vector2, intensity: float, radius: float, age: float}

# Shader material
var shader_material: ShaderMaterial

func _ready():
	# Ensure darkness overlay is visible (in case it was disabled during level editing)
	darkness_overlay.visible = true

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

	# Initialize echo arrays
	update_echo_shader_params()

func _process(delta: float):
	# Update player position in shader
	var player_screen_pos = get_screen_position(player.global_position)
	shader_material.set_shader_parameter("player_position", player_screen_pos)

	# Handle echolocation input
	if Input.is_action_just_pressed("echolocate") and can_use_echolocation():
		trigger_echolocation()

	# Update echolocation pulses (fade over time)
	update_echo_pulses(delta)

	# Update shader with current echo positions
	update_echo_shader_params()

func can_use_echolocation() -> bool:
	# Check if player has enough hunger to use echolocation
	if hunger_manager:
		var hunger_cost = hunger_manager.max_hunger * (hunger_cost_percentage / 100.0)
		return hunger_manager.current_hunger > hunger_cost
	return false

func trigger_echolocation():
	# Apply hunger cost
	if hunger_manager:
		var hunger_cost = hunger_manager.max_hunger * (hunger_cost_percentage / 100.0)
		hunger_manager.take_damage(hunger_cost)

	# Play echo sound
	if echo_audio:
		echo_audio.play()

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
