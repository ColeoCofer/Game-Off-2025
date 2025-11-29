extends Area2D

signal bug_eaten()

# Hovering animation parameters
@export var hover_amplitude: float = 3.0
@export var hover_speed: float = 2.0
@export var fade_out_duration: float = 0.3
@export var hunger_restore_amount: float = 50.0

var time_passed: float = 0.0
var initial_y: float = 0.0

func _ready():
	# Store initial position for hovering effect
	initial_y = position.y

	# Connect to the body_entered signal
	body_entered.connect(_on_body_entered)

	# Play the animation
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("hover")

func _process(delta):
	# Create a gentle hovering/bobbing effect
	time_passed += delta
	position.y = initial_y + sin(time_passed * hover_speed) * hover_amplitude

func _on_body_entered(body: Node2D):
	# Check if the body that entered is the player
	if body is PlatformerController2D:
		# Restore hunger
		var hunger_manager = body.get_node_or_null("HungerManager")
		if hunger_manager:
			hunger_manager.consume_food(hunger_restore_amount)

		# Emit signal for game manager/UI to track collection
		bug_eaten.emit()

		# Play bite sound effect
		if has_node("BiteSound"):
			$BiteSound.play()

		# Play collection animation and remove
		_collect_animation()

func _collect_animation():
	# Stop hovering effect
	set_process(false)

	# Disable collision so player can't collect twice
	$CollisionShape2D.set_deferred("disabled", true)

	# Fade out animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, fade_out_duration)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), fade_out_duration)

	# Wait for sound to finish before freeing (if sound is playing)
	if has_node("BiteSound") and $BiteSound.stream:
		var sound_duration = $BiteSound.stream.get_length()
		var wait_time = max(fade_out_duration, sound_duration)
		tween.chain().tween_interval(wait_time - fade_out_duration)

	tween.tween_callback(queue_free)
