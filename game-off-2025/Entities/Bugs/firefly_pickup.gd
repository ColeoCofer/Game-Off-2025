extends Area2D

## Collectible firefly that grants the player a shield
## When collected, spawns a firefly companion that protects from one hit

signal firefly_collected

# Movement animation parameters
@export var orbit_radius: float = 8.0
@export var orbit_speed: float = 3.0
@export var float_amplitude: float = 2.0
@export var float_speed: float = 2.5
@export var collection_duration: float = 0.5

var time_passed: float = 0.0
var initial_position: Vector2
var orbit_angle: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var light: PointLight2D = $PointLight2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	# Store initial position
	initial_position = position
	orbit_angle = randf() * TAU

	# Connect to the body_entered signal
	body_entered.connect(_on_body_entered)

func _process(delta):
	time_passed += delta

	# Orbit in a circle
	orbit_angle += orbit_speed * delta
	var orbit_offset = Vector2(
		cos(orbit_angle) * orbit_radius,
		sin(orbit_angle) * orbit_radius
	)

	# Add gentle floating
	var float_offset = Vector2(0, sin(time_passed * float_speed) * float_amplitude)

	# Apply combined movement
	position = initial_position + orbit_offset + float_offset

func _on_body_entered(body: Node2D):
	# Check if the body that entered is the player
	if body is PlatformerController2D:
		# Give player the firefly shield
		var firefly_manager = body.get_node_or_null("FireflyManager")
		if firefly_manager:
			firefly_manager.collect_firefly()

		# Emit signal
		firefly_collected.emit()

		# Play collection animation and remove
		_collect_animation()

func _collect_animation():
	# Stop movement effect
	set_process(false)

	# Disable collision so player can't collect twice
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	# Fly to player animation
	var tween = create_tween()
	tween.set_parallel(true)

	# Bright flash
	if light:
		tween.tween_property(light, "energy", 3.0, collection_duration * 0.3)

	# Scale up and fade
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), collection_duration)
	tween.tween_property(self, "modulate:a", 0.0, collection_duration * 0.7).set_delay(collection_duration * 0.3)

	# Remove after animation
	tween.finished.connect(queue_free)
