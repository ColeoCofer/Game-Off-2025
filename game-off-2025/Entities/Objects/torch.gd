extends Node2D

# Torch light parameters
@export var light_energy: float = 2.0
@export var light_flicker_speed: float = 3.0
@export var light_flicker_intensity: float = 0.2

var time_passed: float = 0.0

func _ready():
	# Play the animation if it exists
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("idle")

	# Set up initial light energy
	if has_node("PointLight2D"):
		$PointLight2D.energy = light_energy

func _process(delta):
	# Create a flickering fire effect for the light
	time_passed += delta

	if has_node("PointLight2D"):
		# Combine multiple sine waves for more organic flickering
		var flicker1 = sin(time_passed * light_flicker_speed) * light_flicker_intensity
		var flicker2 = sin(time_passed * light_flicker_speed * 1.7) * (light_flicker_intensity * 0.5)
		var flicker3 = sin(time_passed * light_flicker_speed * 2.3) * (light_flicker_intensity * 0.3)

		$PointLight2D.energy = light_energy + flicker1 + flicker2 + flicker3
