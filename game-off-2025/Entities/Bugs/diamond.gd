extends Area2D

signal diamond_collected(diamond_id: int)

# Hovering animation parameters
@export var hover_amplitude: float = 3.0
@export var hover_speed: float = 1.8
@export var fade_out_duration: float = 0.5
@export var glow_energy: float = 2.0
@export var glow_pulse_speed: float = 2.5

# Unique ID for this diamond in the level (0, 1, or 2)
@export var diamond_id: int = 0

var time_passed: float = 0.0
var initial_y: float = 0.0
var is_collected: bool = false

func _ready():
	# Store initial position for hovering effect
	initial_y = position.y

	# Check if this diamond has already been collected
	_check_if_collected()

	# Connect to the body_entered signal
	body_entered.connect(_on_body_entered)

	# Set up glow effect
	if has_node("PointLight2D"):
		$PointLight2D.energy = glow_energy

func _process(delta):
	# Create a gentle hovering/bobbing effect
	time_passed += delta
	position.y = initial_y + sin(time_passed * hover_speed) * hover_amplitude

	# Pulse the glow effect
	if has_node("PointLight2D"):
		var pulse = 1.0 + sin(time_passed * glow_pulse_speed) * 0.4
		$PointLight2D.energy = glow_energy * pulse

func _check_if_collected():
	# Diamonds always spawn for replayability!
	# They're only tracked temporarily within a single level attempt
	pass

func _on_body_entered(body: Node2D):
	# Check if the body that entered is the player
	if is_collected:
		print("Diamond %d: already marked as collected (is_collected=true)" % diamond_id)
		return

	# Check if already collected in this run (temporary collection)
	if DiamondCollectionManager.is_diamond_collected_this_run(diamond_id):
		print("Diamond %d: already in current_run_collected array" % diamond_id)
		return

	if body is PlatformerController2D:
		print("Diamond %d: COLLECTING NOW!" % diamond_id)
		# Mark as collected (temporarily)
		is_collected = true

		# Save collection to manager (temporarily, until level completion)
		var current_level = SceneManager.current_level
		DiamondCollectionManager.collect_diamond(current_level, diamond_id)

		# Emit signal for any listeners
		diamond_collected.emit(diamond_id)

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

	# Sparkle and fade animation
	var tween = create_tween()
	tween.set_parallel(true)

	# Bright flash of light
	if has_node("PointLight2D"):
		tween.tween_property($PointLight2D, "energy", glow_energy * 3.0, fade_out_duration * 0.2)
		tween.tween_property($PointLight2D, "energy", 0.0, fade_out_duration * 0.8).set_delay(fade_out_duration * 0.2)

	# Scale up and fade
	tween.tween_property(self, "modulate:a", 0.0, fade_out_duration)
	tween.tween_property(self, "scale", Vector2(2.5, 2.5), fade_out_duration)
	tween.tween_property(self, "position:y", position.y - 40, fade_out_duration)

	tween.tween_callback(queue_free)
