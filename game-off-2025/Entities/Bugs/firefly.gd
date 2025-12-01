extends Area2D

signal firefly_collected(firefly_id: int)

# Hovering animation parameters
@export var hover_amplitude: float = 2.0
@export var hover_speed: float = 1.5
@export var fade_out_duration: float = 0.4
@export var glow_energy: float = 1.5
@export var glow_pulse_speed: float = 2.0

# Unique ID for this firefly in the level (0, 1, or 2)
@export var firefly_id: int = 0
@export var hunger_restore_amount: float = 100.0

var time_passed: float = 0.0
var initial_y: float = 0.0
var is_collected: bool = false

func _ready():
	# Store initial position for hovering effect
	initial_y = position.y

	# Check if this firefly has already been collected
	_check_if_collected()

	# Connect to the body_entered signal
	body_entered.connect(_on_body_entered)

	# Play the animation
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("idle")

	# Set up glow effect
	if has_node("PointLight2D"):
		$PointLight2D.energy = glow_energy

func _process(delta):
	# Create a gentle hovering/bobbing effect
	time_passed += delta
	position.y = initial_y + sin(time_passed * hover_speed) * hover_amplitude

	# Pulse the glow effect
	if has_node("PointLight2D"):
		var pulse = 1.0 + sin(time_passed * glow_pulse_speed) * 0.3
		$PointLight2D.energy = glow_energy * pulse

func _check_if_collected():
	# Fireflies always spawn for replayability!
	# They're only tracked temporarily within a single level attempt
	# (We removed the permanent collection check so they're always fun to collect)
	pass

func _on_body_entered(body: Node2D):
	# Check if the body that entered is the player
	if is_collected:
		return

	if body is PlatformerController2D:
		# Mark as collected (temporarily for this instance only)
		is_collected = true

		# Restore hunger
		var hunger_manager = body.get_node_or_null("HungerManager")
		if hunger_manager:
			hunger_manager.consume_food(hunger_restore_amount)

		# Give player the firefly shield companion
		var firefly_manager = body.get_node_or_null("FireflyManager")
		if firefly_manager:
			firefly_manager.collect_firefly()

		# Emit signal for any listeners
		firefly_collected.emit(firefly_id)

		# Optional: Play collection sound effect here
		# if has_node("AudioStreamPlayer2D"):
		#     $AudioStreamPlayer2D.play()

		# Play collection animation and remove
		_collect_animation()

func _collect_animation():
	# Stop hovering effect
	set_process(false)

	# Disable collision so player can't collect twice
	$CollisionShape2D.set_deferred("disabled", true)

	# Fade out animation with a slight float-up effect
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, fade_out_duration)
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), fade_out_duration)
	tween.tween_property(self, "position:y", position.y - 30, fade_out_duration)
	tween.tween_callback(queue_free)
