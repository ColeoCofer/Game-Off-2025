extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_area: Area2D = $DamageArea
@onready var emission_timer: Timer = $EmissionTimer

## Emission settings
@export var min_interval: float = 2.0
@export var max_interval: float = 5.0
@export var emission_duration: float = 1.0
@export var boost_force: float = -400.0  ## Ah yes its gotta be negative 

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

	# Wait for emission duration, then stop
	await get_tree().create_timer(emission_duration).timeout
	_stop_emission()

func _stop_emission() -> void:
	is_emitting = false

	# Return to idle animation
	if animated_sprite:
		animated_sprite.play("idle")

	# Disable boost area
	damage_area.monitoring = false

	# Schedule next emission
	_schedule_next_emission()

func _on_body_entered(body: Node2D) -> void:
	print("Body entered: ", body.name, " | Groups: ", body.get_groups())

	# Check if it's the player (capital P...)
	if body.is_in_group("Player") or body.name == "Player":
		print("Player detected! Applying boost...")
		# Apply upward boost to the player
		if body is CharacterBody2D:
			body.velocity.y = boost_force
			print("Boost applied: ", boost_force)
		else:
			print("Body is not CharacterBody2D, it's: ", body.get_class())
