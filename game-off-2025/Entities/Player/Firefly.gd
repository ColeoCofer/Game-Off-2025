extends Node2D

## Firefly companion that orbits around the player
## Glows with a bright yellow light and follows the bat

@export var orbit_radius_min: float = 15.0  # Minimum orbit distance
@export var orbit_radius_max: float = 25.0  # Maximum orbit distance
@export var orbit_speed: float = 1.5  # Base orbit speed (radians per second)
@export var orbit_variation: float = 0.8  # Speed variation for natural movement
@export var float_amplitude: float = 4.0  # Vertical floating range
@export var float_speed: float = 2.0  # Speed of floating motion
@export var drift_amount: float = 8.0  # How much it drifts from perfect circle
@export var glow_pulse_speed: float = 3.5  # Speed of glow pulsing
@export var glow_min: float = 0.75  # Minimum glow brightness
@export var glow_max: float = 1.0  # Maximum glow brightness

var time: float = 0.0
var orbit_angle: float = 0.0
var noise_offset: float = 0.0
var previous_position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO

@onready var light: PointLight2D = $PointLight2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var trail_particles: CPUParticles2D = $TrailParticles

func _ready():
	# Start at a random angle for variety
	orbit_angle = randf() * TAU
	time = randf() * TAU
	noise_offset = randf() * 1000.0
	previous_position = position

func _process(delta: float):
	time += delta

	# Variable orbit speed for more organic movement
	var speed_variation = sin(time * orbit_variation) * 0.3 + 1.0
	orbit_angle += orbit_speed * speed_variation * delta

	# Dynamic orbit radius that changes over time
	var radius_variation = sin(time * 0.7) * 0.5 + 0.5
	var current_radius = lerp(orbit_radius_min, orbit_radius_max, radius_variation)

	# Calculate base position in orbit
	var base_x = cos(orbit_angle) * current_radius
	var base_y = sin(orbit_angle) * current_radius

	# Add organic floating with multiple sine waves
	var float_offset_y = sin(time * float_speed) * float_amplitude
	float_offset_y += sin(time * float_speed * 1.7 + 2.0) * (float_amplitude * 0.3)

	# Add drift using perlin-like noise simulation
	var drift_x = sin(time * 1.3 + noise_offset) * drift_amount
	var drift_y = cos(time * 0.9 + noise_offset + 5.0) * drift_amount * 0.5

	# Combine all movements for natural motion
	var target_pos = Vector2(base_x + drift_x, base_y + float_offset_y + drift_y)

	# Smooth movement with lerp
	position = position.lerp(target_pos, 1.0 - exp(-10.0 * delta))

	# Calculate velocity for shader
	velocity = (position - previous_position) / delta if delta > 0 else Vector2.ZERO
	previous_position = position

	# Update shader with velocity for motion blur
	if sprite and sprite.material:
		sprite.material.set_shader_parameter("velocity", velocity)

	# Pulse the glow with variation
	var glow_intensity = lerp(glow_min, glow_max, (sin(time * glow_pulse_speed) + 1.0) / 2.0)
	glow_intensity *= (1.0 + sin(time * glow_pulse_speed * 2.3) * 0.1)  # Add subtle flicker

	if light:
		light.energy = glow_intensity
	if sprite:
		sprite.modulate.a = glow_intensity
