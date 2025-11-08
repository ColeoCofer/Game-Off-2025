extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@ontml:parameter>
@onready var damage_area: Area2D = $DamageArea
@onready var emission_timer: Timer = $EmissionTimer

## Emission settings
@export var min_interval: float = 2.0
@export var max_interval: float = 5.0
@export var emission_duration: float = 1.0

var is_emitting: bool = false

func _ready() -> void:
	# Disable damage area initially
	damage_area.monitoring = false

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
		animated_sprite.play("emit")  # Adjust animation name as needed

	# Enable damage area
	damage_area.monitoring = true

	# Wait for emission duration, then stop
	await get_tree().create_timer(emission_duration).timeout
	_stop_emission()

func _stop_emission() -> void:
	is_emitting = false

	# Stop animation (or play idle animation if you have one)
	if animated_sprite:
		animated_sprite.stop()

	# Disable damage area
	damage_area.monitoring = false

	# Schedule next emission
	_schedule_next_emission()

func _on_body_entered(body: Node2D) -> void:
	# Check if it's the player
	if body.is_in_group("player") or body.name == "Player":
		var death_manager = body.get_node_or_null("DeathManager")
		if death_manager and death_manager.has_method("trigger_hazard_death"):
			death_manager.trigger_hazard_death()
