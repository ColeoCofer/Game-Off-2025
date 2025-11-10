extends Area2D

# Export variables
@export var damage_amount: float = 10.0
@export var projectile_gravity: float = 980.0  # Pixels per second squared
@export var max_lifetime: float = 5.0  # Auto-destroy after this many seconds
@export var splatter_duration: float = 0.3  # How long to show splatter before destroying

# Movement
var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 0.0
var is_splattering: bool = false

# References
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	# Connect collision signal
	body_entered.connect(_on_body_entered)

	# Play flying animation
	if animated_sprite:
		animated_sprite.play("flying")

func _physics_process(delta: float):
	if is_splattering:
		return

	# Apply gravity
	velocity.y += projectile_gravity * delta

	# Move projectile
	position += velocity * delta

	# Track lifetime
	lifetime += delta
	if lifetime >= max_lifetime:
		queue_free()

# Initialize projectile with target position
func launch_at_target(target_position: Vector2, arc_height: float = 200.0, flight_time: float = 1.2):
	# Calculate trajectory to reach target in flight_time seconds
	var displacement = target_position - global_position

	# Calculate horizontal velocity (constant)
	velocity.x = displacement.x / flight_time

	# Calculate vertical velocity to reach arc_height and then land at target
	# Using kinematic equation: v = (d - 0.5*g*t²) / t
	velocity.y = (displacement.y - 0.5 * projectile_gravity * flight_time * flight_time) / flight_time

	# Add extra upward velocity for the arc
	velocity.y -= sqrt(2.0 * projectile_gravity * arc_height)

func _on_body_entered(body: Node2D):
	if is_splattering:
		return

	# Check if hit player
	if body.is_in_group("Player") or body is PlatformerController2D:
		_damage_player(body)
		_splatter()
	# Check if hit ground/walls
	elif body is TileMap or body is StaticBody2D:
		_splatter()

func _damage_player(player: Node2D):
	# Find and damage player's hunger
	var hunger_manager = player.get_node_or_null("HungerManager")
	if hunger_manager and hunger_manager.has_method("take_damage"):
		hunger_manager.take_damage(damage_amount)

func _splatter():
	if is_splattering:
		return

	is_splattering = true
	velocity = Vector2.ZERO

	# Disable collision
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	# Play splatter animation
	if animated_sprite and animated_sprite.sprite_frames.has_animation("splatter"):
		animated_sprite.play("splatter")

	# Destroy after splatter animation
	await get_tree().create_timer(splatter_duration).timeout
	queue_free()
