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
var frame_count: int = 0

# References
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	print("Projectile _ready() called at position: ", global_position)
	print("Projectile collision_layer: ", collision_layer)
	print("Projectile collision_mask: ", collision_mask)

	# Connect collision signal
	var result = body_entered.connect(_on_body_entered)
	print("Projectile: body_entered signal connected: ", result == OK)

	# Play flying animation
	if animated_sprite:
		print("Projectile: Playing flying animation")
		animated_sprite.play("flying")
	else:
		print("Projectile: ERROR - No AnimatedSprite2D found!")

	# Check collision shape
	if collision_shape:
		print("Projectile: CollisionShape2D found, disabled: ", collision_shape.disabled)
	else:
		print("Projectile: ERROR - No CollisionShape2D found!")

func _physics_process(delta: float):
	if is_splattering:
		return

	frame_count += 1
	if frame_count == 1 or frame_count % 30 == 0:
		print("Projectile frame ", frame_count, " - pos: ", global_position, " vel: ", velocity)

	# Apply gravity
	velocity.y += projectile_gravity * delta

	# Move projectile
	position += velocity * delta

	# Track lifetime
	lifetime += delta
	if lifetime >= max_lifetime:
		print("Projectile reached max lifetime, destroying")
		queue_free()

# Initialize projectile with target position
func launch_at_target(target_position: Vector2, arc_height: float = 35, flight_time: float = 1.0):
	print("Projectile: launch_at_target called")
	print("  From: ", global_position)
	print("  To: ", target_position)
	print("  Arc height: ", arc_height)

	# Calculate trajectory to reach target in flight_time seconds
	var displacement = target_position - global_position

	# Calculate horizontal velocity (constant)
	velocity.x = displacement.x / flight_time

	# Calculate vertical velocity accounting for gravity
	# Formula: v_y = (displacement_y / time) - (0.5 * gravity * time)
	# This ensures projectile lands at target despite gravity pulling it down
	velocity.y = (displacement.y / flight_time) - (0.5 * projectile_gravity * flight_time)

	# Add extra arc height (optional upward boost)
	velocity.y -= arc_height

	print("  Velocity: ", velocity)

func _on_body_entered(body: Node2D):
	if is_splattering:
		return

	print("Projectile hit: ", body.name, " (", body.get_class(), ")")

	# Check if hit player
	if body.is_in_group("Player") or body is PlatformerController2D:
		print("Hit player! Dealing damage...")
		_damage_player(body)
		_splatter()
	# Check if hit ground/walls
	elif body is TileMap or body is StaticBody2D or body is TileMapLayer:
		print("Hit terrain, splattering...")
		_splatter()
	else:
		print("Hit unknown object, splattering anyway...")
		_splatter()

func _damage_player(player: Node2D):
	# Projectile hits should instantly kill the player
	var death_manager = player.get_node_or_null("DeathManager")
	print("DeathManager found: ", death_manager != null)
	if death_manager and death_manager.has_method("trigger_enemy_death"):
		print("Projectile hit! Triggering enemy death")
		death_manager.trigger_enemy_death()
	else:
		print("ERROR: DeathManager not found or doesn't have trigger_enemy_death method!")

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
