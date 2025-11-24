extends Area2D
## Photo shard collectible that appears in cutscenes
## A piece of a torn photograph that triggers story moments

signal photo_shard_collected

# Hovering/bobbing animation parameters
@export var hover_amplitude: float = 2.0
@export var hover_speed: float = 1.5
@export var glow_pulse_speed: float = 1.8

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

	# Store base glow energy
	if light:
		base_glow_energy = light.energy

func _process(delta):
	# Create a gentle hovering/bobbing effect
	time_passed += delta
	position.y = initial_y + sin(time_passed * hover_speed) * hover_amplitude

	# Subtle glow pulse
	if light:
		var pulse = 1.0 + sin(time_passed * glow_pulse_speed) * 0.2
		light.energy = base_glow_energy * pulse

func _on_body_entered(body: Node2D):
	# Check if the body that entered is the player
	if is_collected:
		return

	if body.name == "Player" or body is CharacterBody2D:
		collect()

func collect():
	"""Collect the photo shard"""
	if is_collected:
		return

	is_collected = true
	photo_shard_collected.emit()
	queue_free()

func play_spawn_animation():
	"""Spawn animation - currently just starts bobbing"""
	pass
