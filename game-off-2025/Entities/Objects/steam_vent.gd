extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_area: Area2D = $DamageArea
@onready var emission_timer: Timer = $EmissionTimer

## Emission settings
@export var min_interval: float = 2.0
@export var max_interval: float = 5.0
@export var emission_duration: float = 1.0
@export var boost_force: float = -600.0  ## Consistent upward boost force applied to player 

var is_emitting: bool = false

func _ready() -> void:
	# Disable boost area initially
	damage_area.monitoring = false

	# Play idle animation
	if animated_sprite:
		animated_sprite.play("idle")

	# Connect signals
	damage_area.body_entered.connect(_on_body_entered)
	emission_timer.timeout.connect(_on_emission_timer_timeout)

	# Start the emission cycle
	_schedule_next_emission()

func _schedule_next_emission() -> void:
	var wait_time = randf_range(min_interval, max_interval)
	emission_timer.wait_time = wait_time
	emission_timer.start()

func _on_emission_timer_timeout() -> void:
	_emit_steam()

func _emit_steam() -> void:
	is_emitting = true

	# Play the steam animation
	if animated_sprite:
		animated_sprite.play("emit")

	# Enable boost area
	damage_area.monitoring = true

	# Need to wait one frame for the area to register overlapping bodies
	if not is_inside_tree():
		return
	await get_tree().process_frame

	# Check if still in tree after await
	if not is_inside_tree():
		return

	# Apply boost to any bodies already in the area
	_boost_bodies_in_area()

	# Wait for emission duration, then stop
	if not is_inside_tree():
		return
	await get_tree().create_timer(emission_duration).timeout

	# Check if still in tree after await
	if not is_inside_tree():
		return
	_stop_emission()

func _stop_emission() -> void:
	is_emitting = false

	# Return to idle animationr
	if animated_sprite:
		animated_sprite.play("idle")

	# Disable boost area
	damage_area.monitoring = false

	# Schedule next emission
	_schedule_next_emission()

func _boost_bodies_in_area() -> void:
	# Get all bodies currently overlapping with the damage area
	var bodies = damage_area.get_overlapping_bodies()

	for body in bodies:
		print("Body found: ", body.name, " | Groups: ", body.get_groups())
		# Check if it's the player
		if body.is_in_group("Player") or body.name == "Player":
			if body is CharacterBody2D:
				# Use apply_steam_boost method if available for consistent physics
				if body.has_method("apply_steam_boost"):
					body.apply_steam_boost(boost_force)
					print("Steam boost applied to player via method: ", boost_force)
				else:
					# Fallback to direct velocity set
					body.velocity.y = boost_force
					print("Steam boost applied to player (fallback): ", boost_force)
			else:
				print("Player found but not CharacterBody2D: ", body.get_class())

func _on_body_entered(body: Node2D) -> void:
	print("Body entered during emission: ", body.name)
	# Only boost if we're actively emitting
	if not is_emitting:
		return

	# Check if it's the player
	if body.is_in_group("Player") or body.name == "Player":
		if body is CharacterBody2D:
			# Use apply_steam_boost method if available for consistent physics
			if body.has_method("apply_steam_boost"):
				body.apply_steam_boost(boost_force)
				print("Steam boost applied on entry via method: ", boost_force)
			else:
				# Fallback to direct velocity set
				body.velocity.y = boost_force
				print("Steam boost applied on entry (fallback): ", boost_force)
